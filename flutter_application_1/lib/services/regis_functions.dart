// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RegisFunctions {
  static final baseUrl = dotenv.env['BASE_URL'];

  /// คืนค่าเป็นข้อความสถานะ: 'success', 'email_exists', หรือ error message
  static Future<String> addRegistrant(Map data) async {
    final url = Uri.parse('$baseUrl/registrant');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return 'success';
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        if (error['message'] == 'Email already exists') {
          return 'email_exists';
        } else {
          return 'error: ${error['message']}';
        }
      } else {
        return 'error: status code ${response.statusCode}';
      }
    } catch (e) {
      return 'error: $e';
    }
  }
}
