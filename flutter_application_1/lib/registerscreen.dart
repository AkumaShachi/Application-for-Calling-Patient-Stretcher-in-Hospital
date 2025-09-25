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
  var _nameCtrl = TextEditingController();
  var _phoneCtrl = TextEditingController();
  var _emailCtrl = TextEditingController();
  var _usernameCtrl = TextEditingController();
  var _passwordCtrl = TextEditingController();
  var _confirmCtrl = TextEditingController();
  var _TokenCtrl = TextEditingController();

  int _fieldsIndex = 10;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  String? selectedRole = '';

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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _TokenCtrl.dispose();
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

    if (_passwordCtrl.text.length < 6) {
      _shakeCtrl.forward(from: 0);
      _showMsg('รหัสผ่านอย่างน้อย 6 ตัวอักษร');
      return;
    }

    // ตรวจ token เพื่อเลือก role
    final token = _TokenCtrl.text.trim();
    switch (token) {
      case '123456':
        selectedRole = 'porter';
        break;
      case '654321':
        selectedRole = 'nurse';
        break;
      case '111111':
        selectedRole = 'admin';
        break;
      default:
        _shakeCtrl.forward(from: 0);
        _showMsg('รหัสพนักงานไม่ถูกต้อง');
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

    final trimmedId = _idCtrl.text.trim();
    final trimmedPhone = _phoneCtrl.text.trim();
    final trimmedEmail = _emailCtrl.text.trim();
    final trimmedUsername = _usernameCtrl.text.trim();
    final trimmedName = _nameCtrl.text.trim();
    final nameParts = trimmedName.isNotEmpty ? trimmedName.split(RegExp(r'\s+')) : <String>[];
    final fname = nameParts.isNotEmpty ? nameParts.first : '';
    final lname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // เตรียมข้อมูลส่งไป backend
    final data = {
      "id_U": trimmedId,
      "fname_U": fname,
      "lname_U": lname,
      "phone_U": trimmedPhone,
      "email_U": trimmedEmail,
      "role_U": selectedRole,
      "username": trimmedUsername,
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



  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fields = [
      _LabeledField(
        controller: _idCtrl,
        label: 'เลขประจำตัว',
        hint: '',
        icon: Icons.badge_rounded,
      ),
      _LabeledField(
        controller: _nameCtrl,
        label: 'ชื่อ-นามสกุล',
        hint: '',
        icon: Icons.person_rounded,
      ),
      _LabeledField(
        controller: _phoneCtrl,
        label: 'เบอร์โทรศัพท์',
        hint: '',
        keyboard: TextInputType.phone,
        icon: Icons.phone_rounded,
      ),
      _LabeledField(
        controller: _emailCtrl,
        label: 'อีเมล',
        hint: '',
        keyboard: TextInputType.emailAddress,
        icon: Icons.alternate_email_rounded,
        validator: (v) {
          if (v == null || v.isEmpty) return 'กรุณากรอก อีเมล';
          final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
          return ok ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
        },
      ),
      _LabeledField(
        controller: _TokenCtrl,
        label: 'รหัสเจ้าหน้าที่/พยาบาล',
        hint: 'รหัสพนักงาน',
        icon: Icons.account_circle_rounded,
      ),
      _LabeledField(
        controller: _usernameCtrl,
        label: 'ชื่อผู้ใช้',
        hint: 'username',
        icon: Icons.account_circle_rounded,
      ),
      _LabeledPasswordField(
        controller: _passwordCtrl,
        label: 'รหัสผ่าน',
        hint: 'อย่างน้อย 6 ตัวอักษร',
        obscure: _obscurePassword,
        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        validator: (v) {
          if (v == null || v.isEmpty) return 'กรุณากรอก รหัสผ่าน';
          if (v.length < 6) return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
          return null;
        },
      ),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: [Color(0xFFF7F5FF), Color(0xFFEDE9FF)],
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
              diameter: 260,
              colors: [
                AppTheme.deepPurple.withOpacity(0.22),
                AppTheme.purple.withOpacity(0.18),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ลงทะเบียนบุคลากร',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              colors: [AppTheme.deepPurple, AppTheme.purple],
                            ).createShader(r),
                            child: const Text(
                              'สร้างบัญชีใหม่',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'กรุณากรอกข้อมูลให้ครบถ้วน',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black87.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _shakeOffset,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _GlassCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                for (int i = 0; i < fields.length; i++)
                                  _animatedField(i, fields[i]),
                                const SizedBox(height: 12),
                                _animatedField(
                                  fields.length,
                                  _GradientButton(
                                    text: 'ลงทะเบียน',
                                    loading: _loading,
                                    onTap: _loading ? null : _submit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: Opacity(opacity: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedField(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(
      position: _slides[i],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: child,
      ),
    ),
  );
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

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard,
    this.icon,
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
            keyboardType: keyboard,
            validator:
                validator ??
                (v) => (v == null || v.isEmpty) ? 'กรุณากรอก $label' : null,
            inputFormatters: keyboard == TextInputType.phone
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: AppTheme.deepPurple)
                  : null,
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(
                  color: AppTheme.lavender,
                  width: 1.2,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(color: AppTheme.deepPurple, width: 1.6),
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
              prefixIcon: const Icon(
                Icons.lock_rounded,
                color: AppTheme.deepPurple,
              ),
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(
                  color: AppTheme.lavender,
                  width: 1.2,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(color: AppTheme.deepPurple, width: 1.6),
              ),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.deepPurple,
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
