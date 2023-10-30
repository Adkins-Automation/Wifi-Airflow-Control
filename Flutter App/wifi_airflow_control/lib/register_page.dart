import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget{
  @override
  // ignore: library_private_types_in_public_api
  _RegistrationPageState createState() => _RegistrationPageState(); 
}

class _RegistrationPageState extends State<RegistrationPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registration Page',
          ),
        ),
        body: Padding(padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Full Name'),
          ),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email Address'),),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (){
                String name = nameController.text;
                String email = emailController.text;
                String password = passwordController.text;

                print('Name: $name');
                print('Email: $email');
                print('Password: $password');
              },
              child: Text('Register'),)

        ],),
        ),
    );
  }
}