import 'dart:ui';
import 'package:flutter/material.dart';

import 'nurses_screen/nurse_list_case.dart';
import 'porters_screen/porter_list_case.dart';
import 'registerscreen.dart';
import 'forgetscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ---------- Logic เดิม ----------
  final _formKey = GlobalKey<FormState>();
  bool rememberMe = false;
  bool showPassword = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    } else if (email == "nurse" && password == "nurse") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NurseListCaseScreen()),
      );
    } else if (email == "porter" && password == "porter") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PorterCaseListScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
      );
    }
  }

  // ---------- UI / Animation ----------
  // โทนสีหลัก
  static const Color kDeepPurple = Color(0xFF5B2EFF);
  static const Color kPurple = Color(0xFF8C6CFF);
  static const Color kLavender = Color(0xFFEDE9FF);

  late final AnimationController _inCtrl; // เข้า
  late final AnimationController _outCtrl; // ออก

  late final Animation<Offset> _logoSlideIn;
  late final Animation<double> _logoFadeIn;
  late final Animation<double> _logoScaleIn;

  late final Animation<Offset> _titleSlideIn;
  late final Animation<double> _titleFadeIn;

  late final Animation<Offset> _logoSlideOut;
  late final Animation<double> _logoFadeOut;
  late final Animation<double> _logoScaleOut;

  late final Animation<Offset> _titleSlideOut;
  late final Animation<double> _titleFadeOut;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    // Animate In
    _inCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    final inCurve = CurvedAnimation(parent: _inCtrl, curve: Curves.easeOutBack);

    _logoSlideIn = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(inCurve);
    _logoFadeIn = CurvedAnimation(parent: _inCtrl, curve: Curves.easeOut);
    _logoScaleIn = Tween<double>(begin: 0.95, end: 1.0).animate(inCurve);

    _titleSlideIn = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(inCurve);
    _titleFadeIn = CurvedAnimation(parent: _inCtrl, curve: Curves.easeOut);

    // Animate Out (เผื่อใช้ภายหลัง)
    _outCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    final outCurve = CurvedAnimation(
      parent: _outCtrl,
      curve: Curves.easeInCubic,
    );

    _logoSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0),
    ).animate(outCurve);
    _logoFadeOut = ReverseAnimation(
      CurvedAnimation(parent: _outCtrl, curve: Curves.easeIn),
    );
    _logoScaleOut = Tween<double>(begin: 1.0, end: 0.98).animate(outCurve);

    _titleSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0),
    ).animate(outCurve);
    _titleFadeOut = ReverseAnimation(
      CurvedAnimation(parent: _outCtrl, curve: Curves.easeIn),
    );

    // หน่วงก่อนเล่นเข้า
    Future.delayed(const Duration(milliseconds: 300), _inCtrl.forward);
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    _outCtrl.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง Gradient โทนม่วง + Soft blobs
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
                kPurple.withOpacity(0.28),
                kDeepPurple.withOpacity(0.18),
              ],
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: _BlurCircle(
              diameter: 260,
              colors: [
                kDeepPurple.withOpacity(0.22),
                kPurple.withOpacity(0.18),
              ],
            ),
          ),

          // เนื้อหา
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // LOGO (animate)
                  AnimatedBuilder(
                    animation: Listenable.merge([_inCtrl, _outCtrl]),
                    builder: (context, _) {
                      final slide = _exiting ? _logoSlideOut : _logoSlideIn;
                      final fade = _exiting ? _logoFadeOut : _logoFadeIn;
                      final scale = _exiting ? _logoScaleOut : _logoScaleIn;

                      return FadeTransition(
                        opacity: fade,
                        child: SlideTransition(
                          position: slide,
                          child: ScaleTransition(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Colors.white, kLavender],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kDeepPurple.withOpacity(0.12),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset('assets/logo.png', height: 64),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // TITLE (animate + gradient text)
                  AnimatedBuilder(
                    animation: Listenable.merge([_inCtrl, _outCtrl]),
                    builder: (context, _) {
                      final slide = _exiting ? _titleSlideOut : _titleSlideIn;
                      final fade = _exiting ? _titleFadeOut : _titleFadeIn;

                      return FadeTransition(
                        opacity: fade,
                        child: SlideTransition(
                          position: slide,
                          child: ShaderMask(
                            shaderCallback:
                                (rect) => const LinearGradient(
                                  colors: [kDeepPurple, kPurple],
                                ).createShader(rect),
                            child: const Text(
                              'เรียกเปลคนไข้',
                              style: TextStyle(
                                color: Colors.white, // ถูก Shader ทับ
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // การ์ดฟอร์ม (Glass)
                  _GlassCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _LabeledTextFormField(
                          controller: emailController,
                          label: 'ชื่อผู้ใช้',
                          hint: 'กรอกชื่อผู้ใช้',
                          keyboard: TextInputType.text,
                          icon: Icons.account_circle_rounded,
                          validator:
                              (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'กรุณากรอก ชื่อผู้ใช้'
                                      : null,
                        ),
                        const SizedBox(height: 14),
                        _LabeledPasswordFormField(
                          controller: passwordController,
                          label: 'รหัสผ่าน',
                          hint: 'กรุณากรอกรหัสผ่าน',
                          obscure: !showPassword,
                          onToggle:
                              () =>
                                  setState(() => showPassword = !showPassword),
                          validator:
                              (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'กรุณากรอก รหัสผ่าน'
                                      : null,
                        ),
                        const SizedBox(height: 8),

                        // Remember + Forgot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged:
                                      (v) => setState(
                                        () => rememberMe = v ?? false,
                                      ),
                                ),
                                const Text('จำรหัสผ่าน'),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForgetScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: kDeepPurple,
                              ),
                              child: const Text('ลืมรหัสผ่าน?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // ปุ่มเข้าสู่ระบบ (Gradient + press scale)
                        _GradientButton(
                          text: 'เข้าสู่ระบบ',
                          onTap: () {
                            // เล่น exit เล็กน้อยเพื่อความลื่นไหล (ไม่บังคับ)
                            setState(() => _exiting = true);
                            _outCtrl.forward().whenComplete(() {
                              if (mounted) _login();
                              // หมายเหตุ: ถ้าอยากให้รัน _login ก่อน แล้วค่อยอนิเมชันออก ให้สลับลำดับได้
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        // ลิงก์สมัคร
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ยังไม่มีบัญชี? ',
                              style: theme.textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                              child: const Text(
                                'ลงทะเบียน',
                                style: TextStyle(
                                  color: kDeepPurple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Terms
                  Opacity(opacity: 0.85),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- UI Helpers -------------------- */

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

/// TextFormField พร้อม label + icon
class _LabeledTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboard;
  final IconData? icon;
  final String? Function(String?)? validator;

  const _LabeledTextFormField({
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
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon:
                icon != null
                    ? Icon(icon, color: _LoginScreenState.kDeepPurple)
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
              borderSide: BorderSide(
                color: _LoginScreenState.kLavender,
                width: 1.2,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: _LoginScreenState.kDeepPurple,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password FormField พร้อมปุ่มโชว์/ซ่อน
class _LabeledPasswordFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _LabeledPasswordFormField({
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
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_rounded,
              color: _LoginScreenState.kDeepPurple,
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
              borderSide: BorderSide(
                color: _LoginScreenState.kLavender,
                width: 1.2,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: _LoginScreenState.kDeepPurple,
                width: 1.6,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
                color: _LoginScreenState.kDeepPurple,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ปุ่ม Gradient ม่วง + กดเด้งเล็กน้อย
class _GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  const _GradientButton({required this.text, this.onTap});

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
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                _LoginScreenState.kDeepPurple,
                _LoginScreenState.kPurple,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _LoginScreenState.kDeepPurple.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontSize: 16,
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
