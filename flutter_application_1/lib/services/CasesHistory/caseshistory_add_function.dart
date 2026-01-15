import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CaseHistoryAddService {
  CaseHistoryAddService._();

  static final String? _baseUrl = dotenv.env['BASE_URL'];

  static Uri _buildUri(String path) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError('BASE_URL is not configured');
    }
    final normalized = _baseUrl!.endsWith('/')
        ? _baseUrl!.substring(0, _baseUrl!.length - 1)
        : _baseUrl!;
    return Uri.parse('$normalized$path');
  }

  static Future<Map<String, dynamic>> createHistory(
    Map<String, dynamic> payload,
  ) async {
    final uri = _buildUri('/cases/history');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 201 || response.statusCode == 200) {
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    final message = decoded is Map<String, dynamic>
        ? decoded['message']?.toString() ?? decoded['error']?.toString()
        : null;
    throw Exception(
      message ??
          'Failed to create history record (status ${response.statusCode})',
    );
  }
}
