import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wifi_airflow_control/ui/onboarding_page.dart';
import 'package:wifi_airflow_control/util/shared_preferences.dart';
import 'util/firebase_options.dart';
import 'ui/main_page.dart';

class App extends StatefulWidget {
  final bool onboardingFinished;
  App({required this.onboardingFinished});
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iFlow',
      home: widget.onboardingFinished ? MainPage() : OnboardingPage(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  bool onboardingFinished = await isOnboardingCompleted();
  runApp(App(onboardingFinished: onboardingFinished));
}
