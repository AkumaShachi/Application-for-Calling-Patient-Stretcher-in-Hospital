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
            'ยกเลิก',
            style: TextStyle(color: Colors.blue),
            overflow: TextOverflow.visible, // ไม่ตัดคำ
            softWrap: false, // ไม่ขึ้นบรรทัดใหม่
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // save logic here
            },
            child: const Text(
              'บันทึก',
              style: TextStyle(color: Colors.blue),
              overflow: TextOverflow.visible, // ไม่ตัดคำ
              softWrap: false, // ไม่ขึ้นบรรทัดใหม่
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔵 Mic button
            Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue[50],
                  child: IconButton(
                    icon: const Icon(Icons.mic, size: 32, color: Colors.blue),
                    onPressed: () {
                      // ใส่ logic สำหรับเริ่มพูดตรงนี้
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Text('แตะเพื่อพูด', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),

            // 🗒️ ข้อความที่พูด
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ข้อความ:\nหมายเลขผู้ป่วย GE174 ประเภทผู้ป่วยใน จุดรับคัด C ชั้น 4 ส่งห้องเอกซเรย์ ใช้เปลนอน อุปกรณ์เสริมออกซิเจน',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ ข้อมูลที่ต้องระบุ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'ข้อมูลที่ต้องระบุ:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _checkItem(Icons.badge, 'หมายเลขผู้ป่วย'),
                  _checkItem(Icons.person, 'ประเภทผู้ป่วย'),
                  _checkItem(Icons.location_on, 'จุดรับ-ส่ง'),
                  _checkItem(Icons.bed, 'ประเภทเปล'),
                  _checkItem(Icons.list, 'อุปกรณ์เสริม'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Helper สำหรับรายการเช็ค
  Widget _checkItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }
}
