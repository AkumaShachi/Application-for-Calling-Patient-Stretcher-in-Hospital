import 'package:flutter/material.dart';
import 'nurses_screen/nurse_list_case.dart';
import 'registerscreen.dart';
import 'porters_screen/porter_list_case.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool rememberMe = false;
  bool showPassword = false;
  String? value;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    } else if (email == "nurse" && password == "nurse") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NurseListCaseScreen(),
        ), // เปลี่ยน NextScreen เป็นหน้าที่ต้องการ
      );
    } else if (email == "porter" && password == "porter") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PorterCaseListScreen(),
        ), // เปลี่ยน NextScreen เป็นหน้าที่ต้องการ
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F5FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Form(
          key: _formKey,
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

              // UserID
              _buildTextField(
                'ชื่อผู้ใช้',
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
              ),

              // Password
              _buildPasswordField(
                'รหัสผ่าน',
                isConfirm: showPassword,
                controller: passwordController,
              ),

              // Remember password & Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value!;
                          });
                        },
                      ),
                      Text("จำรหัสผ่าน"),
                    ],
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
                onPressed: _login,
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
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty ? 'กรุณากรอก $label' : null,
      ),
    );
  }

  Widget _buildPasswordField(
    String label, {
    required bool isConfirm,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: !isConfirm,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                showPassword = !showPassword;
              });
            },
          ),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty ? 'กรุณากรอก $label' : null,
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
