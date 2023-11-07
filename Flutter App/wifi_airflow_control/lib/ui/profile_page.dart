import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wifi_airflow_control/ui/dialogs/sign_out_dialog.dart';

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? currentUser;

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _displayNameController.text = currentUser?.displayName ?? '';
    _emailController.text = currentUser?.email ?? '';
    _phoneNumberController.text = currentUser?.phoneNumber ?? '';
    _photoUrlController.text = currentUser?.photoURL ?? '';
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
              ElevatedButton(
                onPressed: _updatePhotoUrl,
                child: Text('Update Photo'),
              ),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                ),
              ),
              ElevatedButton(
                onPressed: _updateDisplayName,
                child: Text('Update Display Name'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
              ElevatedButton(
                onPressed: _updateEmail,
                child: Text('Update Email'),
              ),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                ),
              ),
              ElevatedButton(
                onPressed: _updatePhoneNumber,
                child: Text('Update Phone Number'),
              ),
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
              if (currentUser!.providerData
                  .where((element) => element.providerId == 'google.com')
                  .isEmpty)
                ElevatedButton(
                  onPressed: _linkGoogleAccount,
                  child: Text('Link Google Account'),
                ),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateDisplayName() async {
    try {
      await currentUser?.updateDisplayName(_displayNameController.text);
      setState(() {
        currentUser = _auth.currentUser;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _updateEmail() async {
    try {
      await currentUser?.updateEmail(_emailController.text);
      setState(() {
        currentUser = _auth.currentUser;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _updatePhoneNumber() async {
    // Phone number updating requires a more complex flow involving SMS verification.
    // This is a placeholder and the actual implementation would be more involved.
    print("Phone number updating goes here");
  }

  Future<void> _updatePhotoUrl() async {
    try {
      await currentUser?.updatePhotoURL(_photoUrlController.text);
      setState(() {
        currentUser = _auth.currentUser;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _updatePassword() async {
    try {
      await currentUser?.updatePassword(_passwordController.text);
    } catch (e) {
      _showError(e.toString());
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
      _showError(e.toString());
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _photoUrlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
