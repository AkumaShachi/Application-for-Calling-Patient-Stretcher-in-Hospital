import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole = 'พยาบาล';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ลงทะเบียนบุคลากร')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'กรุณากรอกข้อมูลให้ครบถ้วน',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),

                // เลขประจำตัว
                _buildTextField('เลขประจำตัว'),

                // ชื่อ-นามสกุล
                _buildTextField('ชื่อ-นามสกุล'),

                // เบอร์โทรศัพท์
                _buildTextField(
                  'เบอร์โทรศัพท์',
                  keyboardType: TextInputType.phone,
                ),

                // อีเมล
                _buildTextField(
                  'อีเมล',
                  keyboardType: TextInputType.emailAddress,
                ),

                // ตำแหน่ง
                Text('ตำแหน่ง', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'พยาบาล',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                    Text('พยาบาล'),
                    Radio<String>(
                      value: 'เจ้าหน้าที่แปล',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                    Text('เจ้าหน้าที่แปล'),
                  ],
                ),
                SizedBox(height: 16),
                // รหัสเจ้าหน้าที่/พยาบาล
                _buildTextField('รหัสเจ้าหน้าที่/พยาบาล'),

                // ชื่อผู้ใช้
                _buildTextField('ชื่อผู้ใช้'),

                // รหัสผ่าน
                _buildPasswordField('รหัสผ่าน', isConfirm: false),

                // ยืนยันรหัสผ่าน
                _buildPasswordField('ยืนยันรหัสผ่าน', isConfirm: true),

                SizedBox(height: 24),

                // ปุ่มลงทะเบียน
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // ส่งข้อมูล
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('กำลังลงทะเบียน...')),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ลงทะเบียนสำเร็จ!')),
                        );
                        Future.delayed(Duration(seconds: 6), () {
                          Navigator.pop(context);
                        });
                      }
                    },
                    child: Text(
                      'ลงทะเบียน',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
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

  Widget _buildPasswordField(String label, {required bool isConfirm}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(
              isConfirm
                  ? (_obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility)
                  : (_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
            ),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
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
}
