import 'package:flutter/material.dart';
import '../services/CasesHistory/caseshistory_get_function.dart';

class AdminListHistoryCaseScreen extends StatefulWidget {
  const AdminListHistoryCaseScreen({super.key});

  @override
  State<AdminListHistoryCaseScreen> createState() =>
      _AdminListHistoryCaseScreenState();
}

class _AdminListHistoryCaseScreenState
    extends State<AdminListHistoryCaseScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
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

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final history = await CasesHistoryService.fetchHistory();
    return history.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _fetchHistory();
    });
    await _historyFuture;
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
      appBar: AppBar(title: const Text('ประวัติเคส')),
      body: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                keyboardType: TextInputType.text, // อนุญาตตัวอักษร เช่น G12
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
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _HistoryErrorView(
                      message: 'โหลดประวัติไม่สำเร็จ\n${snapshot.error}',
                      onRetry: _refresh,
                    );
                  }

                  final data = snapshot.data ?? [];
                  final filtered = data.where(_matchesPatient).toList();
                  final emptyMessage = _searchQuery.isEmpty
                      ? 'ยังไม่มีประวัติเคส'
                      : 'ไม่พบประวัติที่ตรงกับหมายเลขผู้ป่วย';

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        children: [_HistoryEmptyView(message: emptyMessage)],
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
                        return _HistoryCard(
                          item: item,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminHistoryCaseDetailScreen(item: item),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const _HistoryCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _stringValue(item['status']).toLowerCase();
    final createdAt = _formatDate(item['created_at']); // วันที่แบบ พ.ศ.
    final completedAt = _formatDate(item['completed_at']); // วันที่แบบ พ.ศ.
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
                  _HistoryStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),
              _HistoryInfo(
                label: 'ประเภทผู้ป่วย',
                value: _stringValue(item['patient_type'], dashWhenEmpty: true),
              ),
              _HistoryInfo(
                label: 'เส้นทาง',
                value:
                    '${_stringValue(item['room_from'], dashWhenEmpty: true)} - ${_stringValue(item['room_to'], dashWhenEmpty: true)}',
              ),
              _HistoryInfo(
                label: 'ประเภทเปล',
                value: _stringValue(
                  item['stretcher_type'],
                  dashWhenEmpty: true,
                ),
              ),
              if (equipmentList.isNotEmpty)
                _HistoryInfo(
                  label: 'อุปกรณ์',
                  value: _equipmentPreview(equipmentList),
                ),
              if (_stringValue(item['notes']).isNotEmpty)
                _HistoryInfo(
                  label: 'หมายเหตุ',
                  value: _stringValue(item['notes']),
                ),
              const Divider(height: 24),
              _HistoryInfo(
                label: 'ผู้ร้องขอ',
                value: _composeName(item, 'requested_by'),
              ),
              _HistoryInfo(
                label: 'เจ้าหน้าที่เวรเปลที่ได้รับมอบหมาย',
                value: _composeName(item, 'assigned_porter'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HistoryInfo(label: 'สร้างเมื่อ', value: createdAt),
                  ),
                  Expanded(
                    child: _HistoryInfo(
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

  // >>> ชื่อมี fallback เป็น username <<<
  static String _composeName(Map<String, dynamic> item, String prefix) {
    final first = _stringValue(item['${prefix}_fname']);
    final last = _stringValue(item['${prefix}_lname']);
    final uname = _stringValue(item['${prefix}_username']);
    final display = [first, last].where((v) => v.isNotEmpty).join(' ').trim();
    if (display.isNotEmpty) return display;
    if (uname.isNotEmpty) return uname;
    return '-';
  }

  static String _stringValue(dynamic value, {bool dashWhenEmpty = false}) {
    if (value == null) return dashWhenEmpty ? '-' : '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return dashWhenEmpty ? '-' : '';
    }
    return text;
  }

  /// ✅ รองรับทั้ง "YYYY-MM-DD HH:mm:ss" และ ISO8601 ที่มี 'T'
  /// ✅ แปลงปีเป็น พ.ศ. (+543) โดยค่าเริ่มต้น
  static String _formatDate(
    dynamic value, {
    bool showTime = true,
    bool buddhistEra = true, // เปิด พ.ศ. เป็นค่าเริ่มต้น
    bool showEraSuffix =
        false, // ถ้าต้องการให้มี "พ.ศ." ต่อท้าย ให้ส่ง true ตอนเรียกใช้
  }) {
    if (value == null) return '-';
    final txt = value.toString().trim();
    if (txt.isEmpty) return '-';
    final candidate = txt.contains('T') ? txt : txt.replaceFirst(' ', 'T');
    try {
      final dt = DateTime.parse(candidate).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = (dt.year + (buddhistEra ? 543 : 0)).toString();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final datePart = '$d/$m/$y' + (showEraSuffix ? ' พ.ศ.' : '');
      return showTime ? '$datePart $hh:$mm' : datePart;
    } catch (_) {
      return '-';
    }
  }

  static List<String> _parseEquipments(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value
          .map((e) {
            if (e is Map<String, dynamic>) {
              return e['name']?.toString() ??
                  e['eqpt_name']?.toString() ??
                  e['title']?.toString() ??
                  '';
            }
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
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

class AdminHistoryCaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const AdminHistoryCaseDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final status = _HistoryCard._stringValue(item['status']).toLowerCase();
    final createdAt = _HistoryCard._formatDate(item['created_at']); // พ.ศ.
    final completedAt = _HistoryCard._formatDate(item['completed_at']); // พ.ศ.
    final equipments = _HistoryCard._parseEquipments(item['equipments']);
    final notes = _HistoryCard._stringValue(item['notes']);

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดประวัติ')),
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
                            _HistoryCard._stringValue(
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
                    _HistoryStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'ข้อมูลผู้ป่วย',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _HistoryInfo(
                  label: 'ประเภทผู้ป่วย',
                  value: _HistoryCard._stringValue(
                    item['patient_type'],
                    dashWhenEmpty: true,
                  ),
                ),
                _HistoryInfo(
                  label: 'เส้นทาง',
                  value:
                      '${_HistoryCard._stringValue(item['room_from'], dashWhenEmpty: true)} - ${_HistoryCard._stringValue(item['room_to'], dashWhenEmpty: true)}',
                ),
                _HistoryInfo(
                  label: 'ประเภทเปล',
                  value: _HistoryCard._stringValue(
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
                  ..._HistoryCard._buildEquipmentBullets(equipments),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                const SizedBox(height: 20),
                const Text(
                  'ผู้เกี่ยวข้อง',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _HistoryInfo(
                  label: 'ผู้ร้องขอ',
                  value: _HistoryCard._composeName(item, 'requested_by'),
                ),
                _HistoryInfo(
                  label: 'เจ้าหน้าที่เวรเปลที่ได้รับมอบหมาย',
                  value: _HistoryCard._composeName(item, 'assigned_porter'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'เวลา',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _HistoryInfo(label: 'สร้างเมื่อ', value: createdAt),
                _HistoryInfo(label: 'เสร็จสิ้นเมื่อ', value: completedAt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryInfo extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryInfo({required this.label, required this.value});

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

class _HistoryStatusBadge extends StatelessWidget {
  final String status;

  const _HistoryStatusBadge({required this.status});

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

class _HistoryEmptyView extends StatelessWidget {
  final String message;

  const _HistoryEmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
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

class _HistoryErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _HistoryErrorView({required this.message, this.onRetry});

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
