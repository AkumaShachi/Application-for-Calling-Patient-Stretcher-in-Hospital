import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StretcherDeleteService {
  StretcherDeleteService._();

  static final String? _baseUrl = dotenv.env['BASE_URL'];

  static Uri _buildUri(String path) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError('BASE_URL is not configured');
    }
    final normalized = _baseUrl!.endsWith('/') ? _baseUrl!.substring(0, _baseUrl!.length - 1) : _baseUrl!;
    return Uri.parse('$normalized$path');
  }

  static Future<void> deleteStretcher(dynamic stretcherId) async {
    final uri = _buildUri('/stretchers/$stretcherId');
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      return;
    }

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    final message = decoded is Map<String, dynamic>
        ? decoded['message']?.toString() ?? decoded['error']?.toString()
        : null;
    throw Exception(message ?? 'Failed to delete stretcher type (status ${response.statusCode})');
  }
}
