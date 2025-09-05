// ignore_for_file: library_private_types_in_public_api, sized_box_for_whitespace, avoid_print

import 'package:flutter/material.dart';
import '../loginscreen.dart';
import 'porter_case_detail.dart';

class PorterCaseListScreen extends StatefulWidget {
  const PorterCaseListScreen({super.key});

  @override
  _PorterCaseListScreeState createState() => _PorterCaseListScreeState();
}

class _PorterCaseListScreeState extends State<PorterCaseListScreen> {
  int selectedTabIndex = 0;
  final List<String> tabs = [
    'ทั้งหมด',
    'รอรับเคส',
    'กำลังดำเนินการ',
    'เสร็จสิ้น',
  ];
  final List<Map<String, dynamic>> allCases = [
    {
      'id': 'GE174',
      'type': 'ผู้ป่วยฉุกเฉิน',
      'location': 'ตึก OPD - Ward 5A',
      'floor': 'ชั้น 5',
      'status': 'รอรับเคส',
      'time': '10:30',
    },
    {
      'id': 'GE175',
      'type': 'นอนพัก',
      'location': 'ตึก OPD - Ward 3A',
      'floor': 'ชั้น 3',
      'status': 'รอรับเคส',
      'time': '11:15',
    },
    {
      'id': 'ER150',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A2',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '10:30',
    },
    {
      'id': 'ER151',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A1',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '11:15',
    },
    {
      'id': 'GE174',
      'type': 'ผู้ป่วยฉุกเฉิน',
      'location': 'ตึก OPD - Ward 5A',
      'floor': 'ชั้น 5',
      'status': 'รอรับเคส',
      'time': '10:30',
    },
    {
      'id': 'GE175',
      'type': 'นอนพัก',
      'location': 'ตึก OPD - Ward 3A',
      'floor': 'ชั้น 3',
      'status': 'รอรับเคส',
      'time': '11:15',
    },
    {
      'id': 'ER150',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A2',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '10:30',
    },
    {
      'id': 'ER151',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A1',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '11:15',
    },
    {
      'id': 'GE174',
      'type': 'ผู้ป่วยฉุกเฉิน',
      'location': 'ตึก OPD - Ward 5A',
      'floor': 'ชั้น 5',
      'status': 'รอรับเคส',
      'time': '10:30',
    },
    {
      'id': 'GE175',
      'type': 'นอนพัก',
      'location': 'ตึก OPD - Ward 3A',
      'floor': 'ชั้น 3',
      'status': 'รอรับเคส',
      'time': '11:15',
    },
    {
      'id': 'ER150',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A2',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '10:30',
    },
    {
      'id': 'ER151',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A1',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '11:15',
    },
    {
      'id': 'GE174',
      'type': 'ผู้ป่วยฉุกเฉิน',
      'location': 'ตึก OPD - Ward 5A',
      'floor': 'ชั้น 5',
      'status': 'รอรับเคส',
      'time': '10:30',
    },
    {
      'id': 'GE175',
      'type': 'นอนพัก',
      'location': 'ตึก OPD - Ward 3A',
      'floor': 'ชั้น 3',
      'status': 'รอรับเคส',
      'time': '11:15',
    },
    {
      'id': 'ER150',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A2',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '10:30',
    },
    {
      'id': 'ER151',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A1',
      'floor': 'ชั้น 1',
      'status': 'กำลังดำเนินการ',
      'time': '11:15',
    },
    {
      'id': 'ER151',
      'type': 'ฉุกเฉิน',
      'location': 'ห้องฉุกเฉิน A1',
      'floor': 'ชั้น 1',
      'status': 'เสร็จสิ้น',
      'time': '11:15',
    },
  ];

  List<Map<String, dynamic>> get filteredCases {
    if (selectedTabIndex == 0) {
      // "ทั้งหมด" ยกเว้นสถานะ "เสร็จสิ้น"
      return allCases.where((c) => c['status'] != 'เสร็จสิ้น').toList();
    }
    return allCases
        .where((c) => c['status'] == tabs[selectedTabIndex])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการเคส'),
        automaticallyImplyLeading: false,
      ),
      endDrawer: Container(
        width: MediaQuery.of(context).size.width * 0.67, // 2/3 หน้าจอ
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // แทนที่จะใช้ DrawerHeader ลองใช้ Container + Padding
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 175,
                      height: 175,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, size: 80, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('ชื่อผู้ใช้: พนักงานเปลคนไข้'),
                    ),
                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('ออกจากระบบ'),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedTabIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabIndex = index;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final item = filteredCases[index];
                return buildCaseCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCaseCard(Map<String, dynamic> item) {
    final isWaiting = item['status'] == 'รอรับเคส';
    final isProcessing = item['status'] == 'กำลังดำเนินการ';
    final isFinishing = item['status'] == 'เสร็จสิ้น';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// แถวบน: สถานะและเวลา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isWaiting
                            ? Colors.pink.shade100
                            : isFinishing
                            ? Colors.green.shade100
                            : Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item['status'],
                    style: TextStyle(
                      color:
                          isWaiting
                              ? Colors.red
                              : isFinishing
                              ? Colors.green
                              : Colors.yellow.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  item['time'],
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            SizedBox(height: 8),

            /// รหัสเคส
            Text(
              item['id'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),

            /// รายละเอียดเคส
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'ประเภทผู้ป่วย: ',
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextSpan(
                    text: item['type'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2),
            Text(
              'จุดรับ-ส่ง: ${item['location']} - ${item['floor']}',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 8),

            /// แถวล่าง: ลิงก์ดูรายละเอียด + ปุ่ม
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PorterCaseDetailScreen(),
                      ),
                    );
                    print('ดูรายละเอียด ${item['id']}');
                  },
                  child: Text(
                    'ดูรายละเอียด',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                if (isWaiting)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: Text('รับเคส'),
                  ),
                if (isProcessing)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: Text('เสร็จสิ้น'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
