// ignore_for_file: library_private_types_in_public_api, sized_box_for_whitespace, avoid_print, deprecated_member_use
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/theme.dart';
import '../editprofilescreen.dart';
import '../loginscreen.dart';
import '../services/getcase_function.dart';
import '../services/recordhistory_function.dart';
import '../services/updatecase_function.dart';
import 'porter_case_detail.dart';

class PorterCaseListScreen extends StatefulWidget {
  const PorterCaseListScreen({super.key});
  @override
  _PorterCaseListScreenState createState() => _PorterCaseListScreenState();
}

class _PorterCaseListScreenState extends State<PorterCaseListScreen>
    with TickerProviderStateMixin {
  int selectedTabIndex = 0;
  String fname = '', lname = '', username = '', email = '', phone = '';
  File? _selectedImage;
  String? profileImageUrl;
  List<Map<String, dynamic>> cases = [];

  final List<String> tabs = [
    'ทั้งหมด',
    'รอดำเนินการ',
    'กำลังดำเนินการ',
    'เสร็จสิ้น',
  ];

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// ✅ ฟังก์ชัน map ชื่อแท็บไทย → key status จริง
  String statusKey(String tabLabel) {
    switch (tabLabel) {
      case 'รอดำเนินการ':
        return 'pending';
      case 'กำลังดำเนินการ':
        return 'in_progress';
      case 'เสร็จสิ้น':
        return 'completed';
      default:
        return '';
    }
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fname = prefs.getString('fname_U') ?? '';
      lname = prefs.getString('lname_U') ?? '';
      username = prefs.getString('id') ?? '';
      email = prefs.getString('email_U') ?? '';
      phone = prefs.getString('phone_U') ?? '';
      profileImageUrl = prefs.getString('profile_image');
    });
    loadCases();
  }

  void loadCases() async {
    if (username.isEmpty) return;
    print('🔹 Loading cases for tab: ${tabs[selectedTabIndex]}');
    try {
      List<Map<String, dynamic>> fetchedCases = [];
      switch (tabs[selectedTabIndex]) {
        case 'ทั้งหมด':
          var activeCases = await GetcaseFunction.fetchMyCasesPorter(username);
          fetchedCases = activeCases
              .where((c) => c['status'] != 'completed')
              .toList();
          break;

        case 'รอดำเนินการ':
        case 'กำลังดำเนินการ':
          var myCases = await GetcaseFunction.fetchMyCasesPorter(username);
          var selectedStatus = statusKey(tabs[selectedTabIndex]);
          fetchedCases = myCases
              .where((c) => c['status'] == selectedStatus)
              .toList();
          break;

        case 'เสร็จสิ้น':
          fetchedCases = await RecordhistoryFunction.fetchCompletedCasesPorter(
            username,
          );
          fetchedCases = fetchedCases.map((c) {
            c['assigned_porter_username'] =
                c['assigned_porter_username'] ?? username;
            return c;
          }).toList();
          break;
      }

      for (var c in fetchedCases) {
        print('🔹 Case Map: $c');
      }
      print('🔹 Total fetched cases: ${fetchedCases.length}');

      setState(() {
        cases = fetchedCases;
      });
    } catch (e) {
      print('❌ Error loading cases: $e');
    }
  }

  void handleCaseAction(Map<String, dynamic> item) async {
    final currentStatus = item['status']?.toString() ?? 'pending';
    final newStatus = currentStatus == 'pending' ? 'in_progress' : 'completed';
    try {
      final success = await UpdateCase.updateStatus(
        item['case_id'].toString(),
        newStatus,
        assignedPorter: username,
      );
      if (success) {
        setState(() {
          item['status'] = newStatus;
        });
      }
    } catch (e) {
      print('❌ Error updating case: $e');
    }
  }

  List<Map<String, dynamic>> get filteredCases {
    final selectedStatus = statusKey(tabs[selectedTabIndex]);
    return cases.where((c) {
      final status = c['status']?.toString() ?? '';
      final assignedPorter = c['assigned_porter_username']?.toString() ?? '';

      if (selectedStatus.isEmpty) {
        return status != '';
      } else if (selectedStatus == 'completed') {
        return status == 'completed' && assignedPorter == username;
      } else {
        return status == selectedStatus &&
            (selectedStatus == 'in_progress'
                ? assignedPorter == username
                : true);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _buildDrawer(context);
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('รายการเคส'),
          automaticallyImplyLeading: false,
        ),
        endDrawer: _buildDrawer(context),
        body: Stack(
          children: [
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
            FadeTransition(
              opacity: _fadeCtrl,
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight + 50),
                child: Column(
                  children: [
                    _buildTabs(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filteredCases.length,
                        itemBuilder: (context, i) {
                          final item = filteredCases[i];
                          return _GlassCard(
                            child: AnimatedCaseCard(
                              item: item,
                              username: username,
                              onAction: handleCaseAction,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedTabIndex = index);
                loadCases();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.deepPurple : Colors.white70,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class AnimatedCaseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String username;
  final void Function(Map<String, dynamic> item)? onAction;

  const AnimatedCaseCard({
    required this.item,
    required this.username,
    this.onAction,
    super.key,
  });

  String timeAgo(String createdAt) {
    final createdTime = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(createdTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${createdTime.day}/${createdTime.month}/${createdTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'pending';
    final isWaiting = status == 'pending';
    final isProcessing = status == 'in_progress';
    final isFinishing = status == 'completed';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 แถวบน: สถานะ + เวลา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isWaiting
                        ? Colors.pink.shade100
                        : isProcessing
                        ? Colors.yellow.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isWaiting
                        ? 'รอดำเนินการ'
                        : isProcessing
                        ? 'กำลังดำเนินการ'
                        : 'เสร็จสิ้น',
                    style: TextStyle(
                      color: isWaiting
                          ? Colors.red
                          : isProcessing
                          ? Colors.orange
                          : Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  item['created_at'] != null
                      ? timeAgo(item['created_at'])
                      : '-',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🔹 รหัสผู้ป่วย
            Text(
              item['patient_id']?.toString() ?? 'ไม่มีรหัส',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),

            // 🔹 ประเภทผู้ป่วย
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'ประเภทผู้ป่วย: ',
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextSpan(
                    text: item['patient_type'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),

            // 🔹 จุดรับ-ส่ง
            Text(
              'จุดรับ-ส่ง: ${item['room_from'] ?? '-'} - ${item['room_to'] ?? '-'}',
              style: const TextStyle(color: Colors.black87),
            ),

            const SizedBox(height: 12),

            // 🔹 ปุ่ม Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PorterCaseDetailScreen(item: item),
                      ),
                    );
                  },
                  child: const Text(
                    'ดูรายละเอียด',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                if (!isFinishing)
                  ElevatedButton(
                    onPressed: () async {
                      if (onAction != null) {
                        onAction!(item);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWaiting ? Colors.blue : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isWaiting ? 'รับเคส' : 'เสร็จสิ้น'),
                  ),
              ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.purple.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
