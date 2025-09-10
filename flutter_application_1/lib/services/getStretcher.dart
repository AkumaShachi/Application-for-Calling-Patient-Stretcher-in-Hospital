// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GetStretcher {
  static final baseUrl = dotenv.env['BASE_URL'];

  /// ดึงข้อมูลประเภทเปล
  /// คืนค่าเป็น List<Map<String, dynamic>> หรือ null ถ้า failed
  static Future<List<Map<String, dynamic>>> getStretcherTypes() async {
    final url = Uri.parse('$baseUrl/stretcher');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Error fetching stretcher types: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching stretcher types: $e');
      return [];
    }
  }
}
