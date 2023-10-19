import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'damper.dart';
import 'damper_slider.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance
      .refFromURL("https://iflow-fe711-default-rtdb.firebaseio.com/");
  User? _user;
  Map<String, Damper> _dampers = {};
  FlutterBlue flutterBlue = FlutterBlue.instance;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  void _initUser() {
    _user = _auth.currentUser;
    if (_user != null) {
      _loadDampers();
    }
  }

  Future<String> _signIn(String email, String password) async {
    // Perform sign-in logic using Firebase Authentication
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      setState(() {
        _user = userCredential.user;
      });
      return "pass";
    } catch (e) {
      // Handle sign-in errors
      print('Sign-in failed: $e');
      if (e.toString().startsWith("[firebase_auth/user-not-found]")) {
        return "user-not-found";
      }

      return "fail";
    }
  }

  Future<bool> _register(String email, String password) async {
    // Perform registration logic using Firebase Authentication
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      setState(() {
        _user = userCredential.user;
      });
      return true;
    } catch (e) {
      // Handle registration errors
      print('Registration failed: $e');
      return false;
    }
  }

  Future<void> _signOut() async {
    // Perform sign-out logic using Firebase Authentication
    try {
      await _auth.signOut();
      setState(() {
        _user = null;
        _dampers = {};
      });
    } catch (e) {
      // Handle sign-out errors
      print('Sign-out failed: $e');
    }
  }

  Future<bool> requestBluetoothScanPermission() async {
    // This maps the permission_handler's Permission to the Android-specific string
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetoothScan, Permission.bluetoothConnect].request();

    print(statuses);
    return statuses[Permission.bluetoothConnect]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted;

    // if (statuses[Permission.bluetoothConnect]!.isGranted &&
    //     statuses[Permission.bluetoothScan]!.isGranted) {
    //   // Permission granted
    //   print("bluetooth permissions granted");
    //   return true;
    // } else if (statuses[Permission.bluetoothConnect]!.isDenied) {
    //   // Permission denied
    // } else if (statuses[Permission.bluetoothConnect]!.isPermanentlyDenied) {
    //   // The user opted to never again see the permission request dialog for this app.
    //   // Open the app settings to allow the user to grant the permission.
    //   openAppSettings();
    // }
    // return false;
  }

  Future<void> _connectToDamper(
      String damperId, String ssid, String password, String userId) async {
    var granted = await requestBluetoothScanPermission();
    if (!granted) return;

    _showLoadingDialog(context);

    String wifiServiceUUID = '00001800-0000-1000-8000-00805f9b34fb';
    String userIdServiceUUID = '00001801-0000-1000-8000-00805f9b34fb';
    flutterBlue.startScan(
        withServices: [Guid(wifiServiceUUID)],
        timeout: Duration(seconds: 30)).catchError((error) {
      print("Error starting scan: $error");
    });

    Set<String> seenDevices = {}; // Set to store unique device addresses

    // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (!seenDevices.contains(result.device.id.toString())) {
          // This is a new device
          seenDevices.add(result.device.id.toString());

          // Print device details
          print('Device Name: ${result.device.name}');
          print('Device ID: ${result.device.id}');
          print('Device RSSI: ${result.rssi}');
          print('Device Data: ${result.advertisementData}');
          print('-------------------------');
        }

        if (result.device.id.id.replaceAll(':', '').toLowerCase() ==
            damperId.toLowerCase()) {
          try {
            // Stop scanning
            flutterBlue.stopScan();

            // Connect to the selected device
            await result.device.connect().catchError((error) {
              _showFailureMessage(context, error.toString());
            });

            // Discover services after connecting to the device
            List<BluetoothService> services =
                await result.device.discoverServices();

            print(services);

            // Find the right service (using the service UUID provided)
            BluetoothService wifiService = services.firstWhere(
                (service) => service.uuid.toString() == wifiServiceUUID);

            BluetoothCharacteristic ssidCharacteristic =
                wifiService.characteristics.firstWhere((c) =>
                    c.uuid.toString() ==
                    "00002a00-0000-1000-8000-00805f9b34fb");
            BluetoothCharacteristic passwordCharacteristic =
                wifiService.characteristics.firstWhere((c) =>
                    c.uuid.toString() ==
                    "00002a01-0000-1000-8000-00805f9b34fb");

            BluetoothService userIdService = services.firstWhere(
                (service) => service.uuid.toString() == userIdServiceUUID);

            BluetoothCharacteristic userIdCharacteristic =
                userIdService.characteristics.firstWhere((c) =>
                    c.uuid.toString() ==
                    "00002ac4-0000-1000-8000-00805f9b34fb");

            await ssidCharacteristic.write(utf8.encode(ssid));
            await passwordCharacteristic.write(utf8.encode(password));
            await userIdCharacteristic.write(utf8.encode(userId));

            // Optionally, you can disconnect after a timeout or after certain operations
            // result.device.disconnect();

            _showSuccessMessage(context);

            setState(() {
              _dampers[damperId] =
                  Damper(damperId, "Damper ${_dampers.length + 1}", 0);
              _updateDampers();
            });
          } catch (e) {
            print(e);
            // Show error message dialog
            _showFailureMessage(context, e.toString());
          }
        }
      }
    });

    // Cancel the subscription after the scan timeout
    Future.delayed(Duration(seconds: 30), () {
      subscription.cancel();
      if (_dampers[damperId] == null && _isScanning) {
        _showFailureMessage(context, "Device not found");
      }
    });
  }

  void _addDamper() async {
    // var result = await _showNewDamperDialog(context);
    // String? damperId = result?['damperId'];
    // String? ssid = result?['ssid'];
    // String? password = result?['password'];

    String? damperId = "08b61f82f372";
    String? ssid = "Zenfone 9_3070";
    String? password = "mme9h4xpeq9mtdw";

    if (damperId != null && damperId.isNotEmpty) {
      _connectToDamper(damperId, ssid!, password!, _auth.currentUser!.uid);
    }
  }

  void _loadDampers() {
    _db.child(_auth.currentUser!.uid).get().then((snapshot) {
      if (snapshot.exists) {
        final dampersData = snapshot.value as Map<dynamic, dynamic>;
        print(dampersData);
        setState(() {
          _dampers = dampersData.map((id, data) => MapEntry(
              id,
              Damper(
                id,
                data['label'] ?? '',
                data['position'] ?? 0,
              )));
        });
      }
    });
  }

  void _updateDampers() {
    final dampersData = {
      for (var damper in _dampers.values)
        damper.id: {'label': damper.label, 'position': damper.currentPosition}
    };
    _db.child(_auth.currentUser!.uid).set(dampersData).then((_) {
      print("Dampers updated successfully in Realtime Database");
    }).catchError((error) {
      print("Error updating dampers in Realtime Database: $error");
      print(dampersData);
    });
  }

  void deleteRadioButtonGroup(String id) {
    setState(() {
      print(_dampers[id]);
      _dampers.remove(id);
      _updateDampers();
    });
  }

  void updatedSelected(String id, int? value) {
    setState(() {
      _dampers[id]?.currentPosition = value!;
      _updateDampers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("iFlow"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              if (_user == null) {
                showSignInDialog(context);
              } else {
                // Prompt to confirm sign out
                showSignOutDialog(context);
              }
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _dampers.length,
        itemBuilder: (context, index) {
          print("$index, ${_dampers.values.elementAt(index)}");
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: UniqueKey(),
                          initialValue: _dampers.values.elementAt(index).label,
                          decoration: InputDecoration(
                            labelText: 'Damper Name',
                          ),
                          onChanged: (value) {
                            _dampers.values.elementAt(index).label = value;
                            _updateDampers();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => showDeleteDamperDialog(context, index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: DamperSlider(
                          initialValue:
                              _dampers.values.elementAt(index).currentPosition,
                          onEnd: (endValue) {
                            updatedSelected(
                                _dampers.values.elementAt(index).id, endValue);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDamper,
        tooltip: 'Add new device',
        child: const Icon(Icons.add),
      ),
    );
  }

  void showDeleteDamperDialog(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                          'Are you sure you want to remove ${_dampers.values.elementAt(index).label}?'),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              deleteRadioButtonGroup(
                                  _dampers.values.elementAt(index).id);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )));
  }

  void showSignInDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final scaffold = ScaffoldMessenger.of(context);

    // Show sign-in/register options
    showDialog(
      context: context,
      builder: (context) {
        bool success_ = true;
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!success_) SizedBox(height: 16),
                  if (!success_)
                    Text("Invalid email or password",
                        style: TextStyle(
                          color: Colors.red,
                        )),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Perform sign-in logic
                      _signIn(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      ).then((response) {
                        if (response == "pass") {
                          scaffold.showSnackBar(
                              SnackBar(content: Text("Signed In")));
                          _loadDampers();
                          Navigator.pop(context);
                        } else if (response == "fail") {
                          setState(() {
                            success_ = false;
                          });
                        } else if (response == "user-not-found") {
                          _register(emailController.text.trim(),
                                  passwordController.text.trim())
                              .then((success) {
                            if (success) {
                              scaffold.showSnackBar(SnackBar(
                                  content: Text("Account registered")));
                              Navigator.pop(context);
                            } else {
                              setState(() {
                                success_ = false;
                              });
                            }
                          });
                        }
                      });
                    },
                    child: Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to sign out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Perform sign-out logic
                  _signOut();
                  Navigator.pop(context);
                },
                child: Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String?>?> _showNewDamperDialog(
      BuildContext context) async {
    String? damperId;
    String? ssid;
    String? password;

    return showDialog<Map<String, String?>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  damperId = value;
                },
                decoration: InputDecoration(hintText: "Damper ID"),
              ),
              SizedBox(height: 10), // Spacer
              TextField(
                onChanged: (value) {
                  ssid = value;
                },
                decoration: InputDecoration(hintText: "SSID"),
              ),
              SizedBox(height: 10), // Spacer
              TextField(
                onChanged: (value) {
                  password = value;
                },
                decoration: InputDecoration(hintText: "Password"),
                obscureText: true, // To hide password input
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop({
                  'damperId': damperId,
                  'ssid': ssid,
                  'password': password,
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context) {
    _isScanning = true;
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents the user from closing the dialog by tapping outside of it
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Connecting..."),
            ],
          ),
        );
      },
    ).then((value) => _isScanning = false);
  }

  void _showSuccessMessage(BuildContext context) {
    if (_isScanning) Navigator.of(context).pop(); // Close the loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected successfully!')),
    );
  }

  void _showFailureMessage(BuildContext context, String reason) {
    if (_isScanning) Navigator.of(context).pop(); // Close the loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connection failed: $reason')),
    );
  }
}
