import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class EmailWaitPage extends StatefulWidget {
  @override
  EmailWaitPageState createState() => EmailWaitPageState();
}

class EmailWaitPageState extends State<EmailWaitPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    user?.sendEmailVerification();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified ?? false) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Email verification link sent to your email"),
        SizedBox(height: 20),
        CircularProgressIndicator(),
      ]),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ),
      ],
    );
  }
}
