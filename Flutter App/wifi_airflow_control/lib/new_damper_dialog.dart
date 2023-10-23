import 'package:flutter/material.dart';

class NewDamperDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String? damperId;
    String? ssid;
    String? password;

    // damperId = "08b61f82f372";
    // ssid = "Zenfone 9_3070";
    // password = "mme9h4xpeq9mtdw";
    // ssid = "Adkins";
    // password = "chuck1229";

    // Create TextEditingControllers for each TextField
    final damperIdController = TextEditingController(text: damperId);
    final ssidController = TextEditingController(text: ssid);
    final passwordController = TextEditingController(text: password);

    return AlertDialog(
      title: Text('Enter Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: damperIdController,
            onChanged: (value) {
              damperId = value;
            },
            decoration: InputDecoration(hintText: "Damper ID"),
          ),
          SizedBox(height: 10), // Spacer
          TextField(
            controller: ssidController,
            onChanged: (value) {
              ssid = value;
            },
            decoration: InputDecoration(hintText: "SSID"),
          ),
          SizedBox(height: 10), // Spacer
          TextField(
            controller: passwordController,
            onChanged: (value) {
              password = value;
            },
            decoration: InputDecoration(hintText: "Password"),
            obscureText: true, // To hide password input
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop({
              'damperId': damperId,
              'ssid': ssid,
              'password': password,
            });
          },
        ),
      ],
    );
  }
}
