import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../services/CasesHistory/caseshistory_get_function.dart';
import 'admin_employee_history_daily_screen.dart';
import 'admin_list_historycase.dart' show AdminHistoryCaseDetailScreen;

enum EmployeeHistoryRole { nurse, porter }

class AdminEmployeeHistoryScreen extends StatefulWidget {
  const AdminEmployeeHistoryScreen({
    super.key,
    required this.employee,
    required this.role,
  });

  final Map<String, dynamic> employee;
  final EmployeeHistoryRole role;

  @override
  State<AdminEmployeeHistoryScreen> createState() =>
      _AdminEmployeeHistoryScreenState();
}

class _AdminEmployeeHistoryScreenState
    extends State<AdminEmployeeHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _allEntries = [];
  final List<Map<String, dynamic>> _filteredEntries = [];

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_handleSearch);
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_handleSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _displayName {
    final first = _stringValue(widget.employee['user_fname']);
    final last = _stringValue(widget.employee['user_lname']);
    return [first, last].where((part) => part.isNotEmpty).join(' ');
  }

  String get _roleLabel {
    switch (widget.role) {
      case EmployeeHistoryRole.porter:
        return 'เจ้าหน้าที่เวรเปล';
      case EmployeeHistoryRole.nurse:
        return 'พยาบาล';
    }
  }

  String get _appBarTitle {
    final name = _displayName;
    if (name.isEmpty) return 'ประวัติการทำงาน';
    return 'ประวัติการทำงานของ $name';
  }

  int? _resolveUserId(Map<String, dynamic> employee) {
    final v = employee['user_id'] ?? employee['id'] ?? employee['userId'];
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  String _resolveUserName(Map<String, dynamic> employee) {
    final v =
        employee['user_username'] ??
        employee['username'] ??
        employee['user_email'] ??
        employee['email'];
    if (v == null) return '';
    final t = v.toString().trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t;
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1) ดึงข้อมูลทั้งหมดจาก API
      final raw = await CasesHistoryService.fetchHistory();

      // 2) ตัวระบุพนักงานจาก props
      final userId = _resolveUserId(widget.employee); // อาจเป็น null
      final userName = _resolveUserName(widget.employee); // อาจเป็น ''
      final empFName = _stringValue(widget.employee['user_fname']);
      final empLName = _stringValue(widget.employee['user_lname']);

      if ((userId == null) &&
          userName.isEmpty &&
          empFName.isEmpty &&
          empLName.isEmpty) {
        setState(() {
          _allEntries.clear();
          _filteredEntries.clear();
          _loading = false;
          _errorMessage =
              'ไม่พบตัวระบุพนักงานเพียงพอสำหรับการกรอง (user_id / username / ชื่อ–นามสกุล)';
        });
        return;
      }

      // 3) กรองตาม role + userId/username/fullname
      final owned = raw
          .whereType<Map<String, dynamic>>()
          .where(
            (row) => _isOwnedByThisEmployee(
              row,
              role: widget.role,
              userId: userId,
              username: userName,
              empFName: empFName,
              empLName: empLName,
            ),
          )
          .toList();

      // 4) Normalize คีย์ให้เป็นชุดเดียวกับ UI (เพิ่มคีย์ที่เคยหาย)
      final normalized = owned.map(_normalizeRow).toList();

      // 5) เรียงเวลาย้อนหลัง
      normalized.sort((a, b) {
        final aDate = _parseDate(a['created_at']);
        final bDate = _parseDate(b['created_at']);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      // 6) ใช้คำค้นหา
      final query = _searchCtrl.text.trim().toLowerCase();
      final filtered = _applyQuery(normalized, query);

      if (!mounted) return;
      setState(() {
        _allEntries
          ..clear()
          ..addAll(normalized);
        _filteredEntries
          ..clear()
          ..addAll(filtered);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _allEntries.clear();
        _filteredEntries.clear();
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  bool _isOwnedByThisEmployee(
    Map<String, dynamic> row, {
    required EmployeeHistoryRole role,
    required int? userId,
    required String username,
    required String empFName,
    required String empLName,
  }) {
    final wantId = userId;
    final wantUser = _safeLower(username);
    final wantFull = _fullName(empFName, empLName);

    int? pickInt(List<String> keys) {
      for (final k in keys) {
        final v = row[k];
        if (v == null) continue;
        final n = int.tryParse(v.toString());
        if (n != null) return n;
      }
      return null;
    }

    String pickLower(List<String> keys) {
      for (final k in keys) {
        final s = _safeLower(row[k]);
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    String pickFull(List<String> fKeys, List<String> lKeys) {
      String f = '';
      String l = '';
      for (final k in fKeys) {
        f = _safeLower(row[k]);
        if (f.isNotEmpty) break;
      }
      for (final k in lKeys) {
        l = _safeLower(row[k]);
        if (l.isNotEmpty) break;
      }
      return _fullName(f, l);
    }

    if (role == EmployeeHistoryRole.porter) {
      final porterId = pickInt([
        'rhis_assigned_porter',
        'assigned_porter_id',
        'porter_id',
        'porter_num',
      ]);
      final porterUser = pickLower([
        'assigned_porter_username',
        'porter_username',
      ]);
      final porterFull = pickFull(
        ['assigned_porter_fname', 'porter_fname', 'user_fname'],
        ['assigned_porter_lname', 'porter_lname', 'user_lname'],
      );

      if (wantId != null && porterId != null && wantId == porterId) return true;
      if (wantUser.isNotEmpty &&
          porterUser.isNotEmpty &&
          wantUser == porterUser) {
        return true;
      }
      if (wantFull.isNotEmpty &&
          porterFull.isNotEmpty &&
          wantFull == porterFull) {
        return true;
      }

      return false;
    } else {
      final reqId = pickInt([
        'rhis_requested_by',
        'requested_by_id',
        'requester_id',
        'requester_num',
      ]);
      final reqUser = pickLower([
        'requested_by_username',
        'requester_username',
      ]);
      final reqFull = pickFull(
        ['requested_by_fname', 'requester_fname', 'user_fname'],
        ['requested_by_lname', 'requester_lname', 'user_lname'],
      );

      if (wantId != null && reqId != null && wantId == reqId) return true;
      if (wantUser.isNotEmpty && reqUser.isNotEmpty && wantUser == reqUser) {
        return true;
      }
      if (wantFull.isNotEmpty && reqFull.isNotEmpty && wantFull == reqFull) {
        return true;
      }

      return false;
    }
  }

  String _safeLower(dynamic v) {
    if (v == null) return '';
    final t = v.toString().trim();
    return (t.isEmpty || t.toLowerCase() == 'null') ? '' : t.toLowerCase();
  }

  String _fullName(dynamic first, dynamic last) {
    final f = _safeLower(first);
    final l = _safeLower(last);
    final joined = [f, l].where((e) => e.isNotEmpty).join(' ').trim();
    return joined;
  }

  void _handleSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredEntries
        ..clear()
        ..addAll(_applyQuery(_allEntries, query));
    });
  }

  List<Map<String, dynamic>> _applyQuery(
    List<Map<String, dynamic>> source,
    String query,
  ) {
    if (query.isEmpty) {
      return source.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    final q = query.toLowerCase();
    return source
        .where((item) {
          final id =
              (item['patient_id'] ?? item['patientId'])
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';
          return id.contains(q); // <-- ค้นหาเฉพาะ patientId
        })
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _valuesForSearch(Map<String, dynamic> entry) {
    final values = <String>[];

    void add(dynamic value) {
      final text = value?.toString().trim().toLowerCase();
      if (text != null && text.isNotEmpty && text != 'null') {
        values.add(text);
      }
    }

    add(entry['patient_id']);
    add(entry['patient_type']);
    add(entry['room_from']);
    add(entry['room_to']);
    add(entry['status']);
    add(entry['notes']);
    add(entry['case_id']);
    add(entry['history_id']);

    return values;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final candidate = text.contains('T') ? text : text.replaceFirst(' ', 'T');
    try {
      return DateTime.parse(candidate).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(dynamic raw) {
    final date = _parseDate(raw);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }

  String _initials(String? first, String? last) {
    final buffer = StringBuffer();
    if (first != null && first.isNotEmpty) buffer.write(first[0].toUpperCase());
    if (last != null && last.isNotEmpty) buffer.write(last[0].toUpperCase());
    final result = buffer.toString();
    return result.isEmpty ? '?' : result;
  }

  void _openHistoryDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdminHistoryCaseDetailScreen(item: Map<String, dynamic>.from(item)),
      ),
    );
  }

  // ---------- เปิดหน้าสถิติรายวัน (ปฏิทิน + ช่วงเวลา) ----------
  void _openDailyStats() {
    final stats = _buildDailyStatsFromEntries(_allEntries);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEmployeeHistoryDailyScreen(
          employeeName: _displayName.isEmpty ? 'พนักงาน' : _displayName,
          stats: stats,
          entries: _allEntries, // ส่งรายการเคสทั้งหมดให้หน้าปฏิทินใช้ฟิลเตอร์
        ),
      ),
    );
  }

  // รวมข้อมูลรายวันจาก _allEntries → List<DailyHistoryStat>
  List<DailyHistoryStat> _buildDailyStatsFromEntries(
    List<Map<String, dynamic>> rows,
  ) {
    final map = <DateTime, _Acc>{};

    for (final r in rows) {
      final created = _parseDate(r['created_at']);
      if (created == null) continue;
      final day = DateTime(created.year, created.month, created.day);

      final acc = map.putIfAbsent(day, () => _Acc());
      acc.total++;

      final status = r['status']?.toString().toLowerCase() ?? '';
      switch (status) {
        case 'completed':
          acc.completed++;
          break;
        case 'pending':
          acc.pending++;
          break;
        case 'in_progress':
          acc.inProgress++;
          break;
        default:
          acc.others++;
          break;
      }
    }

    final list = map.entries.map((e) {
      final a = e.value;
      return DailyHistoryStat(
        date: e.key,
        total: a.total,
        completed: a.completed,
        pending: a.pending,
        inProgress: a.inProgress,
        others: a.others,
      );
    }).toList();

    list.sort((a, b) => b.date.compareTo(a.date)); // ใหม่ → เก่า
    return list;
  }
  // -----------------------------------------------

  // --------- ปรับเพิ่มคีย์ที่จำเป็นสำหรับหน้า Detail ให้ครบ ----------
  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    String pickStr(List keys) {
      for (final k in keys) {
        final v = row[k];
        if (v != null) {
          final t = v.toString().trim();
          if (t.isNotEmpty && t.toLowerCase() != 'null') return t;
        }
      }
      return '';
    }

    dynamic pickRaw(List keys) {
      for (final k in keys) {
        if (row.containsKey(k) && row[k] != null) return row[k];
      }
      return null;
    }

    String fullName(String f, String l) =>
        [f, l].where((e) => e.trim().isNotEmpty).join(' ').trim();

    // ขอ/ผู้มอบหมาย
    final requestedByF = pickStr([
      'requested_by_fname',
      'requester_fname',
      'req_fname',
      'user_fname',
    ]);
    final requestedByL = pickStr([
      'requested_by_lname',
      'requester_lname',
      'req_lname',
      'user_lname',
    ]);
    final requestedByU = pickStr([
      'requested_by_username',
      'requester_username',
      'req_username',
      'username',
    ]);

    final porterF = pickStr([
      'assigned_porter_fname',
      'porter_fname',
      'user_fname',
    ]);
    final porterL = pickStr([
      'assigned_porter_lname',
      'porter_lname',
      'user_lname',
    ]);
    final porterU = pickStr([
      'assigned_porter_username',
      'porter_username',
      'username',
    ]);

    return {
      // ids
      'history_id': pickStr(['history_id', 'ch_id', 'id']),
      'case_id': pickStr(['case_id', 'cid', 'caseId', 'ch_case_id']),

      // patient
      'patient_id': pickStr(['patient_id', 'case_patient_id', 'patientId']),
      'patient_type': pickStr(['patient_type', 'case_patient_type', 'type']),

      // route
      'room_from': pickStr([
        'room_from',
        'from_room',
        'case_room_from',
        'from',
      ]),
      'room_to': pickStr(['room_to', 'to_room', 'case_room_to', 'to']),

      // status / notes
      'status': pickStr(['status', 'case_status', 'ch_status', 'state']),
      'notes': pickStr(['notes', 'note', 'case_notes', 'remark']),

      // times
      'created_at': pickStr([
        'created_at',
        'ch_created_at',
        'createdAt',
        'created_at_str',
      ]),
      'completed_at': pickStr([
        'completed_at',
        'ch_completed_at',
        'completedAt',
        'done_at',
      ]),

      // equipments
      'equipments': pickRaw([
        'equipments',
        'equipment',
        'equipments_list',
        'eqpt',
      ]),

      // --- เพิ่ม: เปล/ผู้เกี่ยวข้อง ---
      'stretcher_type': pickStr(['stretcher_type', 'str_type_name']),

      'requested_by_id': pickStr([
        'rhis_requested_by',
        'requested_by_id',
        'requester_id',
        'requester_num',
      ]),
      'requested_by_username': requestedByU,
      'requested_by_fname': requestedByF,
      'requested_by_lname': requestedByL,
      'requested_by_display': fullName(requestedByF, requestedByL).isNotEmpty
          ? fullName(requestedByF, requestedByL)
          : (requestedByU.isNotEmpty ? requestedByU : ''),

      'assigned_porter_id': pickStr([
        'rhis_assigned_porter',
        'assigned_porter_id',
        'porter_id',
        'porter_num',
      ]),
      'assigned_porter_username': porterU,
      'assigned_porter_fname': porterF,
      'assigned_porter_lname': porterL,
      'assigned_porter_display': fullName(porterF, porterL).isNotEmpty
          ? fullName(porterF, porterL)
          : (porterU.isNotEmpty ? porterU : ''),
    };
  }
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final canOpenDaily = !_loading && _allEntries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          if (canOpenDaily)
            IconButton(
              tooltip: 'สถิติรายวัน',
              icon: const Icon(Icons.insights_outlined),
              onPressed: _openDailyStats,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: _loading ? null : _fetchHistory,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!, onRetry: _fetchHistory);
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 12),
          if (_filteredEntries.isEmpty)
            _EmptyState(roleLabel: _roleLabel)
          else
            ..._filteredEntries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryEntryCard(
                  item: item,
                  formattedCreatedAt: _formatDate(item['created_at']),
                  formattedCompletedAt: _formatDate(item['completed_at']),
                  onTap: () => _openHistoryDetail(item),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final imageUrl = _stringValue(widget.employee['user_profile_image']);
    final name = _displayName.isEmpty ? 'ไม่ทราบชื่อ' : _displayName;
    final employeeId = _stringValue(widget.employee['user_id']);
    final email = _stringValue(widget.employee['user_email']);
    final phone = _stringValue(widget.employee['user_phone']);
    final totalCount = _allEntries.length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppTheme.lavender,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? Text(
                      _initials(
                        widget.employee['user_fname']?.toString(),
                        widget.employee['user_lname']?.toString(),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel,
                    style: TextStyle(
                      color: AppTheme.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryInfoRow(
                    label: 'รหัสพนักงาน',
                    value: employeeId.isEmpty ? '-' : employeeId,
                  ),
                  _SummaryInfoRow(
                    label: 'อีเมล',
                    value: email.isEmpty ? '-' : email,
                  ),
                  _SummaryInfoRow(
                    label: 'เบอร์โทร',
                    value: phone.isEmpty ? '-' : phone,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _SummaryChip(
                      label: 'จำนวนเคสทั้งหมด',
                      value: '$totalCount',
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  _handleSearch();
                },
              ),
        labelText: 'ค้นหา หมายเลขผู้ป่วย',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SummaryInfoRow extends StatelessWidget {
  const _SummaryInfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.item,
    required this.formattedCreatedAt,
    required this.formattedCompletedAt,
    this.onTap,
  });

  final Map<String, dynamic> item;
  final String formattedCreatedAt;
  final String formattedCompletedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusMeta = _statusMeta(item['status']);
    final patientId = item['patient_id']?.toString() ?? '-';
    final patientType = item['patient_type']?.toString() ?? '-';
    final routeFrom = item['room_from']?.toString() ?? '-';
    final routeTo = item['room_to']?.toString() ?? '-';
    final notes = item['notes']?.toString() ?? '';
    final equipments = _equipmentPreview(item['equipments']);
    final stretcher = item['stretcher_type']?.toString() ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'หมายเลขผู้ป่วย: $patientId',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusMeta.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusMeta.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusMeta.color,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _HistoryInfoLine(
                icon: Icons.local_hospital_outlined,
                label: 'ประเภทผู้ป่วย',
                value: patientType,
              ),
              _HistoryInfoLine(
                icon: Icons.alt_route,
                label: 'เส้นทาง',
                value: '$routeFrom → $routeTo',
              ),
              if (stretcher.isNotEmpty)
                _HistoryInfoLine(
                  icon: Icons.accessible_forward_outlined,
                  label: 'ประเภทเปล',
                  value: stretcher,
                ),
              _HistoryInfoLine(
                icon: Icons.schedule,
                label: 'สร้างเมื่อ',
                value: formattedCreatedAt,
              ),
              _HistoryInfoLine(
                icon: Icons.check_circle_outline,
                label: 'เสร็จสิ้น',
                value: formattedCompletedAt,
              ),
              if (equipments.isNotEmpty)
                _HistoryInfoLine(
                  icon: Icons.medical_services_outlined,
                  label: 'อุปกรณ์',
                  value: equipments,
                ),
              if (notes.isNotEmpty)
                _HistoryInfoLine(
                  icon: Icons.notes_outlined,
                  label: 'หมายเหตุ',
                  value: notes,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryInfoLine extends StatelessWidget {
  const _HistoryInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.roleLabel});
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีประวัติการทำงานของ $roleLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.color,
    required this.background,
  });
  final String label;
  final Color color;
  final Color background;
}

_StatusMeta _statusMeta(dynamic raw) {
  final status = raw?.toString().toLowerCase() ?? '';
  switch (status) {
    case 'pending':
      return _StatusMeta(
        label: 'รอจัดการ',
        color: Colors.orange.shade800,
        background: Colors.orange.shade50,
      );
    case 'in_progress':
      return _StatusMeta(
        label: 'กำลังดำเนินการ',
        color: Colors.blue.shade700,
        background: Colors.blue.shade50,
      );
    case 'completed':
      return _StatusMeta(
        label: 'เสร็จสิ้น',
        color: Colors.green.shade700,
        background: Colors.green.shade50,
      );
    default:
      return _StatusMeta(
        label: status.isEmpty ? 'ไม่ทราบสถานะ' : status,
        color: Colors.grey.shade700,
        background: Colors.grey.shade200,
      );
  }
}

String _equipmentPreview(dynamic raw) {
  if (raw == null) return '';

  if (raw is List) {
    final items = raw
        .map((e) {
          if (e is Map<String, dynamic>) {
            return e['name']?.toString() ??
                e['eqpt_name']?.toString() ??
                e['title']?.toString() ??
                '';
          }
          return e.toString();
        })
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty && v.toLowerCase() != 'null')
        .toList();
    return items.join(', ');
  }

  final text = raw.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return '';
  return text;
}

class _Acc {
  int total = 0, completed = 0, pending = 0, inProgress = 0, others = 0;
}
