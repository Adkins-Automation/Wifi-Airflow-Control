import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wifi_airflow_control/ui/dialogs/email_wait_dialog.dart';

class RegisterPage extends StatefulWidget {
  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  String? _error;
  User? _user;

  Future<String> _register(
      {required String email, required String password, String? name}) async {
    // Perform registration logic using Firebase Authentication
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (name != null) {
        await userCredential.user?.updateDisplayName(name);
      }
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_error != null)
                Text(_error!,
                    style: TextStyle(
                      color: Colors.red,
                    )),
              SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name (optional)',
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
                  _register(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          name: nameController.text.trim())
                      .then((response) {
                    if (response == 'pass') {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Account registered")));
                      showDialog<bool?>(
                        context: context,
                        builder: (BuildContext context) {
                          return EmailWaitPage();
                        },
                        barrierDismissible: false,
                      ).then((isValidated) {
                        if (isValidated != null) {
                          Navigator.of(context).pop(isValidated);
                        }
                      });
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
      ),
    );
  }
}
