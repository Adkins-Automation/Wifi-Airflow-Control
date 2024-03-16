import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wifi_airflow_control/ui/profile_page.dart';
import 'dart:async';

import 'package:wifi_airflow_control/ui/sign_in_page.dart';

class EmailWaitPage extends StatefulWidget {
  @override
  EmailWaitPageState createState() => EmailWaitPageState();
}



class EmailWaitPageState extends State<EmailWaitPage> {
FirebaseAuth _auth = FirebaseAuth.instance;
  //User? _user;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  String? _error;
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
          Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                      ),
                      );
        } 
      });
    }

    @override
    void dispose() {
      super.dispose();
      _timer.cancel();
    }


Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:Text("Email verification link sent to your email")
      )
    );
}
}