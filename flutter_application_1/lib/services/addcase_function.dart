// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AddcaseFunction {
  static final baseUrl = dotenv.env['BASE_URL'];

  static Future<void> saveCase(Map<String, dynamic> caseData) async {
    final url = Uri.parse('$baseUrl/add_case');
    print('Request body: ${jsonEncode(caseData)}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(caseData),
      );

      if (response.statusCode == 200) {
        print('Case saved successfully');
      } else {
        print('Failed to save case: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving case: $e');
    }
  }
}
