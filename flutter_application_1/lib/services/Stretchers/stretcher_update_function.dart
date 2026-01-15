import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StretcherUpdateService {
  StretcherUpdateService._();

  static final String? _baseUrl = dotenv.env['BASE_URL'];

  static Uri _buildUri(String path) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError('BASE_URL is not configured');
    }
    final normalized = _baseUrl!.endsWith('/') ? _baseUrl!.substring(0, _baseUrl!.length - 1) : _baseUrl!;
    return Uri.parse('$normalized$path');
  }

  static Future<Map<String, dynamic>> updateStretcher(
    dynamic stretcherId, {
    String? name,
    int? quantity,
  }) async {
    if (name == null && quantity == null) {
      throw ArgumentError('At least one field (name or quantity) must be provided');
    }

    final uri = _buildUri('/stretchers/$stretcherId');
    final body = <String, dynamic>{};

    if (name != null) {
      body['name'] = name;
    }

    if (quantity != null) {
      body['quantity'] = quantity;
    }

    final response = await http.put(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200) {
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    final message = decoded is Map<String, dynamic>
        ? decoded['message']?.toString() ?? decoded['error']?.toString()
        : null;
    throw Exception(message ?? 'Failed to update stretcher type (status ${response.statusCode})');
  }
}
