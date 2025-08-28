import 'dart:ui';
import 'package:flutter/material.dart';
import 'registerscreen.dart';
//import 'NurseListCaseScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool showPassword = false;

  // controllers
  late final AnimationController _inCtrl; // เข้า
  late final AnimationController _outCtrl; // ออก

  // logo animations (เข้า)
  late final Animation<Offset> _logoSlideIn; // -1.2 -> 0
  late final Animation<double> _logoFadeIn; // 0 -> 1
  late final Animation<double> _logoScaleIn; // 0.95 -> 1.0

  // title animations (เข้า)
  late final Animation<Offset> _titleSlideIn;
  late final Animation<double> _titleFadeIn;

  // logo animations (ออก)
  late final Animation<Offset> _logoSlideOut; // 0 -> 1.2
  late final Animation<double> _logoFadeOut; // 1 -> 0
  late final Animation<double> _logoScaleOut; // 1.0 -> 0.98

  // title animations (ออก)
  late final Animation<Offset> _titleSlideOut;
  late final Animation<double> _titleFadeOut;

  bool _exiting = false;

  // โทนสีหลัก
  static const Color kDeepPurple = Color(0xFF5B2EFF);
  static const Color kPurple = Color(0xFF8C6CFF);
  static const Color kLavender = Color(0xFFEDE9FF);

  @override
  void initState() {
    super.initState();

    // animate in
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

    // animate out
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

    // delay ก่อนเข้า 300ms
    Future.delayed(const Duration(milliseconds: 300), _inCtrl.forward);
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    _outCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    // TODO: ใส่ logic ตรวจสอบล็อกอินจริงได้ตามต้องการ
    setState(() => _exiting = true);
    await _outCtrl.forward();

    if (!mounted) return;

    // เมื่อกด login แล้วเข้าไปหน้า NurseListCaseScreen (CasesScreen)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // พื้นหลังไล่เฉด + วงกลมนุ่ม ๆ โทนม่วง
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

          // แก้วควันม่วง ๆ (soft blobs)
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // LOGO (animate in/out)
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
                              gradient: LinearGradient(
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

                // TITLE (animate in/out + gradient text)
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
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              color: Colors.white, // ถูก Shader ทับ
                              fontSize: 36,
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

                // Card ฟอร์มแบบ glassmorphism เบา ๆ
                _GlassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _LabeledField(
                        label: 'อีเมลหรือเบอร์โทรศัพท์',
                        hint: 'กรุณากรอกอีเมลหรือเบอร์โทรศัพท์',
                        keyboard: TextInputType.emailAddress,
                        icon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 14),
                      _LabeledPasswordField(
                        label: 'รหัสผ่าน',
                        hint: 'กรุณากรอกรหัสผ่าน',
                        showPassword: showPassword,
                        onToggle:
                            () => setState(() => showPassword = !showPassword),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: kDeepPurple,
                            ),
                            child: const Text('ลืมรหัสผ่าน?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ปุ่มกราเดียนต์
                      _GradientButton(
                        text: 'เข้าสู่ระบบ',
                        onTap: _exiting ? null : _onLoginPressed,
                      ),
                      const SizedBox(height: 8),

                      // ลิ้งค์สมัคร
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ยังไม่มีบัญชี? ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap:
                                _exiting
                                    ? null
                                    : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const RegisterScreen(),
                                        ),
                                      );
                                    },
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

                const SizedBox(height: 32),

                // ข้อความล่างนิด ๆ (มินิมอล)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// วงกลมสีม่วงเบลอ ๆ
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

/// การ์ดใส ๆ แบบ glass เบา ๆ
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

/// TextField พร้อม label และไอคอน
class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextInputType? keyboard;
  final IconData? icon;

  const _LabeledField({
    required this.label,
    required this.hint,
    this.keyboard,
    this.icon,
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
            keyboardType: keyboard,
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
        ),
      ],
    );
  }
}

/// Password field พร้อมปุ่มโชว์/ซ่อน
class _LabeledPasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final bool showPassword;
  final VoidCallback onToggle;

  const _LabeledPasswordField({
    required this.label,
    required this.hint,
    required this.showPassword,
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
          elevation: 0,
          borderRadius: borderRadius,
          child: TextField(
            obscureText: !showPassword,
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
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: _LoginScreenState.kDeepPurple,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ปุ่ม Gradient ม่วงแบบมินิมอล
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
          child: const Text(
            'เข้าสู่ระบบ',
            style: TextStyle(
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
