import 'package:flutter/material.dart';
import 'nurse_add_case.dart';

class NurseListCaseScreen extends StatefulWidget {
  const NurseListCaseScreen({super.key});
  @override
  State<NurseListCaseScreen> createState() => _NurseListCaseScreenState();
}

class _NurseListCaseScreenState extends State<NurseListCaseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  final List<Map<String, String>> allCases = [
    {
      "nurse": "พยาบาล สมศรี",
      "time": "2 นาทีที่แล้ว",
      "caseId": "GE174",
      "type": "ผู้ป่วยฉุกเฉิน",
      "location": "ER - Ward 5B",
      "transferType": "เปลนอน",
      "equipment": "ออกซิเจน, เครื่องวัดความดัน",
    },
    {
      "nurse": "พยาบาล วิภา",
      "time": "15 นาทีที่แล้ว",
      "caseId": "GE175",
      "type": "ผู้ป่วยทั่วไป",
      "location": "OPD - Ward 3A",
      "transferType": "เปลนั่ง",
      "equipment": "ไม่มี",
    },
    {
      "nurse": "พยาบาล รัตนา",
      "time": "1 ชั่วโมงที่แล้ว",
      "caseId": "GE176",
      "type": "ผู้ป่วยวิกฤต",
      "location": "ICU - Ward 4B",
      "transferType": "เปลนอน",
      "equipment": "ออกซิเจน",
    },
    {
      "nurse": "พยาบาล สมศรี",
      "time": "2 นาทีที่แล้ว",
      "caseId": "GE174",
      "type": "ผู้ป่วยฉุกเฉิน",
      "location": "ER - Ward 5B",
      "transferType": "เปลนอน",
      "equipment": "ออกซิเจน, เครื่องวัดความดัน",
    },
    {
      "nurse": "พยาบาล วิภา",
      "time": "15 นาทีที่แล้ว",
      "caseId": "GE175",
      "type": "ผู้ป่วยทั่วไป",
      "location": "OPD - Ward 3A",
      "transferType": "เปลนั่ง",
      "equipment": "ไม่มี",
    },
    {
      "nurse": "พยาบาล รัตนา",
      "time": "1 ชั่วโมงที่แล้ว",
      "caseId": "GE176",
      "type": "ผู้ป่วยวิกฤต",
      "location": "ICU - Ward 4B",
      "transferType": "เปลนอน",
      "equipment": "ออกซิเจน",
    },
    {
      "nurse": "พยาบาล สมศรี",
      "time": "2 นาทีที่แล้ว",
      "caseId": "GE174",
      "type": "ผู้ป่วยฉุกเฉิน",
      "location": "ER - Ward 5B",
      "transferType": "เปลนอน",
      "equipment": "ออกซิเจน, เครื่องวัดความดัน",
    },
    {
      "nurse": "พยาบาล วิภา",
      "time": "15 นาทีที่แล้ว",
      "caseId": "GE175",
      "type": "ผู้ป่วยทั่วไป",
      "location": "OPD - Ward 3A",
      "transferType": "เปลนั่ง",
      "equipment": "ไม่มี",
    },
    {
      "nurse": "พยาบาล รัตนา",
      "time": "1 ชั่วโมงที่แล้ว",
      "caseId": "GE176",
      "type": "ผู้ป่วยวิกฤต",
      "location": "ICU - Ward 4B",
      "transferType": "เปลนอน",
      "equipment": "ออกซิเจน",
    },
  ];

  final List<Map<String, String>> myCases = [
    {
      "nurse": "พยาบาล สมศรี",
      "time": "2 นาทีที่แล้ว",
      "caseId": "GE177",
      "type": "ผู้ป่วยฉุกเฉิน",
      "location": "ER - Ward 5B",
      "transferType": "เปลนอน",
      "equipment": "ออกซิเจน, เครื่องวัดความดัน",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("บันทึกเคสผู้ป่วย"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'เคสทั้งหมด'), Tab(text: 'เคสของฉัน')],
        ),
      ),
      body: Column(
        children: [
          // ✅ ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาเคสผู้ป่วย',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // เพิ่ม logic ค้นหา ถ้าต้องการ
              },
            ),
          ),
          // ✅ Tab content ที่แสดง case
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CaseListView(cases: allCases),
                CaseListView(cases: myCases),
              ],
            ),
          ),
        ],
      ),
      // ✅ ปุ่มไมค์
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NurseAddCaseScreen()),
          );
        },
        child: const Icon(Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CaseListView extends StatelessWidget {
  final List<Map<String, String>> cases;

  const CaseListView({super.key, required this.cases});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: cases.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final item = cases[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["nurse"] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  item["time"] ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                infoRow(
                  Icons.confirmation_number,
                  "หมายเลขผู้ป่วย: ${item['caseId']}",
                ),
                infoRow(Icons.person, "ประเภทผู้ป่วย: ${item['type']}"),
                infoRow(Icons.place, "จุดรับ-ส่ง: ${item['location']}"),
                infoRow(
                  Icons.airline_seat_flat,
                  "ประเภทเปล: ${item['transferType']}",
                ),
                infoRow(
                  Icons.medical_services,
                  "อุปกรณ์เสริม: ${item['equipment']}",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
