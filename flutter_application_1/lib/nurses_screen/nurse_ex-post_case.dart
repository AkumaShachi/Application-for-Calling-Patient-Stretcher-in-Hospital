import 'package:flutter/material.dart';

class NurseExCaseScreen extends StatefulWidget {
  const NurseExCaseScreen({super.key});
  @override
  State<NurseExCaseScreen> createState() => _NurseExCaseScreenState();
}

class _NurseExCaseScreenState extends State<NurseExCaseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มเคสใหม่'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'แก้ไข',
            style: TextStyle(color: Colors.blue),
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // save logic here
            },
            child: const Text(
              'ยืนยัน',
              style: TextStyle(color: Colors.blue),
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ข้อมูลผู้ใช้และเคส
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
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.medical_services, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'พยาบาล สมศรี',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                        _caseItem(Icons.badge, 'หมายเลขผู้ป่วย : GE174'),
                        _caseItem(Icons.person, 'ประเภทผู้ป่วย : ผู้ป่วยใน'),
                        _caseItem(
                          Icons.location_on,
                          'จุดรับ-ส่ง : Ward 4C - ER',
                        ),
                        _caseItem(Icons.bed, 'ประเภทเปล : เปลนอน'),
                        _caseItem(
                          Icons.list,
                          'อุปกรณ์เสริม : ออกซิเจน, เครื่องวัดความดัน',
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

  // Helper สำหรับแสดงข้อมูลเคสแต่ละบรรทัด
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
