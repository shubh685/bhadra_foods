import 'package:bhad_foods/Admin_Dashboard.dart';
import 'package:bhad_foods/Salesman_Dashboard.dart';
import 'package:bhad_foods/Sup_stockiest.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Forgot_Pwd.dart';
import 'Register.dart';

class _Palette {
  static const bgTop = Color(0xFF381C00);     // Dark warm brown (top)
  static const bgBottom = Color(0xFF1E0E00);  // Deep brown (bottom)
  static const haloGold = Color(0xFFFFDF7D);  // Outer glowing ring
  static const logoBg = Color(0xFF381C00);    // Inner circle fill
  static const gold = Color(0xFFE2BA55);      // Golden accent/border
  static const goldLight = Color(0xFFF7D57F); // Light golden text
  static const card = Color(0xFFFFFDF5);      // Warm ivory card background
  static const border = Color(0xFFE8D3A7);    // Light border color
  static const espresso = Color(0xFF361800);  // Dark brown for primary buttons
  static const espressoDeep = Color(0xFF220D00);
  static const ink = Color(0xFF2E1A05);
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  bool hidePassword = true;
  bool rememberMe = false;
  String? selectedRole;

  final List<String> roles = [
    'Admin',
    'Salesman',
    'Sales Officer',
    'Area Sales Manager',
    'Regional Sales Manager',
    'Zone Wise Sales Manager',
    'Sales Head',
    'Super Stockiest'
  ];

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
    super.dispose();
  }

  void _handleLogin() {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role to continue'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (selectedRole == 'Admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else if (selectedRole == "Salesman" || selectedRole == "Sales Officer" || selectedRole == "Area Sales manager"
    || selectedRole == "Regional Sales Manager" || selectedRole == "Zone Wise Sales Manager" || selectedRole == "Sales Head"){
      // Routes all field/salesman roles (Salesman, SO, ASM, RSM, ZSM, Sales Head) to Salesman Dashboard
      Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()),);
    }
    else if (selectedRole == "Super Stockiest") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SuperStockistPortal()));
    }
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
                        'Fresh Taste, Trusted Quality',
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
                                  _sectionTitle('Log In'),
                                  const SizedBox(height: 20),
                                  _buildDropdown(),
                                  const SizedBox(height: 14),
                                  buildIconField(Icons.person_outline, 'Mobile or Gmail'),
                                  const SizedBox(height: 14),
                                  buildIconField(Icons.lock_outline, 'Password', isPassword: true),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const ResetPwd()),
                                          );
                                        },
                                        child: Text('Forgot Password?', style: GoogleFonts.plusJakartaSans(color: _Palette.ink, fontWeight: FontWeight.w600, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _GradientButton(
                                    label: 'LOGIN',
                                    icon: Icons.login_rounded,
                                    onPressed: _handleLogin,
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('New User? ', style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 13)),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const Registeration()),
                                          );
                                        },
                                        child: Text('Register', style: GoogleFonts.plusJakartaSans(color: _Palette.espresso, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 13)),
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: _Palette.border),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: roles.contains(selectedRole) ? selectedRole : null,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: _Palette.espresso,
          ),
          hint: Text(
            'Select Role',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          items: roles.map((String role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Row(
                children: [
                  _iconBadge(Icons.badge_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      role,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: _Palette.espresso,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedRole = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget buildIconField(IconData icon, String hint, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword ? hidePassword : false,
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _Palette.haloGold.withOpacity(0.85),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _Palette.haloGold.withOpacity(glowOpacity),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.logoBg,
              border: Border.all(
                color: _Palette.gold,
                width: 1.8,
              ),
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
                    size: 40,
                  ),
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
  const _GradientButton({required this.label, required this.icon, required this.onPressed});

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
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Palette.espresso, _Palette.espressoDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _Palette.gold.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20, color: _Palette.goldLight),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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