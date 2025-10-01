import 'package:flutter/material.dart';

import 'admin_list_case.dart';
import 'admin_list_historycase.dart';
import 'admin_stretcher.dart';
import 'admin_equipments.dart';
import 'admin_list_nurse.dart';
import 'admin_list_porter.dart';

class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_AdminMenuItemConfig>[
      _AdminMenuItemConfig(
        title: 'พนักงาน',
        subtitle: 'จัดการบุคลากร',
        icon: Icons.people_alt,
        color: Colors.indigo,
        options: [
          _MenuOption(
            label: 'พยาบาล',
            description: 'ดูรายชื่อพยาบาลทั้งหมด',
            builder: (context) => const AdminListNurseScreen(),
          ),
          _MenuOption(
            label: 'เจ้าหน้าที่',
            description: 'ดูรายชื่อเจ้าหน้าที่เวรเปล',
            builder: (context) => const AdminListPorterScreen(),
          ),
        ],
      ),
      _AdminMenuItemConfig(
        title: 'เคส',
        subtitle: 'สถานะการรับ-ส่งผู้ป่วย',
        icon: Icons.assignment,
        color: Colors.teal,
        options: [
          _MenuOption(
            label: 'ที่มีอยู่ปัจจุบัน',
            description: 'รายการเคสที่กำลังดำเนินอยู่',
            builder: (context) => const AdminListCaseScreen(),
          ),
          _MenuOption(
            label: 'ที่เสร็จแล้ว',
            description: 'ประวัติเคสที่ปิดงานแล้ว',
            builder: (context) => const AdminListHistoryCaseScreen(),
          ),
        ],
      ),
      _AdminMenuItemConfig(
        title: 'อุปกรณ์',
        subtitle: 'ดูและจัดการทรัพยากร',
        icon: Icons.medical_services,
        color: Colors.deepOrange,
        options: [
          _MenuOption(
            label: 'อุปกรณ์',
            description: 'รายการเครื่องมือและอุปกรณ์ทั้งหมด',
            builder: (context) => const AdminEquipmentsScreen(),
          ),
          _MenuOption(
            label: 'เปลผู้ป่วย',
            description: 'รายการเปลที่พร้อมใช้งาน',
            builder: (context) => const AdminStretcherScreen(),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('เมนูผู้ดูแลระบบ'), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return _AdminMenuCard(config: item);
        },
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({required this.config});

  final _AdminMenuItemConfig config;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: config.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOptionsDialog(context, config),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: config.color.withOpacity(0.2),
                child: Icon(config.icon, color: config.color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      config.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_right,
                size: 32,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOptionsDialog(
    BuildContext context,
    _AdminMenuItemConfig config,
  ) async {
    final selected = await showDialog<_MenuOption>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(config.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: config.options
                  .map(
                    (option) => ListTile(
                      title: Text(option.label),
                      subtitle: option.description != null
                          ? Text(option.description!)
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(dialogContext).pop(option),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );

    if (selected == null) {
      return;
    }

    if (selected.builder != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: selected.builder!));
    }
  }
}

class _AdminMenuItemConfig {
  const _AdminMenuItemConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.options,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_MenuOption> options;
}

class _MenuOption {
  const _MenuOption({required this.label, this.description, this.builder});

  final String label;
  final String? description;
  final WidgetBuilder? builder;
}

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'ฟีเจอร์กำลังอยู่ระหว่างการพัฒนา',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'โปรดกลับมาใหม่อีกครั้งเร็วๆ นี้',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
