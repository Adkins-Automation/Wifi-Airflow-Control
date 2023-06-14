import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class Damper {
  String label;
  List<String> positions;
  int currentPosition;

  Damper(this.label, this.positions, this.currentPosition);

  @override
  String toString() {
    return "$label, ${positions[currentPosition]}";
  }
}

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? _user;
  List<Damper> dampers = [];

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  void _initUser() {
    _user = _auth.currentUser;
  }

  Future<void> _signIn(String email, String password) async {
    // Perform sign-in logic using Firebase Authentication
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      setState(() {
        _user = userCredential.user;
      });
    } catch (e) {
      // Handle sign-in errors
      print('Sign-in failed: $e');
    }
  }

  Future<void> _register(String email, String password) async {
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
    } catch (e) {
      // Handle registration errors
      print('Registration failed: $e');
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
      print(dampers[index]);
      dampers.removeAt(index);
    });
  }

  void updatedSelected(int index, int? value) {
    setState(() {
      dampers[index].currentPosition = value!;
    });
  }

  void addNewRadioButtonGroup() {
    setState(() {
      dampers.add(Damper(
          "Damper ${dampers.length + 1}", ["0", "25", "50", "75", "100"], 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iFlow',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("iFlow"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                if (_user == null) {
                  final TextEditingController emailController =
                      TextEditingController();
                  final TextEditingController passwordController =
                      TextEditingController();

                  // Show sign-in/register options
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => Dialog(
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
                                );
                                Navigator.pop(context);
                              },
                              child: Text('Sign In'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Prompt to confirm sign out
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
              },
            )
          ],
        ),
        body: ListView.builder(
          itemCount: dampers.length,
          itemBuilder: (context, index) {
            print("$index, ${dampers[index]}");
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
                            initialValue: dampers[index].label,
                            decoration: InputDecoration(
                              labelText: 'Damper Name',
                            ),
                            onChanged: (value) => dampers[index].label = value,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => showDialog(
                              context: context,
                              builder: (BuildContext context) => Dialog(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                                'Are you sure you want to remove ${dampers[index].label}?'),
                                            const SizedBox(height: 15),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    deleteRadioButtonGroup(
                                                        index);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                        color: Colors.red),
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
                                  ))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: dampers[index].positions.map((option) {
                        int optionIndex =
                            dampers[index].positions.indexOf(option);
                        return Column(
                          children: [
                            Radio(
                              value: optionIndex,
                              groupValue: dampers[index].currentPosition,
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
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(App());
}
