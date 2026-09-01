import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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

class Registeration extends StatefulWidget {
  const Registeration({super.key});

  @override
  State<Registeration> createState() => _RegisterationState();
}

class _RegisterationState extends State<Registeration> with SingleTickerProviderStateMixin {
  bool hidePassword = true;
  String selectedRole = 'Admin';
  String _password = '';
  bool _isRegistering = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();

  // Change this to your live/server URL.
  // Example: https://yourdomain.com/api/register.php
  static const String registerApiUrl =
      'https://YOUR-DOMAIN.com/api/register.php';

  final List<String> roles = ['Admin'];

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
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  double get _strength {
    if (_password.isEmpty) return 0;
    double score = 0;
    if (_password.length >= 6) score += 0.25;
    if (_password.length >= 10) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(_password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(_password)) score += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_password)) score += 0.15;
    return score.clamp(0, 1);
  }

  Color get _strengthColor {
    if (_strength < 0.4) return const Color(0xFFC9432E);
    if (_strength < 0.75) return const Color(0xFFCB9A2E);
    return const Color(0xFF3E8B4F);
  }

  String get _strengthLabel {
    if (_password.isEmpty) return '';
    if (_strength < 0.4) return 'Weak';
    if (_strength < 0.75) return 'Good';
    return 'Strong';
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
                      const _GlowLogo(size: 100),
                      const SizedBox(height: 16),
                      Text(
                        'BHADRA FOODS',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: _Palette.goldLight,
                        ),
                      ),
                      Text(
                        'Create Your Account',
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
                                  _sectionTitle('Register'),
                                  const SizedBox(height: 20),
                                  _buildDisabledAdminRole(),
                                  const SizedBox(height: 14),
                                  buildIconField(Icons.person_outline, 'Full Name', controller: nameController),
                                  const SizedBox(height: 14),
                                  buildIconField(Icons.email_outlined, 'Email Address', controller: emailController),
                                  const SizedBox(height: 14),
                                  buildIconField(Icons.phone_outlined, 'Mobile Number', controller: mobileController),
                                  const SizedBox(height: 14),
                                  buildIconField(
                                    Icons.lock_outline,
                                    'Password',
                                    controller: passwordController,
                                    isPassword: true,
                                    onChanged: (val) => setState(() => _password = val),
                                  ),
                                  if (_password.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _StrengthMeter(
                                      strength: _strength,
                                      color: _strengthColor,
                                      label: _strengthLabel,
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  _GradientButton(
                                    label: _isRegistering ? 'REGISTERING...' : 'REGISTER',
                                    icon: _isRegistering
                                        ? Icons.hourglass_top_rounded
                                        : Icons.app_registration_rounded,
                                    onPressed: _isRegistering
                                        ? () {}
                                        : _registerAdmin,
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
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

  Future<void> _registerAdmin() async {
    FocusScope.of(context).unfocus();

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || mobile.isEmpty || password.isEmpty) {
      _showError('Please fill all fields.');
      return;
    }

    final emailValid =
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailValid) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      _showError('Please enter a valid 10-digit mobile number.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (selectedRole != 'Admin') {
      _showError('Only Admin registration is allowed.');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final response = await http
          .post(
        Uri.parse(registerApiUrl),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'mobile': mobile,
          'password': password,
          'role': 'Admin',
        }),
      )
          .timeout(const Duration(seconds: 30));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception(
          'Invalid server response (${response.statusCode}).',
        );
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        if (!mounted) return;
        setState(() => _isRegistering = false);
        _showSuccessDialog();
      } else {
        if (!mounted) return;
        setState(() => _isRegistering = false);
        _showError(
          (data['message'] ?? 'Registration failed.').toString(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRegistering = false);
      _showError(
        'Unable to connect to the server. Please check your API URL and internet connection.',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFC9432E),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _Palette.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF3E8B4F), size: 28),
              const SizedBox(width: 10),
              Text(
                'Registration Successful!',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _Palette.ink,
                ),
              ),
            ],
          ),
          content: Text(
            'Your account has been created successfully. Please login to continue.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: _Palette.ink,
            ),
          ),
          actions: [
            _GradientButton(
              label: 'LOGIN NOW',
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
              fontSize: 26,
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

  Widget _buildDisabledAdminRole() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: _Palette.border),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Row(
        children: [
          _iconBadge(Icons.admin_panel_settings_outlined),
          const SizedBox(width: 12),
          Text(
            'Admin (Registration Only)',
            style: GoogleFonts.plusJakartaSans(
              color: _Palette.espresso,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          const Icon(Icons.lock, color: _Palette.border, size: 18),
        ],
      ),
    );
  }

  Widget buildIconField(
      IconData icon,
      String hint, {
        TextEditingController? controller,
        bool isPassword = false,
        ValueChanged<String>? onChanged,
      }) {
    return TextField(
      controller: controller,
      keyboardType: hint == 'Email Address'
          ? TextInputType.emailAddress
          : hint == 'Mobile Number'
          ? TextInputType.phone
          : TextInputType.text,
      obscureText: isPassword ? hidePassword : false,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _Palette.ink),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: _iconBadge(icon),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey[600],
            size: 20,
          ),
          onPressed: () => setState(() => hidePassword = !hidePassword),
        )
            : null,
        labelText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _Palette.espresso, width: 1.6),
        ),
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
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 11 : 15, horizontal: widget.compact ? 16 : 0),
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
              Icon(widget.icon, size: widget.compact ? 16 : 20, color: _Palette.goldLight),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.compact ? 13 : 15,
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