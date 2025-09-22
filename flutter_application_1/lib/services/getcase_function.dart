import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GetcaseFunction {
  static final baseUrl = dotenv.env['BASE_URL'];

  static Future<List<Map<String, dynamic>>> fetchAllCasesNurse() async {
    final url = Uri.parse('$baseUrl/cases/nurse/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to fetch cases');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMyCasesNurse(
    String username,
  ) async {
    final url = Uri.parse('$baseUrl/cases/nurse/$username');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to fetch my cases');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllCasesPorter() async {
    final url = Uri.parse('$baseUrl/cases/porter/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to fetch cases');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMyCasesPorter(
    String username,
  ) async {
    final url = Uri.parse('$baseUrl/cases/porter/$username');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to fetch my cases');
    }
  }
}
