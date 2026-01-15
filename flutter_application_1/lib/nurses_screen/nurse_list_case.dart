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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeCtrl.forward();
    _loadUserInfo();
    _fetchCases();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCases();
    });
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

  List<Map<String, dynamic>> _filterCases(List<Map<String, dynamic>> cases) {
    if (_searchQuery.isEmpty) return cases;
    return cases.where((item) {
      final patientId = (item['patient_id'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      // ค้นหาจากหมายเลขผู้ป่วย
      return patientId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: [
            // ----- Gradient background -----
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    AppTheme.lavender,
                  ],
                ),
              ),
            ),

            // ----- Content -----
            SafeArea(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: Column(
                  children: [
                    // Header with title
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'บันทึกเคสผู้ป่วย',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.deepPurple,
                                  ),
                                ),
                                Text(
                                  'จำนวน ${allCases.length} เคส',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Builder(
                            builder: (context) => IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.deepPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu,
                                  color: AppTheme.deepPurple,
                                ),
                              ),
                              onPressed: () =>
                                  Scaffold.of(context).openEndDrawer(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ค้นหาด้วยหมายเลขผู้ป่วย...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppTheme.deepPurple,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppTheme.deepPurple,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.all(4),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade600,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.list_alt, size: 18),
                                const SizedBox(width: 8),
                                const Text('เคสทั้งหมด'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person, size: 18),
                                const SizedBox(width: 8),
                                const Text('เคสของฉัน'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tab view content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          loadingAll
                              ? const Center(child: CircularProgressIndicator())
                              : _filterCases(allCases).isEmpty
                              ? _buildEmptyState('ไม่พบเคสที่ค้นหา')
                              : CaseListView(
                                  cases: _filterCases(allCases),
                                  timeFormatter: timeAgo,
                                  formatEquipment: formatEquipment,
                                ),
                          loadingMy
                              ? const Center(child: CircularProgressIndicator())
                              : _filterCases(myCases).isEmpty
                              ? _buildEmptyState('ไม่พบเคสที่ค้นหา')
                              : CaseListView(
                                  cases: _filterCases(myCases),
                                  timeFormatter: timeAgo,
                                  formatEquipment: formatEquipment,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // ... rest of the file ...
        endDrawer: _buildDrawer(context),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.deepPurple, AppTheme.purple],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NurseAddCaseScreen()),
              );
            },
            child: const Icon(Icons.mic, color: Colors.white, size: 28),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index];
        final timeText = timeFormatter(item["created_at"] ?? '');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.deepPurple.withOpacity(0.1),
                      AppTheme.lavender.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.deepPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item["fname_U"] ?? ""} ${item["lname_U"] ?? ""}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${item['patient_id'] ?? '-'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepPurple,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.category,
                      'ประเภทผู้ป่วย',
                      item['patient_type'] ?? '-',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.location_on,
                      'จุดรับ → จุดส่ง',
                      '${item['room_from'] ?? '-'}\n→ ${item['room_to'] ?? '-'}',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _infoBadge(
                      Icons.airline_seat_flat,
                      'ประเภทเปล',
                      item['stretcher_type'] ?? '-',
                      AppTheme.deepPurple,
                    ),
                    const SizedBox(height: 12),
                    _infoBadge(
                      Icons.medical_services_outlined,
                      'อุปกรณ์',
                      formatEquipment(item['equipment']),
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBadge(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
