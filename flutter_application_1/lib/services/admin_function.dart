import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AdminFunction {
  static final baseUrl = dotenv.env['BASE_URL'];

  // ดึงเคสทั้งหมดสำหรับ Admin (รวม completed จาก history)
  static Future<List<Map<String, dynamic>>> fetchAllCasesAdmin() async {
    final url = Uri.parse('$baseUrl/cases/admin/all');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Failed to fetch admin cases: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching admin cases: $e');
      return [];
    }
  }

  static Future<bool> deleteCase(String caseId) async {
    final url = Uri.parse('$baseUrl/cases/$caseId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete case: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting case: $e');
      return false;
    }
  }

  static Future<bool> deleteSelectedCases(List<String> caseIds) async {
    final url = Uri.parse('$baseUrl/admin/cases/delete/list');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'caseIds': caseIds}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete selected cases: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting selected cases: $e');
      return false;
    }
  }

  static Future<bool> updateCase(
    String caseId,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/admin/cases/$caseId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update case: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating case: $e');
      return false;
    }
  }
}
