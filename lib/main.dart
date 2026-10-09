import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin_Dashboard.dart';
import 'Log_In.dart';
import 'Salesman_Dashboard.dart';

// ✅ Use the SAME API endpoint as Log_In.dart so login + auto-login stay consistent
const String API_URL = 'https://gray-dragonfly-662322.hostingersite.com/bhadra_foods/login.php';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // After splash animation, try auto-login
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      _checkAutoLoginWithBackend();
    });
  }

  // ============================================================
  // ✅ AUTO-LOGIN — Supports Admin + ALL Sales Roles
  // Reads saved credentials from SharedPreferences, verifies with
  // login.php, and routes to the correct dashboard.
  // ============================================================
  Future<void> _checkAutoLoginWithBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // ✅ Saved credential keys (must match what Log_In.dart stores)
    final String savedUsername = prefs.getString('username') ?? '';
    final String savedPassword = prefs.getString('password') ?? '';
    final String savedRole     = prefs.getString('role')     ?? '';

    Widget targetScreen = const Login();

    // Only attempt verification when all saved fields exist
    if (isLoggedIn &&
        savedUsername.isNotEmpty &&
        savedPassword.isNotEmpty &&
        savedRole.isNotEmpty) {
      try {
        final response = await http
            .post(
          Uri.parse(API_URL),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            // ✅ MUST use 'username' key — login.php reads $data['username']
            'username': savedUsername,
            'password': savedPassword,
            'role':     savedRole,
          }),
        )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == 'success' && data['user'] != null) {
            final user = data['user'];

            final String role  = user['role']?.toString()      ?? savedRole;
            final String empId = user['emp_id']?.toString()    ?? '';
            final String name  = user['name']?.toString()      ?? '';
            final String email = user['email']?.toString()     ?? '';
            final String mobile= user['mobile']?.toString()    ?? '';

            // ✅ Refresh stored details so next launch stays in sync
            await prefs.setString('emp_id',   empId);
            await prefs.setString('name',     name);
            await prefs.setString('email',    email);
            await prefs.setString('mobile',   mobile);
            await prefs.setString('role',     role);
            await prefs.setString('username', savedUsername);
            await prefs.setString('password', savedPassword);
            await prefs.setBool('isLoggedIn', true);

            // ✅ Normalize role for robust checking (handles lowercase & trimming)
            final String normalizedRole = role.toLowerCase().trim();

            if (normalizedRole == 'admin') {
              // ---- ADMIN ----
              targetScreen = const AdminDashboard();
            } else if (normalizedRole == 'salesman' ||
                normalizedRole == 'sales officer' ||
                normalizedRole == 'asm' ||
                normalizedRole == 'rsm' ||
                normalizedRole == 'zsm' ||
                normalizedRole == 'area sales manager' ||
                normalizedRole == 'regional sales manager' ||
                normalizedRole == 'zone wise sales manager' ||
                normalizedRole == 'sales head') {
              // ---- ALL SALES ROLES ----
              targetScreen = DashboardScreen(
                loggedInRole: role,
                loggedInUserId: empId,
                loggedInUserName: name,
                email: email,
                mobile: mobile,
              );
            } else {
              // Unknown role → force fresh login
              await prefs.clear();
              targetScreen = const Login();
            }
          } else {
            // Invalid session → clear & go to login
            await prefs.clear();
            targetScreen = const Login();
          }
        } else {
          await prefs.clear();
          targetScreen = const Login();
        }
      } catch (e) {
        debugPrint("Auto Login Verification Failed: $e");
        await prefs.clear();
        targetScreen = const Login();
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => targetScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
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
              colors: [Color(0xFF3D1F03), Color(0xFF1D0E02)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFD4AF37), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color:
                            const Color(0xFFD4AF37).withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/photos/bfs.jpg',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        'Presented By Shivro Tech IT Solutions',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}