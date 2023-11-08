import 'package:shared_preferences/shared_preferences.dart';

Future<void> setOnboardingCompleted() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboardingCompleted', true);
}

Future<bool> isOnboardingCompleted() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboardingCompleted') ?? false;
}
