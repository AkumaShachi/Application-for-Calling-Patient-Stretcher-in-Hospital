import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ProfileUpdateService {
  ProfileUpdateService._();

  static final String? _baseUrl = dotenv.env['BASE_URL'];

  static Uri _buildUri(String path) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError('BASE_URL is not configured');
    }
    final normalized = _baseUrl!.endsWith('/') ? _baseUrl!.substring(0, _baseUrl!.length - 1) : _baseUrl!;
    return Uri.parse('$normalized$path');
  }

  static Future<Map<String, dynamic>> updateProfile(
    String username, {
    required String fname,
    required String lname,
    required String email,
    required String phone,
    File? profileImage,
  }) async {
    final uri = _buildUri('/profile/${Uri.encodeComponent(username)}');

    http.BaseRequest request;

    if (profileImage != null) {
      final multipart = http.MultipartRequest('PUT', uri)
        ..fields.addAll({
          'fname': fname,
          'lname': lname,
          'email': email,
          'phone': phone,
        })
        ..files.add(await http.MultipartFile.fromPath('profile_image', profileImage.path));
      request = multipart;
    } else {
      final body = jsonEncode({
        'fname': fname,
        'lname': lname,
        'email': email,
        'phone': phone,
      });
      request = http.Request('PUT', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = body;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200) {
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    final message = decoded is Map<String, dynamic>
        ? decoded['message']?.toString() ?? decoded['error']?.toString()
        : null;
    throw Exception(message ?? 'Failed to update profile (status ${response.statusCode})');
  }
}
