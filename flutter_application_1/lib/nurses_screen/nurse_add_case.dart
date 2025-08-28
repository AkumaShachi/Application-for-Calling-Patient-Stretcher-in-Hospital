import 'package:flutter/material.dart';
import 'dart:math';

import 'nurse_ex-post_case.dart';

class NurseAddCaseScreen extends StatefulWidget {
  const NurseAddCaseScreen({super.key});
  @override
  State<NurseAddCaseScreen> createState() => _NurseAddCaseScreenState();
}

class _NurseAddCaseScreenState extends State<NurseAddCaseScreen> {
  // controller สำหรับแต่ละช่อง
  final TextEditingController patientIdController = TextEditingController();
  final TextEditingController patientTypeController = TextEditingController();
  final TextEditingController receivePointController = TextEditingController();
  final TextEditingController sendPointController = TextEditingController();
  final TextEditingController stretcherTypeController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();

  @override
  void dispose() {
    patientIdController.dispose();
    patientTypeController.dispose();
    receivePointController.dispose();
    sendPointController.dispose();
    stretcherTypeController.dispose();
    equipmentController.dispose();
    super.dispose();
  }

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NurseExCaseScreen(),
                ),
              );
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _inputItem(
                    Icons.badge,
                    'หมายเลขผู้ป่วย',
                    patientIdController,
                  ),
                  _inputItem(
                    Icons.person,
                    'ประเภทผู้ป่วย',
                    patientTypeController,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _inputItem(
                          Icons.location_on,
                          'จุดรับ',
                          receivePointController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _inputItem(
                          Icons.location_on,
                          'จุดส่ง',
                          sendPointController,
                        ),
                      ),
                    ],
                  ),
                  _inputItem(Icons.bed, 'ประเภทเปล', stretcherTypeController),
                  _inputItem(Icons.list, 'อุปกรณ์เสริม', equipmentController),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 🔵 Mic button
            Column(
              children: [
                CircleAvatar(
                  radius: min(MediaQuery.of(context).size.width * 0.1, 100),
                  backgroundColor: Colors.blue[50],
                  child: IconButton(
                    icon: Icon(
                      Icons.mic,
                      size: min(MediaQuery.of(context).size.width * 0.1, 100),
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      // ใส่ logic สำหรับเริ่มพูดตรงนี้
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Text('แตะเพื่อพูด', style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputItem(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
              onChanged: (_) => setState(() {}),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'กรุณากรอก $label'
                          : null,
            ),
          ),
          const SizedBox(width: 8),
          if (controller.text.isNotEmpty)
            const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }
}
