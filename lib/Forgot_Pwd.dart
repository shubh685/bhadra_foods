import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Log_In.dart';

class _Palette {
  static const bgTop = Color(0xFF3D1F03);
  static const bgBottom = Color(0xFF1D0E02);
  static const card = Color(0xFFFFFDF7);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFE5B869);
  static const border = Color(0xFFE5C896);
  static const espresso = Color(0xFF3B1E04);
  static const espressoDeep = Color(0xFF241202);
  static const ink = Color(0xFF2E1A05);
}

class ResetPwd extends StatefulWidget {
  const ResetPwd({super.key});

  @override
  State<ResetPwd> createState() => _ResetPwdState();
}

class _ResetPwdState extends State<ResetPwd> with SingleTickerProviderStateMixin {
  bool isEmailVerified = false;
  bool isOtpSubmitted = false;
  bool isOtpVerified = false;

  bool hideNewPassword = true;
  bool hideConfirmPassword = true;
  String _newPassword = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _entrance.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double get _strength {
    if (_newPassword.isEmpty) return 0;
    double score = 0;
    if (_newPassword.length >= 6) score += 0.25;
    if (_newPassword.length >= 10) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(_newPassword)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(_newPassword)) score += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_newPassword)) score += 0.15;
    return score.clamp(0, 1);
  }

  Color get _strengthColor {
    if (_strength < 0.4) return const Color(0xFFC9432E);
    if (_strength < 0.75) return const Color(0xFFCB9A2E);
    return const Color(0xFF3E8B4F);
  }

  String get _strengthLabel {
    if (_newPassword.isEmpty) return '';
    if (_strength < 0.4) return 'Weak';
    if (_strength < 0.75) return 'Good';
    return 'Strong';
  }

  void _showSuccessDialog() {
    final DateTime now = DateTime.now();
    final String formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _Palette.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF3E8B4F), size: 28),
              ),
              const SizedBox(width: 10),
              Text(
                'Success',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _Palette.ink,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password updated successfully!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _Palette.ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Updated on: $formattedDate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            _GradientButton(
              label: 'BACK TO LOGIN',
              icon: Icons.login_rounded,
              compact: true,
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Login()),
                      (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_Palette.bgTop, _Palette.bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Soft radial background highlight behind the logo
              Align(
                alignment: const Alignment(0, -0.75),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6E3900).withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Screen Body Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GlowLogo(size: 80),
                      const SizedBox(height: 12),
                      Text(
                        'Reset Password',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: _Palette.goldLight,
                        ),
                      ),
                      Text(
                        'Secure your account with a new password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: _Palette.goldLight.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _Palette.card,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: _Palette.gold.withOpacity(0.25)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                  BoxShadow(
                                    color: _Palette.gold.withOpacity(0.08),
                                    blurRadius: 40,
                                    spreadRadius: -6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _sectionTitle('Reset Password'),
                                  const SizedBox(height: 20),
                                  // Step 1: Email
                                  _buildStepHeader('1', 'Enter Registered Email', isEmailVerified),
                                  const SizedBox(height: 10),
                                  if (!isEmailVerified) ...[
                                    TextField(
                                      controller: _emailController,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _Palette.ink),
                                      decoration: _inputDecoration(Icons.email_outlined, 'Email Address'),
                                    ),
                                    const SizedBox(height: 10),
                                    _GradientButton(
                                      label: 'SEND OTP',
                                      icon: Icons.send_outlined,
                                      compact: true,
                                      onPressed: () {
                                        setState(() {
                                          isEmailVerified = true;
                                          isOtpSubmitted = false;
                                        });
                                      },
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3E8B4F).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF3E8B4F).withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Color(0xFF3E8B4F), size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'OTP sent to ${_emailController.text}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                color: const Color(0xFF3E8B4F),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // Step 2: OTP Verification
                                  if (isEmailVerified) ...[
                                    _buildStepHeader('2', 'Verify OTP', isOtpSubmitted),
                                    const SizedBox(height: 10),
                                    if (!isOtpSubmitted) ...[
                                      TextField(
                                        controller: _otpController,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _Palette.ink),
                                        decoration: _inputDecoration(Icons.password_outlined, 'Enter OTP'),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _GradientButton(
                                              label: 'VERIFY OTP',
                                              icon: Icons.verified_outlined,
                                              compact: true,
                                              onPressed: () {
                                                setState(() {
                                                  isOtpSubmitted = true;
                                                  isOtpVerified = true;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          TextButton(
                                            onPressed: () {
                                              // Resend OTP logic
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('OTP resent successfully!'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Resend',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: _Palette.espresso,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3E8B4F).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF3E8B4F).withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Color(0xFF3E8B4F), size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'OTP Verified Successfully!',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF3E8B4F),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                  if (isOtpVerified) ...[
                                    const SizedBox(height: 16),
                                    _buildStepHeader('3', 'Set New Password', false),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _newPasswordController,
                                      obscureText: hideNewPassword,
                                      onChanged: (val) => setState(() => _newPassword = val),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _Palette.ink),
                                      decoration: _inputDecoration(
                                        Icons.lock_outline,
                                        'New Password',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            hideNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() => hideNewPassword = !hideNewPassword),
                                        ),
                                      ),
                                    ),
                                    if (_newPassword.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _StrengthMeter(
                                        strength: _strength,
                                        color: _strengthColor,
                                        label: _strengthLabel,
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: hideConfirmPassword,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _Palette.ink),
                                      decoration: _inputDecoration(
                                        Icons.lock_outline,
                                        'Confirm Password',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            hideConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() => hideConfirmPassword = !hideConfirmPassword),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _GradientButton(
                                      label: 'UPDATE PASSWORD',
                                      icon: Icons.save_outlined,
                                      onPressed: () {
                                        if (_newPasswordController.text == _confirmPasswordController.text) {
                                          _showSuccessDialog();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Passwords do not match!'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Remember your password? ',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(builder: (_) => const Login()),
                                                (route) => false,
                                          );
                                        },
                                        child: Text(
                                          'Login',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: _Palette.espresso,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        const SizedBox(width: 20, child: Divider(color: _Palette.border, thickness: 2)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _Palette.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 20, child: Divider(color: _Palette.border, thickness: 2)),
      ],
    );
  }

  Widget _buildStepHeader(String number, String title, bool done) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: done ? const Color(0xFF3E8B4F) : _Palette.espresso,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (done ? const Color(0xFF3E8B4F) : _Palette.gold).withOpacity(0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : Text(
            number,
            style: GoogleFonts.plusJakartaSans(color: _Palette.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: _Palette.ink)),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.all(10),
        child: _iconBadge(icon),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon,
      labelText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.espresso, width: 1.6),
      ),
    );
  }
}

Widget _iconBadge(IconData icon) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: _Palette.espresso.withOpacity(0.08),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: _Palette.espresso, size: 16),
  );
}

class _StrengthMeter extends StatelessWidget {
  final double strength;
  final Color color;
  final String label;
  const _StrengthMeter({required this.strength, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: Colors.grey[300]),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 250),
                    widthFactor: strength,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

class _GlowLogo extends StatefulWidget {
  final double size;
  const _GlowLogo({required this.size});

  @override
  State<_GlowLogo> createState() => _GlowLogoState();
}

class _GlowLogoState extends State<_GlowLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowOpacity = 0.25 + (_controller.value * 0.35);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _Palette.bgTop,
            border: Border.all(color: _Palette.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: _Palette.gold.withOpacity(glowOpacity),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                'assets/photos/bfs.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.restaurant_menu,
                  color: _Palette.gold,
                  size: 44,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 11 : 14, horizontal: widget.compact ? 16 : 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Palette.espresso, _Palette.espressoDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: _Palette.gold.withOpacity(0.35),
                blurRadius: widget.compact ? 12 : 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(widget.icon, size: widget.compact ? 16 : 18, color: _Palette.goldLight),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.compact ? 13 : 14,
                  letterSpacing: 1,
                  color: _Palette.goldLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}