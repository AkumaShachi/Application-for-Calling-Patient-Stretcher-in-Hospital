// ignore_for_file: sized_box_for_whitespace, avoid_print, deprecated_member_use

import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../editprofilescreen.dart';
import '../loginscreen.dart';
import 'nurse_add_case.dart';
import '../services/getcase_function.dart';
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

  String fname = '', lname = '', username = '', email = '', phone = '';
  File? _selectedImage;
  String? profileImageUrl;

  List<Map<String, dynamic>> allCases = [];
  List<Map<String, dynamic>> myCases = [];
  bool loadingAll = true;
  bool loadingMy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final fetchedAll = await GetcaseFunction.fetchAllCasesNurse();
      final fetchedMy = await GetcaseFunction.fetchMyCasesNurse(username);
      setState(() {
        allCases = fetchedAll;
        myCases = fetchedMy;
        loadingAll = false;
        loadingMy = false;
      });
    } catch (e) {
      print("Error fetching cases: $e");
    }
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

  String formatEquipment(dynamic equipment) {
    if (equipment == null) return 'ไม่มี';
    if (equipment is List) return equipment.join(', ');
    if (equipment is String) return equipment;
    return equipment.toString();
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
              Tab(text: 'เคสทั้งหมด'),
              Tab(text: 'เคสของฉัน'),
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
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาเคสผู้ป่วย',
                        prefixIcon: const Icon(Icons.search),
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
                                cases: allCases,
                                timeFormatter: timeAgo,
                                formatEquipment: formatEquipment,
                              ),
                        loadingMy
                            ? const Center(child: CircularProgressIndicator())
                            : CaseListView(
                                cases: myCases,
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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index];
        return _GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item["fname_U"]} ${item["lname_U"]}',
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
                  "อุปกรณ์: ${formatEquipment(item['equipment'])}",
                ),
              ],
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
