import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:i_flow/util/constants.dart';
import 'package:i_flow/ui/sign_in_page.dart';
import 'package:i_flow/ui/dialogs/sign_out_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import '../dto/damper.dart';
import 'widgets/damper_slider.dart';
import 'dialogs/delete_damper_dialog.dart';
import 'new_damper_page.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.refFromURL(firebaseUrl);
  User? _user;
  Map<String, Damper> _dampers = {};
  FlutterBlue flutterBlue = FlutterBlue.instance;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initUser();

    Timer.periodic(Duration(minutes: 1), (timer) {
      _downloadDampers();
    });
  }

  void _initUser() {
    _user = _auth.currentUser;
    if (_user != null) {
      _downloadDampers();
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

  Future<bool> _requestBluetoothScanPermission() async {
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
    var granted = await _requestBluetoothScanPermission();
    if (!granted) return;

    _showConnectingDialog();

    flutterBlue.startScan(
        withServices: [Guid(wifiServiceUUID)],
        timeout: Duration(seconds: 30)).catchError((error) {
      print("Error starting scan: $error");
    });

    damperId = damperId.replaceAll(':', '').toLowerCase();
    Set<String> seenDevices = {}; // Set to store unique device addresses

    // Listen to scan results
    StreamSubscription<List<ScanResult>>? subscription;
    subscription = flutterBlue.scanResults.listen((results) async {
      // Check if dialog is still active
      if (!_isConnecting) {
        flutterBlue.stopScan();
        subscription?.cancel();
        return;
      }

      for (ScanResult result in results) {
        String deviceId = result.device.id.id.replaceAll(':', '').toLowerCase();
        if (!seenDevices.contains(deviceId)) {
          // This is a new device
          seenDevices.add(deviceId);

          // Print device details
          print('Device Name: ${result.device.name}');
          print('Device ID: ${result.device.id}');
          print('Device RSSI: ${result.rssi}');
          print('Device Data: ${result.advertisementData}');
          print('-------------------------');
        }

        if (deviceId == damperId) {
          try {
            // Stop scanning
            flutterBlue.stopScan();

            // Connect to the selected device
            await result.device.connect().catchError((error) {
              _showFailureMessage(error.toString());
            });

            // Discover services after connecting to the device
            List<BluetoothService> services =
                await result.device.discoverServices();

            print("services: $services");

            // Find the right service (using the service UUID provided)
            BluetoothService wifiService = services.firstWhere(
                (service) => service.uuid.toString() == wifiServiceUUID);

            BluetoothCharacteristic xCharacteristic = wifiService
                .characteristics
                .firstWhere((c) => c.uuid.toString() == wifiCharacteristicUUID);

            var x = '$ssid;$password;$userId';

            await xCharacteristic.write(utf8.encode(x));

            StreamSubscription<DatabaseEvent>? subscription;
            subscription =
                _db.child(userId).child(damperId).onValue.listen((event) {
              // Check if dialog is still active
              if (!_isConnecting) {
                subscription?.cancel();
                return;
              }
              print(event.snapshot.value);
              if (event.snapshot.value != null) {
                var data = event.snapshot.value as Map<dynamic, dynamic>;
                if (data['label'] == null ||
                    data['position'] == null ||
                    data['lastHeartbeat'] == null) {
                  return;
                }
                _showSuccessMessage();
                _downloadDampers();
                subscription?.cancel();
              }
            });
          } catch (e) {
            print(e);
            _showFailureMessage(e.toString());
          }

          result.device.disconnect();
        }
      }
    });

    // Cancel the subscription after the scan timeout
    Future.delayed(Duration(seconds: 30), () {
      subscription?.cancel();
      if (!seenDevices.contains(damperId) && _isConnecting) {
        _showFailureMessage("Device not found");
      }
    });
  }

  void _addDamper() async {
    if (_auth.currentUser == null) {
      _showSignInDialog(context);
      return;
    }
    var result = await _showNewDamperDialog(context);
    String? damperId = result?['damperId'];
    String? ssid = result?['ssid'];
    String? password = result?['password'];

    if (damperId != null &&
        damperId.isNotEmpty &&
        ssid != null &&
        ssid.isNotEmpty &&
        password != null &&
        password.isNotEmpty) {
      _connectToDamper(damperId, ssid, password, _auth.currentUser!.uid);
    }
  }

  void _downloadDampers() {
    if (_auth.currentUser == null) return;
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
                data['lastHeartbeat'],
              )));
        });
      }
    });
  }

  void _uploadDampers() {
    final dampersData = {
      for (var damper in _dampers.values)
        damper.id: {
          'label': damper.label,
          'position': damper.currentPosition,
          'lastHeartbeat': damper.lastHeartbeat
        }
    };
    _db.child(_auth.currentUser!.uid).set(dampersData).then((_) {
      print("Dampers updated successfully in Realtime Database");
    }).catchError((error) {
      print("Error updating dampers in Realtime Database: $error");
      print(dampersData);
    });
  }

  void _deleteDamper(String id) {
    setState(() {
      print(_dampers[id]);
      _dampers.remove(id);
      _uploadDampers();
    });
  }

  void _updatePosition(String id, int? value) {
    setState(() {
      _dampers[id]?.currentPosition = value!;
      _uploadDampers();
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
            onPressed: () async {
              if (_user == null) {
                User? user = await _showSignInDialog(context);
                setState(() {
                  _user = user;
                  if (_user != null) _downloadDampers();
                });
              } else {
                // Prompt to confirm sign out
                _showSignOutDialog(context);
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            _downloadDampers();
          },
          child: ListView.builder(
            itemCount: _dampers.length,
            itemBuilder: (context, index) {
              print("$index, ${_dampers.values.elementAt(index)}");
              final damper = _dampers.values.elementAt(index);
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
                              initialValue: damper.label,
                              decoration: InputDecoration(
                                labelText: 'Damper Name',
                              ),
                              onChanged: (value) {
                                damper.label = value;
                                _uploadDampers();
                              },
                            ),
                          ),
                          Text(damper.isOnline() ? "Online" : "Offline"),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  damper.isOnline() ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _showDeleteDamperDialog(context, index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: DamperSlider(
                              initialValue: damper.currentPosition,
                              onEnd: (endValue) {
                                _updatePosition(damper.id, endValue);
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
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDamper,
        tooltip: 'Add new device',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDamperDialog(BuildContext context, int index) {
    DeleteDamperDialog deleteDamperDialog =
        DeleteDamperDialog(_dampers.values.elementAt(index), _deleteDamper);
    showDialog(
        context: context,
        builder: (BuildContext context) => deleteDamperDialog.build(context));
  }

  Future<User?> _showSignInDialog(BuildContext context) async {
    return await Navigator.push<User?>(
        context, MaterialPageRoute(builder: ((context) => SignInPage())));
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => SignOutDialog(_signOut),
    );
  }

  Future<Map<String, String?>?> _showNewDamperDialog(
      BuildContext context) async {
    return await Navigator.push<Map<String, String?>>(
      context,
      MaterialPageRoute(builder: (BuildContext context) => NewDamperPage()),
    );
  }

  void _showConnectingDialog() {
    _isConnecting = true;
    showDialog(
      context: context,
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
    ).then((value) => _isConnecting = false);
  }

  void _showSuccessMessage() {
    if (_isConnecting) Navigator.of(context).pop(); // Close the loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected successfully!')),
    );
  }

  void _showFailureMessage(reason) {
    if (_isConnecting) Navigator.of(context).pop(); // Close the loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connection failed: $reason')),
    );
  }
}