// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../services/Stretchers/stretcher_add_function.dart';
import '../services/Stretchers/stretcher_delete_function.dart';
import '../services/Stretchers/stretcher_get_function.dart';
import '../services/Stretchers/stretcher_update_function.dart';

class AdminStretcherScreen extends StatefulWidget {
  const AdminStretcherScreen({super.key});

  @override
  State<AdminStretcherScreen> createState() => _AdminStretcherScreenState();
}

class _AdminStretcherScreenState extends State<AdminStretcherScreen> {
  final List<Map<String, dynamic>> _stretchers = [];
  bool _initialLoading = true;
  bool _refreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStretchers(initial: true);
  }

  Future<void> _fetchStretchers({bool initial = false}) async {
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
      final fetched = await StretcherGetService.fetchStretchers();
      if (!mounted) return;
      setState(() {
        _stretchers
          ..clear()
          ..addAll(fetched);
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _readableError(error);
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

  Future<void> _handleAdd() async {
    final success = await _showStretcherDialog();
    if (success == true && mounted) {
      await _fetchStretchers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เพิ่มข้อมูลเปลเรียบร้อย')));
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> stretcher) async {
    final success = await _showStretcherDialog(stretcher: stretcher);
    if (success == true && mounted) {
      await _fetchStretchers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลเปลเรียบร้อย')));
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> stretcher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบข้อมูลเปล'),
        content: Text('ต้องการลบ "${stretcher['str_type_name']}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      _refreshing = true;
    });

    try {
      await StretcherDeleteService.deleteStretcher(stretcher['str_type_id']);
      if (!mounted) return;
      await _fetchStretchers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลเปลเรียบร้อย')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: ${_readableError(error)}')),
      );
    }
  }

  Future<bool?> _showStretcherDialog({Map<String, dynamic>? stretcher}) async {
    final isEdit = stretcher != null;
    final nameCtrl = TextEditingController(
      text: stretcher?['str_type_name']?.toString() ?? '',
    );
    final quantityCtrl = TextEditingController(
      text: stretcher?['str_quantity']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    String? localError;
    bool submitting = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            return AlertDialog(
              title: Text(isEdit ? 'แก้ไขข้อมูลเปล' : 'เพิ่มข้อมูลเปล'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อเปล',
                          hintText: 'เช่น เปลสำหรับเคลื่อนย้าย',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกชื่อเปล';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'จำนวน',
                          hintText: 'เช่น 5',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกจำนวน';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'จำนวนต้องเป็นตัวเลขที่ไม่ติดลบ';
                          }
                          return null;
                        },
                      ),
                      if (localError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          localError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          FocusScope.of(dialogContext).unfocus();
                          final name = nameCtrl.text.trim();
                          final quantity = int.parse(quantityCtrl.text.trim());

                          setLocalState(() {
                            submitting = true;
                            localError = null;
                          });

                          try {
                            if (isEdit) {
                              await StretcherUpdateService.updateStretcher(
                                stretcher['str_type_id'],
                                name: name,
                                quantity: quantity,
                              );
                            } else {
                              await StretcherAddService.createStretcher(
                                name: name,
                                quantity: quantity,
                              );
                            }
                            Navigator.of(dialogContext).pop(true);
                          } catch (error) {
                            setLocalState(() {
                              submitting = false;
                              localError = _readableError(error);
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _readableError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
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
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchStretchers(initial: true),
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchStretchers(),
            child: _stretchers.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 80,
                      horizontal: 16,
                    ),
                    children: const [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text('ยังไม่มีข้อมูลเปลในระบบ'),
                            SizedBox(height: 4),
                            Text(
                              'แตะปุ่ม เพิ่มเปล เพื่อสร้างรายการใหม่',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 96, top: 12),
                    itemBuilder: (context, index) {
                      final stretcher = _stretchers[index];
                      return _StretcherCard(
                        stretcher: stretcher,
                        onEdit: () => _handleEdit(stretcher),
                        onDelete: () => _confirmDelete(stretcher),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: _stretchers.length,
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
        title: const Text('จัดการเปลพยาบาล'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _refreshing || _initialLoading
                ? null
                : () => _fetchStretchers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshing ? null : _handleAdd,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มเปล'),
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
      ),
    );
  }
}

class _StretcherCard extends StatelessWidget {
  final Map<String, dynamic> stretcher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StretcherCard({
    required this.stretcher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = stretcher['str_type_name']?.toString() ?? '-';
    final quantityRaw = stretcher['str_quantity'];
    final quantity = quantityRaw is num
        ? quantityRaw.toString()
        : quantityRaw?.toString() ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.lavender,
          foregroundColor: AppTheme.deepPurple,
          child: const Icon(Icons.local_hospital),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'จำนวนทั้งหมด: $quantity',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              tooltip: 'แก้ไข',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'ลบ',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
