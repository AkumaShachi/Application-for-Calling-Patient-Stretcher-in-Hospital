// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, use_super_parameters, non_constant_identifier_names, deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design/theme.dart';

import 'services/editprofile_function.dart';
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

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  late TextEditingController _fnameController;
  late TextEditingController _lnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  File? _selectedImage;
  String? profileImageUrl;

  late final AnimationController _inCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  late final Animation<Offset> _titleSlide = Tween<Offset>(
    begin: const Offset(-1.2, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _inCtrl, curve: Curves.easeOutBack));

  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _inCtrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _fnameController = TextEditingController(text: widget.fname);
    _lnameController = TextEditingController(text: widget.lname);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    profileImageUrl = widget.ImageUrl;

    Future.delayed(const Duration(milliseconds: 300), _inCtrl.forward);
  }

  @override
  void dispose() {
    _inCtrl.dispose();
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

    await updateProfileWithImage(
      username,
      profileData.map((k, v) => MapEntry(k, v.toString())),
      _selectedImage,
      EditProfileFunction.baseUrl!,
    ).then((url) {
      if (url != null) {
        setState(() {
          profileImageUrl = url;
          _selectedImage = null;
        });
        prefs.setString('profile_image', url);
      }
    });

    await prefs.setString('fname_U', _fnameController.text);
    await prefs.setString('lname_U', _lnameController.text);
    await prefs.setString('email_U', _emailController.text);
    await prefs.setString('phone_U', _phoneController.text);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("บันทึกข้อมูลสำเร็จ")));

    Navigator.pop(context, {...profileData, 'profile_image': profileImageUrl});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง gradient + blur circle
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  AppTheme.lavender,
                ],
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -30,
            child: _BlurCircle(
              diameter: 220,
              colors: [
                AppTheme.purple.withOpacity(0.28),
                AppTheme.deepPurple.withOpacity(0.18),
              ],
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: _BlurCircle(
              diameter: 220,
              colors: [
                AppTheme.purple.withOpacity(0.28),
                AppTheme.deepPurple.withOpacity(0.18),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
            child: Column(
              children: [
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [AppTheme.deepPurple, AppTheme.purple],
                      ).createShader(rect),
                      child: const Text(
                        'แก้ไขข้อมูลส่วนตัว',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _GlassCard(
                  child: Column(
                    children: [
                      Center(
                        child: InkWell(
                          onTap: () async {
                            final image = await pickImage();
                            if (image != null) {
                              setState(() => _selectedImage = image);
                            }
                          },
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (profileImageUrl != null
                                      ? NetworkImage(profileImageUrl!)
                                      : null),
                            child:
                                (_selectedImage == null &&
                                    profileImageUrl == null)
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildField("ชื่อ", _fnameController),
                      const SizedBox(height: 16),
                      _buildField("นามสกุล", _lnameController),
                      const SizedBox(height: 16),
                      _buildField(
                        "อีเมล",
                        _emailController,
                        keyboard: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        "เบอร์โทร",
                        _phoneController,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 28),
                      _GradientButton(text: "บันทึก", onTap: _saveProfile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.lavender, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.deepPurple, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/* ----- ใช้ helpers เดิมจาก LoginScreen ----- */

class _BlurCircle extends StatelessWidget {
  final double diameter;
  final List<Color> colors;
  const _BlurCircle({required this.diameter, required this.colors});
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _GradientButton({required this.text, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [AppTheme.deepPurple, AppTheme.purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepPurple.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
