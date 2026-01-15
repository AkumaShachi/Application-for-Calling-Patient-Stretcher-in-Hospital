import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmployeeDirectory {
  const EmployeeDirectory({
    required this.nurses,
    required this.porters,
    required this.others,
  });

  final List<Map<String, dynamic>> nurses;
  final List<Map<String, dynamic>> porters;
  final List<Map<String, dynamic>> others;

  bool get isEmpty => nurses.isEmpty && porters.isEmpty && others.isEmpty;

  Map<String, List<Map<String, dynamic>>> toMap() => {
        'nurses': nurses,
        'porters': porters,
        'others': others,
      };
}

class EmployeeGetService {
  EmployeeGetService._();

  static final String? _baseUrl = dotenv.env['BASE_URL'];

  static Uri _buildUri(String path) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError('BASE_URL is not configured');
    }
    final normalized =
        _baseUrl!.endsWith('/') ? _baseUrl!.substring(0, _baseUrl!.length - 1) : _baseUrl!;
    return Uri.parse('$normalized$path');
  }

  static Future<EmployeeDirectory> fetchEmployees() async {
    final uri = _buildUri('/users');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ?? decoded['error']?.toString()
          : null;
      throw Exception(message ?? 'Failed to fetch employees (status ${response.statusCode})');
    }

    final payload = jsonDecode(response.body);
    if (payload is List) {
      final items = payload
          .whereType<Map>()
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
      return _partitionEmployees(items);
    }

    throw const FormatException('Unexpected response format');
  }

  static EmployeeDirectory _partitionEmployees(List<Map<String, dynamic>> employees) {
    final nurses = <Map<String, dynamic>>[];
    final porters = <Map<String, dynamic>>[];
    final others = <Map<String, dynamic>>[];

    for (final employee in employees) {
      final roleName = employee['role_name']?.toString().toLowerCase().trim();
      final roleId = employee['role_id'];

      if (roleName == 'nurse' || roleId == 2) {
        nurses.add(employee);
      } else if (roleName == 'porter' || roleId == 3) {
        porters.add(employee);
      } else {
        others.add(employee);
      }
    }

    return EmployeeDirectory(nurses: nurses, porters: porters, others: others);
  }
}
