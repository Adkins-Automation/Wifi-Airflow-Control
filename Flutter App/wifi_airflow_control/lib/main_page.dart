import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

  void addNewDamper() {
    /*
    todo
    1. scan/type code
    2. connect via bluetooth
    -- get wifi credentials???
    3. send wifi credentials
    4. wait for device to connect to wifi
    5. add damper to account
    */
    final id = "damper${_dampers.length + 1}";
    setState(() {
      _dampers[id] = Damper(id, "Damper ${_dampers.length + 1}", 0);
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
        onPressed: addNewDamper,
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
}
