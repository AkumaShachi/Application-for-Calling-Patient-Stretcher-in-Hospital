// ignore_for_file: non_constant_identifier_names, file_names
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/theme.dart';
import '../services/addcase_function.dart';
import 'nurse_list_case.dart';

class NurseExCaseScreen extends StatefulWidget {
  final String patientId;
  final String patientType;
  final String receivePoint;
  final String sendPoint;
  final String stretcherType;
  final String equipments;
  final String nurseName; // ✅ เพิ่มตรงนี้

  const NurseExCaseScreen({
    super.key,
    required this.patientId,
    required this.patientType,
    required this.receivePoint,
    required this.sendPoint,
    required this.stretcherType,
    required this.equipments,
    required this.nurseName, // ✅ constructor
  });

  @override
  State<NurseExCaseScreen> createState() => _NurseExCaseScreenState();
}

class _NurseExCaseScreenState extends State<NurseExCaseScreen>
    with TickerProviderStateMixin {
  String userName = '';

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutBack));

  void initState() {
    super.initState();
    _loadUserName();
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _fadeCtrl.forward(),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final fname = prefs.getString('fname_U') ?? '';
    final lname = prefs.getString('lname_U') ?? '';
    setState(() => userName = '$fname $lname');
  }

  void _confirmAndSave() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.deepPurple,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ยืนยันการบันทึก',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'คุณแน่ใจว่าจะบันทึกข้อมูลเคสนี้หรือไม่?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.deepPurple,
                              side: BorderSide(color: AppTheme.deepPurple),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('ยกเลิก'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _saveCase();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NurseListCaseScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppTheme.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: AppTheme.deepPurple.withOpacity(0.3),
                            ),
                            child: const Text(
                              'บันทึก',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  void _saveCase() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id') ?? '';
    final caseData = {
      'patientId': widget.patientId,
      'patientType': widget.patientType,
      'roomFrom': widget.receivePoint,
      'roomTo': widget.sendPoint,
      'stretcherTypeId': widget.stretcherType,
      'requestedBy': id,
      'equipmentIds': widget.equipments,
    };
    await AddcaseFunction.saveCase(caseData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลเคสเรียบร้อยแล้ว')),
      );
    }
  }
  // เรียกใช้ AddcaseFunction.saveCase

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตัวอย่างการเพิ่มเคส'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          TextButton(
            onPressed: _confirmAndSave,
            child: const Text(
              'บันทึก',
              style: TextStyle(color: AppTheme.deepPurple),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // พื้นหลัง gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.scaffoldBackgroundColor, AppTheme.lavender],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ข้อควรระวัง: กรุณาตรวจสอบความถูกต้องและความครบถ้วนของข้อมูลก่อนบันทึก เนื่องจากไม่สามารถแก้ไขได้ภายหลัง',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services,
                            color: AppTheme.deepPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.nurseName.isEmpty
                                ? 'พยาบาล'
                                : widget.nurseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.black26),
                      _caseItem(
                        Icons.badge,
                        'หมายเลขผู้ป่วย : ${widget.patientId}',
                      ),
                      _caseItem(
                        Icons.person,
                        'ประเภทผู้ป่วย : ${widget.patientType}',
                      ),
                      _caseItem(
                        Icons.location_on,
                        'จุดรับ-ส่ง : ${widget.receivePoint} - ${widget.sendPoint}',
                      ),
                      _caseItem(
                        Icons.bed,
                        'ประเภทเปล : ${widget.stretcherType}',
                      ),
                      _caseItem(
                        Icons.list,
                        'อุปกรณ์เสริม : ${widget.equipments}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caseItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B2EFF).withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
