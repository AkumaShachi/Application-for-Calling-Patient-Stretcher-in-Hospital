// ignore_for_file: avoid_print, unintended_html_in_doc_comment
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ResetFunctions {
  static final baseUrl = dotenv.env['BASE_URL'];

  /// คืนค่าเป็น Map<String, dynamic> หรือ null ถ้า error
  static Future<Map<String, dynamic>?> resetPassword(
    Map<String, dynamic> resetData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-reset-pass'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(resetData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Reset email sent: $data');
        return data;
      } else {
        final data = jsonDecode(response.body);
        print('Failed to send reset email: $data');
        return data;
      }
    } catch (e) {
      print('Error sending reset email: $e');
      return null;
    }
  }
}
