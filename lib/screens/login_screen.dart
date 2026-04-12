// lib/screens/login_screen.dart
// ═══════════════════════════════════════════════════════════════
//  CYBER INVESTIGATOR — LOGIN SCREEN
//  Themed to match the game's dark ops terminal aesthetic.
//  No bottom nav bar on auth screens.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/cyber_theme.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Animation controllers ─────────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _glitchCtrl;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;

  // ── Ticker (same as home screen) ─────────────────────────
  int _tickerOffset = 0;
  Timer? _tickerTimer;
  static const String _tickerContent =
      'SECURE ACCESS PORTAL  ·  AUTHENTICATION REQUIRED  ·  CLEARANCE LEVEL: ALPHA  ·  CYBEROPS NETWORK ONLINE  ·  ';

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glitchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));

    _fadeIn   = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp  = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _scanAnim  = CurvedAnimation(parent: _scanCtrl, curve: Curves.linear);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _tickerTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (mounted) setState(() => _tickerOffset = (_tickerOffset + 1) % _tickerContent.length);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entryCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _glitchCtrl.dispose();
    _tickerTimer?.cancel();
    super.dispose();
  }

  // ── Firebase Login Logic ──────────────────────────────────
  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    HapticFeedback.mediumImpact();

    // Client-side validation before hitting Firebase
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'CREDENTIALS REQUIRED — FILL ALL FIELDS';
      });
      _glitchCtrl.forward().then((_) => _glitchCtrl.reverse());
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (!mounted) return;

      // Navigate to home on success
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainMenuScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mapFirebaseError(e.code);
      });
      _glitchCtrl.forward().then((_) => _glitchCtrl.reverse());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'SYSTEM ERROR — TRY AGAIN LATER';
      });
    }
  }

  // ── Map Firebase error codes to themed messages ───────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'AGENT NOT FOUND — UNKNOWN OPERATIVE ID';
      case 'wrong-password':
        return 'ACCESS DENIED — INVALID ACCESS CODE';
      case 'invalid-email':
        return 'INVALID FORMAT — CHECK OPERATIVE ID';
      case 'user-disabled':
        return 'ACCOUNT SUSPENDED — CONTACT COMMAND';
      case 'too-many-requests':
        return 'TOO MANY ATTEMPTS — STAND DOWN & RETRY LATER';
      case 'network-request-failed':
        return 'NETWORK FAILURE — CHECK YOUR CONNECTION';
      case 'invalid-credential':
        return 'INVALID CREDENTIALS — RECHECK AND RETRY';
      default:
        return 'AUTHENTICATION FAILURE — CODE: ${code.toUpperCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String tickerRotated = _tickerContent.substring(_tickerOffset) +
        _tickerContent.substring(0, _tickerOffset);

    return Scaffold(
      backgroundColor: CyberColors.bgDeep,
      body: Stack(children: [
        // Background hex grid
        Positioned.fill(child: AnimatedBuilder(
          animation: _scanCtrl,
          builder: (_, __) => CustomPaint(painter: _AuthHexGridPainter(progress: _scanCtrl.value)),
        )),
        // Radial vignette
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(
              center: Alignment.center, radius: 1.2,
              colors: [Colors.transparent, CyberColors.bgDeep.withOpacity(0.75)],
              stops: const [0.35, 1.0]),
        ))),
        // Scanlines
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScanlinesPainter()))),
        // Corner brackets
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _CornersPainter()))),

        // Ticker at top
        Positioned(top: 0, left: 0, right: 0,
            child: _AuthTicker(content: tickerRotated)),

        // Main content
        SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    const SizedBox(height: 24),

                    // ── Logo ──
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => _AuthLogo(pulseValue: _pulseAnim.value),
                    ),

                    const SizedBox(height: 20),

                    // ── Title ──
                    Text('AGENT LOGIN',
                        style: GoogleFonts.orbitron(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: CyberColors.neonCyan, letterSpacing: 4,
                            shadows: [const Shadow(color: CyberColors.neonCyan, blurRadius: 14)])),
                    const SizedBox(height: 6),
                    Text('AUTHENTICATION PORTAL — CLEARANCE REQUIRED',
                        style: GoogleFonts.shareTechMono(
                            fontSize: 9, color: CyberColors.textMuted, letterSpacing: 1.5)),

                    const SizedBox(height: 32),

                    // ── Login form card ──
                    _AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          _CardHeader(
                            icon: Icons.lock_outlined,
                            title: 'SECURE CREDENTIALS',
                            subtitle: 'Enter your operative access details',
                          ),

                          const SizedBox(height: 24),

                          // Email field
                          _CyberTextField(
                            controller: _emailCtrl,
                            label: 'OPERATIVE ID (EMAIL)',
                            hint: 'agent@cybercell.in',
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),

                          // Password field
                          _CyberTextField(
                            controller: _passwordCtrl,
                            label: 'ACCESS CODE (PASSWORD)',
                            hint: '••••••••••••',
                            icon: Icons.key_outlined,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: CyberColors.textMuted,
                                size: 18,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _handleForgotPassword,
                              child: Text('FORGOT ACCESS CODE?',
                                  style: GoogleFonts.shareTechMono(
                                      fontSize: 10, color: CyberColors.neonCyan.withOpacity(0.7),
                                      letterSpacing: 1)),
                            ),
                          ),

                          // Error message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: _errorMessage!),
                          ],

                          const SizedBox(height: 24),

                          // Login button
                          _LoginButton(
                            isLoading: _isLoading,
                            onTap: _handleLogin,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Sign up link ──
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('NEW OPERATIVE?  ',
                          style: GoogleFonts.shareTechMono(
                              fontSize: 11, color: CyberColors.textMuted, letterSpacing: 0.5)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const SignupScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration: const Duration(milliseconds: 350),
                            ),
                          );
                        },
                        child: Text('REQUEST ACCESS',
                            style: GoogleFonts.shareTechMono(
                                fontSize: 11, color: CyberColors.neonCyan,
                                fontWeight: FontWeight.bold, letterSpacing: 0.5,
                                decoration: TextDecoration.underline,
                                decorationColor: CyberColors.neonCyan.withOpacity(0.5))),
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // ── System status ──
                    _SystemStatusRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Forgot password via Firebase ──────────────────────────
  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'ENTER YOUR OPERATIVE ID TO RESET ACCESS CODE');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CyberColors.neonCyan.withOpacity(0.15),
          content: Text(
            'RESET LINK DISPATCHED — CHECK YOUR COMMS CHANNEL',
            style: GoogleFonts.shareTechMono(color: CyberColors.neonCyan, fontSize: 11),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _mapFirebaseError(e.code));
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED AUTH WIDGETS (also used by signup)
// ─────────────────────────────────────────────────────────────

class _AuthTicker extends StatelessWidget {
  final String content;
  const _AuthTicker({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
          color: const Color(0xFF081208),
          border: Border(bottom: BorderSide(color: CyberColors.neonGreen.withOpacity(0.3), width: 1))),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: CyberColors.neonGreen.withOpacity(0.1),
            child: Row(children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: CyberColors.neonGreen,
                  boxShadow: [BoxShadow(color: CyberColors.neonGreen.withOpacity(0.8), blurRadius: 4)])),
              const SizedBox(width: 5),
              Text('LIVE', style: GoogleFonts.shareTechMono(
                  fontSize: 9, color: CyberColors.neonGreen, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ])),
        Expanded(child: ClipRect(child: Align(alignment: Alignment.centerLeft,
            child: Text(content, maxLines: 1, overflow: TextOverflow.clip,
                style: GoogleFonts.shareTechMono(
                    fontSize: 9, color: CyberColors.neonGreen.withOpacity(0.6), letterSpacing: 1.2))))),
      ]),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  final double pulseValue;
  const _AuthLogo({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90, height: 90,
      child: Stack(alignment: Alignment.center, children: [
        // Outer glow
        Container(width: 90, height: 90, decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: CyberColors.neonCyan.withOpacity(0.25 * pulseValue), blurRadius: 30, spreadRadius: 4),
            ])),
        // Rotating dashed ring
        Transform.rotate(
            angle: pulseValue * 2 * pi * 0.1,
            child: CustomPaint(
              size: const Size(90, 90),
              painter: _DashedRingPainter(color: CyberColors.neonCyan.withOpacity(0.4)),
            )),
        // Core
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050E1A),
              border: Border.all(
                  color: CyberColors.neonCyan.withOpacity(0.5 + pulseValue * 0.3),
                  width: 1.5)),
          child: Center(child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [CyberColors.neonCyan, CyberColors.neonPurple]).createShader(bounds),
            child: const Icon(Icons.security, size: 28, color: Colors.white),
          )),
        ),
      ]),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final Widget child;
  const _AuthCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        borderRadius: CyberRadius.medium,
        border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: CyberColors.neonCyan.withOpacity(0.06), blurRadius: 20),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CardHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: CyberColors.neonCyan.withOpacity(0.1),
          borderRadius: CyberRadius.small,
          border: Border.all(color: CyberColors.neonCyan.withOpacity(0.3)),
        ),
        child: Icon(icon, color: CyberColors.neonCyan, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.orbitron(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: CyberColors.neonCyan, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.shareTechMono(
            fontSize: 9, color: CyberColors.textMuted, letterSpacing: 0.5)),
      ])),
    ]);
  }
}

class _CyberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _CyberTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Label
      Row(children: [
        Container(width: 3, height: 12, color: CyberColors.neonCyan),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.shareTechMono(
            fontSize: 9, color: CyberColors.neonCyan,
            letterSpacing: 1.2, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      // Input
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF08131E),
          borderRadius: CyberRadius.small,
          border: Border.all(color: CyberColors.neonCyan.withOpacity(0.2)),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.shareTechMono(
              color: CyberColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: CyberColors.neonCyan.withOpacity(0.5), size: 18),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: GoogleFonts.shareTechMono(
                color: CyberColors.textMuted, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CyberColors.neonRed.withOpacity(0.08),
        borderRadius: CyberRadius.small,
        border: Border.all(color: CyberColors.neonRed.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: CyberColors.neonRed, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.shareTechMono(
            color: CyberColors.neonRed, fontSize: 10, letterSpacing: 0.5))),
      ]),
    );
  }
}

class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }
  @override void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => _pressCtrl.forward(),
      onTapUp: widget.isLoading ? null : (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) => Transform.scale(scale: _pressAnim.value, child: child),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: CyberRadius.medium,
            gradient: LinearGradient(
                begin: Alignment.centerLeft, end: Alignment.centerRight,
                colors: [CyberColors.neonCyan.withOpacity(0.2), CyberColors.neonPurple.withOpacity(0.15)]),
            border: Border.all(color: CyberColors.neonCyan.withOpacity(0.6), width: 1.5),
            boxShadow: [BoxShadow(color: CyberColors.neonCyan.withOpacity(0.15), blurRadius: 16)],
          ),
          child: widget.isLoading
              ? Center(child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(CyberColors.neonCyan),
              )))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.login, color: CyberColors.neonCyan, size: 20,
                shadows: [Shadow(color: CyberColors.neonCyan, blurRadius: 8)]),
            const SizedBox(width: 12),
            Text('AUTHENTICATE',
                style: GoogleFonts.orbitron(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: CyberColors.neonCyan, letterSpacing: 2,
                    shadows: [const Shadow(color: CyberColors.neonCyan, blurRadius: 8)])),
          ]),
        ),
      ),
    );
  }
}

class _SystemStatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _MiniStatusDot(color: CyberColors.neonGreen, label: 'SECURE'),
      const SizedBox(width: 16),
      _MiniStatusDot(color: CyberColors.neonCyan, label: 'ENCRYPTED'),
      const SizedBox(width: 16),
      _MiniStatusDot(color: CyberColors.neonPurple, label: 'MONITORED'),
    ]);
  }
}

class _MiniStatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const _MiniStatusDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 5, height: 5, decoration: BoxDecoration(
        shape: BoxShape.circle, color: color,
        boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 4)])),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.shareTechMono(
        fontSize: 8, color: color.withOpacity(0.7), letterSpacing: 1)),
  ]);
}

// ─────────────────────────────────────────────────────────────
//  PAINTERS
// ─────────────────────────────────────────────────────────────

class _AuthHexGridPainter extends CustomPainter {
  final double progress;
  _AuthHexGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const double hexSize = 36.0;
    const double hexWidth = hexSize * 2;
    final double hexHeight = hexSize * sqrt(3);
    final double driftX = sin(progress * 2 * pi) * 6;
    final double driftY = cos(progress * 2 * pi * 0.7) * 4;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;
    final int cols = (size.width / hexWidth).ceil() + 2;
    final int rows = (size.height / hexHeight).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final int seed = row * 1000 + col;
        if (Random(seed).nextDouble() > 0.35) continue;
        final double cx = col * hexWidth * 0.75 + driftX;
        final double cy = row * hexHeight + (col.isOdd ? hexHeight / 2 : 0) + driftY;
        final double shimmer = sin(progress * 2 * pi + seed * 0.4) * 0.5 + 0.5;
        paint.color = CyberColors.neonCyan.withOpacity(0.02 + shimmer * 0.05);
        _drawHex(canvas, Offset(cx, cy), hexSize * 0.82, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset c, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = c.dx + size * cos(angle);
      final y = c.dy + size * sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AuthHexGridPainter old) => old.progress != progress;
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(0.05)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_ScanlinesPainter _) => false;
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = CyberColors.neonCyan.withOpacity(0.3)
      ..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const double len = 22.0, m = 14.0;
    canvas.drawPath(Path()..moveTo(m, m+len)..lineTo(m, m)..lineTo(m+len, m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-len, m)..lineTo(size.width-m, m)..lineTo(size.width-m, m+len), p);
    canvas.drawPath(Path()..moveTo(m, size.height-m-len)..lineTo(m, size.height-m)..lineTo(m+len, size.height-m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-len, size.height-m)..lineTo(size.width-m, size.height-m)..lineTo(size.width-m, size.height-m-len), p);
  }
  @override bool shouldRepaint(_CornersPainter _) => false;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  const _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()..color = color..strokeWidth = 1.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const dashCount = 12;
    const dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          dashAngle * i, dashAngle * 0.6, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}