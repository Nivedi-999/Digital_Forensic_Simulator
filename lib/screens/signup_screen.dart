// lib/screens/signup_screen.dart
// ═══════════════════════════════════════════════════════════════
//  CYBER INVESTIGATOR — SIGN UP SCREEN
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
import 'login_screen.dart';
import '../services/progress_service.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;
  String? _errorMessage;

  // ── Animations ─────────────────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseAnim;

  // ── Ticker ──────────────────────────────────────────────
  int _tickerOffset = 0;
  Timer? _tickerTimer;
  static const String _tickerContent =
      'NEW AGENT REGISTRATION  ·  WELCOME TO CYBEROPS  ·  CLEARANCE PENDING  ·  IDENTITY VERIFICATION REQUIRED  ·  ';

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _fadeIn  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Rebuild when password changes so strength bar updates live
    _passwordCtrl.addListener(() { if (mounted) setState(() {}); });

    _tickerTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (mounted) setState(() => _tickerOffset = (_tickerOffset + 1) % _tickerContent.length);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _entryCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _tickerTimer?.cancel();
    super.dispose();
  }

  // ── Firebase Signup Logic ─────────────────────────────────
  Future<void> _handleSignup() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    HapticFeedback.mediumImpact();

    // ── Client-side validation ──
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty || _confirmCtrl.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ALL FIELDS REQUIRED — COMPLETE THE FORM';
      });
      return;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ACCESS CODES DO NOT MATCH — RETRY';
      });
      return;
    }

    if (_passwordCtrl.text.length < 6) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ACCESS CODE TOO SHORT — MINIMUM 6 CHARACTERS';
      });
      return;
    }

    // ── Firebase account creation ──
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Save the agent codename as the Firebase display name
      await credential.user?.updateDisplayName(_nameCtrl.text.trim());
      await ProgressService.instance.init();
      await ProgressService.instance.saveDisplayName(_nameCtrl.text.trim());

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
      case 'email-already-in-use':
        return 'OPERATIVE ID TAKEN — AGENT ALREADY REGISTERED';
      case 'invalid-email':
        return 'INVALID FORMAT — CHECK OPERATIVE ID';
      case 'weak-password':
        return 'ACCESS CODE TOO WEAK — INCREASE COMPLEXITY';
      case 'operation-not-allowed':
        return 'REGISTRATION DISABLED — CONTACT COMMAND';
      case 'network-request-failed':
        return 'NETWORK FAILURE — CHECK YOUR CONNECTION';
      default:
        return 'REGISTRATION FAILURE — CODE: ${code.toUpperCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String tickerRotated = _tickerContent.substring(_tickerOffset) +
        _tickerContent.substring(0, _tickerOffset);

    return Scaffold(
      backgroundColor: CyberColors.bgDeep,
      body: Stack(children: [
        // Background
        Positioned.fill(child: AnimatedBuilder(
          animation: _scanCtrl,
          builder: (_, __) => CustomPaint(painter: _SignupHexGridPainter(progress: _scanCtrl.value)),
        )),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(
              center: Alignment.topCenter, radius: 1.3,
              colors: [CyberColors.neonPurple.withOpacity(0.04), CyberColors.bgDeep.withOpacity(0.85)],
              stops: const [0.2, 1.0]),
        ))),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScanlinesPainter()))),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _CornersPainter()))),

        // Ticker
        Positioned(top: 0, left: 0, right: 0,
            child: _AuthTicker(content: tickerRotated, accentColor: CyberColors.neonPurple)),

        // Content
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

                    const SizedBox(height: 20),

                    // ── Logo ──
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => _SignupLogo(pulseValue: _pulseAnim.value),
                    ),

                    const SizedBox(height: 18),

                    // ── Title ──
                    Text('AGENT ENLISTMENT',
                        style: GoogleFonts.orbitron(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: CyberColors.neonPurple, letterSpacing: 3,
                            shadows: [const Shadow(color: CyberColors.neonPurple, blurRadius: 14)])),
                    const SizedBox(height: 6),
                    Text('REGISTER YOUR OPERATIVE IDENTITY',
                        style: GoogleFonts.shareTechMono(
                            fontSize: 9, color: CyberColors.textMuted, letterSpacing: 1.5)),

                    const SizedBox(height: 28),

                    // ── Form card ──
                    _SignupCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          _CardHeader(
                            icon: Icons.badge_outlined,
                            title: 'OPERATIVE REGISTRATION',
                            subtitle: 'Create your field agent profile',
                            color: CyberColors.neonPurple,
                          ),

                          const SizedBox(height: 24),

                          // Agent name
                          _CyberTextField(
                            controller: _nameCtrl,
                            label: 'AGENT CODENAME',
                            hint: 'e.g. CIPHER_01',
                            icon: Icons.person_outlined,
                            accentColor: CyberColors.neonPurple,
                          ),

                          const SizedBox(height: 14),

                          // Email
                          _CyberTextField(
                            controller: _emailCtrl,
                            label: 'OPERATIVE ID (EMAIL)',
                            hint: 'agent@cybercell.in',
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            accentColor: CyberColors.neonPurple,
                          ),

                          const SizedBox(height: 14),

                          // Password
                          _CyberTextField(
                            controller: _passwordCtrl,
                            label: 'ACCESS CODE',
                            hint: 'min. 6 characters',
                            icon: Icons.key_outlined,
                            obscureText: _obscurePassword,
                            accentColor: CyberColors.neonPurple,
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: CyberColors.textMuted, size: 18,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Confirm password
                          _CyberTextField(
                            controller: _confirmCtrl,
                            label: 'CONFIRM ACCESS CODE',
                            hint: 'repeat access code',
                            icon: Icons.lock_outlined,
                            obscureText: _obscureConfirm,
                            accentColor: CyberColors.neonPurple,
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: CyberColors.textMuted, size: 18,
                              ),
                            ),
                          ),

                          // Strength indicator (when typing)
                          if (_passwordCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _PasswordStrengthBar(password: _passwordCtrl.text),
                          ],

                          // Error
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: _errorMessage!),
                          ],

                          const SizedBox(height: 24),

                          // Register button
                          _RegisterButton(
                            isLoading: _isLoading,
                            onTap: _handleSignup,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Login link ──
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('ALREADY ENLISTED?  ',
                          style: GoogleFonts.shareTechMono(
                              fontSize: 11, color: CyberColors.textMuted, letterSpacing: 0.5)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const LoginScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration: const Duration(milliseconds: 350),
                            ),
                          );
                        },
                        child: Text('ACCESS PORTAL',
                            style: GoogleFonts.shareTechMono(
                                fontSize: 11, color: CyberColors.neonPurple,
                                fontWeight: FontWeight.bold, letterSpacing: 0.5,
                                decoration: TextDecoration.underline,
                                decorationColor: CyberColors.neonPurple.withOpacity(0.5))),
                      ),
                    ]),

                    const SizedBox(height: 24),
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
}

// ─────────────────────────────────────────────────────────────
//  SIGNUP-SPECIFIC WIDGETS
// ─────────────────────────────────────────────────────────────

class _SignupLogo extends StatelessWidget {
  final double pulseValue;
  const _SignupLogo({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 80,
      child: Stack(alignment: Alignment.center, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: CyberColors.neonPurple.withOpacity(0.2 * pulseValue), blurRadius: 28, spreadRadius: 4),
            ])),
        Transform.rotate(
            angle: -pulseValue * 2 * pi * 0.08,
            child: CustomPaint(
              size: const Size(80, 80),
              painter: _SignupRingPainter(color: CyberColors.neonPurple.withOpacity(0.4)),
            )),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF050E1A),
              border: Border.all(
                  color: CyberColors.neonPurple.withOpacity(0.5 + pulseValue * 0.3),
                  width: 1.5)),
          child: Center(child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [CyberColors.neonPurple, CyberColors.neonCyan]).createShader(bounds),
            child: const Icon(Icons.person_add_outlined, size: 26, color: Colors.white),
          )),
        ),
      ]),
    );
  }
}

class _SignupCard extends StatelessWidget {
  final Widget child;
  const _SignupCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CyberColors.bgCard,
        borderRadius: CyberRadius.medium,
        border: Border.all(color: CyberColors.neonPurple.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: CyberColors.neonPurple.withOpacity(0.06), blurRadius: 20),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int get _strength {
    int s = 0;
    if (password.length >= 6) s++;
    if (password.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[0-9]').hasMatch(password)) s++;
    if (RegExp(r'[!@#$%^&*]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    final color = s <= 1 ? CyberColors.neonRed
        : s <= 3 ? CyberColors.neonAmber
        : CyberColors.neonGreen;
    final label = s <= 1 ? 'WEAK' : s <= 3 ? 'MODERATE' : 'STRONG';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('CODE STRENGTH: ', style: GoogleFonts.shareTechMono(
            fontSize: 9, color: CyberColors.textMuted)),
        Text(label, style: GoogleFonts.shareTechMono(
            fontSize: 9, color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      Row(children: List.generate(5, (i) => Expanded(child: Container(
        height: 3,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: i < s ? color : CyberColors.borderSubtle,
        ),
      )))),
    ]);
  }
}

class _RegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _RegisterButton({required this.isLoading, required this.onTap});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton> with SingleTickerProviderStateMixin {
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
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            borderRadius: CyberRadius.medium,
            gradient: LinearGradient(
                begin: Alignment.centerLeft, end: Alignment.centerRight,
                colors: [CyberColors.neonPurple.withOpacity(0.2), CyberColors.neonCyan.withOpacity(0.12)]),
            border: Border.all(color: CyberColors.neonPurple.withOpacity(0.6), width: 1.5),
            boxShadow: [BoxShadow(color: CyberColors.neonPurple.withOpacity(0.15), blurRadius: 16)],
          ),
          child: widget.isLoading
              ? Center(child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(CyberColors.neonPurple),
              )))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person_add_outlined, color: CyberColors.neonPurple, size: 20,
                shadows: [Shadow(color: CyberColors.neonPurple, blurRadius: 8)]),
            const SizedBox(width: 12),
            Text('ENLIST NOW',
                style: GoogleFonts.orbitron(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: CyberColors.neonPurple, letterSpacing: 2,
                    shadows: [const Shadow(color: CyberColors.neonPurple, blurRadius: 8)])),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS (reimported from login style)
// ─────────────────────────────────────────────────────────────

class _AuthTicker extends StatelessWidget {
  final String content;
  final Color accentColor;
  const _AuthTicker({required this.content, this.accentColor = CyberColors.neonGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
          color: const Color(0xFF081208),
          border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.3), width: 1))),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: accentColor.withOpacity(0.1),
            child: Row(children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: accentColor,
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.8), blurRadius: 4)])),
              const SizedBox(width: 5),
              Text('LIVE', style: GoogleFonts.shareTechMono(
                  fontSize: 9, color: accentColor, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ])),
        Expanded(child: ClipRect(child: Align(alignment: Alignment.centerLeft,
            child: Text(content, maxLines: 1, overflow: TextOverflow.clip,
                style: GoogleFonts.shareTechMono(
                    fontSize: 9, color: accentColor.withOpacity(0.6), letterSpacing: 1.2))))),
      ]),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _CardHeader({
    required this.icon, required this.title, required this.subtitle,
    this.color = CyberColors.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: CyberRadius.small,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.orbitron(
            fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
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
  final Color accentColor;

  const _CyberTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.accentColor = CyberColors.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 3, height: 12, color: accentColor),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.shareTechMono(
            fontSize: 9, color: accentColor, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF08131E),
          borderRadius: CyberRadius.small,
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.shareTechMono(color: CyberColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accentColor.withOpacity(0.5), size: 18),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: GoogleFonts.shareTechMono(color: CyberColors.textMuted, fontSize: 13),
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

class _SystemStatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _MiniStatusDot(color: CyberColors.neonGreen, label: 'SECURE'),
      const SizedBox(width: 16),
      _MiniStatusDot(color: CyberColors.neonPurple, label: 'ENCRYPTED'),
      const SizedBox(width: 16),
      _MiniStatusDot(color: CyberColors.neonCyan, label: 'MONITORED'),
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

class _SignupHexGridPainter extends CustomPainter {
  final double progress;
  _SignupHexGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const double hexSize = 36.0;
    const double hexWidth = hexSize * 2;
    final double hexHeight = hexSize * sqrt(3);
    final double driftX = cos(progress * 2 * pi) * 5;
    final double driftY = sin(progress * 2 * pi * 0.6) * 5;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;
    final int cols = (size.width / hexWidth).ceil() + 2;
    final int rows = (size.height / hexHeight).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final int seed = row * 1000 + col;
        if (Random(seed).nextDouble() > 0.32) continue;
        final double cx = col * hexWidth * 0.75 + driftX;
        final double cy = row * hexHeight + (col.isOdd ? hexHeight / 2 : 0) + driftY;
        final double shimmer = sin(progress * 2 * pi + seed * 0.35) * 0.5 + 0.5;
        paint.color = CyberColors.neonPurple.withOpacity(0.015 + shimmer * 0.04);
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
  bool shouldRepaint(_SignupHexGridPainter old) => old.progress != progress;
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
      ..color = CyberColors.neonPurple.withOpacity(0.3)
      ..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const double len = 22.0, m = 14.0;
    canvas.drawPath(Path()..moveTo(m, m+len)..lineTo(m, m)..lineTo(m+len, m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-len, m)..lineTo(size.width-m, m)..lineTo(size.width-m, m+len), p);
    canvas.drawPath(Path()..moveTo(m, size.height-m-len)..lineTo(m, size.height-m)..lineTo(m+len, size.height-m), p);
    canvas.drawPath(Path()..moveTo(size.width-m-len, size.height-m)..lineTo(size.width-m, size.height-m)..lineTo(size.width-m, size.height-m-len), p);
  }
  @override bool shouldRepaint(_CornersPainter _) => false;
}

class _SignupRingPainter extends CustomPainter {
  final Color color;
  const _SignupRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()..color = color..strokeWidth = 1.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const dashCount = 10;
    const dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          dashAngle * i, dashAngle * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_SignupRingPainter old) => old.color != color;
}