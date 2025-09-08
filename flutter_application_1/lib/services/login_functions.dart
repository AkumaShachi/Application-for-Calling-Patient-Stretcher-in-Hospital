// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LoginFunctions {
  static final baseUrl = dotenv.env['BASE_URL'];

  // return เป็น Map<String, dynamic> หรือ null ถ้า failed
  static Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        // แปลง JSON string ที่ server ส่งกลับเป็น Map
        final data = jsonDecode(response.body);
        print('Login successful: $data');
        return data;
      } else {
        print('Failed to login: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred while logging in: $e');
      return null;
    }
  }
}
