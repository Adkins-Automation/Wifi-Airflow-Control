import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:i_flow/register_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _error;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign In"),
      ),
      body: Padding(
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
            if (_error != null) SizedBox(height: 16),
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
                // Perform sign-in logic
                _signIn(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                ).then((response) {
                  if (response == "pass") {
                    scaffold.showSnackBar(SnackBar(content: Text("Signed In")));
                    Navigator.pop(context, _user);
                  } else if (response == "fail") {
                    setState(() {
                      _error = "Invalid username or password";
                    });
                  } else if (response == "user-not-found") {
                    setState(() {
                      _error = "User not found";
                    });
                  }
                }); // _signIn
              },
              child: Text('Sign In'),
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push<User?>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterScreen(),
                      )).then((value) {
                    if (value != null) Navigator.pop(context, value);
                  });
                },
                child: Text('Register')),
          ],
        ),
      ),
    );
  }
}
