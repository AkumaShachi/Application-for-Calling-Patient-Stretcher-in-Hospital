import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StretcherEquipmentService {
  static final baseUrl = dotenv.env['BASE_URL'];

  // =====================
  // Stretcher Types
  // =====================

  /// ดึงรายการประเภทเปลทั้งหมด
  static Future<List<Map<String, dynamic>>> fetchStretcherTypes() async {
    final url = Uri.parse('$baseUrl/stretcher');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching stretcher types: $e');
      return [];
    }
  }

  /// เพิ่มประเภทเปลใหม่
  static Future<bool> addStretcherType(String typeName, int quantity) async {
    final url = Uri.parse('$baseUrl/add/stretcher');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type_name': typeName, 'quantity': quantity}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding stretcher type: $e');
      return false;
    }
  }

  /// แก้ไขประเภทเปล
  static Future<bool> updateStretcherType(
    String id,
    String typeName,
    int quantity,
  ) async {
    final url = Uri.parse('$baseUrl/stretcher/$id');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type_name': typeName, 'quantity': quantity}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating stretcher type: $e');
      return false;
    }
  }

  /// ลบประเภทเปล
  static Future<bool> deleteStretcherType(String id) async {
    final url = Uri.parse('$baseUrl/stretcher/$id');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting stretcher type: $e');
      return false;
    }
  }

  // =====================
  // Equipment
  // =====================

  /// ดึงรายการอุปกรณ์ทั้งหมด
  static Future<List<Map<String, dynamic>>> fetchEquipments() async {
    final url = Uri.parse('$baseUrl/equipments');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching equipments: $e');
      return [];
    }
  }

  /// เพิ่มอุปกรณ์ใหม่
  static Future<bool> addEquipment(String name, int quantity) async {
    final url = Uri.parse('$baseUrl/add/equipments');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'equipment_name': name, 'quantity': quantity}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding equipment: $e');
      return false;
    }
  }

  /// แก้ไขอุปกรณ์
  static Future<bool> updateEquipment(
    String id,
    String name,
    int quantity,
  ) async {
    final url = Uri.parse('$baseUrl/equipments/$id');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'equipment_name': name, 'quantity': quantity}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating equipment: $e');
      return false;
    }
  }

  /// ลบอุปกรณ์
  static Future<bool> deleteEquipment(String id) async {
    final url = Uri.parse('$baseUrl/equipments/$id');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting equipment: $e');
      return false;
    }
  }
}
