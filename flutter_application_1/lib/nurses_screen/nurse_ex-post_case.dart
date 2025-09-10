import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _NurseExCaseScreenState extends State<NurseExCaseScreen> {
  String userName = '';
  String Name = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id') ?? '';
    final fname = prefs.getString('fname_U') ?? '';
    final lname = prefs.getString('lname_U') ?? '';
    setState(() {
      userName = '$fname $lname';
    });
  }

  void _confirmAndSave() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการบันทึก'),
          content: const Text('คุณแน่ใจว่าจะบันทึกข้อมูลเคสนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // ปิด popup
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ปิด popup ก่อน
                _saveCase();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NurseListCaseScreen(),
                  ),
                ); // เรียกบันทึกเคส
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  void _saveCase() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id') ?? '';
    // เตรียมข้อมูลเคสเป็น Map
    final caseData = {
      'patientId': widget.patientId,
      'patientType': widget.patientType,
      'roomFrom': widget.receivePoint,
      'roomTo': widget.sendPoint,
      'stretcherTypeId': widget.stretcherType,
      'requestedBy': id, // ใช้ id จาก SharedPreferences
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตัวอย่างการเพิ่มเคส'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _confirmAndSave, // ฟังก์ชันเรียก popup
            child: const Text('บันทึก', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ข้อควรระวัง: กรุณาตรวจสอบความถูกต้องและความครบถ้วนของข้อมูลก่อนบันทึก เนื่องจากไม่สามารถแก้ไขได้ภายหลัง',
                style: TextStyle(fontSize: 14),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          widget.nurseName.isEmpty
                              ? 'พยาบาล'
                              : widget.nurseName, // ✅ ใช้จาก constructor
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black26),
                  // ข้อมูลเคส
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caseItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
