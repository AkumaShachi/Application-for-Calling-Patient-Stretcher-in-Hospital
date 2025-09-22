// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
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

  Widget _buildInfo(String label, dynamic value) {
    return Padding(
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
  }
}
