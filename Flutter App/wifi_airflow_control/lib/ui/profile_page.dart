import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wifi_airflow_control/ui/dialogs/sign_out_dialog.dart';
import 'package:wifi_airflow_control/ui/dialogs/text_prompt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_airflow_control/main.dart';

class ProfilePage extends StatefulWidget {
  final textStyle = TextStyle(fontSize: 20.0);
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? currentUser;
  SharedPreferences? prefs;
  bool _darkMode = false;

  void getPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    getPref();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (currentUser?.photoURL != null)
                ClipOval(child: Image.network(currentUser!.photoURL!)),
              SizedBox(height: 16),
              Text(currentUser?.displayName ?? '', style: widget.textStyle),
              ElevatedButton(
                onPressed: _updateDisplayName,
                child: Text('Update Display Name'),
              ),
              SizedBox(height: 16),
              Text(currentUser?.email ?? '', style: widget.textStyle),
              ElevatedButton(
                onPressed: _updateEmail,
                child: Text('Update Email'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
              ElevatedButton(
                onPressed: _updatePassword,
                child: Text('Update Password'),
              ),
              SizedBox(height: 16),
              if (currentUser!.providerData
                  .where((element) => element.providerId == 'google.com')
                  .isEmpty)
                ElevatedButton(
                  onPressed: _linkGoogleAccount,
                  child: Text('Link Google Account'),
                )
              else
                ElevatedButton(
                    onPressed: _unlinkGoogleAccount,
                    child: Text('Unlink Google Account')),
              SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => SignOutDialog(() {
                              _auth
                                  .signOut()
                                  .then((_) => Navigator.pop(context));
                            }));
                  },
                  child: Text('Sign Out')),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny,
                      color: _darkMode ? Colors.grey : Colors.yellow),
                  Switch(
                    value: _darkMode,
                    onChanged: (bool value) {
                      setState(() {
                        _darkMode = value;
                        changeTheme(_darkMode);
                      });
                    },
                  ),
                  Icon(Icons.nights_stay,
                      color: _darkMode ? Colors.blue : Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void changeTheme(bool darkMode) {
    //final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs != null) {
      prefs?.setBool('lightTheme', !darkMode);
      App.of(context).changeTheme(darkMode ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _updateDisplayName() async {
    try {
      String? displayName = await showDialog(
          context: context,
          builder: (context) => TextPromptDialog(
                title: 'Display Name',
                initialValue: currentUser?.displayName,
              ));
      if (displayName == null) return;
      await currentUser?.updateDisplayName(displayName);
      setState(() {
        currentUser = _auth.currentUser;
      });
    } catch (e) {
      var message = "Failed to update display name";
      if (e is FirebaseAuthException) {
        message = e.message ?? message;
      }
      _showMessage(message);
    }
  }

  Future<void> _updateEmail() async {
    try {
      String? email = await showDialog(
          context: context,
          builder: (context) => TextPromptDialog(
                title: 'Email',
                initialValue: currentUser?.email,
              ));
      if (email == null) return;
      await currentUser?.updateEmail(email);
      setState(() {
        currentUser = _auth.currentUser;
      });
    } catch (e) {
      var message = "Failed to update email";
      if (e is FirebaseAuthException) {
        message = e.message ?? message;
      }
      _showMessage(message);
    }
  }

  Future<void> _updatePassword() async {
    try {
      await currentUser?.updatePassword(_passwordController.text);
      _showMessage("Password Updated");
      setState(() {
        _passwordController.text = '';
      });
    } catch (e) {
      var message = "Failed to update password";
      if (e is FirebaseAuthException) {
        message = e.message ?? message;
      }
      _showMessage(message);
    }
  }

  Future<void> _unlinkGoogleAccount() async {
    try {
      await currentUser?.unlink('google.com');
      setState(() {
        currentUser = _auth.currentUser;
      });
    } catch (e) {
      print(e);
      _showMessage("Failed to unlink Google Account");
    }
  }

  Future<void> _linkGoogleAccount() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await currentUser?.linkWithCredential(credential);
        setState(() {
          currentUser = _auth.currentUser;
        });
      }
    } catch (e) {
      print(e);
      _showMessage("Failed to link Google Account");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
