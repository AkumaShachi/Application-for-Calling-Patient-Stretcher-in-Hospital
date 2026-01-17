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
      if (diff.inSeconds < 60) return '${diff.inSeconds} วินาทีที่แล้ว';
      if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
      if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
      return '${diff.inDays} วันที่แล้ว';
    } catch (e) {
      return '';
    }
  }

  String formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.';
    } catch (e) {
      return dateStr;
    }
  }

  // Helper to format patient ID - return as-is
  String _formatPatientId(String? patientId) {
    if (patientId == null || patientId.isEmpty) return '-';
    return patientId;
  }

  // Helper to extract prefix from patient ID (HN/AN/XN/DN)
  String _getPatientIdPrefix(String? patientId) {
    if (patientId == null || patientId.isEmpty) return 'HN';
    final upper = patientId.toUpperCase();
    if (upper.startsWith('AN')) return 'AN';
    if (upper.startsWith('XN')) return 'XN';
    if (upper.startsWith('DN')) return 'DN';
    if (upper.startsWith('HN')) return 'HN';
    return 'HN'; // default
  }

  // Helper to get patient ID number without prefix
  String _getPatientIdNumber(String? patientId) {
    if (patientId == null || patientId.isEmpty) return '-';
    final upper = patientId.toUpperCase();
    // Remove known prefixes
    for (final prefix in ['HN', 'AN', 'XN', 'DN']) {
      if (upper.startsWith(prefix)) {
        return patientId.substring(prefix.length);
      }
    }
    return patientId;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final status = item['status']?.toString() ?? 'pending';
    bool isPending = status == 'pending';
    bool isInProgress = status == 'in_progress';
    bool isCompleted = status == 'completed';

    // Status configuration
    IconData statusIcon = isPending
        ? Icons.access_time
        : (isInProgress ? Icons.local_shipping : Icons.check_circle);
    Color statusColor = isPending
        ? Colors.blue
        : (isInProgress ? Colors.orange : Colors.green);
    String statusText = isPending
        ? '⏳ รอดำเนินการ'
        : (isInProgress ? '🚀 กำลังดำเนินการ' : '✅ เสร็จสิ้น');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              statusColor,
              statusColor.withOpacity(0.8),
              Colors.grey.shade100,
            ],
            stops: const [0.0, 0.15, 0.35],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'รายละเอียดเคส',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Time badge
                    if (item['created_at'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo(item['created_at']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Status badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.deepPurple.withOpacity(0.1),
                                AppTheme.purple.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.deepPurple.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.deepPurple.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppTheme.deepPurple,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Patient info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.deepPurple,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _getPatientIdPrefix(
                                              item['patient_id']?.toString(),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getPatientIdNumber(
                                              item['patient_id']?.toString(),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        '${item['patient_type'] ?? '-'}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Location Section
                        _buildSectionHeader(
                          icon: Icons.route,
                          title: 'ข้อมูลการเคลื่อนย้าย',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),

                        // Location cards
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildLocationRow(
                                icon: Icons.radio_button_checked,
                                label: 'จุดรับ',
                                value: item['room_from'] ?? '-',
                                color: Colors.green,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 4,
                                  bottom: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 2,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.green, Colors.red],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Icon(
                                      Icons.arrow_downward,
                                      color: Colors.grey.shade400,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              _buildLocationRow(
                                icon: Icons.location_on,
                                label: 'จุดส่ง',
                                value: item['room_to'] ?? '-',
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Equipment Section
                        _buildSectionHeader(
                          icon: Icons.medical_services,
                          title: 'ข้อมูลอุปกรณ์',
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.airline_seat_flat,
                                label: 'ประเภทเปล',
                                value:
                                    item['stretcher_type'] ??
                                    item['stretcher_type_name'] ??
                                    item['str_type_name'] ??
                                    '-',
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.build,
                          label: 'อุปกรณ์เพิ่มเติม',
                          value: (item['equipments'] is List)
                              ? (item['equipments'] as List).join(', ')
                              : (item['equipments'] ??
                                    item['equipment'] ??
                                    'ไม่มี'),
                          color: Colors.teal,
                          isWide: true,
                        ),

                        const SizedBox(height: 24),

                        // People Section
                        _buildSectionHeader(
                          icon: Icons.people,
                          title: 'ผู้เกี่ยวข้อง',
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(height: 12),

                        _buildPersonRow(
                          icon: Icons.person_outline,
                          label: 'ผู้เรียกเคส',
                          name:
                              '${item['requested_by_fname'] ?? ''} ${item['requested_by_lname'] ?? ''}'
                                  .trim(),
                          color: Colors.blue,
                        ),

                        if (item['assigned_porter_username'] != null) ...[
                          const SizedBox(height: 10),
                          _buildPersonRow(
                            icon: Icons.local_shipping,
                            label: 'พนักงานเปล',
                            name: item['assigned_porter_username'],
                            color: Colors.orange,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Timestamps
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              if (item['created_at'] != null)
                                _buildTimestampRow(
                                  label: '🕐 สร้างเมื่อ',
                                  value: formatDateTime(item['created_at']),
                                ),
                              if (isCompleted && item['completed_at'] != null)
                                _buildTimestampRow(
                                  label: '✅ เสร็จสิ้นเมื่อ',
                                  value: formatDateTime(item['completed_at']),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow({
    required IconData icon,
    required String label,
    required String name,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? '-' : name,
                  style: const TextStyle(
                    fontSize: 15,
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

  Widget _buildTimestampRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
