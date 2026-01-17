// ignore_for_file: non_constant_identifier_names, prefer_final_fields, deprecated_member_use, use_build_context_synchronously, avoid_print

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design/theme.dart';

import 'services/regis_functions.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  var _formKey = GlobalKey<FormState>();
  var _idCtrl = TextEditingController();
  var _fnameCtrl = TextEditingController();
  var _lnameCtrl = TextEditingController();
  var _phoneCtrl = TextEditingController();
  var _emailCtrl = TextEditingController();
  var _usernameCtrl = TextEditingController();
  var _passwordCtrl = TextEditingController();
  var _confirmCtrl = TextEditingController();

  int _fieldsIndex = 11;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  String? selectedRole;

  // Role options for dropdown
  final List<Map<String, String>> _roleOptions = [
    {'value': 'porter', 'label': 'พนักงานเปล'},
    {'value': 'nurse', 'label': 'พยาบาล'},
  ];

  late final AnimationController _inCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _inCtrl,
    curve: const Interval(0.00, 0.20, curve: Curves.easeOut),
  );
  late final Animation<Offset> _titleSlide =
      Tween<Offset>(begin: const Offset(0, .20), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _inCtrl,
          curve: const Interval(0.00, 0.20, curve: Curves.easeOutBack),
        ),
      );
  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _inCtrl,
    curve: const Interval(0.12, 0.35, curve: Curves.easeOut),
  );
  late final Animation<Offset> _cardSlide =
      Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _inCtrl,
          curve: const Interval(0.12, 0.35, curve: Curves.easeOutCubic),
        ),
      );
  late final List<Animation<double>> _fades = List.generate(_fieldsIndex + 1, (
    i,
  ) {
    final start = 0.30 + i * 0.06;
    final end = min(0.55 + i * 0.06, 1.0);
    return CurvedAnimation(
      parent: _inCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  });
  late final List<Animation<Offset>> _slides = List.generate(_fieldsIndex + 1, (
    i,
  ) {
    final start = 0.30 + i * 0.06;
    final end = min(0.55 + i * 0.06, 1.0);
    return Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _inCtrl,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ),
    );
  });
  late final Animation<Offset> _shakeOffset = TweenSequence<Offset>([
    TweenSequenceItem(
      tween: Tween(begin: Offset.zero, end: const Offset(0.03, 0)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(begin: const Offset(0.03, 0), end: const Offset(-0.03, 0)),
      weight: 2,
    ),
    TweenSequenceItem(
      tween: Tween(begin: const Offset(-0.03, 0), end: Offset.zero),
      weight: 1,
    ),
  ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();

    // start
    Future.delayed(const Duration(milliseconds: 180), _inCtrl.forward);
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    _shakeCtrl.dispose();
    _idCtrl.dispose();
    _fnameCtrl.dispose();
    _lnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // ตรวจ form
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      _showMsg('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    // ตรวจ role
    if (selectedRole == null || selectedRole!.isEmpty) {
      _shakeCtrl.forward(from: 0);
      _showMsg('กรุณาเลือกประเภทบุคลากร');
      return;
    }

    if (_passwordCtrl.text.length < 6) {
      _shakeCtrl.forward(from: 0);
      _showMsg('รหัสผ่านอย่างน้อย 6 ตัวอักษร');
      return;
    }

    // ตรวจรหัสผ่านตรงกัน
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _shakeCtrl.forward(from: 0);
      _showMsg('รหัสผ่านไม่ตรงกัน');
      return;
    }

    // mock loading
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() => _loading = false);

    // Remove dashes from phone before sending
    final cleanPhone = _phoneCtrl.text.replaceAll('-', '');

    // data เบื้องต้น (user)
    var data = {
      "id_U": _idCtrl.text,
      "fname_U": _fnameCtrl.text,
      "lname_U": _lnameCtrl.text,
      "phone_U": cleanPhone,
      "email_U": _emailCtrl.text,
      "role_U": selectedRole,
      "username": _usernameCtrl.text,
      "password": _passwordCtrl.text,
    };

    final result = await RegisFunctions.addRegistrant(data);
    print(result);
    if (result == 'success') {
      _showMsg('ลงทะเบียนสำเร็จ!');
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      _showMsg(result);
    }
  }

  Future<void> submit() async {
    // ตรวจ form
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      _showMsg('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      _shakeCtrl.forward(from: 0);
      _showMsg('รหัสผ่านอย่างน้อย 6 ตัวอักษร');
      return;
    }
    if (selectedRole == null || selectedRole!.isEmpty) {
      _shakeCtrl.forward(from: 0);
      _showMsg('กรุณาเลือกประเภทบุคลากร');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _shakeCtrl.forward(from: 0);
      _showMsg('รหัสผ่านไม่ตรงกัน');
      return;
    }

    // mock loading
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() => _loading = false);
    _showMsg('ลงทะเบียนสำเร็จ!');
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    // Remove dashes from phone before sending
    final cleanPhone = _phoneCtrl.text.replaceAll('-', '');

    var data = {
      "id_U": _idCtrl.text,
      "fname_U": _fnameCtrl.text,
      "lname_U": _lnameCtrl.text,
      "phone_U": cleanPhone,
      "email_U": _emailCtrl.text,
      "role_U": selectedRole,
      "username": _usernameCtrl.text,
      "password": _passwordCtrl.text,
      // เพิ่มข้อมูลเฉพาะตาม role
      if (selectedRole == "nurse") ...{
        "license_number": '',
        "department": '',
        "position": '',
      },
      if (selectedRole == "porter") ...{
        "shift": '',
        "area": '',
        "position": '',
      },
    };

    final result = await RegisFunctions.addRegistrant(data);
    if (result == 'success') {
      Navigator.pop(context);
    } else {
      _showMsg(result);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const borderRadius = BorderRadius.all(Radius.circular(14));

    final fields = [
      // 1. Role Dropdown (First position) - ใส่ icon ให้แต่ละประเภท
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.work_rounded,
                color: const Color(0xFF1976D2),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'ประเภทบุคลากร',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: borderRadius,
              border: Border.all(
                color: selectedRole != null
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade300,
                width: selectedRole != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: selectedRole?.isEmpty == true ? null : selectedRole,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              hint: Text(
                'เลือกประเภทบุคลากร',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF1976D2),
              ),
              isExpanded: true,
              items: [
                // พนักงานเปล
                DropdownMenuItem<String>(
                  value: 'porter',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Color(0xFF1976D2),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'พนักงานเปล',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // พยาบาล
                DropdownMenuItem<String>(
                  value: 'nurse',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'พยาบาล',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => selectedRole = value);
              },
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'กรุณาเลือกประเภทบุคลากร' : null,
            ),
          ),
        ],
      ),
      // 2. ID Field (digits only, max 10)
      _LabeledField(
        controller: _idCtrl,
        label: 'เลขประจำตัว',
        hint: '',
        icon: Icons.badge_rounded,
        keyboard: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
      ),
      // 3. Name Row (First Name + Last Name)
      Row(
        children: [
          Expanded(
            child: _LabeledField(
              controller: _fnameCtrl,
              label: 'ชื่อ',
              hint: '',
              icon: Icons.person_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LabeledField(
              controller: _lnameCtrl,
              label: 'นามสกุล',
              hint: '',
              icon: Icons.person_outline_rounded,
            ),
          ),
        ],
      ),
      // 4. Phone Field (formatted with dashes)
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เบอร์โทรศัพท์',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            elevation: 0,
            borderRadius: borderRadius,
            child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                _PhoneNumberFormatter(),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'กรุณากรอก เบอร์โทรศัพท์';
                final digits = v.replaceAll('-', '');
                if (digits.length != 10) return 'เบอร์โทรต้องมี 10 หลัก';
                return null;
              },
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.phone_rounded,
                  color: AppTheme.deepPurple.withOpacity(0.7),
                  size: 20,
                ),
                hintText: '',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(
                    color: AppTheme.deepPurple,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(
                    color: Colors.red.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
      // 5. Email Field
      _LabeledField(
        controller: _emailCtrl,
        label: 'อีเมล',
        hint: '',
        keyboard: TextInputType.emailAddress,
        icon: Icons.email_rounded,
        validator: (v) {
          if (v == null || v.isEmpty) return 'กรุณากรอก อีเมล';
          final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
          return ok ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
        },
      ),
      // 6. Username
      _LabeledField(
        controller: _usernameCtrl,
        label: 'ชื่อผู้ใช้',
        hint: '',
        icon: Icons.account_circle_rounded,
      ),
      // 7. Password
      _LabeledPasswordField(
        controller: _passwordCtrl,
        label: 'รหัสผ่าน',
        hint: '',
        obscure: _obscurePassword,
        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        validator: (v) {
          if (v == null || v.isEmpty) return 'กรุณากรอก รหัสผ่าน';
          if (v.length < 6) return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
          return null;
        },
      ),
      // 9. Confirm Password
      _LabeledPasswordField(
        controller: _confirmCtrl,
        label: 'ยืนยันรหัสผ่าน',
        hint: 'กรอกรหัสผ่านอีกครั้ง',
        obscure: _obscureConfirmPassword,
        onToggle: () =>
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        validator: (v) {
          if (v == null || v.isEmpty) return 'กรุณากรอก ยืนยันรหัสผ่าน';
          if (v != _passwordCtrl.text) return 'รหัสผ่านไม่ตรงกัน';
          return null;
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Blue Header - สีพื้นเรียบ user-friendly
            Container(
              color: const Color(0xFF1976D2),
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ลงทะเบียนบุคลากร',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'สร้างบัญชีใหม่',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'กรุณากรอกข้อมูลให้ครบถ้วน',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        for (int i = 0; i < fields.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: fields[i],
                          ),
                        const SizedBox(height: 16),
                        // Submit Button - สีฟ้าพื้น
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'ลงทะเบียน',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- Reusable UI ------------------------- */

/// วงกลมเบลอ ๆ โทนม่วง
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

/// การ์ดใส ๆ แบบ glassmorphism เบา ๆ
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B2EFF).withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// TextField พร้อม label + icon + validation
class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboard;
  final IconData? icon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard,
    this.icon,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(14));

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
        Material(
          elevation: 0,
          borderRadius: borderRadius,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboard,
            validator:
                validator ??
                (v) => (v == null || v.isEmpty) ? 'กรุณากรอก $label' : null,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: AppTheme.deepPurple.withOpacity(0.7),
                      size: 20,
                    )
                  : null,
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(color: AppTheme.deepPurple, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: Colors.red.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password field พร้อมโชว์/ซ่อน + validation
class _LabeledPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _LabeledPasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(14));

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
        Material(
          elevation: 0,
          borderRadius: borderRadius,
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator:
                validator ??
                (v) => (v == null || v.isEmpty) ? 'กรุณากรอก $label' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_rounded,
                color: AppTheme.deepPurple.withOpacity(0.7),
                size: 20,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(color: AppTheme.deepPurple, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: Colors.red.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.deepPurple.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ปุ่ม Gradient ม่วงแบบมินิมอล + กดเด้งเล็กน้อย + แสดงโหลด
class _GradientButton extends StatefulWidget {
  final String text;
  final bool loading;
  final VoidCallback? onTap;

  const _GradientButton({required this.text, this.loading = false, this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.98,
  ).animate(_pressCtrl);

  @override
  Widget build(BuildContext context) {
    final child = widget.loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontSize: 16,
            ),
          );

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null && !widget.loading) _pressCtrl.forward();
      },
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: widget.loading ? null : widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Opacity(
          opacity: widget.loading ? 0.85 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }
}

/// Phone number formatter to add dashes (097-956-7181)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 10; i++) {
      if (i == 3 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
