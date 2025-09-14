// ignore_for_file: library_private_types_in_public_api, sized_box_for_whitespace, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../editprofilescreen.dart';
import '../loginscreen.dart';
import '../services/getcase_function.dart';
import '../services/recordhistory_function.dart';
import '../services/ีupdatecase_function.dart';
import 'porter_case_detail.dart';

class PorterCaseListScreen extends StatefulWidget {
  const PorterCaseListScreen({super.key});

  @override
  _PorterCaseListScreenState createState() => _PorterCaseListScreenState();
}

class _PorterCaseListScreenState extends State<PorterCaseListScreen> {
  int selectedTabIndex = 0;
  String fname = '';
  String lname = '';
  String username = '';
  String email = '';
  String phone = '';

  File? _selectedImage;
  String? profileImageUrl;

  List<Map<String, dynamic>> cases = [];

  final List<String> tabs = [
    'ทั้งหมด',
    'รอดำเนินการ',
    'กำลังดำเนินการ',
    'เสร็จสิ้น',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
          fetchedCases = myCases
              .where((c) => c['status'] == tabs[selectedTabIndex])
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

      // 🔹 Debug: print Map ของแต่ละเคส
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
        // ✅ อัปเดต status ของ item ใน memory เลย ไม่ต้องโหลดใหม่ทั้งหมด
        setState(() {
          item['status'] = newStatus;
        });
      }
    } catch (e) {
      print('❌ Error updating case: $e');
    }
  }

  List<Map<String, dynamic>> get filteredCases {
    final selectedStatus = tabs[selectedTabIndex];

    return cases.where((c) {
      final status = c['status']?.toString() ?? '';
      final assignedPorter = c['assigned_porter_username']?.toString() ?? '';

      if (selectedStatus == 'ทั้งหมด') {
        return status != ''; // เอาทุกเคส
      } else if (selectedStatus == 'เสร็จสิ้น') {
        return status == 'completed' && assignedPorter == username;
      } else {
        return status == selectedStatus &&
            (selectedStatus == 'กำลังดำเนินการ'
                ? assignedPorter == username
                : true);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการเคส'),
        automaticallyImplyLeading: false,
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Avatar วงกลม
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null),
                    child: (_selectedImage == null && profileImageUrl == null)
                        ? Icon(Icons.person, size: 60)
                        : null,
                  ),

                  SizedBox(height: 20),

                  // ชื่อผู้ใช้
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('ชื่อผู้ใช้: $fname $lname'),
                  ),

                  // อีเมล
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text('อีเมล: $email'),
                  ),

                  // เบอร์โทร
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text('เบอร์โทร: $phone'),
                  ),

                  // ปุ่มแก้ไข
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('แก้ไขข้อมูล'),
                    onTap: () async {
                      Navigator.pop(context); // ปิด Drawer ก่อน
                      final updatedProfile = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            fname: fname,
                            lname: lname,
                            email: email,
                            phone: phone,
                            ImageUrl: profileImageUrl,
                          ),
                        ),
                      );

                      if (updatedProfile != null) {
                        setState(() {
                          fname = updatedProfile['fname_U'] ?? fname;
                          lname = updatedProfile['lname_U'] ?? lname;
                          email = updatedProfile['email_U'] ?? email;
                          phone = updatedProfile['phone_U'] ?? phone;
                          profileImageUrl =
                              updatedProfile['profile_image'] ??
                              profileImageUrl; // เพิ่มตรงนี้
                        });
                      }
                    },
                  ),

                  // ปุ่มออกจากระบบ
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('ออกจากระบบ'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedTabIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = index;
                      });
                      loadCases(); // โหลดเคสใหม่ตาม tab
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        index == 0 ? 'ทั้งหมด' : tabs[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final item = filteredCases[index];
                return AnimatedCaseCard(
                  item: item,
                  username: username,
                  onAction: handleCaseAction, // ใช้ฟังก์ชันเดียว
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedCaseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String username;
  final void Function(Map<String, dynamic> item)?
  onAction; // callback เวลากดปุ่ม

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
    // ✅ อ่านค่า status ตรงจาก item ทุกครั้ง ไม่เก็บค้างใน state
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
              offset: Offset(0, 3),
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

            // 🔹 ปุ่ม Action (ตามสถานะ)
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
                  child: Text(
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
