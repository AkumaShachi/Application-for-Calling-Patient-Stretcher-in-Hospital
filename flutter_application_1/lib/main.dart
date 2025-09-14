import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'loginscreen.dart';
import 'services/user_prefs.dart';

void main() async {
  await dotenv.load(fileName: "assets/.env");
  await UserPreferences.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppName',
      home: LoginScreen(),
      // home: NurseAddCaseScreen(),
      debugShowCheckedModeBanner: false, //บอมหัวควย
    );
  }
}
