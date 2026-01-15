import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/theme.dart';
import '../services/getcase_function.dart';
import '../services/admin_function.dart';
import '../loginscreen.dart';
import 'admin_edit_case.dart';

class AdminListCaseScreen extends StatefulWidget {
  const AdminListCaseScreen({super.key});

  @override
  State<AdminListCaseScreen> createState() => _AdminListCaseScreenState();
}

class _AdminListCaseScreenState extends State<AdminListCaseScreen> {
  List<Map<String, dynamic>> cases = [];
  List<Map<String, dynamic>> filteredCases = [];
  bool isLoading = true;
  String searchQuery = '';

  // Selection Mode State
  bool isSelectionMode = false;
  Set<String> selectedCaseIds = {};

  @override
  void initState() {
    super.initState();
    _fetchCases();
    // Refresh every 10 seconds? Maybe not needed for admin unless specified
  }

  Future<void> _fetchCases() async {
    setState(() => isLoading = true);
    try {
      // Reuse nurse fetch all as it likely gets all active cases
      final data = await GetcaseFunction.fetchAllCasesNurse();
      setState(() {
        cases = data;
        filteredCases = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching cases: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterCases(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredCases = cases;
      } else {
        filteredCases = cases.where((item) {
          final patientId = item['patient_id']?.toString().toLowerCase() ?? '';
          final fname = item['fname_U']?.toString().toLowerCase() ?? '';
          return patientId.contains(query.toLowerCase()) ||
              fname.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteCase(String caseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text(
          'คุณต้องการลบเคสนี้ใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบเคส'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminFunction.deleteCase(caseId);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบเคสเรียบร้อยแล้ว')));
        _fetchCases();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบเคส')),
        );
      }
    }
  }

  Future<void> _deleteSelectedCases() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '⚠️ ยืนยันการลบ ${selectedCaseIds.length} รายการ',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'คุณต้องการลบเคสที่เลือกใช่หรือไม่?\n\n'
          'ระบบจะคืนค่าอุปกรณ์และเปลกลับสู่คลังให้โดยอัตโนมัติ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            const SnackBar(content: Text('ลบรายการที่เลือกเรียบร้อยแล้ว')),
          );
          setState(() {
            isSelectionMode = false;
            selectedCaseIds.clear();
          });
        }
        _fetchCases();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบรายการ')),
          );
        }
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
    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
            ? Text(
                'เลือก ${selectedCaseIds.length} รายการ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : const Text(
                'จัดการเคส (Admin)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        centerTitle: true,
        backgroundColor: isSelectionMode
            ? Colors.grey[800]
            : AppTheme.deepPurple,
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
            : null,
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: selectedCaseIds.isEmpty ? null : _deleteSelectedCases,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchCases,
            ),
            IconButton(
              icon: const Icon(Icons.checklist, color: Colors.white),
              tooltip: 'เลือกหลายรายการ',
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _logout(context),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterCases,
              decoration: InputDecoration(
                hintText: 'ค้นหาด้วย HN หรือชื่อ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCases.isEmpty
                ? const Center(child: Text('ไม่พบข้อมูลเคส'))
                : ListView.builder(
                    itemCount: filteredCases.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredCases[index];
                      final caseId = item['case_id'].toString();
                      final isSelected = selectedCaseIds.contains(caseId);

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
                                    if (selectedCaseIds.isEmpty)
                                      isSelectionMode = false;
                                  } else {
                                    selectedCaseIds.add(caseId);
                                  }
                                });
                              }
                            : null,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          color: isSelected
                              ? AppTheme.lavender.withOpacity(0.3)
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                if (isSelectionMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? AppTheme.deepPurple
                                          : Colors.grey,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item["fname_U"] ?? "-"} ${item["lname_U"] ?? "-"}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.lavender
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'HN: ${item['patient_id'] ?? '-'}',
                                                  style: TextStyle(
                                                    color: AppTheme.deepPurple,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!isSelectionMode)
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed: () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AdminEditCaseScreen(
                                                              caseData: item,
                                                            ),
                                                      ),
                                                    );
                                                    _fetchCases();
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () => _deleteCase(
                                                    item['case_id'].toString(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const Divider(),
                                      _infoRow(
                                        Icons.medical_services,
                                        'ประเภท:',
                                        item['patient_type'],
                                      ),
                                      _infoRow(
                                        Icons.airline_seat_flat,
                                        'เปล:',
                                        item['str_type_name'],
                                      ),
                                      _infoRow(
                                        Icons.login,
                                        'รับจาก:',
                                        item['case_room_from'],
                                      ),
                                      _infoRow(
                                        Icons.logout,
                                        'ส่งที่:',
                                        item['case_room_to'],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'สถานะ: ${item['case_status']}',
                                        style: TextStyle(
                                          color:
                                              item['case_status'] == 'completed'
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
