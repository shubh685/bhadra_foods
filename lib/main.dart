import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin_Dashboard.dart';
import 'Log_In.dart';
import 'Salesman_Dashboard.dart';

const String API_URL = 'http://192.168.0.102/bhadra_foods/login.php';

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

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
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

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      _checkAutoLoginWithBackend();
    });
  }

  Future<void> _checkAutoLoginWithBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String savedUsername = prefs.getString('saved_username') ?? '';
    final String savedPassword = prefs.getString('saved_password') ?? '';
    final String savedRole = prefs.getString('role') ?? '';

    Widget targetScreen = const Login();

    if (isLoggedIn && savedUsername.isNotEmpty && savedPassword.isNotEmpty && savedRole.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(API_URL),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': savedUsername,
            'password': savedPassword,
            'role': savedRole,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == 'success' && data['user'] != null) {
            final user = data['user'];
            String role = user['role'] ?? savedRole;
            String empId = user['emp_id'] ?? '';
            String name = user['name'] ?? '';
            String email = user['email'] ?? '';

            // Refresh stored details
            await prefs.setString('emp_id', empId);
            await prefs.setString('name', name);
            await prefs.setString('email', email);
            await prefs.setString('role', role);

            if (role.toLowerCase() == 'admin') {
              targetScreen = const AdminDashboard();
            } else {
              targetScreen = DashboardScreen(
                loggedInRole: role,
                loggedInUserId: empId,
                loggedInUserName: name,
                email: email,
              );
            }
          } else {
            await prefs.clear();
          }
        } else {
          await prefs.clear();
        }
      } catch (e) {
        debugPrint("Auto Login Verification Failed: $e");
        await prefs.clear();
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
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
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