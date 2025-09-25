// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/Equipments/equipment_get_function.dart';
import '../services/Stretchers/stretcher_get_function.dart';

import '../services/user_prefs.dart';
import '../services/Microphone/mic_function.dart';
import '../design/theme.dart';
import 'nurse_ex-post_case.dart';

class NurseAddCaseScreen extends StatefulWidget {
  const NurseAddCaseScreen({super.key});
  @override
  State<NurseAddCaseScreen> createState() => _NurseAddCaseScreenState();
}

class _NurseAddCaseScreenState extends State<NurseAddCaseScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController patientIdController = TextEditingController();
  final TextEditingController patientTypeController = TextEditingController();
  final TextEditingController receivePointController = TextEditingController();
  final TextEditingController sendPointController = TextEditingController();

  List<int> selectedEquipmentIds = [];
  int? selectedStretcherTypeId;

  String stretcherTypeName = '';
  String equipmentNames = '';
  String? editingField;

  final MicController micController = MicController();
  bool isMicButtonDisabled = false;

  late final AnimationController _inCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<Offset> _titleSlide = Tween<Offset>(
    begin: const Offset(-1.2, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _inCtrl, curve: Curves.easeOutBack));

  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _inCtrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _initMicAndRecorder();
    Future.delayed(const Duration(milliseconds: 300), _inCtrl.forward);
  }

  Future<void> _initMicAndRecorder() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    await micController.init();
  }

  @override
  void dispose() {
    patientIdController.dispose();
    patientTypeController.dispose();
    receivePointController.dispose();
    sendPointController.dispose();
    micController.stop();
    _inCtrl.dispose();
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: [theme.scaffoldBackgroundColor, AppTheme.lavender],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [AppTheme.deepPurple, AppTheme.purple],
                        ).createShader(rect),
                        child: const Text(
                          'เพิ่มเคสใหม่',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _GlassCard(
                        child: Column(
                          children: [
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
                            _inputItem(
                              Icons.location_on,
                              'จุดรับ',
                              receivePointController,
                            ),
                            _inputItem(
                              Icons.location_on,
                              'จุดส่ง',
                              sendPointController,
                            ),
                            _stretcherTypeSelector(),
                            _equipmentSelector(),
                            const SizedBox(height: 24),
                            // Mic + Recorder
                            GestureDetector(
                              onTapDown: (details) async {
                                if (isMicButtonDisabled) return;
                                if (editingField == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'กรุณาเลือกฟิลด์ก่อนกดไมค์',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => isMicButtonDisabled = true);
                                try {
                                  if (!micController.isInitialized) {
                                    await micController.init();
                                  }
                                  // เคลียร์ผลก่อนเริ่ม
                                  micController.recognizedText = "";
                                  try {
                                    await micController.listen(
                                      editingField: editingField,
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
                                } catch (e) {
                                  print("Mic error: $e");
                                } finally {
                                  setState(() => isMicButtonDisabled = false);
                                }
                              },
                              onTapUp: (details) async {
                                if (micController.isListening)
                                  await micController.stop();
                                // เมื่อหยุด ให้เอาข้อความที่ได้ไปแทน controller ของฟิลด์ที่เลือก
                                if (editingField != null &&
                                    micController.recognizedText.isNotEmpty) {
                                  switch (editingField) {
                                    case 'หมายเลขผู้ป่วย':
                                      patientIdController.text =
                                          micController.recognizedText;
                                      break;
                                    case 'ประเภทผู้ป่วย':
                                      patientTypeController.text =
                                          micController.recognizedText;
                                      break;
                                    case 'จุดรับ':
                                      receivePointController.text =
                                          micController.recognizedText;
                                      break;
                                    case 'จุดส่ง':
                                      sendPointController.text =
                                          micController.recognizedText;
                                      break;
                                  }
                                }
                                setState(() {});
                              },
                              onTapCancel: () async {
                                if (micController.isListening)
                                  await micController.stop();
                                // same as onTapUp
                                if (editingField != null &&
                                    micController.recognizedText.isNotEmpty) {
                                  switch (editingField) {
                                    case 'หมายเลขผู้ป่วย':
                                      patientIdController.text =
                                          micController.recognizedText;
                                      break;
                                    case 'ประเภทผู้ป่วย':
                                      patientTypeController.text =
                                          micController.recognizedText;
                                      break;
                                    case 'จุดรับ':
                                      receivePointController.text =
                                          micController.recognizedText;
                                      break;
                                    case 'จุดส่ง':
                                      sendPointController.text =
                                          micController.recognizedText;
                                      break;
                                  }
                                }
                                setState(() {});
                              },
                              child: CircleAvatar(
                                radius: min(
                                  MediaQuery.of(context).size.width * 0.1,
                                  100,
                                ),
                                backgroundColor: micController.isListening
                                    ? Colors.red[50]
                                    : Colors.blue[50],
                                child: Icon(
                                  micController.isListening
                                      ? Icons.mic_off
                                      : Icons.mic,
                                  size: min(
                                    MediaQuery.of(context).size.width * 0.1,
                                    100,
                                  ),
                                  color: micController.isListening
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              micController.isListening
                                  ? "กำลังฟัง: ${editingField ?? ''}"
                                  : "แตะค้างเพื่อพูด (push-to-talk)",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              micController.recognizedText,
                              style: const TextStyle(fontSize: 16),
                            ),
                            _GradientButton(
                              text: 'บันทึกเคส',
                              onTap: _validateAndSubmit,
                            ),
                          ],
                        ),
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

  Widget _inputItem(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
    final bool isEditing = editingField == label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: isMicButtonDisabled
            ? null
            : () async {
                // เลือก/ยกเลิก field สำหรับการแทนข้อความจากไมค์
                setState(() {
                  if (!isEditing) {
                    editingField = label;
                  } else {
                    editingField = null;
                  }
                });
              },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppTheme.deepPurple),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isEditing ? Colors.green : AppTheme.lavender,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.deepPurple, width: 1.6),
            ),
          ),
          child: Text(
            controller.text.isNotEmpty ? controller.text : '',
            style: const TextStyle(fontSize: 16),
          ),
        ),
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
                future: StretcherGetService.fetchStretchers(),
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
                    future: EquipmentGetService.fetchEquipments(),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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

class _GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  const _GradientButton({required this.text, this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.98,
  ).animate(_pressCtrl);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [AppTheme.deepPurple, AppTheme.purple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }
}
