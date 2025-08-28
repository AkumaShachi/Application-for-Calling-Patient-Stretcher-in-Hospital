import 'dart:ui';
import 'package:flutter/material.dart';
import 'resetpassword.dart';

class ForgetScreen extends StatefulWidget {
  const ForgetScreen({super.key});

  @override
  State<ForgetScreen> createState() => _ForgetScreenState();
}

class _ForgetScreenState extends State<ForgetScreen>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();

  static const Color kDeepPurple = Color(0xFF5B2EFF);
  static const Color kPurple = Color(0xFF8C6CFF);
  static const Color kLavender = Color(0xFFEDE9FF);

  late final AnimationController _inCtrl;
  late final Animation<Offset> _titleSlideIn;
  late final Animation<double> _titleFadeIn;

  @override
  void initState() {
    super.initState();

    _inCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    final inCurve = CurvedAnimation(parent: _inCtrl, curve: Curves.easeOutBack);

    _titleSlideIn = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(inCurve);
    _titleFadeIn = CurvedAnimation(parent: _inCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 200), _inCtrl.forward);
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _sendReset() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกอีเมลก่อน")));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("ส่งรหัสรีเซ็ตไปยัง $email")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: [Color(0xFFF7F5FF), Color(0xFFEDE9FF)],
              ),
            ),
          ),

          // soft blobs
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
                  // back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: kDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // title
                  AnimatedBuilder(
                    animation: _inCtrl,
                    builder: (context, _) {
                      return FadeTransition(
                        opacity: _titleFadeIn,
                        child: SlideTransition(
                          position: _titleSlideIn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback:
                                    (r) => const LinearGradient(
                                      colors: [kDeepPurple, kPurple],
                                    ).createShader(r),
                                child: const Text(
                                  'ลืมรหัสผ่าน',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "กรุณากรอกอีเมลของคุณเพื่อรับรหัสรีเซ็ต",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  _GlassCard(
                    child: Column(
                      children: [
                        _LabeledField(
                          controller: emailController,
                          label: "อีเมล",
                          hint: "กรอกอีเมลของคุณ",
                          icon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _GradientButton(
                          text: "ส่งรหัสรีเซ็ตรหัสผ่าน",
                          onTap: _sendReset,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Box
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResetPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "มีรหัสรีเซ็ตแล้ว? กดที่นี่",
                        style: TextStyle(color: kDeepPurple),
                      ),
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

/* ---------------- Widgets ---------------- */

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
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
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
  final TextInputType? keyboard;
  final IconData icon;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
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
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _ForgetScreenState.kDeepPurple),
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(
                  color: _ForgetScreenState.kLavender,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: _ForgetScreenState.kDeepPurple,
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

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GradientButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [
              _ForgetScreenState.kDeepPurple,
              _ForgetScreenState.kPurple,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
