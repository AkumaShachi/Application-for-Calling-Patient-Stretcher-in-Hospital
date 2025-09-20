// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UpdateCase {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  static Future<bool> updateStatus(
    dynamic caseId, // รับ int หรือ String
    String newStatus, {
    String? assignedPorter,
  }) async {
    final url = Uri.parse('$baseUrl/cases/$caseId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': newStatus,
          'assignedPorter': assignedPorter,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
