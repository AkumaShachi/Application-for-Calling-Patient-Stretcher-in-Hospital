import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CasesHistoryService {
  CasesHistoryService._();

  static final String? _baseUrl = dotenv.env['BASE_URL'];

  static Uri _buildUri(String path) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError('BASE_URL is not configured');
    }
    final normalized = _baseUrl!.endsWith('/') ? _baseUrl!.substring(0, _baseUrl!.length - 1) : _baseUrl!;
    return Uri.parse('$normalized$path');
  }

  static Future<List<Map<String, dynamic>>> fetchHistory() async {
    final uri = _buildUri('/cases/history');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ?? decoded['error']?.toString()
          : null;
      throw Exception(message ?? 'Failed to fetch case history (status ${response.statusCode})');
    }

    final payload = jsonDecode(response.body);
    if (payload is List) {
      return payload.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    }

    throw const FormatException('Unexpected response format');
  }

  static Future<Map<String, dynamic>> fetchHistoryById(dynamic historyId) async {
    final uri = _buildUri('/cases/history/$historyId');
    final response = await http.get(uri);
    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200) {
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    final message = decoded is Map<String, dynamic>
        ? decoded['message']?.toString() ?? decoded['error']?.toString()
        : null;
    throw Exception(message ?? 'Failed to fetch case history (status ${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> fetchHistoryForPorter(String username) async {
    final trimmedUsername = username.trim();
    final history = await fetchHistory();

    if (trimmedUsername.isEmpty) {
      return history.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    final normalizedUsername = trimmedUsername.toLowerCase();

    return history
        .where((item) {
          final assigned = item['assigned_porter_username']?.toString();
          return assigned != null && assigned.toLowerCase() == normalizedUsername;
        })
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
