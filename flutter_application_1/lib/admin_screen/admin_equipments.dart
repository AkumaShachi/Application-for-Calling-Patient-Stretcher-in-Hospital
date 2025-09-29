import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../services/Equipments/equipment_add_function.dart';
import '../services/Equipments/equipment_delete_function.dart';
import '../services/Equipments/equipment_get_function.dart';
import '../services/Equipments/equipment_update_function.dart';

class AdminEquipmentsScreen extends StatefulWidget {
  const AdminEquipmentsScreen({super.key});

  @override
  State<AdminEquipmentsScreen> createState() => _AdminEquipmentsScreenState();
}

class _AdminEquipmentsScreenState extends State<AdminEquipmentsScreen> {
  final List<Map<String, dynamic>> _equipments = [];
  bool _initialLoading = true;
  bool _refreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEquipments(initial: true);
  }

  Future<void> _fetchEquipments({bool initial = false}) async {
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
      final fetched = await EquipmentGetService.fetchEquipments();
      if (!mounted) return;
      setState(() {
        _equipments
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
    final success = await _showEquipmentDialog();
    if (success == true && mounted) {
      await _fetchEquipments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มข้อมูลอุปกรณ์เรียบร้อย')),
      );
    }
  }

  Future<void> _handleEdit(Map<String, dynamic> equipment) async {
    final success = await _showEquipmentDialog(equipment: equipment);
    if (success == true && mounted) {
      await _fetchEquipments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตข้อมูลอุปกรณ์เรียบร้อย')),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> equipment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบข้อมูลอุปกรณ์'),
        content: Text('ต้องการลบ "${equipment['eqpt_name']}" หรือไม่?'),
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
      await EquipmentDeleteService.deleteEquipment(equipment['eqpt_id']);
      if (!mounted) return;
      await _fetchEquipments();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลอุปกรณ์เรียบร้อย')));
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

  Future<bool?> _showEquipmentDialog({Map<String, dynamic>? equipment}) async {
    final isEdit = equipment != null;
    final nameCtrl = TextEditingController(
      text: equipment?['eqpt_name']?.toString() ?? '',
    );
    final quantityCtrl = TextEditingController(
      text: equipment?['eqpt_quantity']?.toString() ?? '',
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
              title: Text(isEdit ? 'แก้ไขข้อมูลอุปกรณ์' : 'เพิ่มข้อมูลอุปกรณ์'),
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
                          labelText: 'ชื่ออุปกรณ์',
                          hintText: 'เช่น เครื่องวัดความดัน',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกชื่ออุปกรณ์';
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
                              await EquipmentUpdateService.updateEquipment(
                                equipment['eqpt_id'],
                                name: name,
                                quantity: quantity,
                              );
                            } else {
                              await EquipmentAddService.createEquipment(
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
                onPressed: () => _fetchEquipments(initial: true),
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
            onRefresh: () => _fetchEquipments(),
            child: _equipments.isEmpty
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
                              Icons.inventory_2,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text('ยังไม่มีข้อมูลอุปกรณ์ในระบบ'),
                            SizedBox(height: 4),
                            Text(
                              'แตะปุ่ม เพิ่มอุปกรณ์ เพื่อสร้างรายการใหม่',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
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
                      final equipment = _equipments[index];
                      return _EquipmentCard(
                        equipment: equipment,
                        onEdit: () => _handleEdit(equipment),
                        onDelete: () => _confirmDelete(equipment),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _equipments.length,
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
        title: const Text('จัดการอุปกรณ์'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _refreshing || _initialLoading
                ? null
                : () => _fetchEquipments(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshing ? null : _handleAdd,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มอุปกรณ์'),
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> equipment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EquipmentCard({
    required this.equipment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = equipment['eqpt_name']?.toString() ?? '-';
    final quantityRaw = equipment['eqpt_quantity'];
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
          child: const Icon(Icons.medical_services),
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
