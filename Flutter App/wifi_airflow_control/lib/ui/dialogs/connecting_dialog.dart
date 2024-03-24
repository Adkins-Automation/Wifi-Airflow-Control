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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
