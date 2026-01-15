import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/user_prefs.dart';

import 'loginscreen.dart';

void main() async {
  await dotenv.load(fileName: "assets/.env");
  await UserPreferences.init();
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'th'; // ให้ intl ใช้ภาษาไทย
  await initializeDateFormatting('th'); // เตรียมฟอร์แมตภาษาไทย
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale(
        'th',
      ), // บังคับเป็นไทย (หรือเอาออกเพื่อใช้ตามเครื่อง)
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Calling Stretcher',
      home: const LoginScreen(),
    );
  }
}
