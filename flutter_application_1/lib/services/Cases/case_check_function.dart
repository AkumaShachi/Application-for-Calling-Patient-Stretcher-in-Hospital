import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CaseCheckService {
  CaseCheckService._();

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

  static Future<bool> checkCaseExists(String patientId) async {
    final uri = _buildUri('/cases/check/$patientId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to check case (status ${response.statusCode})');
    }

    final payload = jsonDecode(response.body);
    return payload['exists'] == true;
  }
}
