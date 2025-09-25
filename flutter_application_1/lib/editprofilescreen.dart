// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, use_super_parameters, non_constant_identifier_names, deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'design/theme.dart';

import './services/Profile/profile_get_function.dart';
import './services/Profile/profile_update_function.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isLoadingProfile = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });

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
    if (_isSaving) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('id') ?? '';
    if (username.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('��辺�����ż����')));
      }
      return;
    }

    final fname = _fnameController.text.trim();
    final lname = _lnameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ProfileUpdateService.updateProfile(
        username,
        fname: fname,
        lname: lname,
        email: email,
        phone: phone,
        profileImage: _selectedImage,
      );

      final profile = result['profile'] as Map<String, dynamic>? ?? {};
      final updatedImage = profile['profile_image'] as String?;
      final resolvedImage = (updatedImage != null && updatedImage.isNotEmpty)
          ? updatedImage
          : profileImageUrl;

      await prefs.setString('fname_U', profile['fname']?.toString() ?? fname);
      await prefs.setString('lname_U', profile['lname']?.toString() ?? lname);
      await prefs.setString('email_U', profile['email']?.toString() ?? email);
      await prefs.setString('phone_U', profile['phone']?.toString() ?? phone);
      if (resolvedImage != null) {
        await prefs.setString('profile_image', resolvedImage);
      } else {
        await prefs.remove('profile_image');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        profileImageUrl = resolvedImage;
        _selectedImage = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('�ѹ�֡�����������')));

      Navigator.pop(context, {
        'fname_U': prefs.getString('fname_U'),
        'lname_U': prefs.getString('lname_U'),
        'email_U': prefs.getString('email_U'),
        'phone_U': prefs.getString('phone_U'),
        'profile_image': resolvedImage,
      });
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : '�ѹ�֡��������������'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      } else {
        _isSaving = false;
      }
    }
  }

  Future<void> _loadProfile() async {
    if (_isLoadingProfile) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('id') ?? '';
    if (username.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
      });
    } else {
      _isLoadingProfile = true;
    }

    try {
      final profile = await ProfileGetService.fetchProfile(username);
      final fetchedFname = profile['fname']?.toString() ?? '';
      final fetchedLname = profile['lname']?.toString() ?? '';
      final fetchedEmail = profile['email']?.toString() ?? '';
      final fetchedPhone = profile['phone']?.toString() ?? '';
      final fetchedImage = profile['profile_image']?.toString();

      if (mounted) {
        setState(() {
          _fnameController.text = fetchedFname;
          _lnameController.text = fetchedLname;
          _emailController.text = fetchedEmail;
          _phoneController.text = fetchedPhone;
          profileImageUrl = (fetchedImage != null && fetchedImage.isNotEmpty)
              ? fetchedImage
              : null;
        });
      } else {
        _fnameController.text = fetchedFname;
        _lnameController.text = fetchedLname;
        _emailController.text = fetchedEmail;
        _phoneController.text = fetchedPhone;
        profileImageUrl = (fetchedImage != null && fetchedImage.isNotEmpty)
            ? fetchedImage
            : null;
      }

      await prefs.setString('fname_U', fetchedFname);
      await prefs.setString('lname_U', fetchedLname);
      await prefs.setString('email_U', fetchedEmail);
      await prefs.setString('phone_U', fetchedPhone);
      if (fetchedImage != null && fetchedImage.isNotEmpty) {
        await prefs.setString('profile_image', fetchedImage);
      } else {
        await prefs.remove('profile_image');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('��Ŵ��������������')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      } else {
        _isLoadingProfile = false;
      }
    }
  }

  Future<File?> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    return picked != null ? File(picked.path) : null;
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
                          onTap: (_isSaving || _isLoadingProfile)
                              ? null
                              : () async {
                                  final image = await _pickImage();
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
                      _GradientButton(
                        text: "บันทึก",
                        onTap: (_isSaving || _isLoadingProfile)
                            ? null
                            : _saveProfile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving || _isLoadingProfile)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                  child: const Center(child: CircularProgressIndicator()),
                ),
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
