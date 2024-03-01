import 'package:flutter/material.dart';

class ConnectingDialog extends StatefulWidget {
  final String initialMessage;
  ConnectingDialog({Key? key, required this.initialMessage}) : super(key: key);

  @override
  ConnectingDialogState createState() => ConnectingDialogState();
}

class ConnectingDialogState extends State<ConnectingDialog> {
  String message = '';

  @override
  void initState() {
    super.initState();
    message = widget.initialMessage;
  }

  void updateMessage(String newMessage) {
    setState(() {
      message = newMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text(message),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
