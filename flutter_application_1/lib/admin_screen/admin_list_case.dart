import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_function.dart';
import '../loginscreen.dart';
import 'admin_edit_case.dart';
import 'admin_settings_screen.dart';

class AdminListCaseScreen extends StatefulWidget {
  const AdminListCaseScreen({super.key});

  @override
  State<AdminListCaseScreen> createState() => _AdminListCaseScreenState();
}

class _AdminListCaseScreenState extends State<AdminListCaseScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> cases = [];
  List<Map<String, dynamic>> filteredCases = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'all';

  // Blue theme colors - สีพื้นเรียบๆ
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF2196F3);
  static const Color bgColor = Color(0xFFF5F7FA);

  bool isSelectionMode = false;
  Set<String> selectedCaseIds = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchCases();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    setState(() {
      selectedFilter = ['all', 'active', 'completed'][_tabController.index];
      _applyFilters();
    });
  }

  Future<void> _fetchCases() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminFunction.fetchAllCasesAdmin();
      setState(() {
        cases = data;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching cases: $e');
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = cases;

    if (selectedFilter == 'active') {
      result = result.where((c) => c['case_status'] != 'completed').toList();
    } else if (selectedFilter == 'completed') {
      result = result.where((c) => c['case_status'] == 'completed').toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result.where((item) {
        final patientId = item['patient_id']?.toString().toLowerCase() ?? '';
        final fname = item['fname_U']?.toString().toLowerCase() ?? '';
        final lname = item['lname_U']?.toString().toLowerCase() ?? '';
        return patientId.contains(searchQuery.toLowerCase()) ||
            fname.contains(searchQuery.toLowerCase()) ||
            lname.contains(searchQuery.toLowerCase());
      }).toList();
    }

    filteredCases = result;
  }

  void _filterCases(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  Future<void> _deleteCase(String caseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 12),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: const Text(
          'คุณต้องการลบเคสนี้ใช่หรือไม่?\nการกระทำนี้ไม่สามารถย้อนกลับได้',
        ),
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
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ลบเคส', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminFunction.deleteCase(caseId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('ลบเคสเรียบร้อยแล้ว'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _fetchCases();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เกิดข้อผิดพลาดในการลบเคส'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedCases() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 8),
            Text('ลบ ${selectedCaseIds.length} รายการ'),
          ],
        ),
        content: const Text('ระบบจะคืนค่าอุปกรณ์และเปลกลับสู่คลังโดยอัตโนมัติ'),
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
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text(
              'ยืนยันลบ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminFunction.deleteSelectedCases(
        selectedCaseIds.toList(),
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ลบรายการที่เลือกเรียบร้อยแล้ว'),
              backgroundColor: Colors.green.shade600,
            ),
          );
          setState(() {
            isSelectionMode = false;
            selectedCaseIds.clear();
          });
        }
        _fetchCases();
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = cases
        .where((c) => c['case_status'] == 'pending')
        .length;
    final inProgressCount = cases
        .where((c) => c['case_status'] == 'in_progress')
        .length;
    final completedCount = cases
        .where((c) => c['case_status'] == 'completed')
        .length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        title: Text(
          isSelectionMode
              ? 'เลือก ${selectedCaseIds.length} รายการ'
              : 'จัดการเคส',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    isSelectionMode = false;
                    selectedCaseIds.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'ออกจากระบบ',
                onPressed: () => _logout(context),
              ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: selectedCaseIds.isEmpty ? null : _deleteSelectedCases,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _fetchCases,
            ),
            IconButton(
              icon: const Icon(Icons.checklist_rounded, color: Colors.white),
              tooltip: 'เลือกหลายรายการ',
              onPressed: () => setState(() => isSelectionMode = true),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              tooltip: 'จัดการข้อมูลพื้นฐาน',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Tab Buttons - สีพื้นเรียบๆ มองเห็นชัด
          if (!isSelectionMode)
            Container(
              color: primaryBlue,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildTabButton(
                    label: 'ทั้งหมด',
                    count: cases.length,
                    isSelected: selectedFilter == 'all',
                    color: Colors.white,
                    onTap: () {
                      _tabController.animateTo(0);
                      setState(() {
                        selectedFilter = 'all';
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'รอ/กำลังส่ง',
                    count: pendingCount + inProgressCount,
                    isSelected: selectedFilter == 'active',
                    color: Colors.orange,
                    onTap: () {
                      _tabController.animateTo(1);
                      setState(() {
                        selectedFilter = 'active';
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    label: 'เสร็จแล้ว',
                    count: completedCount,
                    isSelected: selectedFilter == 'completed',
                    color: Colors.green,
                    onTap: () {
                      _tabController.animateTo(2);
                      setState(() {
                        selectedFilter = 'completed';
                        _applyFilters();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Search Bar - ชัดเจน user friendly
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _filterCases,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'ค้นหาด้วย HN หรือชื่อผู้ขอ...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: primaryBlue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Case List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: primaryBlue,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'กำลังโหลดข้อมูล...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : filteredCases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่พบข้อมูลเคส',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: _fetchCases,
                    child: ListView.builder(
                      itemCount: filteredCases.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final item = filteredCases[index];
                        return _buildCaseCard(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryBlue : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? color : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> item) {
    final caseId = item['case_id'].toString();
    final isSelected = selectedCaseIds.contains(caseId);
    final status = item['case_status'] ?? 'pending';

    // Status colors - ชัดเจน มองเห็นง่าย
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF2E7D32); // เขียวเข้ม
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'ส่งเสร็จแล้ว';
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = const Color(0xFFE65100); // ส้มเข้ม
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'กำลังส่ง';
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = const Color(0xFFF57C00); // ส้ม
        statusBgColor = const Color(0xFFFFF8E1);
        statusText = 'รอรับงาน';
        statusIcon = Icons.hourglass_empty;
    }

    return GestureDetector(
      onLongPress: () {
        setState(() {
          isSelectionMode = true;
          selectedCaseIds.add(caseId);
        });
      },
      onTap: isSelectionMode
          ? () {
              setState(() {
                if (isSelected) {
                  selectedCaseIds.remove(caseId);
                  if (selectedCaseIds.isEmpty) isSelectionMode = false;
                } else {
                  selectedCaseIds.add(caseId);
                }
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  if (isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? primaryBlue : Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ชื่อผู้ขอ - ตัวใหญ่ชัดเจน
                        Text(
                          '${item["fname_U"] ?? "-"} ${item["lname_U"] ?? "-"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // HN Badge - เด่นชัด
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'HN: ${item['patient_id'] ?? '-'}',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSelectionMode)
                    Row(
                      children: [
                        // Edit Button
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: primaryBlue,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminEditCaseScreen(caseData: item),
                              ),
                            );
                            _fetchCases();
                          },
                        ),
                        const SizedBox(width: 8),
                        // Delete Button
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          color: Colors.red.shade400,
                          onTap: () => _deleteCase(caseId),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 12),

              // Info Rows - ชัดเจน อ่านง่าย
              _buildInfoRow(
                Icons.local_hospital_rounded,
                'ประเภท',
                item['patient_type'],
              ),
              _buildInfoRow(
                Icons.airline_seat_flat_rounded,
                'ประเภทเปล',
                item['str_type_name'],
              ),
              _buildInfoRow(
                Icons.arrow_forward_rounded,
                'รับจาก',
                item['case_room_from'],
                isLocation: true,
              ),
              _buildInfoRow(
                Icons.pin_drop_rounded,
                'ส่งที่',
                item['case_room_to'],
                isLocation: true,
              ),

              const SizedBox(height: 12),

              // Status Badge - ใหญ่ ชัดเจน
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      'สถานะ: $statusText',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String? value, {
    bool isLocation = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isLocation ? 13 : 14,
                color: const Color(0xFF1A1A2E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
