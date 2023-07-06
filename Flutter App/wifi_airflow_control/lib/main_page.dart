import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'damper.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  User? _user;
  List<Damper> _dampers = [];

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  void _initUser() {
    _user = _auth.currentUser;
  }

  Future<bool> _signIn(String email, String password) async {
    // Perform sign-in logic using Firebase Authentication
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      setState(() {
        _user = userCredential.user;
      });
      return true;
    } catch (e) {
      // Handle sign-in errors
      print('Sign-in failed: $e');
      if (e.toString().startsWith("[firebase_auth/user-not-found]")) {
        return await _register(email, password);
      }

      return false;
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
      });
    } catch (e) {
      // Handle sign-out errors
      print('Sign-out failed: $e');
    }
  }

  void deleteRadioButtonGroup(int index) {
    setState(() {
      print(_dampers[index]);
      _dampers.removeAt(index);
    });
  }

  void updatedSelected(int index, int? value) {
    setState(() {
      _dampers[index].currentPosition = value!;
    });
  }

  void addNewRadioButtonGroup() {
    setState(() {
      _dampers.add(Damper(
          "Damper ${_dampers.length + 1}", ["0", "25", "50", "75", "100"], 0));
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
          print("$index, ${_dampers[index]}");
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
                          initialValue: _dampers[index].label,
                          decoration: InputDecoration(
                            labelText: 'Damper Name',
                          ),
                          onChanged: (value) => _dampers[index].label = value,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _dampers[index].positions.map((option) {
                      int optionIndex =
                          _dampers[index].positions.indexOf(option);
                      return Column(
                        children: [
                          Radio(
                            value: optionIndex,
                            groupValue: _dampers[index].currentPosition,
                            onChanged: (int? value) =>
                                updatedSelected(index, value),
                          ),
                          Text(option),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewRadioButtonGroup,
        tooltip: 'Add new group',
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
                          'Are you sure you want to remove ${_dampers[index].label}?'),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              deleteRadioButtonGroup(index);
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
                      ).then((success) => {
                            if (success)
                              {Navigator.pop(context)}
                            else
                              {
                                _register(emailController.text.trim(),
                                        passwordController.text.trim())
                                    .then((success) => {
                                          if (success)
                                            {Navigator.pop(context)}
                                          else
                                            {
                                              setState(() {
                                                success_ = false;
                                              })
                                            }
                                        })
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
