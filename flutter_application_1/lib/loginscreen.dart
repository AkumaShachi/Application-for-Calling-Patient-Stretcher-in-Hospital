// ignore_for_file: unused_field, deprecated_member_use

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
  final _formKey = GlobalKey<FormState>();
  bool rememberMe = false, showPassword = false, _exiting = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  static const Color kDeepPurple = Color(0xFF5B2EFF);
  static const Color kPurple = Color(0xFF8C6CFF);
  static const Color kLavender = Color(0xFFEDE9FF);

  late final AnimationController _inCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final AnimationController _outCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<Offset> _logoSlide = Tween<Offset>(
    begin: const Offset(-1.2, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _inCtrl, curve: Curves.easeOutBack));
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _inCtrl,
    curve: Curves.easeOut,
  );
  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.95,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _inCtrl, curve: Curves.easeOutBack));
  late final Animation<Offset> _titleSlide = _logoSlide;
  late final Animation<double> _titleFade = _logoFade;

  @override
  void initState() {
    super.initState();
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

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMsg('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }
    if (email == "nurse" && password == "nurse") {
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
      _showMsg('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fields = [
      _buildField(
        label: 'ชื่อผู้ใช้',
        hint: 'กรอกชื่อผู้ใช้',
        controller: emailController,
        icon: Icons.account_circle_rounded,
        validator:
            (v) => (v == null || v.isEmpty) ? 'กรุณากรอก ชื่อผู้ใช้' : null,
      ),
      _buildField(
        label: 'รหัสผ่าน',
        hint: 'กรุณากรอกรหัสผ่าน',
        controller: passwordController,
        icon: Icons.lock_rounded,
        obscure: !showPassword,
        onToggle: () => setState(() => showPassword = !showPassword),
        validator:
            (v) => (v == null || v.isEmpty) ? 'กรุณากรอก รหัสผ่าน' : null,
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
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: ScaleTransition(
                        scale: _logoScale,
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
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: ShaderMask(
                        shaderCallback:
                            (rect) => const LinearGradient(
                              colors: [kDeepPurple, kPurple],
                            ).createShader(rect),
                        child: const Text(
                          'เรียกเปลคนไข้',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _GlassCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        for (final field in fields) ...[
                          field,
                          const SizedBox(height: 14),
                        ],
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
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ForgetScreen(),
                                    ),
                                  ),
                              style: TextButton.styleFrom(
                                foregroundColor: kDeepPurple,
                              ),
                              child: const Text('ลืมรหัสผ่าน?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _GradientButton(
                          text: 'เข้าสู่ระบบ',
                          onTap: () {
                            setState(() => _exiting = true);
                            _outCtrl.forward().whenComplete(() {
                              if (mounted) _login();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
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
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: kDeepPurple) : null,
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kLavender, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kDeepPurple, width: 1.6),
            ),
            suffixIcon:
                onToggle != null
                    ? IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                        color: kDeepPurple,
                      ),
                    )
                    : null,
          ),
        ),
      ],
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
