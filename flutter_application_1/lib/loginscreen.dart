import 'package:flutter/material.dart';
import 'registerscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F5FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32),
            Image.asset('assets/logo.png', height: 80), // ใส่โลโก้ของคุณ
            SizedBox(height: 16),
            Text(
              'เรียกเปลคนไข้',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),

            // Email / Phone
            TextField(
              decoration: InputDecoration(
                labelText: 'อีเมลหรือเบอร์โทรศัพท์',
                hintText: 'กรุณากรอกอีเมลหรือเบอร์โทรศัพท์',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Password
            TextField(
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                hintText: 'กรุณากรอกรหัสผ่าน',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 8),

            // Remember password & Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  // children: [
                  //   Checkbox(
                  //     value: rememberMe,
                  //     onChanged: (value) {
                  //       setState(() {
                  //         rememberMe = value!;
                  //       });
                  //     },
                  //   ),
                  //   Text("จำรหัสผ่าน"),
                  // ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Login button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.deepPurple,
              ),
              child: Text(
                'เข้าสู่ระบบ',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            SizedBox(height: 10),

            // register button
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text(
                'ลงทะเบียน',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Terms
            // Text.rich(
            //   TextSpan(
            //     text: 'การสมัครสมาชิก แสดงว่าคุณยอมรับ ',
            //     children: [
            //       TextSpan(
            //         text: 'เงื่อนไขการใช้งาน',
            //         style: TextStyle(color: Colors.deepPurple),
            //       ),
            //       TextSpan(text: ' และ '),
            //       TextSpan(
            //         text: 'นโยบายความเป็นส่วนตัว',
            //         style: TextStyle(color: Colors.deepPurple),
            //       ),
            //     ],
            //   ),
            //   textAlign: TextAlign.center,
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _socialButton(String assetPath) {
  //   return Container(
  //     padding: EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey.shade300),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Image.asset(assetPath, height: 24),
  //   );
  // }
}
