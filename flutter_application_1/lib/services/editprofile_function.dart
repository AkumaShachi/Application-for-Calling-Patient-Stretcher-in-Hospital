// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EditProfileFunction {
  static final baseUrl = dotenv.env['BASE_URL'];

  /// อัปเดตข้อมูลโปรไฟล์
  static Future<void> updateProfile(
    String username,
    Map<String, dynamic> profileData,
  ) async {
    final url = Uri.parse('$baseUrl/user/$username'); // 👈 แก้ endpoint ให้ตรง

    print('Request URL: $url');
    print('Request body: ${jsonEncode(profileData)}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        print('Profile updated successfully');
        print('Response: ${response.body}');
      } else {
        print('Failed to update profile: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }
}
