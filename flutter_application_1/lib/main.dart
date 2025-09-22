import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/user_prefs.dart';

import 'loginscreen.dart';

void main() async {
  await dotenv.load(fileName: "assets/.env");
  await UserPreferences.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Calling Stretcher', home: const LoginScreen());
  }
}
