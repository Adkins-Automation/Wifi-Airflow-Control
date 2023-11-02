import 'package:flutter/material.dart';

class SignOutDialog extends StatelessWidget {
  final Function _signOut;
  SignOutDialog(this._signOut);
  @override
  Widget build(BuildContext context) {
    return Dialog(
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
    );
  }
}
