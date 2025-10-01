import 'package:flutter/material.dart';

import '../services/Cases/case_get_function.dart';

class AdminListCaseScreen extends StatefulWidget {
  const AdminListCaseScreen({super.key});

  @override
  State<AdminListCaseScreen> createState() => _AdminListCaseScreenState();
}

class _AdminListCaseScreenState extends State<AdminListCaseScreen> {
  late Future<List<Map<String, dynamic>>> _casesFuture;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _casesFuture = _fetchCases();
    _searchCtrl.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_handleSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchCtrl.text.trim();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchCases() async {
    final cases = await CaseGetService.fetchAllCasesForPorter();
    return cases.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _casesFuture = _fetchCases();
    });
    await _casesFuture;
  }

  bool _matchesPatient(Map<String, dynamic> item) {
    if (_searchQuery.isEmpty) return true;
    final patientId = item['patient_id']?.toString().toLowerCase() ?? '';
    return patientId.contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('รายการเคสทั้งหมด')),
      body: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                keyboardType:
                    TextInputType.number, // ถ้า patient_id เป็นตัวเลขล้วน
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchCtrl.clear,
                        ),
                  labelText: 'ค้นหาหมายเลขผู้ป่วย',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _casesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      message: 'โหลดรายการเคสไม่สำเร็จ\n${snapshot.error}',
                      onRetry: _refresh,
                    );
                  }

                  final data = snapshot.data ?? [];
                  final filtered = data.where(_matchesPatient).toList();
                  final emptyMessage = _searchQuery.isEmpty
                      ? 'ยังไม่มีเคส'
                      : 'ไม่พบเคสที่ตรงกับหมายเลขผู้ป่วย';

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        children: [_EmptyView(message: emptyMessage)],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _CaseCard(
                          item: item,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminCaseDetailScreen(item: item),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const _CaseCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _stringValue(item['status']).toLowerCase();
    final createdAt = _formatDate(item['created_at']); // พ.ศ.
    final completedAt = _formatDate(item['completed_at']); // พ.ศ.
    final equipmentList = _parseEquipments(item['equipments']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                      'หมายเลขผู้ป่วย: ${_stringValue(item['patient_id'], dashWhenEmpty: true)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'ประเภทผู้ป่วย',
                value: _stringValue(item['patient_type'], dashWhenEmpty: true),
              ),
              _InfoRow(
                label: 'เส้นทาง',
                value:
                    '${_stringValue(item['room_from'], dashWhenEmpty: true)} - ${_stringValue(item['room_to'], dashWhenEmpty: true)}',
              ),
              _InfoRow(
                label: 'ประเภทเปล',
                value: _stringValue(
                  item['stretcher_type'],
                  dashWhenEmpty: true,
                ),
              ),
              if (equipmentList.isNotEmpty)
                _InfoRow(
                  label: 'อุปกรณ์',
                  value: _equipmentPreview(equipmentList),
                ),
              const Divider(height: 24),
              _InfoRow(
                label: 'ผู้ร้องขอ',
                value: _composeName(item, 'requested_by'),
              ),
              _InfoRow(
                label: 'เจ้าหน้าที่เวรเปลที่ได้รับมอบหมาย',
                value: _composeName(item, 'assigned_porter'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(label: 'สร้างเมื่อ', value: createdAt),
                  ),
                  Expanded(
                    child: _InfoRow(
                      label: 'เสร็จสิ้นเมื่อ',
                      value: completedAt,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _composeName(Map<String, dynamic> item, String prefix) {
    final first = _stringValue(item['${prefix}_fname']);
    final last = _stringValue(item['${prefix}_lname']);
    final display = [first, last].where((v) => v.isNotEmpty).join(' ');
    return display.isEmpty ? '-' : display;
  }

  static String _stringValue(dynamic value, {bool dashWhenEmpty = false}) {
    if (value == null) return dashWhenEmpty ? '-' : '';
    final text = value.toString().trim();
    if (text.isEmpty) return dashWhenEmpty ? '-' : '';
    return text;
  }

  /// ✅ แปลงปีเป็น พ.ศ. (+543) โดยค่าเริ่มต้น และคืนค่าเป็นรูปแบบ dd/MM/yyyy HH:mm
  static String _formatDate(
    dynamic value, {
    bool showTime = true,
    bool buddhistEra = true, // เปิด พ.ศ. เป็นค่าเริ่มต้น
    bool showEraSuffix =
        false, // ถ้าอยากให้มีคำว่า "พ.ศ." ต่อท้าย ให้ส่ง true ตอนเรียกใช้
  }) {
    if (value == null) return '-';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '-';

    DateTime dt;
    try {
      dt = DateTime.parse(raw).toLocal();
    } catch (_) {
      // ถ้า parse ไม่ได้ ก็ส่งค่าดิบกลับไป
      return raw;
    }

    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = (dt.year + (buddhistEra ? 543 : 0)).toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    final datePart = '$d/$m/$y${showEraSuffix ? ' พ.ศ.' : ''}';
    return showTime ? '$datePart $hh:$mm' : datePart;
  }

  static List<String> _parseEquipments(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value
          .map((e) {
            if (e is Map<String, dynamic>) {
              // รองรับ key ชื่อแตกต่างกัน
              return e['name']?.toString() ??
                  e['eqpt_name']?.toString() ??
                  e['title']?.toString() ??
                  '';
            }
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final textValue = value.toString().trim();
    if (textValue.isEmpty) return <String>[];
    return textValue
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _equipmentPreview(List<String> items, {int limit = 3}) {
    if (items.isEmpty) return '';
    if (items.length <= limit) return items.join(', ');
    final shown = items.take(limit).join(', ');
    final remaining = items.length - limit;
    return '$shown (+$remaining รายการ)';
  }

  static List<Widget> _buildEquipmentBullets(List<String> items) {
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class AdminCaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const AdminCaseDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final status = _CaseCard._stringValue(item['status']).toLowerCase();
    final createdAt = _CaseCard._formatDate(item['created_at']); // พ.ศ.
    final completedAt = _CaseCard._formatDate(item['completed_at']); // พ.ศ.
    final equipments = _CaseCard._parseEquipments(item['equipments']);
    final notes = _CaseCard._stringValue(item['notes']);

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดเคส')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'หมายเลขผู้ป่วย',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _CaseCard._stringValue(
                              item['patient_id'],
                              dashWhenEmpty: true,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'ข้อมูลผู้ป่วย',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'ประเภทผู้ป่วย',
                  value: _CaseCard._stringValue(
                    item['patient_type'],
                    dashWhenEmpty: true,
                  ),
                ),
                _InfoRow(
                  label: 'เส้นทาง',
                  value:
                      '${_CaseCard._stringValue(item['room_from'], dashWhenEmpty: true)} - ${_CaseCard._stringValue(item['room_to'], dashWhenEmpty: true)}',
                ),
                _InfoRow(
                  label: 'ประเภทเปล',
                  value: _CaseCard._stringValue(
                    item['stretcher_type'],
                    dashWhenEmpty: true,
                  ),
                ),
                if (equipments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'อุปกรณ์',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._CaseCard._buildEquipmentBullets(equipments),
                ],
                const SizedBox(height: 20),
                const Text(
                  'ผู้เกี่ยวข้อง',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'ผู้ร้องขอ',
                  value: _CaseCard._composeName(item, 'requested_by'),
                ),
                _InfoRow(
                  label: 'เจ้าหน้าที่เวรเปลที่ได้รับมอบหมาย',
                  value: _CaseCard._composeName(item, 'assigned_porter'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'เวลา',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _InfoRow(label: 'สร้างเมื่อ', value: createdAt),
                _InfoRow(label: 'เสร็จสิ้นเมื่อ', value: completedAt),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'หมายเหตุ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notes,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color _backgroundColor() {
    switch (status) {
      case 'pending':
        return Colors.amber.shade100;
      case 'in_progress':
        return Colors.blue.shade100;
      case 'completed':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _textColor() {
    switch (status) {
      case 'pending':
        return Colors.orange.shade800;
      case 'in_progress':
        return Colors.blue.shade800;
      case 'completed':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String _localizeStatus() {
    switch (status) {
      case 'pending':
        return 'รอจัดการ';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'completed':
        return 'เสร็จสิ้น';
      default:
        return status.isEmpty ? 'ไม่ทราบสถานะ' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _localizeStatus(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor(),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _ErrorView({required this.message, this.onRetry});

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
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองใหม่'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
