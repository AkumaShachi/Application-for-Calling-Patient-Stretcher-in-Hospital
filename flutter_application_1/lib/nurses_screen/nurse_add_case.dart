import 'package:flutter/material.dart';
import 'dart:math';
import '../services/getEquipments.dart';
import '../services/getStretcher.dart';
import '../services/user_prefs.dart';
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

  List<int> selectedEquipmentIds = []; // รายการ ID ของอุปกรณ์ที่เลือก
  int? selectedStretcherTypeId; // ID ของประเภทเปลที่เลือก (nullable)
  String stretcherTypeName = ''; // ชื่อประเภทเปล
  String equipmentNames = ''; // ชื่ออุปกรณ์

  @override
  void dispose() {
    // กำจัด controller เมื่อ widget ถูกทำลาย
    patientIdController.dispose();
    patientTypeController.dispose();
    receivePointController.dispose();
    sendPointController.dispose();
    stretcherTypeController.dispose();
    equipmentController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    if (patientIdController.text.isEmpty ||
        patientTypeController.text.isEmpty ||
        receivePointController.text.isEmpty ||
        sendPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    } else if (selectedStretcherTypeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกประเภทเปล')));
      return;
    }

    // ✅ ดึงชื่อผู้ใช้จาก SharedPreferences ผ่าน UserPreferences
    final fname = UserPreferences.fname ?? '';
    final lname = UserPreferences.lname ?? '';
    final userName = '$fname $lname';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NurseExCaseScreen(
          patientId: patientIdController.text,
          patientType: patientTypeController.text,
          receivePoint: receivePointController.text,
          sendPoint: sendPointController.text,
          stretcherType: stretcherTypeName,
          equipments: equipmentNames,
          nurseName: userName, // เพิ่มพารามิเตอร์ nurseName
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มเคสใหม่'), // หัวข้อแอพ
        centerTitle: true, // จัดหัวข้อตรงกลาง
        backgroundColor: Colors.white, // สีพื้นหลัง
        elevation: 0, // เงา
        foregroundColor: Colors.black, // สีตัวอักษร
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context); // กลับไปหน้าก่อนหน้า
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
            onPressed: _validateAndSubmit, // ใช้ method ที่เราแยกไว้
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
                  _stretcherTypeSelector(), // ตัวเลือกประเภทเปล
                  _equipmentSelector(), // ตัวเลือกอุปกรณ์
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

  // สร้างช่อง input
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
              validator: (value) =>
                  value == null || value.isEmpty ? 'กรุณากรอก $label' : null,
            ),
          ),
          const SizedBox(width: 8),
          if (controller.text.isNotEmpty)
            const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }

  // ตัวเลือกประเภทเปล
  Widget _stretcherTypeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton(
        onPressed: () async {
          final selected = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            builder: (context) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: GetStretcher.getStretcherTypes(), // ดึงข้อมูลประเภทเปล
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    ); // แสดง loading
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Center(
                      child: Text('ไม่สามารถโหลดข้อมูลได้'),
                    ); // แสดงข้อผิดพลาด
                  }
                  final types = snapshot.data!; // ข้อมูลประเภทเปล
                  return ListView.builder(
                    itemCount: types.length,
                    itemBuilder: (context, index) {
                      final type = types[index];
                      return ListTile(
                        title: Text(type['type_name']), // ชื่อประเภทเปล
                        subtitle: Text('จำนวน: ${type['quantity']}'), // จำนวน
                        onTap: () =>
                            Navigator.pop(context, type), // เลือกประเภทเปล
                      );
                    },
                  );
                },
              );
            },
          );

          if (selected != null) {
            setState(() {
              selectedStretcherTypeId =
                  selected['id']; // กำหนด ID ประเภทเปลที่เลือก
              stretcherTypeName = selected['type_name']; // กำหนดชื่อประเภทเปล
            });
          }
        },
        child: Row(
          children: [
            const Icon(Icons.bed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stretcherTypeName.isEmpty
                    ? 'เลือกประเภทเปล'
                    : stretcherTypeName, // แสดงชื่อประเภทเปลที่เลือก
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _equipmentSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton(
        onPressed: () async {
          final selected =
              await showModalBottomSheet<List<Map<String, dynamic>>>(
                context: context,
                builder: (context) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: GetEquipments.getEquipments(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Center(
                          child: Text('ไม่สามารถโหลดข้อมูลได้'),
                        );
                      }

                      final equipment = snapshot.data!;
                      List<int> tempSelected = List.from(selectedEquipmentIds);

                      // เพิ่ม StatefulBuilder รอบ Column
                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return SizedBox(
                            height: 400, // กำหนดความสูงของ modal
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: equipment.length,
                                    itemBuilder: (context, index) {
                                      final eq = equipment[index];
                                      final isSelected = tempSelected.contains(
                                        eq['id'],
                                      );
                                      return CheckboxListTile(
                                        title: Text(eq['equipment_name']),
                                        subtitle: Text(
                                          'จำนวน: ${eq['quantity']}',
                                        ),
                                        value: isSelected,
                                        onChanged: (value) {
                                          setModalState(() {
                                            if (value == true) {
                                              tempSelected.add(eq['id']);
                                            } else {
                                              tempSelected.remove(eq['id']);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                      equipment
                                          .where(
                                            (e) =>
                                                tempSelected.contains(e['id']),
                                          )
                                          .toList(),
                                    );
                                  },
                                  child: const Text('ตกลง'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );

          if (selected != null) {
            setState(() {
              selectedEquipmentIds = selected
                  .map((e) => e['id'] as int)
                  .toList();
              equipmentNames = selected
                  .map((e) => e['equipment_name'])
                  .join(', ');
            });
          }
        },
        child: Row(
          children: [
            const Icon(Icons.list),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                equipmentNames.isEmpty ? 'เลือกอุปกรณ์เสริม' : equipmentNames,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
