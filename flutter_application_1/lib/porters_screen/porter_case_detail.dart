// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import '../services/Profile/profile_get_function.dart';
import '../design/theme.dart';

class PorterCaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const PorterCaseDetailScreen({required this.item, super.key});

  @override
  State<PorterCaseDetailScreen> createState() => _PorterCaseDetailScreenState();
}

class _PorterCaseDetailScreenState extends State<PorterCaseDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _inCtrl = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _inCtrl, curve: AppMotion.ease));
  late final Animation<double> _fade = CurvedAnimation(
    parent: _inCtrl,
    curve: AppMotion.ease,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.97,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _inCtrl, curve: AppMotion.pop));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), _inCtrl.forward);
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดเคส')),
      body: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Image.asset('assets/logo.png', height: 60)),
                      const SizedBox(height: 24),
                      _buildInfo('รหัสผู้ป่วย', item['patient_id']),
                      _buildInfo('ประเภทผู้ป่วย', item['patient_type']),
                      _buildInfo(
                        'จุดรับ-ส่ง',
                        '${item['room_from']} - ${item['room_to']}',
                      ),
                      _buildInfo('ประเภทเปล', item['stretcher_type']),
                      _buildInfo('อุปกรณ์', item['equipments']),
                      _buildInfo(
                        'ผู้รับผิดชอบ',
                        '${item['assigned_porter_fname']} ${item['assigned_porter_lname']}',
                      ),
                      _buildInfo(
                        'ผู้เรียกเคส',
                        '${item['requested_by_fname']} ${item['requested_by_lname']}',
                        onTap: () => _showRequesterInfo(item),
                      ),
                      _buildInfo(
                        'เวลาสร้างเคส',
                        item['created_at'] != null
                            ? DateTime.parse(
                                item['created_at'],
                              ).toLocal().toString()
                            : '-',
                      ),
                      _buildInfo(
                        'เวลาเสร็จสิ้น',
                        item['completed_at'] != null
                            ? DateTime.parse(
                                item['completed_at'],
                              ).toLocal().toString()
                            : '-',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRequesterInfo(Map<String, dynamic> item) {
    final username = _extractUsername(item['requested_by_username']);
    final profileFuture = username != null
        ? ProfileGetService.fetchProfile(username)
        : Future<Map<String, dynamic>?>.value(null);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final theme = Theme.of(context);
            final profile = snapshot.data;
            final firstName = _stringValue(
              profile?['fname'] ?? item['requested_by_fname'],
            );
            final lastName = _stringValue(
              profile?['lname'] ?? item['requested_by_lname'],
            );
            final email = _stringValue(profile?['email']);
            final phone = _stringValue(profile?['phone']);
            final profileImage = profile?['profile_image']?.toString() ?? '';
            final displayName = _composeDisplayName(firstName, lastName);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.person, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  const Text('ข้อมูลผู้เรียกเคส'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar + ชื่อ
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null,
                        backgroundColor: Colors.deepPurple.shade100,
                        child: profileImage.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // รายละเอียด
                  Card(
                    color: theme.colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildProfileTile(Icons.email, 'อีเมล', email),
                        const Divider(height: 0),
                        _buildProfileTile(Icons.phone, 'เบอร์โทร', phone),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  label: const Text('ปิด'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.deepPurple),
      title: Text(label),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
  }

  String _composeDisplayName(String firstName, String lastName) {
    final parts = <String>[];
    if (firstName != '-' && firstName.isNotEmpty) {
      parts.add(firstName);
    }
    if (lastName != '-' && lastName.isNotEmpty) {
      parts.add(lastName);
    }
    if (parts.isEmpty) {
      return '-';
    }
    return parts.join(' ');
  }

  String? _extractUsername(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  String _stringValue(dynamic value) {
    if (value == null) {
      return '-';
    }
    final textValue = value.toString().trim();
    return textValue.isEmpty ? '-' : textValue;
  }

  Widget _buildInfo(String label, dynamic value, {VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: AppTheme.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: ${value ?? '-'}',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
    );
  }
}
