import 'package:flutter/material.dart';
import '../design/theme.dart';
import '../services/admin_function.dart';
import '../services/getEquipments.dart';
import '../services/getStretcher.dart';

class AdminEditCaseScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;
  const AdminEditCaseScreen({super.key, required this.caseData});

  @override
  State<AdminEditCaseScreen> createState() => _AdminEditCaseScreenState();
}

class _AdminEditCaseScreenState extends State<AdminEditCaseScreen> {
  late TextEditingController patientIdController;
  late TextEditingController patientTypeController;
  late TextEditingController receivePointController;
  late TextEditingController sendPointController;

  int? selectedStretcherTypeId;
  String stretcherTypeName = '';
  List<int> selectedEquipmentIds = [];
  String equipmentNames = '';

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.caseData;
    patientIdController = TextEditingController(
      text: data['patient_id']?.toString() ?? '',
    );
    patientTypeController = TextEditingController(
      text: data['patient_type']?.toString() ?? '',
    );
    receivePointController = TextEditingController(
      text: data['room_from']?.toString() ?? '',
    );
    sendPointController = TextEditingController(
      text: data['room_to']?.toString() ?? '',
    );

    selectedStretcherTypeId =
        data['str_type_id']; // This might be null if not returned by getcase initially, but we fixed it
    stretcherTypeName = data['stretcher_type']?.toString() ?? '';

    // Parse equipment IDs
    if (data['equipment_ids'] != null) {
      final idsStr = data['equipment_ids'].toString();
      if (idsStr.isNotEmpty) {
        selectedEquipmentIds = idsStr
            .split(',')
            .map((e) => int.tryParse(e) ?? 0)
            .where((e) => e != 0)
            .toList();
      }
    }
    equipmentNames = data['equipment']?.toString() ?? '';
  }

  @override
  void dispose() {
    patientIdController.dispose();
    patientTypeController.dispose();
    receivePointController.dispose();
    sendPointController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (patientIdController.text.isEmpty ||
        patientTypeController.text.isEmpty ||
        receivePointController.text.isEmpty ||
        sendPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() => isLoading = true);

    final updateData = {
      'patient_id': patientIdController.text,
      'patient_type': patientTypeController.text,
      'room_from': receivePointController.text,
      'room_to': sendPointController.text,
      'str_type_id': selectedStretcherTypeId,
      'equipments': selectedEquipmentIds,
      'notes': '', // Not implemented yet
    };

    final success = await AdminFunction.updateCase(
      widget.caseData['case_id'].toString(),
      updateData,
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกการแก้ไขเรียบร้อย')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการแก้ไข')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'แก้ไขเคส (Admin)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField('หมายเลขผู้ป่วย', patientIdController),
            _buildTextField('ประเภทผู้ป่วย', patientTypeController),
            _buildTextField('จุดรับ', receivePointController),
            _buildTextField('จุดส่ง', sendPointController),
            const SizedBox(height: 16),
            _stretcherSelector(),
            const SizedBox(height: 16),
            _equipmentSelector(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'บันทึกการแก้ไข',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _stretcherSelector() {
    return InkWell(
      onTap: () async {
        final selected = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          builder: (context) => _StretcherList(),
        );
        if (selected != null) {
          setState(() {
            selectedStretcherTypeId = selected['id'];
            stretcherTypeName = selected['type_name'];
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'ประเภทเปล',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stretcherTypeName.isEmpty ? 'เลือกประเภทเปล' : stretcherTypeName,
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _equipmentSelector() {
    return InkWell(
      onTap: () async {
        final selected = await showModalBottomSheet<List<Map<String, dynamic>>>(
          context: context,
          isScrollControlled: true,
          builder: (context) =>
              _EquipmentList(initialSelectedIds: selectedEquipmentIds),
        );
        if (selected != null) {
          setState(() {
            selectedEquipmentIds = selected.map((e) => e['id'] as int).toList();
            equipmentNames = selected.map((e) => e['eqpt_name']).join(', ');
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'อุปกรณ์',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                equipmentNames.isEmpty ? 'เลือกอุปกรณ์' : equipmentNames,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _StretcherList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.5,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: GetStretcher.getStretcherTypes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return ListTile(
                title: Text(item['type_name']),
                onTap: () => Navigator.pop(context, item),
              );
            },
          );
        },
      ),
    );
  }
}

class _EquipmentList extends StatefulWidget {
  final List<int> initialSelectedIds;
  const _EquipmentList({required this.initialSelectedIds});
  @override
  State<_EquipmentList> createState() => _EquipmentListState();
}

class _EquipmentListState extends State<_EquipmentList> {
  List<int> selectedIds = [];

  @override
  void initState() {
    super.initState();
    selectedIds = List.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const Text(
            'เลือกอุปกรณ์',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: GetEquipments.getEquipments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    final id = item['id'];
                    final isSelected = selectedIds.contains(id);
                    return CheckboxListTile(
                      title: Text(item['eqpt_name']),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedIds.add(id);
                          } else {
                            selectedIds.remove(id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // We need to pass back the full objects to update names easily without re-fetching
              // But GetEquipments returns {id, eqpt_name, ...}
              // I'll fetch again or just pass IDs?
              // To update names in parent, I need names.
              // I'll iterate snapshot data to find names matching selectedIds
              final allEquips = await GetEquipments.getEquipments();
              final selectedObjects = allEquips
                  .where((e) => selectedIds.contains(e['id']))
                  .toList();
              Navigator.pop(context, selectedObjects);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}
