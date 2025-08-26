import 'package:flutter/material.dart';
import 'loginscreen.dart';
import 'nurses_screen/nurse_add_case.dart';
import 'nurses_screen/nurse_ex-post_case.dart';
import 'registerscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppName',
      home: NurseAddCaseScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
