import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/getEquipments.dart';
import '../services/getStretcher.dart';
import '../services/recorder_function.dart';
import '../services/user_prefs.dart';
import '../services/mic_function.dart';
import 'nurse_ex-post_case.dart';

class NurseAddCaseScreen extends StatefulWidget {
  const NurseAddCaseScreen({super.key});

  @override
  State<NurseAddCaseScreen> createState() => _NurseAddCaseScreenState();
}

class _NurseAddCaseScreenState extends State<NurseAddCaseScreen> {
  // Controllers
  final TextEditingController patientIdController = TextEditingController();
  final TextEditingController patientTypeController = TextEditingController();
  final TextEditingController receivePointController = TextEditingController();
  final TextEditingController sendPointController = TextEditingController();
  final TextEditingController stretcherTypeController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();

  List<int> selectedEquipmentIds = [];
  int? selectedStretcherTypeId;

  String stretcherTypeName = '';
  String equipmentNames = '';

  String? editingField;

  final MicController micController = MicController();
  final AudioRecorder audioRecorder = AudioRecorder();

  bool isMicButtonDisabled = false; // ป้องกันกดซ้อน

  @override
  void initState() {
    super.initState();
    micController.init();
    _checkPermissionAndInitRecorder();
  }

  Future<void> _checkPermissionAndInitRecorder() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) return;
    }
    await audioRecorder.init();
  }

  @override
  void dispose() {
    patientIdController.dispose();
    patientTypeController.dispose();
    receivePointController.dispose();
    sendPointController.dispose();
    stretcherTypeController.dispose();
    equipmentController.dispose();
    audioRecorder.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
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
          nurseName: userName,
        ),
      ),
    );
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
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.blue)),
        ),
        actions: [
          TextButton(
            onPressed: _validateAndSubmit,
            child: const Text('บันทึก', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _inputItem(Icons.badge, 'หมายเลขผู้ป่วย', patientIdController),
            _inputItem(Icons.person, 'ประเภทผู้ป่วย', patientTypeController),
            _inputItem(Icons.location_on, 'จุดรับ', receivePointController),
            _inputItem(Icons.location_on, 'จุดส่ง', sendPointController),
            _stretcherTypeSelector(),
            _equipmentSelector(),
            const SizedBox(height: 24),
            // Mic + Recorder
            CircleAvatar(
              radius: min(MediaQuery.of(context).size.width * 0.1, 100),
              backgroundColor: Colors.blue[50],
              child: IconButton(
                icon: Icon(
                  micController.isListening ? Icons.mic_off : Icons.mic,
                  size: min(MediaQuery.of(context).size.width * 0.1, 100),
                  color: Colors.blue,
                ),
                onPressed: isMicButtonDisabled
                    ? null
                    : () async {
                        setState(() => isMicButtonDisabled = true);
                        try {
                          final status = await Permission.microphone.status;
                          if (!status.isGranted) {
                            final result = await Permission.microphone
                                .request();
                            if (!result.isGranted) return;
                          }

                          if (micController.isListening) {
                            await micController.stop();
                            if (audioRecorder.isRecording) {
                              File? recordedFile = await audioRecorder
                                  .stopRecording();
                              if (recordedFile != null) {
                                print(
                                  "ไฟล์เสียงบันทึกแล้ว: ${recordedFile.path}",
                                );
                              }
                            }
                          } else {
                            if (editingField != null)
                              await micController.stop();

                            await audioRecorder.startRecording();
                            if (editingField != null) {
                              try {
                                micController.listen(
                                  editingField: editingField!,
                                  controllers: {
                                    'หมายเลขผู้ป่วย': patientIdController,
                                    'ประเภทผู้ป่วย': patientTypeController,
                                    'จุดรับ': receivePointController,
                                    'จุดส่ง': sendPointController,
                                  },
                                  onUpdate: () => setState(() {}),
                                );
                              } catch (err) {
                                print("Mic listen error: $err");
                                await micController.stop();
                              }
                            }
                          }
                        } catch (e) {
                          print("Mic/Recorder error: $e");
                        } finally {
                          setState(() => isMicButtonDisabled = false);
                        }
                      },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              micController.isListening
                  ? "กำลังฟัง: ${editingField ?? ''}"
                  : "แตะเพื่อพูด",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              micController.recognizedText,
              style: const TextStyle(fontSize: 16),
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
    bool isEditing = editingField == label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEditing,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.grey,
            ),
            onPressed: isMicButtonDisabled
                ? null
                : () async {
                    setState(() => isMicButtonDisabled = true);
                    try {
                      if (isEditing) {
                        setState(() => editingField = null);
                        await micController.stop();
                      } else {
                        if (editingField != null) await micController.stop();
                        setState(() {
                          editingField = label;
                          micController.recognizedText = '';
                        });
                        try {
                          micController.listen(
                            editingField: label,
                            controllers: {
                              'หมายเลขผู้ป่วย': patientIdController,
                              'ประเภทผู้ป่วย': patientTypeController,
                              'จุดรับ': receivePointController,
                              'จุดส่ง': sendPointController,
                            },
                            onUpdate: () => setState(() {}),
                          );
                        } catch (err) {
                          print("Mic listen error: $err");
                          await micController.stop();
                        }
                      }
                    } finally {
                      setState(() => isMicButtonDisabled = false);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _stretcherTypeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton(
        onPressed: () async {
          final selected = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            builder: (context) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: GetStretcher.getStretcherTypes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Center(child: Text('ไม่สามารถโหลดข้อมูลได้'));
                  }
                  final types = snapshot.data!;
                  return ListView.builder(
                    itemCount: types.length,
                    itemBuilder: (context, index) {
                      final type = types[index];
                      return ListTile(
                        title: Text(type['type_name']),
                        subtitle: Text('จำนวน: ${type['quantity']}'),
                        onTap: () => Navigator.pop(context, type),
                      );
                    },
                  );
                },
              );
            },
          );

          if (selected != null) {
            setState(() {
              selectedStretcherTypeId = selected['id'];
              stretcherTypeName = selected['type_name'];
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
                    : stretcherTypeName,
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

                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return SizedBox(
                            height: 400,
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
