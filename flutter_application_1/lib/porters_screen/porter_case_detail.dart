// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';

class PorterCaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const PorterCaseDetailScreen({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    print(item); // debug

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดเคส')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'รหัสผู้ป่วย: ${item['patient_id'] ?? '-'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ประเภทผู้ป่วย: ${item['patient_type'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'จุดรับ-ส่ง: ${item['room_from'] ?? '-'} - ${item['room_to'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'ประเภทเปล: ${item['stretcher_type'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'อุปกรณ์: ${item['equipments'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'ผู้รับผิดชอบ: ${item['assigned_porter_fname'] ?? '-'} ${item['assigned_porter_lname'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'ผู้เรียกเคส: ${item['requested_by_fname'] ?? '-'} ${item['requested_by_lname'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'เวลาสร้างเคส: ${item['created_at'] != null ? DateTime.parse(item['created_at']).toLocal().toString() : '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'เวลาเสร้จสิ้น: ${item['completed_at'] != null ? DateTime.parse(item['completed_at']).toLocal().toString() : '-'}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
