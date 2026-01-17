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
  // Tabs: Vacant, Completed (In Progress ใช้ popup แทน)
  List<String> get tabs => ['เคสที่ว่าง', 'เคสที่เสร็จสิ้น'];

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

  bool _isPopupShowing = false;

  void loadCases() async {
    if (username.isEmpty) return;
    try {
      List<Map<String, dynamic>> fetchedCases = [];

      if (selectedTabIndex == 1) {
        // เสร็จสิ้น
        fetchedCases = await RecordhistoryFunction.fetchCompletedCasesPorter(
          username,
        );
        fetchedCases = fetchedCases.map((c) {
          c['assigned_porter_username'] =
              c['assigned_porter_username'] ?? username;
          c['status'] = 'completed';
          return c;
        }).toList();
      } else {
        // Vacant or In Progress
        var myCases = await GetcaseFunction.fetchMyCasesPorter(username);

        // Check for active case (in_progress)
        final activeCase = myCases.firstWhere(
          (c) => c['status'] == 'in_progress',
          orElse: () => {},
        );

        // If there is an active case and popup is not showing, show it!
        if (activeCase.isNotEmpty && !_isPopupShowing) {
          // Use WidgetsBinding to ensure build is done before showing dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showInProgressPopup(activeCase);
            }
          });
        }

        var selectedStatus = statusKey(tabs[selectedTabIndex]);
        fetchedCases = myCases
            .where((c) => c['status'] == selectedStatus)
            .toList();
      }

      setState(() {
        // Sort ER cases first
        fetchedCases.sort((a, b) {
          final aType = (a['patient_type'] ?? '').toString().toUpperCase();
          final bType = (b['patient_type'] ?? '').toString().toUpperCase();
          final aIsER = aType.startsWith('ER');
          final bIsER = bType.startsWith('ER');
          if (aIsER && !bIsER) return -1;
          if (!aIsER && bIsER) return 1;
          return 0;
        });
        cases = fetchedCases;
      });
    } catch (e) {
      print('❌ Error loading cases: $e');
    }
  }

  // Helper function to format patient ID - keep the prefix for display
  String _formatPatientId(String? patientId) {
    if (patientId == null || patientId.isEmpty) return '-';
    return patientId;
  }

  void handleCaseAction(Map<String, dynamic> item) async {
    final currentStatus = item['status']?.toString() ?? 'pending';

    if (currentStatus == 'pending') {
      try {
        final success = await UpdateCase.updateStatus(
          item['case_id'].toString(),
          'in_progress',
          assignedPorter: username,
        );
        if (success) {
          item['status'] = 'in_progress';
          // User accepted case, refresh to trigger auto-popup
          loadCases();
        }
      } catch (e) {
        print('❌ Error updating case: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการรับเคส')),
        );
      }
    } else if (currentStatus == 'in_progress') {
      if (!_isPopupShowing) {
        _showInProgressPopup(item);
      }
    }
  }

  void _showInProgressPopup(Map<String, dynamic> item) {
    if (_isPopupShowing) return; // Prevent double popup
    _isPopupShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false, // ไม่สามารถปิด popup โดยแตะข้างนอก
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // ป้องกันการกดปุ่ม back
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'กำลังดำเนินการ',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Patient ID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'HN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatPatientId(item['patient_id']?.toString()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: Colors.black87,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Patient Type
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ประเภท: ${item['patient_type'] ?? '-'}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Room From
                    _buildLocationCard(
                      icon: Icons.location_on,
                      color: Colors.green,
                      label: 'จุดรับ',
                      value: item['room_from'] ?? '-',
                    ),
                    const SizedBox(height: 12),

                    // Arrow
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
                    const SizedBox(height: 12),

                    // Room To
                    _buildLocationCard(
                      icon: Icons.flag,
                      color: Colors.red,
                      label: 'จุดส่ง',
                      value: item['room_to'] ?? '-',
                    ),
                    const SizedBox(height: 24),

                    // Stretcher Type
                    if (item['stretcher_type'] != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.airline_seat_flat,
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'เปล: ${item['stretcher_type']}',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),

                    // Slide to Complete Bar
                    _SlideToCompleteWidget(
                      onComplete: () async {
                        Navigator.of(dialogContext).pop();
                        await _completeCase(item);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _cancelCase(item);
                        },
                        icon: Icon(
                          Icons.cancel_outlined,
                          color: Colors.red.shade600,
                        ),
                        label: Text(
                          'ยกเลิกเคส',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.red.shade300,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isPopupShowing = false;
    });
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeCase(Map<String, dynamic> item) async {
    try {
      final success = await UpdateCase.updateStatus(
        item['case_id'].toString(),
        'completed',
        assignedPorter: username,
      );
      if (success) {
        setState(() {
          selectedTabIndex = 1; // ไปที่ tab เสร็จสิ้น (index 1)
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 เคสเสร็จสิ้นเรียบร้อย!'),
            backgroundColor: Colors.green,
          ),
        );
        loadCases();
      }
    } catch (e) {
      print('❌ Error completing case: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ')),
      );
    }
  }

  Future<void> _cancelCase(Map<String, dynamic> item) async {
    try {
      final success = await UpdateCase.updateStatus(
        item['case_id'].toString(),
        'pending',
        assignedPorter: null, // ลบ porter ที่รับเคสออก
      );
      if (success) {
        setState(() {
          selectedTabIndex = 0; // กลับไปที่ tab เคสที่ว่าง
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ยกเลิกเคสเรียบร้อย เคสถูกส่งกลับไปรอดำเนินการ',
            ),
            backgroundColor: Colors.orange.shade600,
          ),
        );
        loadCases();
      }
    } catch (e) {
      print('❌ Error canceling case: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการยกเลิกเคส')),
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
                    // Profile Image - Clickable
                    GestureDetector(
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
                                  : (profileImageUrl != null &&
                                            profileImageUrl!.isNotEmpty
                                        ? NetworkImage(profileImageUrl!)
                                        : const AssetImage(
                                            'assets/default_porter_avatar.png',
                                          )),
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
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'พนักงานเปล',
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

class PorterCaseCard extends StatefulWidget {
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

  @override
  State<PorterCaseCard> createState() => _PorterCaseCardState();
}

class _PorterCaseCardState extends State<PorterCaseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Start pulsing for ER cases
    final patientType = (widget.item['patient_type'] ?? '')
        .toString()
        .toUpperCase();
    if (patientType.startsWith('ER')) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

  // Helper to extract prefix from patient ID
  String getPatientIdPrefix(String? patientId) {
    if (patientId == null || patientId.isEmpty) return 'HN';
    final upper = patientId.toUpperCase();
    if (upper.startsWith('AN')) return 'AN';
    if (upper.startsWith('XN')) return 'XN';
    if (upper.startsWith('DN')) return 'DN';
    if (upper.startsWith('HN')) return 'HN';
    return 'HN';
  }

  // Helper to get patient ID number without prefix
  String getPatientIdNumber(String? patientId) {
    if (patientId == null || patientId.isEmpty) return '-';
    final upper = patientId.toUpperCase();
    for (final prefix in ['HN', 'AN', 'XN', 'DN']) {
      if (upper.startsWith(prefix)) {
        return patientId.substring(prefix.length);
      }
    }
    return patientId;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final status = item['status']?.toString() ?? 'pending';
    bool isPending = status == 'pending';
    bool isCompleted = status == 'completed';

    // Check if this is an ER (Emergency) case
    final patientType = (item['patient_type'] ?? '').toString().toUpperCase();
    bool isER = patientType.startsWith('ER');

    // Color scheme based on status and ER
    Color cardBorderColor;
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;
    String statusText;

    if (isER && isPending) {
      // Emergency ER styling
      cardBorderColor = Colors.red.shade400;
      statusBgColor = Colors.red.shade100;
      statusTextColor = Colors.red.shade700;
      statusIcon = Icons.emergency;
      statusText = '🚨 ฉุกเฉิน!';
    } else if (isPending) {
      cardBorderColor = Colors.blue.shade200;
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue.shade700;
      statusIcon = Icons.pending_actions;
      statusText = 'รอดำเนินการ';
    } else if (isCompleted) {
      cardBorderColor = Colors.green.shade300;
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
      statusText = 'เสร็จสิ้น';
    } else {
      cardBorderColor = Colors.orange.shade200;
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange.shade700;
      statusIcon = Icons.sync;
      statusText = 'กำลังดำเนินการ';
    }
    // Use AnimatedBuilder for ER pulsing effect (or no-op for non-ER)
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final double pulseValue = (isER && isPending)
            ? _pulseAnimation.value
            : 1.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: (isER && isPending) ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardBorderColor,
              width: (isER && isPending) ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isER && isPending)
                    ? Colors.red.withOpacity(0.35 * pulseValue)
                    : cardBorderColor.withOpacity(0.2),
                blurRadius: (isER && isPending) ? 18 * pulseValue : 12,
                spreadRadius: (isER && isPending) ? 2 * pulseValue : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row - Status & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: statusTextColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusTextColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo(item['created_at'] ?? ''),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Patient ID - Large
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isER
                            ? Colors.red.shade600
                            : Colors.indigo.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        getPatientIdPrefix(item['patient_id']?.toString()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        getPatientIdNumber(item['patient_id']?.toString()),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          color: isER
                              ? Colors.red.shade800
                              : Colors.indigo.shade800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Patient Type Badge - Special styling for ER
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isER
                          ? [Colors.red.shade200, Colors.red.shade100]
                          : [Colors.purple.shade100, Colors.purple.shade50],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: isER
                        ? Border.all(color: Colors.red.shade300, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isER
                            ? Icons.warning_amber_rounded
                            : Icons.person_outline,
                        size: isER ? 18 : 16,
                        color: isER
                            ? Colors.red.shade700
                            : Colors.purple.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isER
                            ? '🚨 ${item['patient_type'] ?? 'ER'} - ฉุกเฉิน!'
                            : 'ประเภท: ${item['patient_type'] ?? '-'}',
                        style: TextStyle(
                          color: isER
                              ? Colors.red.shade800
                              : Colors.purple.shade700,
                          fontWeight: isER ? FontWeight.bold : FontWeight.w600,
                          fontSize: isER ? 14 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Location Cards
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // From Location
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
                              size: 16,
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
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['room_from'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 13),
                            Container(
                              width: 2,
                              height: 20,
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
                      // To Location
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
                              size: 16,
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
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['room_to'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
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

                const SizedBox(height: 16),

                // Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onTap,
                      icon: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.blue.shade600,
                      ),
                      label: Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    if (!isCompleted)
                      ElevatedButton.icon(
                        onPressed: () => widget.onAction(item),
                        icon: Icon(
                          isPending ? Icons.play_arrow : Icons.check,
                          size: 20,
                        ),
                        label: Text(
                          isPending ? 'รับเคส' : 'เสร็จสิ้น',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPending
                              ? Colors.blue.shade600
                              : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
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

// Slide to Complete Widget
class _SlideToCompleteWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const _SlideToCompleteWidget({required this.onComplete});

  @override
  State<_SlideToCompleteWidget> createState() => _SlideToCompleteWidgetState();
}

class _SlideToCompleteWidgetState extends State<_SlideToCompleteWidget>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  double _maxDrag = 0;
  bool _isCompleting = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isCompleting) return;
    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) _dragPosition = 0;
      if (_dragPosition > _maxDrag) _dragPosition = _maxDrag;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isCompleting) return;
    if (_dragPosition >= _maxDrag * 0.85) {
      // Slide completed
      setState(() {
        _isCompleting = true;
        _dragPosition = _maxDrag;
      });
      widget.onComplete();
    } else {
      // Reset position
      _animationController.reset();
      _animationController.forward();
      final startPosition = _dragPosition;
      _animationController.addListener(() {
        setState(() {
          _dragPosition = startPosition * (1 - _animationController.value);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final thumbSize = 60.0;
        _maxDrag = sliderWidth - thumbSize - 8;

        final progress = _maxDrag > 0 ? (_dragPosition / _maxDrag) : 0.0;

        return Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background progress
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: _dragPosition + thumbSize + 4,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: Colors.green.shade700.withOpacity(0.3),
                ),
              ),
              // Center text
              Center(
                child: AnimatedOpacity(
                  opacity: 1 - progress,
                  duration: const Duration(milliseconds: 100),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 50),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'เลื่อนเพื่อเสร็จสิ้น',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Draggable thumb
              Positioned(
                left: _dragPosition + 4,
                top: 5,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: _isCompleting
                          ? Colors.green.shade800
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleting ? Icons.check : Icons.chevron_right_rounded,
                      color: _isCompleting
                          ? Colors.white
                          : Colors.green.shade600,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
