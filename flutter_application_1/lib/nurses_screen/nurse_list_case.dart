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
      final fetchedMy = await GetcaseFunction.fetchMyCasesNurseWithHistory(
        username,
      );
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
      backgroundColor: Colors.grey.shade50,
      child: Column(
        children: [
          // Header with Gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.deepPurple,
                  AppTheme.purple,
                  Colors.purple.shade300,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                child: Column(
                  children: [
                    // Profile Image with Border - Clickable
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context); // Close drawer
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
                            profileImageUrl =
                                updated['profile_image'] ?? profileImageUrl;
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!) as ImageProvider
                                  : (profileImageUrl != null
                                        ? NetworkImage(profileImageUrl!)
                                        : null),
                              child:
                                  (_selectedImage == null &&
                                      profileImageUrl == null)
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppTheme.deepPurple,
                                    )
                                  : null,
                            ),
                          ),
                          // Camera icon overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: AppTheme.deepPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      '$fname $lname',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'พยาบาล',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Contact Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลติดต่อ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Email Card
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        label: 'อีเมล',
                        value: email.isNotEmpty ? email : '-',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      // Phone Card
                      _buildInfoCard(
                        icon: Icons.phone_outlined,
                        label: 'โทรศัพท์',
                        value: phone.isNotEmpty ? phone : '-',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade300, height: 1),
                const SizedBox(height: 16),

                // Menu Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'เมนู',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Edit Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
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
                            profileImageUrl =
                                updated['profile_image'] ?? profileImageUrl;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                color: AppTheme.deepPurple,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'แก้ไขข้อมูลส่วนตัว',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'อัปเดตชื่อ, อีเมล, เบอร์โทร',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 10),
                          Text('ออกจากระบบ'),
                        ],
                      ),
                      content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'ยกเลิก',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'ออกจากระบบ',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
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

  // Helper to determine status display
  Map<String, dynamic> _getStatusDisplay(String? status) {
    switch (status) {
      case 'completed':
        return {
          'text': '✅ ส่งแล้ว',
          'color': Colors.green,
          'bgColor': Colors.green.shade50,
          'icon': Icons.check_circle,
        };
      case 'in_progress':
        return {
          'text': '🚀 กำลังส่ง',
          'color': Colors.orange,
          'bgColor': Colors.orange.shade50,
          'icon': Icons.local_shipping,
        };
      default: // pending
        return {
          'text': '⏳ รอดำเนินการ',
          'color': Colors.blue,
          'bgColor': Colors.blue.shade50,
          'icon': Icons.pending_actions,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index];
        final timeText = timeFormatter(item["created_at"] ?? '');
        final status = item['status']?.toString() ?? 'pending';
        final statusDisplay = _getStatusDisplay(status);
        final bool isCompleted = status == 'completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (statusDisplay['color'] as Color).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (statusDisplay['color'] as Color).withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with status-based gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [
                            Colors.green.shade50,
                            Colors.green.shade100.withOpacity(0.5),
                          ]
                        : [
                            AppTheme.deepPurple.withOpacity(0.1),
                            AppTheme.lavender.withOpacity(0.3),
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    // Status Badge Row
                    Row(
                      children: [
                        // Status Badge - Large & Clear
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusDisplay['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: (statusDisplay['color'] as Color)
                                  .withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (statusDisplay['color'] as Color)
                                    .withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusDisplay['icon'] as IconData,
                                size: 18,
                                color: statusDisplay['color'] as Color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusDisplay['text'] as String,
                                style: TextStyle(
                                  color: statusDisplay['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Time Badge
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
                    const SizedBox(height: 12),
                    // Patient Info Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.shade600
                                : AppTheme.deepPurple,
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'HN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatPatientId(
                                      item['patient_id']?.toString(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    // Location with better layout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade500,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'จุดรับ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      item['room_from'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 4,
                              bottom: 4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 2,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.green.shade400,
                                        Colors.red.shade400,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade500,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'จุดส่ง',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      item['room_to'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoBadgeSmall(
                            Icons.airline_seat_flat,
                            'เปล',
                            item['stretcher_type'] ?? '-',
                            AppTheme.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _infoBadgeSmall(
                            Icons.medical_services_outlined,
                            'อุปกรณ์',
                            formatEquipment(item['equipment']),
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    // Completed at info for completed cases
                    if (isCompleted && item['completed_at'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เสร็จสิ้นเมื่อ: ${_formatCompletedTime(item['completed_at'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _infoBadgeSmall(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
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

  // Helper function to format patient ID without duplicate HN
  String _formatPatientId(String? patientId) {
    if (patientId == null || patientId.isEmpty) return '-';
    // Remove HN prefix if already exists
    String cleanId = patientId.replaceFirst(
      RegExp(r'^HN', caseSensitive: false),
      '',
    );
    return cleanId;
  }

  // Helper function to format completed time
  String _formatCompletedTime(String? completedAt) {
    if (completedAt == null) return '-';
    try {
      final date = DateTime.parse(completedAt).toLocal();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month ${hour}:$minute น.';
    } catch (e) {
      return completedAt;
    }
  }
}
