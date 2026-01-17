import 'package:flutter/material.dart';
import '../services/stretcher_equipment_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> stretcherTypes = [];
  List<Map<String, dynamic>> equipments = [];
  bool isLoading = true;

  // Colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    final stretchers = await StretcherEquipmentService.fetchStretcherTypes();
    final eqs = await StretcherEquipmentService.fetchEquipments();
    setState(() {
      stretcherTypes = stretchers;
      equipments = eqs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'จัดการข้อมูลพื้นฐาน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.local_hospital_rounded), text: 'ประเภทเปล'),
            Tab(icon: Icon(Icons.medical_services_rounded), text: 'อุปกรณ์'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : TabBarView(
              controller: _tabController,
              children: [_buildStretcherTab(), _buildEquipmentTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'เพิ่มประเภทเปล' : 'เพิ่มอุปกรณ์',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStretcherTab() {
    if (stretcherTypes.isEmpty) {
      return _buildEmptyState(
        'ยังไม่มีประเภทเปล',
        Icons.local_hospital_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stretcherTypes.length,
        itemBuilder: (context, index) {
          final item = stretcherTypes[index];
          return _buildItemCard(
            id: item['id']?.toString() ?? '',
            name: item['type_name'] ?? '',
            quantity: item['quantity'] ?? 0,
            icon: Icons.local_hospital_rounded,
            isStretcher: true,
          );
        },
      ),
    );
  }

  Widget _buildEquipmentTab() {
    if (equipments.isEmpty) {
      return _buildEmptyState(
        'ยังไม่มีอุปกรณ์',
        Icons.medical_services_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: equipments.length,
        itemBuilder: (context, index) {
          final item = equipments[index];
          return _buildItemCard(
            id: item['id']?.toString() ?? '',
            name: item['equipment_name'] ?? '',
            quantity: item['quantity'] ?? 0,
            icon: Icons.medical_services_rounded,
            isStretcher: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม + เพื่อเพิ่มใหม่',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({
    required String id,
    required String name,
    required int quantity,
    required IconData icon,
    required bool isStretcher,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryBlue, size: 24),
          ),
          const SizedBox(width: 14),

          // Name & Quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'จำนวน: $quantity',
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

          // Edit Button
          IconButton(
            onPressed: () => _showEditDialog(id, name, quantity, isStretcher),
            icon: Icon(Icons.edit_rounded, color: primaryBlue, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: primaryBlue.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delete Button
          IconButton(
            onPressed: () => _showDeleteDialog(id, name, isStretcher),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade400,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final bool isStretcher = _tabController.index == 0;
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isStretcher
                    ? Icons.local_hospital_rounded
                    : Icons.medical_services_rounded,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Text(isStretcher ? 'เพิ่มประเภทเปล' : 'เพิ่มอุปกรณ์'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isStretcher ? 'ชื่อประเภทเปล' : 'ชื่ออุปกรณ์',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.label_rounded, color: primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'จำนวน',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.numbers_rounded, color: primaryBlue),
              ),
            ),
          ],
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
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  quantityController.text.isEmpty)
                return;

              Navigator.pop(context);
              final qty = int.tryParse(quantityController.text) ?? 0;

              bool success;
              if (isStretcher) {
                success = await StretcherEquipmentService.addStretcherType(
                  nameController.text,
                  qty,
                );
              } else {
                success = await StretcherEquipmentService.addEquipment(
                  nameController.text,
                  qty,
                );
              }

              if (success) {
                _fetchData();
                _showSnackBar('เพิ่มสำเร็จ', Colors.green);
              } else {
                _showSnackBar('เกิดข้อผิดพลาด', Colors.red);
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('เพิ่ม'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    String id,
    String currentName,
    int currentQty,
    bool isStretcher,
  ) {
    final nameController = TextEditingController(text: currentName);
    final quantityController = TextEditingController(
      text: currentQty.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_rounded, color: primaryBlue),
            ),
            const SizedBox(width: 12),
            const Text('แก้ไข'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isStretcher ? 'ชื่อประเภทเปล' : 'ชื่ออุปกรณ์',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.label_rounded, color: primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'จำนวน',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.numbers_rounded, color: primaryBlue),
              ),
            ),
          ],
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
            onPressed: () async {
              Navigator.pop(context);
              final qty = int.tryParse(quantityController.text) ?? 0;

              bool success;
              if (isStretcher) {
                success = await StretcherEquipmentService.updateStretcherType(
                  id,
                  nameController.text,
                  qty,
                );
              } else {
                success = await StretcherEquipmentService.updateEquipment(
                  id,
                  nameController.text,
                  qty,
                );
              }

              if (success) {
                _fetchData();
                _showSnackBar('แก้ไขสำเร็จ', Colors.green);
              } else {
                _showSnackBar('เกิดข้อผิดพลาด', Colors.red);
              }
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('บันทึก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id, String name, bool isStretcher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 12),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: Text('คุณต้องการลบ "$name" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              bool success;
              if (isStretcher) {
                success = await StretcherEquipmentService.deleteStretcherType(
                  id,
                );
              } else {
                success = await StretcherEquipmentService.deleteEquipment(id);
              }

              if (success) {
                _fetchData();
                _showSnackBar('ลบสำเร็จ', Colors.green);
              } else {
                _showSnackBar(
                  'ไม่สามารถลบได้ (อาจมีเคสที่ใช้งานอยู่)',
                  Colors.red,
                );
              }
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('ลบ'),
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
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
