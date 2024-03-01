import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'util/firebase_options.dart';
import 'ui/main_page.dart';

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();

  static AppState of(BuildContext context) =>
      context.findAncestorStateOfType<AppState>()!;
}

class AppState extends State<App> {
  ThemeMode _themeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iFlow',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(), // standard dark theme
      themeMode: _themeMode,
      home: MainPage(),
    );
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(App());
}
