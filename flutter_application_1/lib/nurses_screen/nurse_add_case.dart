// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/getEquipments.dart';
import '../services/getStretcher.dart';

import '../services/user_prefs.dart';
import '../services/mic_function.dart';
import '../design/theme.dart';
import '../data/hospital_locations.dart';
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

  /// แปลงข้อความจากเสียงพูดเป็นหมายเลขผู้ป่วย (HN/AN/XN/DN + ตัวเลข)
  String _parsePatientId(String input) {
    final text = input.toUpperCase().replaceAll(' ', '');

    // รายการ prefix ที่อนุญาต
    const validPrefixes = ['HN', 'AN', 'XN', 'DN'];

    // Mapping คำพูดภาษาไทยเป็น prefix
    final thaiMappings = {
      'เอชเอ็น': 'HN',
      'เอชเอน': 'HN',
      'เฮชเอ็น': 'HN',
      'เฮชเอน': 'HN',
      'ฮอสปิตอล': 'HN',
      'โฮสปิตอล': 'HN',
      'เอเอ็น': 'AN',
      'เอเอน': 'AN',
      'แอดมิต': 'AN',
      'เอ็กซ์เอ็น': 'XN',
      'เอ็กซ์เอน': 'XN',
      'เอ๊กซ์': 'XN',
      'ดีเอ็น': 'DN',
      'ดีเอน': 'DN',
      'ดิสชาร์จ': 'DN',
    };

    String prefix = '';
    String numbers = '';

    // ลองหา prefix จาก input โดยตรง
    for (final p in validPrefixes) {
      if (text.startsWith(p)) {
        prefix = p;
        numbers = text.substring(p.length).replaceAll(RegExp(r'[^0-9]'), '');
        break;
      }
    }

    // ถ้าไม่เจอ ลองหาจาก mapping ภาษาไทย
    if (prefix.isEmpty) {
      final lowerInput = input.toLowerCase().replaceAll(' ', '');
      for (final entry in thaiMappings.entries) {
        if (lowerInput.contains(entry.key.toLowerCase())) {
          prefix = entry.value;
          // ดึงตัวเลขจาก input
          numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
          break;
        }
      }
    }

    // ถ้ายังไม่เจอ prefix ให้ใช้ HN เป็น default
    if (prefix.isEmpty) {
      prefix = 'HN';
      numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
    }

    // รวม prefix + ตัวเลข
    return '$prefix$numbers';
  }

  /// แปลงข้อความจากเสียงพูดเป็นประเภทผู้ป่วย (GE/ER/CV/WC/STR/ISO + ตัวเลข)
  String _parsePatientType(String input) {
    final text = input.toUpperCase().replaceAll(' ', '');

    // รายการ prefix ที่อนุญาต
    const validPrefixes = ['GE', 'ER', 'CV', 'WC', 'STR', 'ISO'];

    // Mapping คำพูดภาษาไทยเป็น prefix
    final thaiMappings = {
      'จีอี': 'GE',
      'จี': 'GE',
      'อีอาร์': 'ER',
      'ฉุกเฉิน': 'ER',
      'ซีวี': 'CV',
      'หัวใจ': 'CV',
      'ดับเบิลยูซี': 'WC',
      'วีซี': 'WC',
      'สตร': 'STR',
      'เอสทีอาร์': 'STR',
      'ไอโซ': 'ISO',
      'แยก': 'ISO',
    };

    String prefix = '';
    String numbers = '';

    // ลองหา prefix จาก input โดยตรง
    for (final p in validPrefixes) {
      if (text.startsWith(p)) {
        prefix = p;
        numbers = text.substring(p.length);
        break;
      }
    }

    // ถ้าไม่เจอ ลองหาจาก mapping ภาษาไทย
    if (prefix.isEmpty) {
      final lowerInput = input.toLowerCase().replaceAll(' ', '');
      for (final entry in thaiMappings.entries) {
        if (lowerInput.contains(entry.key.toLowerCase())) {
          prefix = entry.value;
          // ดึงตัวเลขจาก input
          numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
          break;
        }
      }
    }

    // ถ้ายังไม่เจอ prefix ให้คืนค่าว่างเพื่อให้ผู้ใช้พูดใหม่
    if (prefix.isEmpty) {
      return '';
    }

    // รวม prefix + ตัวเลข
    return '$prefix$numbers';
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40), // เว้นที่ให้ปุ่มย้อนกลับ
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [AppTheme.deepPurple, AppTheme.purple],
                          ).createShader(rect),
                          child: const Text(
                            'เพิ่มเคสใหม่',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                              const SizedBox(height: 12),
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
                                          'ประเภทผู้ป่วย':
                                              patientTypeController,
                                          'จุดรับ': receivePointController,
                                          'จุดส่ง': sendPointController,
                                        },
                                        // ลบ onUpdate ออกเพื่อป้องกันแอปค้างจาก setState ถูกเรียกบ่อยเกินไป
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
                                  // รอ 300ms ให้ speech-to-text ประมวลผลคำสุดท้ายก่อน
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  if (micController.isListening)
                                    await micController.stop();
                                  // รอเพิ่มอีกนิดให้ผลลัพธ์สมบูรณ์
                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );
                                  // เมื่อหยุด ให้เอาข้อความที่ได้ไปแทน controller ของฟิลด์ที่เลือก
                                  if (editingField != null &&
                                      micController.recognizedText.isNotEmpty) {
                                    switch (editingField) {
                                      case 'หมายเลขผู้ป่วย':
                                        // แปลงคำพูดเป็น prefix (HN/AN/XN/DN) + ตัวเลข
                                        patientIdController.text =
                                            _parsePatientId(
                                              micController.recognizedText,
                                            );
                                        break;
                                      case 'ประเภทผู้ป่วย':
                                        // แปลงคำพูดเป็น prefix (GE/ER/CV/WC/STR/ISO) + ตัวเลข
                                        patientTypeController.text =
                                            _parsePatientType(
                                              micController.recognizedText,
                                            );
                                        break;
                                      case 'จุดรับ':
                                        // หาสถานที่ที่ตรงกับคำพูด
                                        final matchedReceive =
                                            HospitalLocations.matchLocation(
                                              micController.recognizedText,
                                            );
                                        receivePointController.text =
                                            matchedReceive ?? '';
                                        break;
                                      case 'จุดส่ง':
                                        // หาสถานที่ที่ตรงกับคำพูด
                                        final matchedSend =
                                            HospitalLocations.matchLocation(
                                              micController.recognizedText,
                                            );
                                        sendPointController.text =
                                            matchedSend ?? '';
                                        break;
                                    }
                                  }
                                  setState(() {});
                                },
                                onTapCancel: () async {
                                  // รอ 300ms ให้ speech-to-text ประมวลผลคำสุดท้ายก่อน
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  if (micController.isListening)
                                    await micController.stop();
                                  // รอเพิ่มอีกนิดให้ผลลัพธ์สมบูรณ์
                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );
                                  // same as onTapUp
                                  if (editingField != null &&
                                      micController.recognizedText.isNotEmpty) {
                                    switch (editingField) {
                                      case 'หมายเลขผู้ป่วย':
                                        // แปลงคำพูดเป็น prefix (HN/AN/XN/DN) + ตัวเลข
                                        patientIdController.text =
                                            _parsePatientId(
                                              micController.recognizedText,
                                            );
                                        break;
                                      case 'ประเภทผู้ป่วย':
                                        // แปลงคำพูดเป็น prefix (GE/ER/CV/WC/STR/ISO) + ตัวเลข
                                        patientTypeController.text =
                                            _parsePatientType(
                                              micController.recognizedText,
                                            );
                                        break;
                                      case 'จุดรับ':
                                        // หาสถานที่ที่ตรงกับคำพูด
                                        final matchedReceive2 =
                                            HospitalLocations.matchLocation(
                                              micController.recognizedText,
                                            );
                                        receivePointController.text =
                                            matchedReceive2 ?? '';
                                        break;
                                      case 'จุดส่ง':
                                        // หาสถานที่ที่ตรงกับคำพูด
                                        final matchedSend2 =
                                            HospitalLocations.matchLocation(
                                              micController.recognizedText,
                                            );
                                        sendPointController.text =
                                            matchedSend2 ?? '';
                                        break;
                                    }
                                  }
                                  setState(() {});
                                },
                                child: CircleAvatar(
                                  radius: min(
                                    MediaQuery.of(context).size.width * 0.08,
                                    60,
                                  ),
                                  backgroundColor: micController.isListening
                                      ? Colors.red[50]
                                      : Colors.blue[50],
                                  child: Icon(
                                    micController.isListening
                                        ? Icons.mic_off
                                        : Icons.mic,
                                    size: min(
                                      MediaQuery.of(context).size.width * 0.08,
                                      60,
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
          ),
          // ปุ่มย้อนกลับ (วางหลัง SafeArea เพื่อให้อยู่บนสุด)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.deepPurple,
                  size: 24,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () async {
          final selected = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.deepPurple, AppTheme.purple],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'เลือกประเภทเปล',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: GetStretcher.getStretcherTypes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return const Center(
                              child: Text('ไม่สามารถโหลดข้อมูลได้'),
                            );
                          }
                          final types = snapshot.data!;
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: types.length,
                            itemBuilder: (context, index) {
                              final type = types[index];
                              final quantity = type['quantity'] ?? 0;
                              final isAvailable = quantity > 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isAvailable
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: isAvailable
                                      ? () => Navigator.pop(context, type)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isAvailable
                                                ? AppTheme.deepPurple
                                                      .withOpacity(0.1)
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.airline_seat_flat,
                                            color: isAvailable
                                                ? AppTheme.deepPurple
                                                : Colors.grey,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                type['type_name'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isAvailable
                                                      ? Colors.black87
                                                      : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    isAvailable
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                    size: 14,
                                                    color: isAvailable
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isAvailable
                                                        ? 'พร้อมใช้งาน'
                                                        : 'ไม่พร้อมใช้งาน',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isAvailable
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quantity badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isAvailable
                                                ? Colors.green
                                                : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '$quantity',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isAvailable
                                                  ? Colors.white
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: stretcherTypeName.isEmpty
                  ? AppTheme.lavender
                  : AppTheme.deepPurple,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.airline_seat_flat,
                  color: AppTheme.deepPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประเภทเปล',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stretcherTypeName.isEmpty
                          ? 'กดเพื่อเลือก'
                          : stretcherTypeName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: stretcherTypeName.isEmpty
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _equipmentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () async {
          final selected = await showModalBottomSheet<List<Map<String, dynamic>>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: GetEquipments.getEquipments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: const Center(
                        child: Text('ไม่สามารถโหลดข้อมูลได้'),
                      ),
                    );
                  }

                  final equipment = snapshot.data!;
                  List<int> tempSelected = List.from(selectedEquipmentIds);

                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.teal.shade600,
                                    Colors.teal.shade400,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.medical_services,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'เลือกอุปกรณ์เสริม',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'เลือกแล้ว ${tempSelected.length} รายการ',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: equipment.length,
                                itemBuilder: (context, index) {
                                  final eq = equipment[index];
                                  final isSelected = tempSelected.contains(
                                    eq['id'],
                                  );
                                  final quantity = eq['quantity'] ?? 0;
                                  final isAvailable = quantity > 0;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    elevation: isSelected ? 4 : 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.teal
                                            : (isAvailable
                                                  ? Colors.grey.shade200
                                                  : Colors.red.shade100),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: isAvailable
                                          ? () {
                                              setModalState(() {
                                                if (isSelected) {
                                                  tempSelected.remove(eq['id']);
                                                } else {
                                                  tempSelected.add(eq['id']);
                                                }
                                              });
                                            }
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Checkbox
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.teal
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.teal
                                                      : (isAvailable
                                                            ? Colors
                                                                  .grey
                                                                  .shade400
                                                            : Colors
                                                                  .grey
                                                                  .shade300),
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 18,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            // Icon
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isAvailable
                                                    ? Colors.teal.withOpacity(
                                                        0.1,
                                                      )
                                                    : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.medical_services_outlined,
                                                color: isAvailable
                                                    ? Colors.teal
                                                    : Colors.grey,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    eq['equipment_name'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isAvailable
                                                          ? Colors.black87
                                                          : Colors.grey,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    isAvailable
                                                        ? 'พร้อมใช้งาน'
                                                        : 'หมด',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isAvailable
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Quantity badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isAvailable
                                                    ? Colors.teal.shade50
                                                    : Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$quantity',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAvailable
                                                      ? Colors.teal
                                                      : Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Confirm Button
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: SafeArea(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        equipment
                                            .where(
                                              (e) => tempSelected.contains(
                                                e['id'],
                                              ),
                                            )
                                            .toList(),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      'ยืนยัน (${tempSelected.length} รายการ)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: equipmentNames.isEmpty ? AppTheme.lavender : Colors.teal,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อุปกรณ์เสริม',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      equipmentNames.isEmpty
                          ? 'กดเพื่อเลือก (ไม่บังคับ)'
                          : '${selectedEquipmentIds.length} รายการ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: equipmentNames.isEmpty
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                    if (equipmentNames.isNotEmpty)
                      Text(
                        equipmentNames,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (selectedEquipmentIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedEquipmentIds.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
