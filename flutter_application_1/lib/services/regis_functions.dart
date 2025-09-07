// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisFunctions {
  static const baseUrl =
      "http://localhost:4000"; // Replace with your actual URL

  static addRegistrant(Map data) async {
    final url = Uri.parse('$baseUrl/registrant');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        print('Registrant added successfully: ${response.body}');
      } else {
        print('Failed to add registrant: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while adding registrant: $e');
    }
  }
}
