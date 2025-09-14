// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, use_super_parameters, non_constant_identifier_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/editprofile_function.dart';
import 'services/updateImage_function.dart';

class EditProfileScreen extends StatefulWidget {
  final String fname;
  final String lname;
  final String email;
  final String phone;
  final String? ImageUrl; // URL จาก server

  const EditProfileScreen({
    Key? key,
    required this.fname,
    required this.lname,
    required this.email,
    required this.phone,
    this.ImageUrl,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fnameController;
  late TextEditingController _lnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  File? _selectedImage; // รูปใหม่จากมือถือ
  String? profileImageUrl; // รูปจาก server

  @override
  void initState() {
    super.initState();
    _fnameController = TextEditingController(text: widget.fname);
    _lnameController = TextEditingController(text: widget.lname);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);

    profileImageUrl = widget.ImageUrl; // โหลดรูปจาก server
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('id') ?? '';

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ไม่พบข้อมูลผู้ใช้")));
      return;
    }

    final profileData = {
      "fname_U": _fnameController.text,
      "lname_U": _lnameController.text,
      "email_U": _emailController.text,
      "phone_U": _phoneController.text,
    };

    // อัปเดตรูปพร้อม profile
    await updateProfileWithImage(
      username,
      profileData.map((k, v) => MapEntry(k, v.toString())),
      _selectedImage,
      EditProfileFunction.baseUrl!,
    ).then((url) {
      if (url != null) {
        setState(() {
          profileImageUrl = url; // อัปเดตรูปจาก server
          _selectedImage = null; // เคลียร์รูปเก่า
        });
        prefs.setString('profile_image', url);
      }
    });

    // อัปเดต SharedPreferences
    await prefs.setString('fname_U', _fnameController.text);
    await prefs.setString('lname_U', _lnameController.text);
    await prefs.setString('email_U', _emailController.text);
    await prefs.setString('phone_U', _phoneController.text);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("บันทึกข้อมูลสำเร็จ")));

    Navigator.pop(context, {
      ...profileData,
      'profile_image': profileImageUrl, // เพิ่มตรงนี้
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขข้อมูล")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: InkWell(
                onTap: () async {
                  final image = await pickImage();
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!) as ImageProvider
                      : (profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null),
                  child: (_selectedImage == null && profileImageUrl == null)
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fnameController,
              decoration: const InputDecoration(
                labelText: "ชื่อ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lnameController,
              decoration: const InputDecoration(
                labelText: "นามสกุล",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "อีเมล",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "เบอร์โทร",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      "ยกเลิก",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("บันทึก"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
