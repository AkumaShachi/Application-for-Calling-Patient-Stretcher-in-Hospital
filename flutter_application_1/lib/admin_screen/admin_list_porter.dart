import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../services/Employee/employee_get_function.dart';
import 'admin_employee_history_screen.dart';

class AdminListPorterScreen extends StatefulWidget {
  const AdminListPorterScreen({super.key});

  @override
  State<AdminListPorterScreen> createState() => _AdminListPorterScreenState();
}

class _AdminListPorterScreenState extends State<AdminListPorterScreen> {
  final List<Map<String, dynamic>> _porters = [];
  final List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  bool _initialLoading = true;
  bool _refreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
    _fetchData(initial: true);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool initial = false}) async {
    if (!mounted) return;

    if (initial) {
      setState(() {
        _initialLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _refreshing = true;
      });
    }

    try {
      final directory = await EmployeeGetService.fetchEmployees();
      if (!mounted) return;
      setState(() {
        _porters
          ..clear()
          ..addAll(directory.porters);
        _applyFilter();
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _describeError(error);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (initial) {
          _initialLoading = false;
        }
        _refreshing = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    _filtered
      ..clear()
      ..addAll(
        query.isEmpty
            ? _porters
            : _porters.where((porter) {
                final buffer = StringBuffer()
                  ..write(porter['user_fname'] ?? '')
                  ..write(' ')
                  ..write(porter['user_lname'] ?? '')
                  ..write(' ')
                  ..write(porter['user_id'] ?? '')
                  ..write(' ')
                  ..write(porter['user_phone'] ?? '')
                  ..write(' ')
                  ..write(porter['user_email'] ?? '');
                return buffer.toString().toLowerCase().contains(query);
              }),
      );
    if (mounted) {
      setState(() {});
    }
  }

  void _openHistory(Map<String, dynamic> porter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEmployeeHistoryScreen(
          employee: Map<String, dynamic>.from(porter),
          role: EmployeeHistoryRole.porter,
        ),
      ),
    );
  }
  String _describeError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }

  String _initials(dynamic fname, dynamic lname) {
    final first = fname?.toString().isNotEmpty == true ? fname.toString()[0] : '';
    final last = lname?.toString().isNotEmpty == true ? lname.toString()[0] : '';
    final result = '$first$last';
    return result.isNotEmpty ? result.toUpperCase() : '?';
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 42),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchData(initial: true),
                icon: const Icon(Icons.refresh),
                label: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_refreshing) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ค้นหาเจ้าหน้าที่เวรเปลตามชื่อ, รหัส, อีเมล หรือเบอร์โทร',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.lavender),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.deepPurple),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchData(),
            child: _filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.person_off, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Center(child: Text('ไม่พบเจ้าหน้าที่เวรเปลที่ตรงกับการค้นหา')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final porter = _filtered[index];
                      final imageUrl = porter['user_profile_image']?.toString();
                      final name = '${porter['user_fname'] ?? ''} ${porter['user_lname'] ?? ''}'.trim();
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.deepPurple.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => _openHistory(porter),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.lavender,
                            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null,
                            child: (imageUrl == null || imageUrl.isEmpty)
                                ? Text(
                                    _initials(porter['user_fname'], porter['user_lname']),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            name.isEmpty ? 'ไม่ทราบชื่อ' : name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('รหัส: ${porter['user_id'] ?? '-'}'),
                              Text('เบอร์โทร: ${porter['user_phone'] ?? '-'}'),
                              Text('อีเมล: ${porter['user_email'] ?? '-'}'),
                            ],
                          ),
                          trailing: const Icon(Icons.history, color: Colors.deepPurple),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _filtered.length,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายชื่อเจ้าหน้าที่เวรเปล'),
        actions: [
          IconButton(
            onPressed: _refreshing || _initialLoading ? null : () => _fetchData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }
}







