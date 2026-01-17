import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../design/theme.dart';
import '../services/admin_function.dart';
import '../registerscreen.dart';
import 'admin_list_case.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminListCaseScreen(),
    const AdminPortersScreen(),
    const AdminNursesScreen(), // Added Nurses Screen
    const AdminDashboardScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              activeIcon: Icon(Icons.list_alt_rounded),
              label: 'เคส',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'พนักงานเปล',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'พยาบาล',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'ภาพรวม',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.deepPurple,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// Porter List Screen
class AdminPortersScreen extends StatefulWidget {
  const AdminPortersScreen({super.key});

  @override
  State<AdminPortersScreen> createState() => _AdminPortersScreenState();
}

class _AdminPortersScreenState extends State<AdminPortersScreen> {
  static final baseUrl = dotenv.env['BASE_URL'] ?? '';
  List<Map<String, dynamic>> porters = [];
  bool isLoading = true;

  // Solid blue colors - สีพื้นเรียบๆ
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _fetchPorters();
  }

  Future<void> _fetchPorters() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminFunction.fetchPorters();
      setState(() {
        porters = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching porters: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPorters = porters.length;
    final activePorters = porters
        .where((p) => (p['active_cases'] ?? 0) > 0)
        .length;
    final availablePorters = totalPorters - activePorters;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.badge_rounded, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'พนักงานเปล',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            tooltip: 'เพิ่มพนักงานใหม่',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
              _fetchPorters();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: primaryBlue,
              onRefresh: _fetchPorters,
              child: Column(
                children: [
                  // Stats Header - สีฟ้าพื้น ชัดเจน
                  Container(
                    color: primaryBlue,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ทั้งหมด
                          Expanded(
                            child: _buildStatColumn(
                              icon: Icons.groups_rounded,
                              iconColor: primaryBlue,
                              iconBgColor: const Color(0xFFE3F2FD),
                              value: totalPorters.toString(),
                              label: 'ทั้งหมด',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey.shade200,
                          ),
                          // ว่าง
                          Expanded(
                            child: _buildStatColumn(
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF2E7D32),
                              iconBgColor: const Color(0xFFE8F5E9),
                              value: availablePorters.toString(),
                              label: 'ว่าง',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey.shade200,
                          ),
                          // กำลังทำงาน
                          Expanded(
                            child: _buildStatColumn(
                              icon: Icons.directions_run_rounded,
                              iconColor: const Color(0xFFE65100),
                              iconBgColor: const Color(0xFFFFF3E0),
                              value: activePorters.toString(),
                              label: 'กำลังทำงาน',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'รายชื่อพนักงาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${porters.length} คน',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Porter List
                  Expanded(
                    child: porters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'ไม่พบข้อมูลพนักงานเปล',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: porters.length,
                            itemBuilder: (context, index) {
                              return _buildPorterCard(porters[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPorterCard(Map<String, dynamic> porter) {
    final completedCases = porter['completed_cases'] ?? 0;
    final activeCases = porter['active_cases'] ?? 0;
    final isActive = activeCases > 0;
    final profileImagePath = porter['user_profile_image'];

    String? fullImageUrl;
    if (profileImagePath != null && profileImagePath.toString().isNotEmpty) {
      fullImageUrl = '$baseUrl$profileImagePath';
    }

    // Status styling
    final Color statusColor = isActive
        ? const Color(0xFFE65100)
        : const Color(0xFF2E7D32);
    final Color statusBgColor = isActive
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE8F5E9);
    final String statusText = isActive ? 'กำลังทำงาน' : 'ว่าง พร้อมรับงาน';
    final IconData statusIcon = isActive
        ? Icons.directions_run
        : Icons.check_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.orange.shade200 : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Image
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? Colors.orange : primaryBlue,
                      width: 3,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: fullImageUrl != null
                          ? NetworkImage(fullImageUrl)
                          : const AssetImage('assets/default_porter_avatar.png')
                                as ImageProvider,
                    ),
                  ),
                ),
                // Status dot
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      isActive ? Icons.directions_run : Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อ - ตัวใหญ่ชัดเจน
                  Text(
                    '${porter['user_fname'] ?? ''} ${porter['user_lname'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Status Badge - ชัดเจน
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Phone
                  if (porter['user_phone'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          porter['user_phone'] ?? '-',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Stats Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Completed cases badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$completedCases',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เสร็จแล้ว',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                if (activeCases > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 12,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$activeCases งาน',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Delete Button
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showDeleteUserDialog(porter),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                size: 22,
              ),
              tooltip: 'ไล่ออก',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog ลบ User พร้อมระบุเหตุผล
  void _showDeleteUserDialog(Map<String, dynamic> user) {
    final userName = '${user['user_fname'] ?? ''} ${user['user_lname'] ?? ''}';
    final userId = user['user_num']?.toString() ?? '';

    // State สำหรับ dialog
    final List<String> selectedReasons = [];
    final TextEditingController noteController = TextEditingController();

    // เหตุผลที่สามารถเลือกได้
    final List<Map<String, dynamic>> reasonOptions = [
      {'id': 'resign', 'label': 'ลาออก', 'icon': Icons.exit_to_app},
      {'id': 'terminate', 'label': 'เลิกจ้าง', 'icon': Icons.cancel_outlined},
      {'id': 'transfer', 'label': 'ย้ายแผนก', 'icon': Icons.swap_horiz},
      {'id': 'retire', 'label': 'เกษียณอายุ', 'icon': Icons.elderly},
      {
        'id': 'discipline',
        'label': 'ปัญหาวินัย',
        'icon': Icons.warning_amber_rounded,
      },
      {'id': 'other', 'label': 'อื่นๆ', 'icon': Icons.more_horiz},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_remove,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ไล่ออกพนักงาน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อพนักงาน
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF1976D2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // หัวข้อเลือกเหตุผล
                Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      color: Colors.grey.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'เลือกเหตุผล *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Checkbox list
                ...reasonOptions.map(
                  (reason) => InkWell(
                    onTap: () {
                      setDialogState(() {
                        if (selectedReasons.contains(reason['id'])) {
                          selectedReasons.remove(reason['id']);
                        } else {
                          selectedReasons.add(reason['id']);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selectedReasons.contains(reason['id']),
                            onChanged: (v) {
                              setDialogState(() {
                                if (v == true) {
                                  selectedReasons.add(reason['id']);
                                } else {
                                  selectedReasons.remove(reason['id']);
                                }
                              });
                            },
                            activeColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Icon(
                            reason['icon'] as IconData,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            reason['label'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // หมายเหตุ
                Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      color: Colors.grey.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'หมายเหตุเพิ่มเติม',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'ระบุรายละเอียดเพิ่มเติม...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Warning
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'การดำเนินการนี้ไม่สามารถยกเลิกได้',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: selectedReasons.isEmpty
                  ? null
                  : () async {
                      // สร้าง reason string
                      final reasonLabels = reasonOptions
                          .where((r) => selectedReasons.contains(r['id']))
                          .map((r) => r['label'])
                          .join(', ');
                      final fullReason = noteController.text.isNotEmpty
                          ? '$reasonLabels: ${noteController.text}'
                          : reasonLabels;

                      Navigator.pop(context);

                      // เรียก API ลบ
                      final success = await AdminFunction.deleteUser(
                        userId,
                        fullReason,
                      );

                      if (success) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text('ลบ $userName เรียบร้อยแล้ว'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        _fetchPorters();
                      } else {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'ไม่สามารถลบได้ (อาจมีเคสที่เชื่อมโยง)',
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('ยืนยันไล่ออก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Admin Nurses Screen
class AdminNursesScreen extends StatefulWidget {
  const AdminNursesScreen({super.key});

  @override
  State<AdminNursesScreen> createState() => _AdminNursesScreenState();
}

class _AdminNursesScreenState extends State<AdminNursesScreen> {
  static final baseUrl = dotenv.env['BASE_URL'] ?? '';
  List<Map<String, dynamic>> nurses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNurses();
  }

  Future<void> _fetchNurses() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminFunction.fetchNurses();
      setState(() {
        nurses = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching nurses: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmDelete(String userId, String name) async {
    final reasons = ['ลาออก', 'ถูกไล่ออก', 'ย้ายแผนก', 'อื่นๆ'];
    String? selectedReason;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('ลบรายชื่อ: $name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'กรุณาระบุเหตุผลที่ลบรายชื่อ:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...reasons.map(
                    (r) => RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selectedReason,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() => selectedReason = val);
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.pop(context); // Close dialog
                          _executeDelete(userId, selectedReason!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withOpacity(0.3),
                  ),
                  child: const Text(
                    'ลบรายชื่อ',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeDelete(String userId, String reason) async {
    // Show loading or overlay
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('กำลังลบข้อมูล...')));

    final success = await AdminFunction.deleteUser(userId, reason);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลเรียบร้อยแล้ว')));
      _fetchNurses(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบข้อมูล')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.medical_services, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'พยาบาล',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade400, Colors.pink.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            tooltip: 'เพิ่มพยาบาลใหม่',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
              _fetchNurses();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchNurses,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : nurses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่พบข้อมูลพยาบาล',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: nurses.length,
              itemBuilder: (context, index) {
                final nurse = nurses[index];
                final createdCases = nurse['created_cases'] ?? 0;
                final profileImagePath = nurse['user_profile_image'];

                String? fullImageUrl;
                if (profileImagePath != null &&
                    profileImagePath.toString().isNotEmpty) {
                  fullImageUrl = '$baseUrl$profileImagePath';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Profile Image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.pink.shade100,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.pink.shade50,
                            backgroundImage: fullImageUrl != null
                                ? NetworkImage(fullImageUrl)
                                : const AssetImage(
                                        'assets/default_nurse_avatar.png',
                                      )
                                      as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${nurse['user_fname'] ?? ''} ${nurse['user_lname'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Phone
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    nurse['user_phone'] ?? '-',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Stats
                              Text(
                                'สร้างเคสแล้ว: $createdCases',
                                style: TextStyle(
                                  color: Colors.pink.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Delete Button
                        IconButton(
                          onPressed: () => _confirmDelete(
                            nurse['user_num'].toString(),
                            '${nurse['user_fname']} ${nurse['user_lname']}',
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                          color: Colors.red,
                          tooltip: 'ลบรายชื่อ',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminFunction.fetchDashboardStats();
      setState(() {
        stats = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ภาพรวมระบบ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.deepPurple,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
          ? const Center(child: Text('ไม่สามารถโหลดข้อมูลได้'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cases Summary Section
                  _buildSectionTitleWithIcon(Icons.analytics, 'สรุปเคส'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(
                        'รอดำเนินการ',
                        '${stats!['cases']['pending'] ?? 0}',
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'กำลังดำเนินการ',
                        '${stats!['cases']['in_progress'] ?? 0}',
                        Icons.local_shipping,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'เสร็จสิ้นวันนี้',
                        '${stats!['cases']['completed_today'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'เสร็จสิ้นทั้งหมด',
                        '${stats!['cases']['completed_total'] ?? 0}',
                        Icons.done_all,
                        Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ER Alert Section
                  if ((stats!['cases']['er_pending'] ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade100, Colors.red.shade50],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.emergency,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'เคสฉุกเฉินรอดำเนินการ!',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${stats!['cases']['er_pending']} เคส',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Staff Summary Section
                  _buildSectionTitleWithIcon(Icons.groups, 'บุคลากร'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'พนักงานเปล',
                          '${stats!['staff']['porters'] ?? 0}',
                          Icons.person,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'พยาบาล',
                          '${stats!['staff']['nurses'] ?? 0}',
                          Icons.medical_services,
                          Colors.pink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Top Porters Section
                  _buildSectionTitleWithIcon(
                    Icons.check_circle_rounded,
                    'พนักงานเปลยอดเยี่ยม',
                  ),
                  const SizedBox(height: 12),
                  ...((stats!['topPorters'] as List?) ?? []).asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final porter = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.amber.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: index == 0
                              ? Colors.amber.shade300
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.amber
                                  : (index == 1
                                        ? Colors.grey.shade400
                                        : (index == 2
                                              ? Colors.brown.shade300
                                              : Colors.grey.shade200)),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index < 3 ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${porter['user_fname'] ?? ''} ${porter['user_lname'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${porter['case_count'] ?? 0} เคส',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitleWithIcon(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.deepPurple, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
