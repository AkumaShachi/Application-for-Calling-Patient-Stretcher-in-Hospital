import 'dart:async';

import 'package:flutter/material.dart';
import '../loginscreen.dart';
import '../services/getcase_function.dart';
import 'nurse_add_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NurseListCaseScreen extends StatefulWidget {
  const NurseListCaseScreen({super.key});

  @override
  State<NurseListCaseScreen> createState() => _NurseListCaseScreenState();
}

class _NurseListCaseScreenState extends State<NurseListCaseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Timer _timer;

  String fname = '';
  String lname = '';
  String username = '';

  List<Map<String, dynamic>> allCases = [];
  List<Map<String, dynamic>> myCases = [];
  bool loadingAll = true;
  bool loadingMy = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
    _fetchCases(); // เรียกครั้งแรกตอนโหลดหน้าจอ

    // ตั้ง Timer ให้ fetch ข้อมูลทุก 5 วินาทีเพื่อ realtime
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchCases();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fname = prefs.getString('fname_U') ?? '';
      lname = prefs.getString('lname_U') ?? '';
      username = prefs.getString('id') ?? '';
    });
    print('Loaded username: $username');
  }

  Future<void> _fetchCases() async {
    try {
      final fetchedAll = await GetcaseFunction.fetchAllCasesNurse();
      final fetchedMy = await GetcaseFunction.fetchMyCasesNurse(username);

      setState(() {
        allCases = fetchedAll;
        myCases = fetchedMy;
        loadingAll = false;
        loadingMy = false;
      });
    } catch (e) {
      print("Error fetching cases: $e");
    }
  }

  String timeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);

      if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
      if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
      return '${diff.inDays} วันก่อน';
    } catch (e) {
      return createdAt;
    }
  }

  String formatEquipment(dynamic equipment) {
    if (equipment == null) return 'ไม่มี';
    if (equipment is List) return equipment.join(', ');
    if (equipment is String) return equipment;
    return equipment.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("บันทึกเคสผู้ป่วย"),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'เคสทั้งหมด'),
            Tab(text: 'เคสของฉัน'),
          ],
        ),
      ),
      endDrawer: Container(
        width: MediaQuery.of(context).size.width * 0.67,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
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
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('ชื่อผู้ใช้: $fname $lname'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('ออกจากระบบ'),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาเคสผู้ป่วย',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // สามารถเพิ่ม logic search/filter ได้
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                loadingAll
                    ? Center(child: CircularProgressIndicator())
                    : CaseListView(
                        cases: allCases,
                        timeFormatter: timeAgo,
                        formatEquipment: formatEquipment,
                      ),
                loadingMy
                    ? Center(child: CircularProgressIndicator())
                    : CaseListView(
                        cases: myCases,
                        timeFormatter: timeAgo,
                        formatEquipment: formatEquipment,
                      ),
              ],
            ),
          ),
        ],
      ),
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
  final List<Map<String, dynamic>> cases;
  final String Function(String) timeFormatter;
  final String Function(dynamic) formatEquipment;

  const CaseListView({
    super.key,
    required this.cases,
    required this.timeFormatter,
    required this.formatEquipment,
  });

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
                  item["nurse_name"] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeFormatter(item["created_at"] ?? ''),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                infoRow(
                  Icons.confirmation_number,
                  "หมายเลขผู้ป่วย: ${item['patient_id'] ?? ''}",
                ),
                infoRow(
                  Icons.person,
                  "ประเภทผู้ป่วย: ${item['patient_type'] ?? ''}",
                ),
                infoRow(
                  Icons.place,
                  "จุดรับ-ส่ง: ${item['room_from'] ?? ''} → ${item['room_to'] ?? ''}",
                ),
                infoRow(
                  Icons.airline_seat_flat,
                  "ประเภทเปล: ${item['stretcher_type'] ?? ''}",
                ),
                infoRow(
                  Icons.medical_services,
                  "อุปกรณ์เสริม: ${formatEquipment(item['equipment'])}",
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
