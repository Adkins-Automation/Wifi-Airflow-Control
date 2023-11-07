import 'package:flutter/material.dart';

class TextPromptDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;

  TextPromptDialog({
    required this.title,
    this.hintText,
    this.initialValue,
    this.validator,
    this.onSaved,
  });

  @override
  TextPromptDialogState createState() => TextPromptDialogState();
}

class TextPromptDialogState extends State<TextPromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialValue ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _textController,
          decoration: InputDecoration(hintText: widget.hintText),
          validator: widget.validator,
          onSaved: widget.onSaved,
        ),
      ),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text("OK"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.pop(context, _textController.text);
            }
          },
        ),
      ],
    );
  }
}
