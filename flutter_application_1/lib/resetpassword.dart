// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'services/forget_functions.dart';
import 'services/reset_functions.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final tokenController = TextEditingController();
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  Timer? _emailLockTimer;
  bool _emailSent = false;
  int _emailLockSeconds = 0;

  // โทนสีหลัก
  static const Color kDeepPurple = Color(0xFF5B2EFF);
  static const Color kPurple = Color(0xFF8C6CFF);
  static const Color kLavender = Color(0xFFEDE9FF);

  // --------- Animations ----------
  late final AnimationController _inCtrl; // entrance (stagger)
  late final AnimationController _shakeCtrl; // error shake

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  late final List<Animation<double>> _fieldFades;
  late final List<Animation<Offset>> _fieldSlides;

  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  late final Animation<Offset> _shakeOffset;

  @override
  void initState() {
    super.initState();

    // Staggered entrance: 0.0 -> 1.0 timeline
    _inCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Title
    _titleFade = CurvedAnimation(
      parent: _inCtrl,
      curve: const Interval(0.00, 0.25, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _inCtrl,
            curve: const Interval(0.00, 0.25, curve: Curves.easeOutBack),
          ),
        );

    // Card
    _cardFade = CurvedAnimation(
      parent: _inCtrl,
      curve: const Interval(0.15, 0.40, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _inCtrl,
            curve: const Interval(0.15, 0.40, curve: Curves.easeOutCubic),
          ),
        );

    // Fields (token, email, new, confirm) stagger
    _fieldFades = List.generate(
      4,
      (i) => CurvedAnimation(
        parent: _inCtrl,
        curve: Interval(
          0.35 + i * 0.08,
          0.60 + i * 0.08,
          curve: Curves.easeOut,
        ),
      ),
    );
    _fieldSlides = List.generate(
      4,
      (i) =>
          Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _inCtrl,
              curve: Interval(
                0.35 + i * 0.08,
                0.60 + i * 0.08,
                curve: Curves.easeOutBack,
              ),
            ),
          ),
    );

    // Button
    _buttonFade = CurvedAnimation(
      parent: _inCtrl,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _inCtrl,
            curve: const Interval(0.65, 0.95, curve: Curves.easeOutBack),
          ),
        );

    // Shake for error
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeOffset = TweenSequence<Offset>([
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

    // start
    Future.delayed(const Duration(milliseconds: 150), _inCtrl.forward);
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    _shakeCtrl.dispose();
    tokenController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _emailLockTimer?.cancel();
    super.dispose();
  }

  Future<bool> _sendReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกอีเมลก่อน")));
      return false;
    }

    try {
      final result = await ForgetFunctions.sendResetEmail(email);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เกิดข้อผิดพลาดในการส่งอีเมล")),
        );
        return false;
      } else if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ส่งรหัสรีเซ็ตไปยัง $email สำเร็จ")),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ส่งอีเมลไม่สำเร็จ: ${result['error']}")),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาด โปรดลองอีกครั้ง")),
      );
      return false;
    }
  }

  void _resetPassword() async {
    final token = tokenController.text.trim();
    final email = emailController.text.trim();
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (token.isEmpty || email.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _shakeCtrl.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }
    // เช็ครูปแบบรหัสผ่าน
    // อย่างน้อย 8 ตัวอักษร, ตัวเลข, ตัวอักษรพิเศษ, ตัวพิมพ์ใหญ่-เล็ก
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$',
    );

    if (!passwordRegex.hasMatch(newPass)) {
      _shakeCtrl.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร, ตัวเลข, ตัวอักษรพิเศษ และตัวพิมพ์ใหญ่-เล็ก',
          ),
        ),
      );
      return;
    }

    // เช็คว่ารหัสผ่านตรงกับยืนยันรหัสผ่าน
    if (newPass != confirm) {
      _shakeCtrl.forward(from: 0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')));
      return;
    }

    setState(() => _loading = true);

    final resetpass = {
      "token": token,
      "email": email,
      "new_password": newPass,
      "confirm_password": confirm,
    };

    // await backend call
    final result = await ResetFunctions.resetPassword(resetpass);

    setState(() => _loading = false);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด โปรดลองอีกครั้ง')),
      );
    } else if (result['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รีเซ็ตรหัสผ่านสำเร็จ')));
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('รีเซ็ตรหัสผ่านไม่สำเร็จ: ${result['error']}')),
      );
    }
  }

  void _onSendPressed() async {
    if (_emailSent) return;
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกอีเมลก่อน")));
      return;
    }

    // เริ่มล็อก UI ทันทีแล้วค่อยเรียกส่ง — หากส่งไม่สำเร็จให้ยกเลิกล็อก
    _startEmailLock(minutes: 30);

    final success = await _sendReset();
    if (!success) {
      // ยกเลิกล็อกถ้าเกิดข้อผิดพลาด
      _emailLockTimer?.cancel();
      if (mounted) {
        setState(() {
          _emailSent = false;
          _emailLockSeconds = 0;
        });
      }
    }
  }

  void _startEmailLock({int minutes = 30}) {
    _emailLockTimer?.cancel();
    setState(() {
      _emailSent = true;
      _emailLockSeconds = minutes * 60;
    });
    _emailLockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _emailLockSeconds--;
        if (_emailLockSeconds <= 0) {
          _emailLockTimer?.cancel();
          _emailSent = false;
          _emailLockSeconds = 0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: [Color(0xFFF7F5FF), Color(0xFFEDE9FF)],
              ),
            ),
          ),

          // Soft blobs
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // back + title bar
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: kDeepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kDeepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title animated
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              colors: [kDeepPurple, kPurple],
                            ).createShader(r),
                            child: const Text(
                              'สร้างรหัสผ่านใหม่',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'กรอกโทเค็นรีเซ็ตจากอีเมลของคุณและตั้งรหัสผ่านใหม่',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card with shake on error
                  SlideTransition(
                    position: _shakeOffset,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _GlassCard(
                          child: Column(
                            children: [
                              // Email
                              FadeTransition(
                                opacity: _fieldFades[1],
                                child: SlideTransition(
                                  position: _fieldSlides[1],
                                  child: _LabeledField(
                                    controller: emailController,
                                    label: "อีเมล",
                                    hint: "example@mail.com",
                                    icon: Icons.email_outlined,
                                    keyboard: TextInputType.emailAddress,
                                    suffix: _emailSent
                                        ? null
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4.0,
                                            ),
                                            child: TextButton(
                                              onPressed: _onSendPressed,
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                backgroundColor:
                                                    _ResetPasswordScreenState
                                                        .kDeepPurple,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text(
                                                'ส่ง',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Token
                              FadeTransition(
                                opacity: _fieldFades[0],
                                child: SlideTransition(
                                  position: _fieldSlides[0],
                                  child: _LabeledField(
                                    controller: tokenController,
                                    label: "รหัสรีเซ็ต",
                                    hint: "กรอกโทเค็นรีเซ็ตจากอีเมล",
                                    icon: Icons.vpn_key,
                                    suffix: IconButton(
                                      icon: const Icon(
                                        Icons.content_copy,
                                        color: kDeepPurple,
                                      ),
                                      onPressed: () {
                                        // copy token to clipboard
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // New Password
                              FadeTransition(
                                opacity: _fieldFades[2],
                                child: SlideTransition(
                                  position: _fieldSlides[2],
                                  child: _LabeledPasswordField(
                                    controller: newPasswordController,
                                    label: "รหัสผ่านใหม่",
                                    hint: "อย่างน้อย 8 ตัว",
                                    obscure: _obscureNew,
                                    onToggle: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Confirm
                              FadeTransition(
                                opacity: _fieldFades[3],
                                child: SlideTransition(
                                  position: _fieldSlides[3],
                                  child: _LabeledPasswordField(
                                    controller: confirmPasswordController,
                                    label: "ยืนยันรหัสผ่าน",
                                    hint: "กรอกรหัสผ่านอีกครั้ง",
                                    obscure: _obscureConfirm,
                                    onToggle: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Button with AnimatedSwitcher for loading
                              FadeTransition(
                                opacity: _buttonFade,
                                child: SlideTransition(
                                  position: _buttonSlide,
                                  child: _GradientButton(
                                    text: 'รีเซ็ตรหัสผ่าน',
                                    loading: _loading,
                                    onTap: _loading ? null : _resetPassword,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'คำแนะนำรหัสผ่าน',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('• ใช้อักขระอย่างน้อย 8 ตัว'),
                              Text('• มีตัวเลขและอักขระพิเศษ'),
                              Text('• ผสมตัวพิมพ์ใหญ่และตัวพิมพ์เล็ก'),
                            ],
                          ),
                        ),
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
}

/* ------------------- Reusable Widgets ------------------- */

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

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final Widget? suffix;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.suffix,
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
          borderRadius: borderRadius,
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: _ResetPasswordScreenState.kDeepPurple,
              ),
              hintText: hint,
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(
                  color: _ResetPasswordScreenState.kLavender,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: _ResetPasswordScreenState.kDeepPurple,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  const _LabeledPasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggle,
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
          borderRadius: borderRadius,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.lock_rounded,
                color: _ResetPasswordScreenState.kDeepPurple,
              ),
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: _ResetPasswordScreenState.kDeepPurple,
                ),
                onPressed: onToggle,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(
                  color: _ResetPasswordScreenState.kLavender,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: _ResetPasswordScreenState.kDeepPurple,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
        if (widget.onTap != null) _pressCtrl.forward();
      },
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: widget.onTap,
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
                colors: [
                  _ResetPasswordScreenState.kDeepPurple,
                  _ResetPasswordScreenState.kPurple,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ResetPasswordScreenState.kDeepPurple.withOpacity(
                    0.25,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              // จางลงนิดถ้า loading
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
