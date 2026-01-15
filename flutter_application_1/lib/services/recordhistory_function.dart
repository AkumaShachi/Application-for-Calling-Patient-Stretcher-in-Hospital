import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RecordhistoryFunction {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  static Future<List<Map<String, dynamic>>> fetchCompletedCasesPorter(
    String username,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recordHistory?username=$username'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch completed cases');
      }
    } catch (e) {
      rethrow;
    }
  }
}
