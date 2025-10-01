// ignore_for_file: sized_box_for_whitespace, avoid_print, deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../editprofilescreen.dart';
import '../loginscreen.dart';
import '../services/Cases/case_delete_function.dart';
import '../services/CasesHistory/caseshistory_add_function.dart';
import '../services/Equipments/equipment_get_function.dart';
import '../services/Profile/profile_get_function.dart';
import '../services/Stretchers/stretcher_get_function.dart';
import 'nurse_add_case.dart';
import '.././services/Cases/case_get_function.dart';
import '../design/theme.dart';

class NurseListCaseScreen extends StatefulWidget {
  const NurseListCaseScreen({super.key});
  @override
  State<NurseListCaseScreen> createState() => _NurseListCaseScreenState();
}

class _NurseListCaseScreenState extends State<NurseListCaseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Timer _timer;
  late AnimationController _fadeCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  String fname = '', lname = '', username = '', email = '', phone = '';
  File? _selectedImage;
  String? profileImageUrl;

  List<Map<String, dynamic>> allCases = [];
  List<Map<String, dynamic>> myCases = [];
  List<Map<String, dynamic>> filteredAllCases = [];
  List<Map<String, dynamic>> filteredMyCases = [];

  bool loadingAll = true;
  bool loadingMy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(_applyFilter);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadUserInfo();
    _fetchCases();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchCases());
    Future.delayed(const Duration(milliseconds: 300), _fadeCtrl.forward);
  }

  @override
  void dispose() {
    _timer.cancel();
    _tabController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fname = prefs.getString('fname_U') ?? '';
      lname = prefs.getString('lname_U') ?? '';
      username = prefs.getString('id') ?? '';
      email = prefs.getString('email_U') ?? '';
      phone = prefs.getString('phone_U') ?? '';
      profileImageUrl = prefs.getString('profile_image');
    });
  }

  Future<void> _fetchCases() async {
    try {
      final fetchedAll = await CaseGetService.fetchAllCasesForNurse();
      final fetchedMy = await CaseGetService.fetchCasesForNurse(username);
      setState(() {
        allCases = fetchedAll;
        myCases = fetchedMy;
        filteredAllCases = allCases;
        filteredMyCases = myCases;
        loadingAll = false;
        loadingMy = false;
      });
      // print("========== All Cases ==========");
      // for (var c in allCases) {
      //   print(c);
      // }
      // print("========== My Cases ==========");
      // for (var c in myCases) {
      //   print(c);
      // }
      // print("========== End ==========");
      _applyFilter();
    } catch (e) {
      print("Error fetching cases: $e");
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredAllCases = allCases;
        filteredMyCases = myCases;
      } else {
        filteredAllCases = allCases
            .where(
              (c) => (c['patient_id'] ?? '').toString().toLowerCase().contains(
                query,
              ),
            )
            .toList();
        filteredMyCases = myCases
            .where(
              (c) => (c['patient_id'] ?? '').toString().toLowerCase().contains(
                query,
              ),
            )
            .toList();
      }
    });
  }

  String timeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
      if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
      return '${diff.inDays} วันก่อน';
    } catch (e) {
      return createdAt;
    }
  }

  String formatEquipment(dynamic equipments) {
    if (equipments == null) return 'ไม่มี';

    List<String> items = [];

    if (equipments is List) {
      if (equipments.isEmpty) return 'ไม่มี';
      items = equipments
          .map((e) {
            if (e is Map<String, dynamic>) return e['name']?.toString() ?? '';
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (equipments is String) {
      if (equipments.trim().isEmpty) return 'ไม่มี';
      items = equipments.split(',').map((e) => e.trim()).toList();
    } else {
      items = [equipments.toString()];
    }

    if (items.length <= 3) {
      return items.join(', ');
    } else {
      return "${items.take(3).join(', ')} ...เพิ่มเติม";
    }
  }

  List<String> normalizeEquipments(dynamic equipments) {
    if (equipments == null) return [];

    if (equipments is List) {
      return equipments
          .map((e) {
            if (e is Map<String, dynamic>) return e['name']?.toString() ?? '';
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (equipments is String) {
      if (equipments.trim().isEmpty) return [];
      return equipments.split(',').map((e) => e.trim()).toList();
    }

    return [equipments.toString()];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ❌ ปิดการกดปุ่มย้อนกลับ
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("บันทึกเคสผู้ป่วย"),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '                  เคสทั้งหมด                  '),
              Tab(text: '                  เคสของฉัน                  '),
            ],
          ),
        ),
        endDrawer: _buildDrawer(context),
        body: Stack(
          children: [
            // ----- Gradient background + blur -----
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1, -1),
                  end: Alignment(1, 1),
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    AppTheme.lavender,
                  ],
                ),
              ),
            ),
            // ----- Content -----
            FadeTransition(
              opacity: _fadeCtrl,
              child: Column(
                children: [
                  SizedBox(height: 10),
                  SizedBox(
                    width:
                        MediaQuery.of(context).size.width *
                        0.9, // ✅ กำหนดความกว้างเอง
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาเคสผู้ป่วยด้วย "หมายเลขผู้ป่วย"',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        loadingAll
                            ? const Center(child: CircularProgressIndicator())
                            : CaseListView(
                                cases: filteredAllCases,
                                timeFormatter: timeAgo,
                                formatEquipment: formatEquipment,
                              ),
                        loadingMy
                            ? const Center(child: CircularProgressIndicator())
                            : CaseListView(
                                cases: filteredMyCases,
                                timeFormatter: timeAgo,
                                formatEquipment: formatEquipment,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.deepPurple,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NurseAddCaseScreen()),
            );
          },
          child: const Icon(Icons.mic, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 60,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!) as ImageProvider
                : (profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null),
            child: (_selectedImage == null && profileImageUrl == null)
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('$fname $lname'),
          ),
          ListTile(leading: const Icon(Icons.email), title: Text(email)),
          ListTile(leading: const Icon(Icons.phone), title: Text(phone)),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('แก้ไขข้อมูล'),
            onTap: () async {
              Navigator.pop(context);
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    fname: fname,
                    lname: lname,
                    email: email,
                    phone: phone,
                    ImageUrl: profileImageUrl,
                  ),
                ),
              );
              if (updated != null) {
                setState(() {
                  fname = updated['fname_U'] ?? fname;
                  lname = updated['lname_U'] ?? lname;
                  email = updated['email_U'] ?? email;
                  phone = updated['phone_U'] ?? phone;
                  profileImageUrl = updated['profile_image'] ?? profileImageUrl;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();

              // 🗑️ เคลียร์ข้อมูลผู้ใช้ที่บันทึกไว้
              await prefs.clear();

              // 🗑️ ถ้าไม่อยากลบทุกอย่าง แค่ลบเฉพาะที่เกี่ยวกับการจำรหัสผ่านก็ได้
              // await prefs.remove('saved_username');
              // await prefs.remove('saved_password');

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/* ---------- ListView พร้อม GlassCard ---------- */
class CaseListView extends StatelessWidget {
  final List<Map<String, dynamic>> cases;
  final String Function(String) timeFormatter;
  final String Function(dynamic) formatEquipment;
  const CaseListView({
    super.key,
    required this.cases,
    required this.timeFormatter,
    required this.formatEquipment,
  });

  String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      final dateTime = DateTime.parse(
        dateStr,
      ).toLocal(); // ✅ แปลงเป็นเวลาท้องถิ่น
      return DateFormat('dd MMM yyyy เวลา HH:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  List<String> extractEquipmentNames(dynamic equipments) {
    if (equipments == null) return [];
    if (equipments is List) {
      return equipments
          .map((e) {
            if (e is Map<String, dynamic>) return e['name']?.toString() ?? '';
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (equipments is String) {
      return equipments
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [equipments.toString()];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index];
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => _buildCaseDetailDialog(ctx, item),
            );
          },
          child: _GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item["requested_by_fname"]} ${item["requested_by_lname"]}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeFormatter(item["created_at"] ?? ''),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _info(
                    Icons.confirmation_number,
                    "หมายเลขผู้ป่วย: ${item['patient_id'] ?? ''}",
                  ),
                  _info(
                    Icons.person,
                    "ประเภทผู้ป่วย: ${item['patient_type'] ?? ''}",
                  ),
                  _info(
                    Icons.place,
                    "จุดรับ-ส่ง: ${item['room_from'] ?? ''} → ${item['room_to'] ?? ''}",
                  ),
                  _info(
                    Icons.airline_seat_flat,
                    "ประเภทเปล: ${item['stretcher_type'] ?? ''}",
                  ),
                  _info(
                    Icons.medical_services,
                    "อุปกรณ์: ${formatEquipment(item['equipments'])}",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _info(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.deepPurple),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _buildCaseDetailDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final bool isCompleted =
        (item['status']?.toString().toLowerCase() == 'completed');
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "หมายเลขผู้ป่วย ${item['patient_id']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🧑‍⚕️ Patient Info
            ListTile(
              leading: const Icon(Icons.person, color: Colors.deepPurple),
              title: Text("ประเภทผู้ป่วย: ${item['patient_type']}"),
            ),
            // 🏥 Location
            ListTile(
              leading: const Icon(Icons.place, color: Colors.teal),
              title: Text("จุดรับ: ${item['room_from']}"),
              subtitle: Text("จุดส่ง: ${item['room_to']}"),
            ),
            // 🛏️ Stretcher
            ListTile(
              leading: const Icon(
                Icons.airline_seat_flat,
                color: Colors.indigo,
              ),
              title: Text("ประเภทเปล: ${item['stretcher_type']}"),
            ),
            // 👷 Assigned Porter
            if ((item['assigned_porter_fname'] != null &&
                    item['assigned_porter_fname'] != "null") ||
                (item['assigned_porter_lname'] != null &&
                    item['assigned_porter_lname'] != "null"))
              ListTile(
                leading: const Icon(Icons.person, color: Colors.deepPurple),
                title: Text(
                  "เจ้าหน้าที่: ${item['assigned_porter_fname']} ${item['assigned_porter_lname']}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () async {
                  final username = item['assigned_porter_username'];
                  if (username == null || username == "null") return;

                  try {
                    final profile = await ProfileGetService.fetchProfile(
                      username,
                    );
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("ข้อมูลเจ้าหน้าที่"),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profile['profile_image'] != null)
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(
                                  profile['profile_image'],
                                ),
                              )
                            else
                              const CircleAvatar(
                                radius: 40,
                                child: Icon(Icons.person, size: 40),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              "${profile['fname']} ${profile['lname']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade300),
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.email,
                                color: Colors.deepPurple,
                              ),
                              title: Text(profile['email'] ?? "-"),
                            ),
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.phone,
                                color: Colors.teal,
                              ),
                              title: Text(profile['phone'] ?? "-"),
                            ),
                          ],
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("โหลดข้อมูลล้มเหลว: $e")),
                    );
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.person, color: Colors.grey),
                title: const Text("เจ้าหน้าที่: -"),
              ),

            // 📋 Status
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.orange),
              title: Text("สถานะ: ${item['status']}"),
            ),
            // 🕒 Timestamps
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blueGrey),
              title: Text("สร้างเมื่อ: ${formatDateTime(item['created_at'])}"),
              subtitle: Text(
                "เสร็จสิ้น: ${formatDateTime(item['completed_at'])}",
              ),
            ),
            // ⚙️ Equipments
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.red),
              title: const Text("อุปกรณ์ที่ใช้"),
              subtitle: Text(
                formatEquipment(item['equipments']),
                style: const TextStyle(fontSize: 13),
              ),
              onTap: () {
                final allEquipments = normalizeEquipments(item['equipments']);
                if (allEquipments.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("อุปกรณ์ทั้งหมด"),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(allEquipments.length, (
                            index,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "${index + 1}. ${allEquipments[index]}",
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      actions: isCompleted
          ? [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("ลบเคส"),
                    onPressed: () async {
                      try {
                        // 1. เพิ่มเคสไปยัง recordhistory ก่อน
                        await CaseHistoryAddService.createHistory({
                          "patientId": item['patient_id'],
                          "patientType": item['patient_type'],
                          "roomFrom": item['room_from'],
                          "roomTo": item['room_to'],
                          "stretcherType": item['stretcher_type'],
                          "stretcherTypeId": item['str_type_id'],
                          "requestedBy": item['requested_by_username'],
                          "assignedPorter": item['assigned_porter_username'],
                          "status": item['status'],
                          "notes": item['notes'],
                          "equipments": extractEquipmentNames(
                            item['equipments'],
                          ),
                          "createdAt": item['created_at'],
                          "completedAt": item['completed_at'],
                        });

                        // 2. ลบเคสออกจากตาราง cases
                        await CaseDeleteService.deleteCase(item['case_id']);

                        if (context.mounted) {
                          Navigator.pop(context); // ปิด dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("ลบเคสเรียบร้อย")),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                          );
                        }
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    label: const Text("ดำเนินการส่งต่อ"),
                    onPressed: () async {
                      // ดึงข้อมูลอุปกรณ์ทั้งหมดมาก่อน
                      final allEquipments =
                          await EquipmentGetService.fetchEquipments();
                      final allStretchers =
                          await StretcherGetService.fetchStretchers();

                      List<int> equipmentIds = [];
                      String equipmentNames = "";
                      int? strecherIds;
                      String strecherNames = "";

                      if (item['equipments'] is String) {
                        // แยกชื่อออกมาเป็น List
                        final selectedNames = (item['equipments'] as String)
                            .split(',')
                            .map((e) => e.trim())
                            .toList();

                        // เทียบชื่อกับ allEquipments เพื่อหา id
                        final matched = allEquipments.where(
                          (eq) => selectedNames.contains(eq['eqpt_name']),
                        );

                        equipmentIds = matched
                            .map<int>((eq) => eq['eqpt_id'] as int)
                            .toList();
                        equipmentNames = matched
                            .map((eq) => eq['eqpt_name'])
                            .join(', ');
                      }
                      if (item['stretcher_type'] != null) {
                        final matched = allStretchers.firstWhere(
                          (s) => s['str_type_name'] == item['stretcher_type'],
                          orElse: () => {},
                        );
                        if (matched.isNotEmpty) {
                          strecherIds = matched['str_type_id'] as int;
                          strecherNames = matched['str_type_name'] as String;
                        }
                      }
                      Navigator.pop(context); // ปิด dialog ก่อน
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NurseAddCaseScreen(
                            initialPatientId: item['patient_id'],
                            initialPatientType: item['patient_type'],
                            initialReceivePoint: item['room_to'],
                            initialSendPoint: '',
                            initialStretcherTypeId: strecherIds,
                            initialStretcherTypeName: strecherNames,
                            initialEquipmentIds: equipmentIds,
                            initialEquipmentNames: equipmentNames,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ปิด"),
              ),
            ],
    );
  }

  List<String> normalizeEquipments(dynamic equipments) {
    if (equipments == null) return [];

    if (equipments is List) {
      return equipments
          .map((e) {
            if (e is Map<String, dynamic>) return e['name']?.toString() ?? '';
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (equipments is String) {
      if (equipments.trim().isEmpty) return [];
      return equipments.split(',').map((e) => e.trim()).toList();
    }

    return [equipments.toString()];
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.65),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
