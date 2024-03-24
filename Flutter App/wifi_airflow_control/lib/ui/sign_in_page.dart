import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wifi_airflow_control/ui/dialogs/email_wait_dialog.dart';
import 'package:wifi_airflow_control/ui/register_page.dart';

class SignInPage extends StatefulWidget {
  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
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
      return e.toString().split('] ')[1];
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential authResult =
            await _auth.signInWithCredential(credential);
        _user = authResult.user;
        return "pass";
      } else {
        return "Google Sign In Failed";
      }
    } catch (error) {
      print(error);
      if (error is PlatformException) {
        PlatformException e = error;
        var message = capitalize(e.code.replaceAll('_', ' '));
        return message;
      }
      return "Google Sign In Failed";
    }
  }

  String capitalize(String input) {
    return input
        .split(" ")
        .map((str) => str[0].toUpperCase() + str.substring(1))
        .join(" ");
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  // Perform sign-in logic
                  _signIn(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  ).then((response) {
                    if (response == "pass") {
                      if (_user?.emailVerified ?? false) {
                        scaffold
                            .showSnackBar(SnackBar(content: Text("Signed In")));
                        Navigator.pop(context);
                      } else {
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
                      }
                    } else {
                      setState(() {
                        _error = response;
                      });
                    }
                  }); // _signIn
                },
                child: Text('Sign In'),
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push<bool?>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterPage(),
                        )).then((isValidated) {
                      if (isValidated != null) {
                        Navigator.pop(context, isValidated);
                      }
                    });
                  },
                  child: Text('Register')),
              ElevatedButton(
                child: Text('Sign in with Google'),
                onPressed: () async {
                  await _signInWithGoogle().then((response) {
                    if (response == "pass") {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _error = response;
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
