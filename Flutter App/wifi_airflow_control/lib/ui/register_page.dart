import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? email;
  String? password;
  String? _error;

  Future<String> _register(String email, String password) async {
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
      return "pass";
    } catch (e) {
      // Handle registration errors
      print('Registration failed: $e');
      return e.toString().split('] ')[1];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!,
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
                _register(emailController.text.trim(),
                        passwordController.text.trim())
                    .then((response) {
                  if (response == 'pass') {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Account registered")));
                    Navigator.pop(context, _user);
                  } else {
                    setState(() {
                      _error = response;
                    });
                  }
                });
              },
              child: Text('Register'),
            )
          ],
        ),
      ),
    );
  }
}
