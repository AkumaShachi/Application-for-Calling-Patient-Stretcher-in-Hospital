import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/theme.dart';
import 'admin_list_historycase.dart' show AdminHistoryCaseDetailScreen;

class DailyHistoryStat {
  const DailyHistoryStat({
    required this.date,
    required this.total,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.others,
  });

  final DateTime date;
  final int total;
  final int completed;
  final int pending;
  final int inProgress;
  final int others;

  int get active => total - completed;
}

enum _PickerMode { day, range }

class AdminEmployeeHistoryDailyScreen extends StatefulWidget {
  const AdminEmployeeHistoryDailyScreen({
    super.key,
    required this.employeeName,
    required this.stats,
    required this.entries,
  });

  final String employeeName;
  final List<DailyHistoryStat> stats;
  final List<Map<String, dynamic>> entries; // normalized entries

  @override
  State<AdminEmployeeHistoryDailyScreen> createState() =>
      _AdminEmployeeHistoryDailyScreenState();
}

class _AdminEmployeeHistoryDailyScreenState
    extends State<AdminEmployeeHistoryDailyScreen> {
  final _fmtDay = DateFormat('dd/MM/yyyy');
  final _fmtDateTime = DateFormat('dd/MM/yyyy HH:mm');

  _PickerMode _mode = _PickerMode.day;
  DateTime? _selectedDay;
  DateTimeRange? _selectedRange;

  late final DateTime _firstDate;
  late final DateTime _lastDate;

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();

    if (widget.stats.isNotEmpty) {
      _firstDate = widget.stats
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      _lastDate = widget.stats
          .map((e) => e.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    } else {
      final dates = widget.entries
          .map(_parseDate)
          .whereType<DateTime>()
          .map((d) => DateTime(d.year, d.month, d.day))
          .toList();
      if (dates.isEmpty) {
        final now = DateTime.now();
        _firstDate = DateTime(now.year - 1, 1, 1);
        _lastDate = DateTime(now.year, now.month, now.day);
      } else {
        _firstDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
        _lastDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
      }
    }

    _selectedDay = _lastDate;
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.employeeName.isEmpty
        ? 'พนักงาน'
        : widget.employeeName;

    final totalCases = widget.stats.fold<int>(0, (s, e) => s + e.total);
    final totalCompleted = widget.stats.fold<int>(0, (s, e) => s + e.completed);
    final totalActive = totalCases - totalCompleted;

    final sel = _buildCountsFromEntries(_filtered);

    return Scaffold(
      appBar: AppBar(title: const Text('สถิติรายวัน')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // สรุปภาพรวมทั้งหมด
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _SummaryChip(
                      label: 'จำนวนเคสทั้งหมด',
                      value: '$totalCases',
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ปฏิทิน + ตัวเลือกโหมด
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เลือกช่วงเวลา',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('วันเดียว'),
                        selected: _mode == _PickerMode.day,
                        onSelected: (v) => setState(() {
                          _mode = _PickerMode.day;
                          _selectedRange = null;
                          _selectedDay ??= _lastDate;
                          _applyFilter();
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('ช่วงวันที่'),
                        selected: _mode == _PickerMode.range,
                        onSelected: (v) async {
                          setState(() => _mode = _PickerMode.range);
                          await _pickRange();
                        },
                      ),
                      if (_selectedDay != null || _selectedRange != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDay = _lastDate;
                              _selectedRange = null;
                              _mode = _PickerMode.day;
                              _applyFilter();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('ล้างตัวกรอง'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_mode == _PickerMode.day) ...[
                    CalendarDatePicker(
                      firstDate: _firstDate,
                      lastDate: _lastDate,
                      initialDate: _selectedDay ?? _lastDate,
                      onDateChanged: (d) {
                        setState(() {
                          _selectedDay = DateTime(d.year, d.month, d.day);
                          _selectedRange = null;
                          _applyFilter();
                        });
                      },
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'วันที่เลือก: ${_fmtDay.format(_selectedDay ?? _lastDate)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickRange,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              _selectedRange == null
                                  ? 'เลือกช่วงวันที่'
                                  : '${_fmtDay.format(_selectedRange!.start)} - ${_fmtDay.format(_selectedRange!.end)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // สรุปช่วงที่เลือก
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สรุปช่วงที่เลือก',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _CountBadge(
                      label: 'จำนวนเคสทั้งหมด',
                      value: sel.total,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // เคสที่ตรงช่วง
          if (_filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _mode == _PickerMode.day
                      ? 'ไม่มีเคสในวันที่ ${_fmtDay.format(_selectedDay ?? _lastDate)}'
                      : 'ไม่มีเคสในช่วงวันที่ที่เลือก',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ..._filtered.map(
              (item) => _CaseCard(
                item: item,
                fmt: _fmtDateTime,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminHistoryCaseDetailScreen(
                      item: Map<String, dynamic>.from(item),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final init =
        _selectedRange ??
        DateTimeRange(
          start: _firstDate,
          end: _lastDate.isBefore(now) ? _lastDate : now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: _firstDate,
      lastDate: _lastDate,
      initialDateRange: init,
      helpText: 'เลือกช่วงวันที่',
      saveText: 'ตกลง',
    );
    if (picked != null) {
      setState(() {
        _selectedRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day),
        );
        _selectedDay = null;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    List<Map<String, dynamic>> out;

    if (_mode == _PickerMode.day) {
      final d = _selectedDay ?? _lastDate;
      final start = DateTime(d.year, d.month, d.day);
      final endExclusive = start.add(const Duration(days: 1));
      out = widget.entries.where((row) {
        final t = _parseDate(row['created_at']);
        return t != null && t.isAfterOrAt(start) && t.isBefore(endExclusive);
      }).toList();
    } else {
      final range = _selectedRange;
      if (range == null) {
        out = const [];
      } else {
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final endExclusive = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
        ).add(const Duration(days: 1));
        out = widget.entries.where((row) {
          final t = _parseDate(row['created_at']);
          return t != null && t.isAfterOrAt(start) && t.isBefore(endExclusive);
        }).toList();
      }
    }

    out.sort((a, b) {
      final ta = _parseDate(a['created_at']);
      final tb = _parseDate(b['created_at']);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    _filtered = out;
    if (mounted) setState(() {});
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

  _Counts _buildCountsFromEntries(List<Map<String, dynamic>> rows) {
    int total = 0, completed = 0, pending = 0, inProgress = 0, others = 0;
    for (final r in rows) {
      total++;
      final s = r['status']?.toString().toLowerCase() ?? '';
      switch (s) {
        case 'completed':
          completed++;
          break;
        case 'pending':
          pending++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        default:
          others++;
      }
    }
    return _Counts(total, completed, pending, inProgress, others);
  }
}

class _Counts {
  const _Counts(
    this.total,
    this.completed,
    this.pending,
    this.inProgress,
    this.others,
  );
  final int total, completed, pending, inProgress, others;
}

extension _DateCmp on DateTime {
  bool isAfterOrAt(DateTime other) => isAfter(other) || isAtSameMomentAs(other);
  bool isBeforeOrAt(DateTime other) =>
      isBefore(other) || isAtSameMomentAs(other);
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            '$value',
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

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.item, required this.fmt, this.onTap});
  final Map<String, dynamic> item;
  final DateFormat fmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? '').toString().toLowerCase();
    final meta = _statusMeta(status);
    final pid = item['patient_id']?.toString() ?? '-';
    final ptype = item['patient_type']?.toString() ?? '-';
    final from = item['room_from']?.toString() ?? '-';
    final to = item['room_to']?.toString() ?? '-';

    final createdAt = item['created_at'];
    final completedAt = item['completed_at'];
    final created = fmt.format(_safeParse(createdAt) ?? DateTime.now());
    final completed =
        (completedAt == null || completedAt.toString().trim().isEmpty)
        ? '-'
        : fmt.format(_safeParse(completedAt)!);

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
                      'รหัสผู้ป่วย: $pid',
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
                      color: meta.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: meta.color,
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
              _infoLine(Icons.local_hospital_outlined, 'ประเภทผู้ป่วย', ptype),
              _infoLine(Icons.alt_route, 'เส้นทาง', '$from → $to'),
              _infoLine(Icons.schedule, 'สร้างเมื่อ', created),
              _infoLine(Icons.check_circle_outline, 'เสร็จสิ้น', completed),
              if ((item['notes']?.toString().trim().isNotEmpty ?? false))
                _infoLine(
                  Icons.notes_outlined,
                  'หมายเหตุ',
                  item['notes'].toString(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
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

  DateTime? _safeParse(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final c = text.contains('T') ? text : text.replaceFirst(' ', 'T');
    try {
      return DateTime.parse(c).toLocal();
    } catch (_) {
      return null;
    }
  }
}

class _StatusMeta {
  const _StatusMeta(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;
}

_StatusMeta _statusMeta(String status) {
  switch (status) {
    case 'pending':
      return _StatusMeta(
        'รอจัดการ',
        Colors.orange.shade800,
        Colors.orange.shade50,
      );
    case 'in_progress':
      return _StatusMeta(
        'กำลังดำเนินการ',
        Colors.blue.shade700,
        Colors.blue.shade50,
      );
    case 'completed':
      return _StatusMeta(
        'เสร็จสิ้น',
        Colors.green.shade700,
        Colors.green.shade50,
      );
    default:
      return _StatusMeta(
        status.isEmpty ? 'ไม่ทราบสถานะ' : status,
        Colors.grey.shade700,
        Colors.grey.shade200,
      );
  }
}
