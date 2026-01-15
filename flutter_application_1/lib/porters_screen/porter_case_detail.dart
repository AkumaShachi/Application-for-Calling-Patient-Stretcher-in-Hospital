// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import '../design/theme.dart';

class PorterCaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const PorterCaseDetailScreen({required this.item, super.key});

  @override
  State<PorterCaseDetailScreen> createState() => _PorterCaseDetailScreenState();
}

class _PorterCaseDetailScreenState extends State<PorterCaseDetailScreen> {
  String timeAgo(String createdAt) {
    try {
      final createdTime = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(createdTime);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final status = item['status']?.toString() ?? 'pending';
    bool isPending = status == 'pending';
    bool isInProgress = status == 'in_progress';

    Color statusColor = isPending
        ? Colors.pink.shade100
        : (isInProgress ? Colors.yellow.shade100 : Colors.green.shade100);
    Color statusTextColor = isPending
        ? Colors.pink.shade700
        : (isInProgress ? Colors.orange.shade800 : Colors.green.shade800);
    String statusText = isPending
        ? 'รอดำเนินการ'
        : (isInProgress ? 'กำลังดำเนินการ' : 'เสร็จสิ้น');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'รายละเอียดเคส',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    item['created_at'] != null
                        ? timeAgo(item['created_at'])
                        : '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.deepPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppTheme.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HN ${item['patient_id'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'ประเภท: ${item['patient_type'] ?? '-'}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              _buildSectionTitle('ข้อมูลการเคลื่อนย้าย'),
              _buildInfoRow(Icons.login, 'จุดรับ', item['room_from']),
              _buildInfoRow(Icons.logout, 'จุดส่ง', item['room_to']),

              const SizedBox(height: 24),
              _buildSectionTitle('ข้อมูลอุปกรณ์'),
              _buildInfoRow(
                Icons.airline_seat_flat,
                'ประเภทเปล',
                item['stretcher_type'] ??
                    item['stretcher_type_name'] ??
                    item['str_type_name'],
              ),
              _buildInfoRow(
                Icons.medical_services,
                'อุปกรณ์',
                (item['equipments'] is List)
                    ? (item['equipments'] as List).join(', ')
                    : (item['equipments'] ?? item['equipment']),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('ผู้เกี่ยวข้อง'),
              _buildInfoRow(
                Icons.person_outline,
                'ผู้เรียกเคส',
                '${item['requested_by_fname'] ?? ''} ${item['requested_by_lname'] ?? ''}',
              ),

              if (item['assigned_porter_username'] != null)
                _buildInfoRow(
                  Icons.assignment_ind,
                  'เวรเปล',
                  item['assigned_porter_username'],
                ),

              const SizedBox(height: 24),
              if (item['created_at'] != null)
                Text(
                  'สร้างเมื่อ: ${DateTime.parse(item['created_at']).toLocal()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
