// ignore_for_file: library_private_types_in_public_api, sized_box_for_whitespace, avoid_print, deprecated_member_use
import 'dart:io';
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
  // Tabs: Vacant, In Progress, Completed
  List<String> get tabs => [
    'เคสที่ว่าง',
    'เคสที่กำลังดำเนินการ',
    'เคสที่เสร็จสิ้น',
  ];

  int selectedTabIndex = 0;
  String fname = '', lname = '', username = '', email = '', phone = '';
  File? _selectedImage;
  String? profileImageUrl;
  List<Map<String, dynamic>> cases = [];

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

  String statusKey(String tabLabel) {
    switch (tabLabel) {
      case 'เคสที่ว่าง':
        return 'pending';
      case 'เคสที่กำลังดำเนินการ':
        return 'in_progress';
      case 'เคสที่เสร็จสิ้น':
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
    try {
      List<Map<String, dynamic>> fetchedCases = [];

      if (selectedTabIndex == 2) {
        // เสร็จสิ้น
        fetchedCases = await RecordhistoryFunction.fetchCompletedCasesPorter(
          username,
        );
        fetchedCases = fetchedCases
            .where((c) {
              // ใช้ case_completed_at ถ้ามี ถ้าไม่มีใช้ created_at
              String dateStr = c['case_completed_at'] ?? c['created_at'] ?? '';
              if (dateStr.isEmpty) return false;
              try {
                final date = DateTime.parse(dateStr).toLocal();
                final now = DateTime.now();
                return date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
              } catch (e) {
                return false;
              }
            })
            .map((c) {
              c['assigned_porter_username'] =
                  c['assigned_porter_username'] ?? username;
              return c;
            })
            .toList();
      } else {
        // Vacant or In Progress
        var myCases = await GetcaseFunction.fetchMyCasesPorter(username);
        var selectedStatus = statusKey(tabs[selectedTabIndex]);
        fetchedCases = myCases
            .where((c) => c['status'] == selectedStatus)
            .toList();
      }

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
        if (newStatus == 'in_progress') {
          // Auto-switch to In Progress tab
          final inProgressIndex = tabs.indexOf('เคสที่กำลังดำเนินการ');
          if (inProgressIndex != -1) {
            setState(() {
              selectedTabIndex = inProgressIndex;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('รับเคสเรียบร้อย! กำลังดำเนินการ...'),
              ),
            );
          }
        } else if (newStatus == 'completed') {
          // Switch to Completed tab
          setState(() {
            selectedTabIndex = 2; // Index of Completed
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เคสเสร็จสิ้นเรียบร้อย!')),
          );
        }
        loadCases(); // Reload to reflect changes
      }
    } catch (e) {
      print('❌ Error updating case: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var drawer = _buildDrawer(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'รายการเคส',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: loadCases,
            ),
          ],
        ),
        drawer: drawer,
        body: Column(
          children: [
            _buildTabs(),
            Expanded(
              child: cases.isEmpty
                  ? const Center(
                      child: Text(
                        'ไม่มีรายการเคสในขณะนี้',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cases.length,
                      itemBuilder: (context, i) {
                        return PorterCaseCard(
                          item: cases[i],
                          username: username,
                          onAction: handleCaseAction,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PorterCaseDetailScreen(item: cases[i]),
                              ),
                            ).then((_) => loadCases());
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedTabIndex = index);
                loadCases();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.deepPurple : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    else
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppTheme.deepPurple),
            accountName: Text(
              '$fname $lname',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!) as ImageProvider
                  : (profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null),
              child: (_selectedImage == null && profileImageUrl == null)
                  ? Icon(Icons.person, size: 40, color: AppTheme.deepPurple)
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('แก้ไขข้อมูลส่วนตัว'),
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
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
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

class PorterCaseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String username;
  final Function(Map<String, dynamic>) onAction;
  final VoidCallback onTap;

  const PorterCaseCard({
    super.key,
    required this.item,
    required this.username,
    required this.onAction,
    required this.onTap,
  });

  String timeAgo(String createdAt) {
    try {
      final createdTime = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(createdTime);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'pending';
    bool isPending = status == 'pending';
    bool isInProgress = status == 'in_progress'; // Used for color logic
    bool isCompleted = status == 'completed';

    Color statusColor = isPending
        ? Colors.pink.shade100
        : (isInProgress ? Colors.yellow.shade100 : Colors.green.shade100);
    Color statusTextColor = isPending
        ? Colors.pink.shade700
        : (isInProgress ? Colors.orange.shade800 : Colors.green.shade800);
    String statusText = isPending
        ? 'รอดำเนินการ'
        : (isInProgress ? 'กำลังดำเนินการ' : 'เสร็จสิ้น');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCompleted
            ? Border.all(color: Colors.green.shade200, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo(item['created_at'] ?? ''),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'HN${item['patient_id'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'ประเภทผู้ป่วย: ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: '${item['patient_type'] ?? '-'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'จุดรับ-ส่ง: ${item['room_from'] ?? '-'} (รับ) - ${item['room_to'] ?? '-'} (ส่ง)',
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onTap,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: Text(
                          'ดูรายละเอียด',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (!isCompleted)
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => onAction(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPending
                                ? Colors.blue
                                : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            isPending ? 'รับเคส' : 'เสร็จสิ้น',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
