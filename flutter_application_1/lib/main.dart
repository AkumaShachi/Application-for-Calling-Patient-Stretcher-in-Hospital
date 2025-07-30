import 'package:flutter/material.dart';
import 'loginscreen.dart';
// import 'nurses_screen/nurse_list_case.dart';
// import 'porters_screen/porter_list_case.dart';

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
      home: LoginScreen(),
      // home: NurseListCaseScreen(),
      // home: PorterCaseListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
