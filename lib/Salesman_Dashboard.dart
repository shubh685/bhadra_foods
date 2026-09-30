import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Log_In.dart';

// API Base URL
const String API_BASE_URL = 'http://192.168.0.104/bhadra_foods/';

class _AdminPalette {
  static const darkHeaderTop = Color(0xFF381C00);
  static const darkHeaderBottom = Color(0xFF1E0E00);
  static const primaryBrown = Color(0xFF4E2613);
  static const goldAccent = Color(0xFFE2BA55);
  static const goldLight = Color(0xFFF7D57F);
  static const bgWarm = Color(0xFFFBF6EE);
  static const cardBg = Color(0xFFFFFDF5);
  static const cardHeaderBg = Color(0xFFF4EBD9);
  static const border = Color(0xFFE8D3A7);
  static const inkDark = Color(0xFF2E1A05);
  static const whatsappGreen = Color(0xFF25D366);
  static const darkModalBg = Color(0xFF1A2130);
  static const darkInputBg = Color(0xFF242F42);
}

class HierarchyUserLocation {
  final String roleKey;
  final String roleTitle;
  final String name;
  final String userId;
  final Color themeColor;
  String addressLocation;
  String assignedRoute;
  double? latitude;
  double? longitude;
  bool isOnline;

  HierarchyUserLocation({
    required this.roleKey,
    required this.roleTitle,
    required this.name,
    required this.userId,
    required this.themeColor,
    required this.addressLocation,
    this.assignedRoute = 'Not Assigned',
    this.latitude,
    this.longitude,
    this.isOnline = false,
  });
}

class DashboardScreen extends StatefulWidget {
  final String loggedInRole;
  final String loggedInUserId;
  final String loggedInUserName;
  final String email;

  const DashboardScreen({
    super.key,
    this.loggedInRole = 'Salesman',
    this.loggedInUserId = 'BHFSM-01',
    this.loggedInUserName = 'Shubham Shah',
    this.email = "shubham@bhadrafoods.com",
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String userRole;
  late String userId;
  late String userName;
  late String userEmail;
  String? assignedRoute;

  bool isCheckedIn = false;
  late Stream<DateTime> _clockStream;
  StreamSubscription<Position>? _positionStreamSub;
  Timer? _minuteLocationTimer;
  Timer? _punchCheckTimer;

  String? currentLiveAddress = "Fetching live GPS location...";
  double? currentLatitude;
  double? currentLongitude;
  bool isGpsEnabled = false;
  File? capturedImageFile;
  String? lastPunchType;
  String? capturedPhotoUrl;
  String? lastPunchDate;
  String? lastPunchTime;
  String? lastPunchDay;

  List<Map<String, dynamic>> attendanceHistory = [];

  final ImagePicker _picker = ImagePicker();
  FaceDetector? _faceDetector;
  bool _faceDetectorInitialized = false;

  final _taskFormKey = GlobalKey<FormState>();
  final _firmNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  Map<String, List<Map<String, dynamic>>> productCatalog = {};
  List<Map<String, dynamic>> rawProductList = [];
  String? selectedCategory;
  String? selectedProductName;
  double selectedProductPrice = 0.0;

  // Leave Management
  final List<String> leaveTypes = [
    'Casual Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Half Day Leave',
    'Sick Leave'
  ];
  String selectedLeaveType = 'Casual Leave';
  final TextEditingController _leaveReasonController = TextEditingController();
  DateTimeRange? _selectedLeaveDateRange;
  List<Map<String, dynamic>> leaveHistory = [];
  // Firm selection with multi-select checkboxes
  Set<String> _selectedFirmsMulti = {};
  bool _showFirmDropdown = false;
  bool _isLoadingFirms = false;
  // Daily Reports & Company Firms
  List<Map<String, dynamic>> dailyTaskHistory = [];
  List<dynamic> hierarchyList = [];
  bool isLoadingHierarchy = true;

  // Registered firms cache for dropdown
  Set<String> _registeredFirms = {};
  bool _isAddingNewFirm = false;
  String? _selectedFirm;

  // Role visibility map (Determines Hierarchy Logic)
  Map<String, List<String>> get roleVisibilityMap => {
    'Salesman': ['Salesman'],
    'Sales Officer': ['Salesman', 'Sales Officer'],
    'ASM': ['Salesman', 'Sales Officer', 'ASM'],
    'RSM': ['Salesman', 'Sales Officer', 'ASM', 'RSM'],
    'ZSM': ['Salesman', 'Sales Officer', 'ASM', 'RSM', 'ZSM'],
    'Sales Head': [
      'Salesman',
      'Sales Officer',
      'ASM',
      'RSM',
      'ZSM',
      'Sales Head'
    ],
  };

  bool get isPunchOutAllowed {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final startTime = 9 * 60;
    final endTime = 18 * 60;

    if (now.weekday == DateTime.sunday) return false;
    return currentTimeInMinutes >= startTime && currentTimeInMinutes <= endTime;
  }

  String getPunchOutStatus() {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final endTime = 18 * 60;

    if (now.weekday == DateTime.sunday) {
      return "⛔ Sunday - Punch Out Restricted";
    }
    if (currentTimeInMinutes < 9 * 60) {
      final remaining = (9 * 60) - currentTimeInMinutes;
      return "⏳ Punch Out starts at 9 AM (${remaining ~/ 60}h ${remaining % 60}m left)";
    } else if (currentTimeInMinutes >= endTime) {
      return "✅ Time for Auto Punch Out (After 6 PM)";
    } else {
      final remaining = endTime - currentTimeInMinutes;
      return "✅ Punch Out available (${remaining ~/ 60}h ${remaining % 60}m left)";
    }
  }

  @override
  void initState() {
    super.initState();
    userRole = widget.loggedInRole;
    userId = widget.loggedInUserId;
    userName = widget.loggedInUserName;
    userEmail = widget.email;

    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());

    _initFaceDetector();
    _initLiveGpsTracking();
    _start1MinLocationTimer();
    _startPunchCheckTimer();

    _fetchProductCatalog();
    _fetchAttendanceStatus();
    _fetchDailyReports();
    _fetchAssignedRoute();
    _fetchLeaveHistory();
    fetchHierarchyAndRoutes();
  }

  Future<void> _initFaceDetector() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: true,
          enableContours: true,
          enableClassification: true,
          minFaceSize: 0.1,
        ),
      );
      _faceDetectorInitialized = true;
    } catch (e) {
      debugPrint("Face detector init error: $e");
    }
  }

  // ============================================================
  // HIERARCHY & LIVE LOCATION
  // ============================================================
  Future<void> fetchHierarchyAndRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true || jsonResponse['status'] == 'success') {
          final List data = jsonResponse['data'] ?? [];
          final visibleRoles = roleVisibilityMap[userRole] ?? [userRole];

          final filtered = data.where((item) {
            final role = item['role']?.toString() ?? '';
            return visibleRoles.contains(role);
          }).toList();

          if (mounted) {
            setState(() {
              hierarchyList = filtered;
              isLoadingHierarchy = false;
            });
          }
        } else {
          if (mounted) setState(() => isLoadingHierarchy = false);
        }
      }
    } catch (e) {
      debugPrint("Error fetching live hierarchy: $e");
      if (mounted) setState(() => isLoadingHierarchy = false);
    }
  }

  Future<void> _refreshHierarchyLiveLocations() async {
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true || jsonResponse['status'] == 'success') {
          final List data = jsonResponse['data'] ?? [];
          final visibleRoles = roleVisibilityMap[userRole] ?? [userRole];
          final filtered = data.where((item) {
            final role = item['role']?.toString() ?? '';
            return visibleRoles.contains(role);
          }).toList();

          if (mounted) {
            setState(() {
              hierarchyList = filtered;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Hierarchy live refresh error: $e");
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _minuteLocationTimer?.cancel();
    _punchCheckTimer?.cancel();
    try {
      _faceDetector?.close();
    } catch (_) {}
    _firmNameController.dispose();
    _mobileController.dispose();
    _pinCodeController.dispose();
    _qtyController.dispose();
    _leaveReasonController.dispose();
    super.dispose();
  }

  void _startPunchCheckTimer() {
    _punchCheckTimer?.cancel();
    _punchCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchAttendanceStatus();
    });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _AdminPalette.bgWarm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text("Logout Confirmation",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.8)),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                ctx,
                MaterialPageRoute(builder: (ctx) => const Login()),
                    (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully!")),
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool hideOld = true;
    bool hideNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: _AdminPalette.bgWarm,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.lock_reset, color: _AdminPalette.primaryBrown),
                      SizedBox(width: 8),
                      Text("Change Password",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _AdminPalette.inkDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldController,
                    obscureText: hideOld,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(hideOld
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setModalState(() => hideOld = !hideOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: hideNew,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(hideNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setModalState(() => hideNew = !hideNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: hideNew,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AdminPalette.primaryBrown,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (newController.text.isNotEmpty &&
                            newController.text == confirmController.text &&
                            newController.text.length >= 4) {
                          _changePassword(userId, userRole, oldController.text,
                              newController.text);
                          Navigator.pop(ctx);
                        } else if (newController.text.length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Password must be at least 4 characters!")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Passwords do not match!")),
                          );
                        }
                      },
                      child: const Text("Update Password",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changePassword(String identifier, String role,
      String oldPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${API_BASE_URL}change_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': identifier,
          'role': role,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Password update status'),
              backgroundColor:
              result['status'] == true ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password Change Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchAssignedRoute() async {
    try {
      final response = await http.get(
        Uri.parse("${API_BASE_URL}manage_salesman.php?emp_id=$userId"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == true || data['status'] == 'success') &&
            data['data'] != null) {
          final users = data['data'] as List;
          for (var user in users) {
            final fetchedEmpId = user['emp_id']?.toString() ?? '';
            final matchesId = fetchedEmpId == userId ||
                user['id']?.toString() == userId;
            if (matchesId) {
              if (mounted) {
                setState(() {
                  // ✅ Use the proper emp_id STRING from DB (e.g. BHFSM-01)
                  if (fetchedEmpId.isNotEmpty) {
                    userId = fetchedEmpId;
                  }
                  assignedRoute = user['assigned_route'] ?? 'Not Assigned';
                  if ((user['name']?.toString() ?? '').isNotEmpty) {
                    userName = user['name'].toString();
                  }
                  if ((user['email']?.toString() ?? '').isNotEmpty) {
                    userEmail = user['email'].toString();
                  }
                });
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Route Fetch Error: $e");
    }
  }

  Future<void> _fetchProductCatalog() async {
    try {
      final response = await http.get(Uri.parse("${API_BASE_URL}catelog.php"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == true || data['status'] == 'success') &&
            data['data'] != null) {
          rawProductList = List<Map<String, dynamic>>.from(data['data']);
          Map<String, List<Map<String, dynamic>>> tempCatalog = {};

          for (var item in rawProductList) {
            String cat = item['category'] ?? 'General';
            if (!tempCatalog.containsKey(cat)) {
              tempCatalog[cat] = [];
            }
            tempCatalog[cat]!.add({
              'id': item['id'],
              'name': item['name'],
              'price': double.tryParse(item['price'].toString()) ?? 0.0,
              'sub_category': item['sub_category'] ?? ''
            });
          }

          if (mounted) {
            setState(() {
              productCatalog = tempCatalog;
              if (productCatalog.isNotEmpty) {
                selectedCategory = productCatalog.keys.first;
                if (productCatalog[selectedCategory]!.isNotEmpty) {
                  selectedProductName =
                  productCatalog[selectedCategory]!.first['name'];
                  selectedProductPrice =
                  productCatalog[selectedCategory]!.first['price'];
                }
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Catalog API Fetch Error: $e");
    }
  }

  void _showCatalogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _AdminPalette.bgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Product Catalog",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _AdminPalette.inkDark)),
            const Divider(),
            Expanded(
              child: rawProductList.isEmpty
                  ? const Center(child: Text("No products found."))
                  : ListView.builder(
                itemCount: rawProductList.length,
                itemBuilder: (ctx, idx) {
                  final item = rawProductList[idx];
                  return Card(
                    color: _AdminPalette.cardBg,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: _AdminPalette.cardHeaderBg,
                        child: Icon(Icons.inventory_2,
                            color: _AdminPalette.primaryBrown),
                      ),
                      title: Text(item['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "Category: ${item['category']} | Sub: ${item['sub_category'] ?? 'N/A'}"),
                      trailing: Text("₹${item['price']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ATTENDANCE — FIXED for get_attendance.php
  // ============================================================
  Future<void> _fetchAttendanceStatus() async {
    try {
      final response = await http
          .get(Uri.parse("${API_BASE_URL}get_attendance.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true && mounted) {
          final List history = data['history'] ?? data['data'] ?? [];

          String? latestPunchType;
          if (history.isNotEmpty) {
            latestPunchType = history.first['punch_type']?.toString();
          }

          setState(() {
            attendanceHistory = List<Map<String, dynamic>>.from(history);
            isCheckedIn = latestPunchType == 'PUNCH_IN';

            if (history.isNotEmpty) {
              final latest = history.first;
              lastPunchType = latest['punch_type'];
              capturedPhotoUrl = latest['photo'];
              lastPunchDate = latest['punch_date'];
              lastPunchTime = latest['punch_time'];
              lastPunchDay = latest['day'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Attendance API Error: $e");
    }
  }

  void _showAttendanceHistoryModal() {
    _fetchAttendanceStatus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: _AdminPalette.bgWarm,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Attendance History",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _AdminPalette.inkDark)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: _AdminPalette.primaryBrown),
                        onPressed: () async {
                          await _fetchAttendanceStatus();
                          setModalState(() {});
                        },
                        tooltip: "Refresh",
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: attendanceHistory.isEmpty
                    ? const Center(child: Text("No attendance history found"))
                    : ListView.builder(
                  itemCount: attendanceHistory.length,
                  itemBuilder: (ctx, idx) {
                    final item = attendanceHistory[idx];
                    final isPunchIn = item['punch_type'] == 'PUNCH_IN';
                    final photo = item['photo'];

                    return Card(
                      color: _AdminPalette.cardBg,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPunchIn
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            isPunchIn ? Icons.login : Icons.logout,
                            color: isPunchIn ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          isPunchIn ? "Punch In" : "Punch Out",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          "📅 ${item['punch_date'] ?? ''} 🕐 ${item['punch_time'] ?? ''}\n📆 ${item['day'] ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: photo != null && photo.toString().isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photo.toString().startsWith('http')
                                ? photo.toString()
                                : '${API_BASE_URL}${photo.toString()}',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 40),
                          ),
                        )
                            : null,
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Submit Punch API — passing explicit device time
  Future<void> _submitPunchApi(File photoFile, String punchType, {bool isAuto = false}) async {
    try {
      var request = http.MultipartRequest(
          "POST", Uri.parse("${API_BASE_URL}punch_attendance.php"));
      request.fields['emp_id'] = userId;
      request.fields['role'] = userRole;
      request.fields['punch_type'] = punchType;
      request.fields['latitude'] = (currentLatitude ?? 0.0).toString();
      request.fields['longitude'] = (currentLongitude ?? 0.0).toString();

      // Pass proper device time as requested
      request.fields['device_date'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      request.fields['device_time'] = DateFormat('HH:mm:ss').format(DateTime.now());
      request.fields['is_auto'] = isAuto ? '1' : '0';

      if (photoFile.path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' || data['status'] == true) {
          if (mounted) {
            setState(() {
              isCheckedIn = (punchType == 'PUNCH_IN');
              if (!isAuto) capturedImageFile = photoFile;
              lastPunchType = punchType;
              capturedPhotoUrl = data['photo_url'] ?? capturedPhotoUrl;
              lastPunchDate = data['punch_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
              lastPunchTime = data['punch_time'] ?? DateFormat('HH:mm:ss').format(DateTime.now());
              lastPunchDay = data['day'] ?? DateFormat('EEEE').format(DateTime.now());
            });
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(data['message'] ?? (isAuto ? 'Auto-Punched out successfully!' : 'Punch recorded successfully!')),
            ),
          );
          _fetchAttendanceStatus();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(data['message'] ?? 'Punch failed!'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("Punch Submission Error: $e")),
      );
    }
  }

  // ============================================================
  // LEAVE MANAGEMENT
  // ============================================================
  Future<void> _fetchLeaveHistory() async {
    try {
      final response = await http.get(
        Uri.parse("${API_BASE_URL}manage_leaves.php?emp_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == true || data['status'] == 'success') && mounted) {
          setState(() {
            leaveHistory = List<Map<String, dynamic>>.from(
                data['leaves'] ?? data['data'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint("Leave History API Error: $e");
    }
  }

  Future<void> _submitLeaveApi(String type, String startDate, String endDate,
      String reason) async {
    try {
      final response = await http.post(
        Uri.parse("${API_BASE_URL}manage_leaves.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'emp_id': userId,
          'leave_type': type,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          await _fetchLeaveHistory();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text("Leave Application Submitted!")),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.red,
                content: Text(data['message'] ?? 'Failed to submit leave')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to submit leave: $e")),
      );
    }
  }

  void _showLeaveApplicationDialog() {
    _selectedLeaveDateRange = null;
    _leaveReasonController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: _AdminPalette.darkModalBg,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Leave Application",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedLeaveType,
                    dropdownColor: _AdminPalette.darkInputBg,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: leaveTypes
                        .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setDialogState(() => selectedLeaveType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _AdminPalette.darkInputBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.calendar_today,
                          color: Colors.redAccent, size: 16),
                      label: Text(
                        _selectedLeaveDateRange == null
                            ? "Select Date Range"
                            : "${DateFormat('dd-MM-yyyy').format(_selectedLeaveDateRange!.start)} to ${DateFormat('dd-MM-yyyy').format(_selectedLeaveDateRange!.end)}",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null)
                          setDialogState(
                                  () => _selectedLeaveDateRange = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _leaveReasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "Reason for Leave",
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.white54)),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B)),
                        onPressed: () {
                          if (_selectedLeaveDateRange != null &&
                              _leaveReasonController.text.isNotEmpty) {
                            String start =
                                "${_selectedLeaveDateRange!.start.year}-${_selectedLeaveDateRange!.start.month.toString().padLeft(2, '0')}-${_selectedLeaveDateRange!.start.day.toString().padLeft(2, '0')}";
                            String end =
                                "${_selectedLeaveDateRange!.end.year}-${_selectedLeaveDateRange!.end.month.toString().padLeft(2, '0')}-${_selectedLeaveDateRange!.end.day.toString().padLeft(2, '0')}";

                            _submitLeaveApi(selectedLeaveType, start, end,
                                _leaveReasonController.text);
                            _leaveReasonController.clear();
                            _selectedLeaveDateRange = null;
                            Navigator.pop(ctx);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please fill all fields")),
                            );
                          }
                        },
                        child: const Text("Submit Leave",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLeaveHistoryModal() {
    _fetchLeaveHistory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: _AdminPalette.bgWarm,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Leave History",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _AdminPalette.inkDark)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: _AdminPalette.primaryBrown),
                          onPressed: () async {
                            await _fetchLeaveHistory();
                            setModalState(() {});
                          },
                          tooltip: "Refresh",
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: leaveHistory.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty,
                            size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No leave history found",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: leaveHistory.length,
                    itemBuilder: (ctx, idx) {
                      final item = leaveHistory[idx];
                      Color statusColor = Colors.orange;
                      if (item['status'] == 'Approved')
                        statusColor = Colors.green;
                      if (item['status'] == 'Rejected')
                        statusColor = Colors.red;

                      return Card(
                        color: _AdminPalette.cardBg,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item['leave_type'] == 'Casual Leave'
                                  ? Icons.beach_access
                                  : item['leave_type'] == 'Sick Leave'
                                  ? Icons.medication
                                  : item['leave_type'] ==
                                  'Maternity Leave'
                                  ? Icons.family_restroom
                                  : item['leave_type'] ==
                                  'Paternity Leave'
                                  ? Icons.people
                                  : Icons.calendar_today,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          title: Text(item['leave_type'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  "📅 ${item['start_date']} to ${item['end_date']}",
                                  style: const TextStyle(fontSize: 12)),
                              Text("📝 ${item['reason']}",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              Text("🕐 ${item['created_at'] ?? ''}",
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: statusColor, width: 1.5),
                            ),
                            child: Text(
                              item['status'] ?? 'Pending',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (leaveHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _AdminPalette.cardHeaderBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLeaveStatSalesman("Total", leaveHistory.length,
                            Colors.grey),
                        _buildLeaveStatSalesman(
                            "Pending",
                            leaveHistory
                                .where((l) => l['status'] == 'Pending')
                                .length,
                            Colors.orange),
                        _buildLeaveStatSalesman(
                            "Approved",
                            leaveHistory
                                .where((l) => l['status'] == 'Approved')
                                .length,
                            Colors.green),
                        _buildLeaveStatSalesman(
                            "Rejected",
                            leaveHistory
                                .where((l) => l['status'] == 'Rejected')
                                .length,
                            Colors.red),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaveStatSalesman(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ============================================================
  // WHATSAPP ORDER
  // ============================================================
  Future<void> _sendWhatsAppOrderAndSave() async {
    if (_taskFormKey.currentState?.validate() != true) return;

    final firmName = _firmNameController.text;
    final mobile = _mobileController.text;
    final pinCode = _pinCodeController.text;
    final productName = selectedProductName ?? '';
    final qty = _qtyController.text;
    final total = calculatedTotal.toStringAsFixed(2);

    final message = """
*New Order Request*
━━━━━━━━━━━━━━━━━━
*Firm:* $firmName
*Mobile:* $mobile
*PIN Code:* $pinCode
*Item Name:* $productName
*Quantity:* $qty
*Total Amount:* ₹$total
*Location Address:* $currentLiveAddress
━━━━━━━━━━━━━━━━━━
*Sales Representative:* $userName ($userId)
*Timestamp:* ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}
    """;

    final encodedMessage = Uri.encodeFull(message);
    final waUrl = Uri.parse("https://wa.me/919512312400?text=$encodedMessage");

    try {
      await _submitDailyReportApi();
      final bool launched =
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Unable to launch WhatsApp application.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Execution Error: $e")),
        );
      }
    }
  }

  // ============================================================
  // DAILY REPORTS
  // ============================================================
  Future<void> _submitDailyReportApi() async {
    // ── Determine firms to submit (checkbox selection OR text field) ──
    final firmName = _firmNameController.text.trim();

    // If user selected firms via checkboxes → use them
    // Else fall back to whatever is in the firm name field
    final List<String> firmsToSubmit = _selectedFirmsMulti.isNotEmpty
        ? _selectedFirmsMulti.toList()
        : (firmName.isNotEmpty ? [firmName] : []);

    if (firmsToSubmit.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.red,
              content: Text("Please enter firm name")),
        );
      }
      return;
    }

    int successCount = 0;
    String lastMessage = '';
    String? lastError;

    // ── Submit each firm using the SAME request shape as method 1 ──
    for (final singleFirm in firmsToSubmit) {
      try {
        final response = await http.post(
          Uri.parse("${API_BASE_URL}manage_daily_reports.php"),
          body: {
            'emp_id': userId,
            'firm_name': singleFirm,
            'mobile': _mobileController.text,
            'pin_code': _pinCodeController.text,
            'category': selectedCategory ?? '',
            'product_name': selectedProductName ?? '',
            'price': selectedProductPrice.toString(),
            'quantity': _qtyController.text,
            'total_amount': calculatedTotal.toString(),
            'latitude': (currentLatitude ?? 0.0).toString(),
            'longitude': (currentLongitude ?? 0.0).toString(),
            'address': currentLiveAddress ?? '',
          },
        );

        // ── SAME parsing logic as method 1 ──
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == true || data['status'] == 'success') {
            successCount++;
            lastMessage = data['message'] ?? 'Order successfully logged in Database!';
            // Track locally (also re-synced from DB below)
            _registeredFirms.add(singleFirm);
          } else {
            lastError = data['message'] ?? 'Failed to save order';
          }
        } else {
          lastError = 'Server error: ${response.statusCode}';
        }
      } catch (e) {
        lastError = "Daily Report Order Error: $e";
      }
    }

    // ══════════════════════════════════════════════════════════════
    // ── SAME post-success flow as method 1 ──
    // ══════════════════════════════════════════════════════════════
    if (successCount > 0) {
      // 1. Refresh from DB (re-syncs _registeredFirms from daily_reports)
      _fetchDailyReports();

      // 2. Clear all form controllers — same as method 1
      _firmNameController.clear();
      _mobileController.clear();
      _pinCodeController.clear();
      _qtyController.text = '1';

      // 3. Reset selection state — same as method 1 + extra multi-select cleanup
      setState(() {
        _selectedFirm = null;
        _isAddingNewFirm = false;
        _showFirmDropdown = false;
        _selectedFirmsMulti.clear();
      });

      if (!mounted) return;

      // 4. Snackbar — same wording pattern, extended for multi-firm
      final bool isPartial = successCount < firmsToSubmit.length;
      final String message = isPartial
          ? "$successCount of ${firmsToSubmit.length} orders saved. ${lastError ?? ''}"
          : (firmsToSubmit.length > 1
          ? "$successCount orders successfully logged!"
          : (lastMessage.isNotEmpty
          ? lastMessage
          : "Order successfully logged in Database!"));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isPartial ? Colors.orange : Colors.green,
          content: Text(message),
        ),
      );
    } else {
      // ── SAME failure flow as method 1 ──
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(lastError ?? 'Failed to save order'),
        ),
      );
    }
  }

  Future<void> _fetchDailyReports() async {
    try {
      final response = await http.get(
        Uri.parse("${API_BASE_URL}manage_daily_reports.php?emp_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if ((data['status'] == true || data['status'] == 'success') &&
            data['reports'] != null) {
          if (!mounted) return;
          setState(() {
            dailyTaskHistory = List<Map<String, dynamic>>.from(
              (data['reports'] as List)
                  .map((item) => Map<String, dynamic>.from(item)),
            );

            // ✅ Repopulate registered firms from daily_reports
            _registeredFirms.clear();
            for (var r in dailyTaskHistory) {
              final fn = r['firm_name']?.toString().trim();
              if (fn != null && fn.isNotEmpty) {
                _registeredFirms.add(fn);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Daily Report Fetching Error: $e");
    }
  }

  void _showDailyTaskHistoryModal() {
    _fetchDailyReports();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: _AdminPalette.cardBg,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Daily Orders Logged",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _AdminPalette.inkDark)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: _AdminPalette.primaryBrown),
                            onPressed: () async {
                              await _fetchDailyReports();
                              setDialogState(() {});
                            },
                            tooltip: "Refresh",
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  if (dailyTaskHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("No daily reports logged.",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                          MediaQuery.of(context).size.height * 0.55,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: dailyTaskHistory.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, idx) {
                            final item = dailyTaskHistory[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_long,
                                    color: Colors.green, size: 20),
                              ),
                              title: Text(item['firm_name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      "📦 ${item['category'] ?? ''} • ${item['product_name'] ?? ''}",
                                      style:
                                      const TextStyle(fontSize: 12)),
                                  Text(
                                      "Qty: ${item['quantity']} × ₹${item['price']}",
                                      style:
                                      const TextStyle(fontSize: 11)),
                                  Text("📍 ${item['address'] ?? 'N/A'}",
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey)),
                                  Text("🕐 ${item['created_at'] ?? ''}",
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey)),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text("₹${item['total_amount']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (dailyTaskHistory.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _AdminPalette.cardHeaderBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Orders:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text("${dailyTaskHistory.length}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // GEOLOCATOR GPS TRACKING & AUTO PUNCH OUT
  // ============================================================
  void _start1MinLocationTimer() {
    _minuteLocationTimer?.cancel();
    _minuteLocationTimer =
        Timer.periodic(const Duration(minutes: 1), (_) async {
          await _fetchAndUpdateCurrentLocation();
          await _refreshHierarchyLiveLocations();
          _checkAutoPunchOut();
        });
  }

  Future<void> _checkAutoPunchOut() async {
    final now = DateTime.now();
    if (isCheckedIn && now.hour >= 18) {
      File dummyFile = capturedImageFile ?? File('');
      await _submitPunchApi(dummyFile, 'PUNCH_OUT', isAuto: true);
    }
  }

  Future<void> _fetchAndUpdateCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      await _updateAddressFromPosition(pos);
    } catch (e) {
      debugPrint("Location update error: $e");
    }
  }

  Future<void> _initLiveGpsTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        currentLiveAddress = "GPS location disabled";
        isGpsEnabled = false;
      });
      return;
    }

    if (mounted) setState(() => isGpsEnabled = true);

    PermissionStatus permStatus = await Permission.locationWhenInUse.status;
    if (permStatus.isDenied) {
      permStatus = await Permission.locationWhenInUse.request();
    }

    if (!permStatus.isGranted) {
      if (!mounted) return;
      setState(() => currentLiveAddress = "Location permission denied");
      return;
    }

    try {
      final Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      await _updateAddressFromPosition(initialPosition);
    } catch (e) {
      if (mounted) {
        setState(() => currentLiveAddress = "Unable to fetch GPS position.");
      }
    }

    await _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) => _updateAddressFromPosition(position));
  }

  Future<void> _updateAddressFromPosition(Position position) async {
    String resolvedAddress;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode
        ].where((p) => p != null && p.trim().isNotEmpty).toList();
        resolvedAddress = parts.isNotEmpty
            ? parts.join(', ')
            : "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      } else {
        resolvedAddress =
        "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      }
    } catch (e) {
      resolvedAddress =
      "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
    }

    if (!mounted) return;
    setState(() {
      currentLiveAddress = resolvedAddress;
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
    });
  }

  // ============================================================
  // FACE DETECTION & SELFIE PUNCH
  // ============================================================
  Future<Map<String, dynamic>> _analyzeFace(File imageFile) async {
    try {
      if (_faceDetector == null || !_faceDetectorInitialized) {
        await _initFaceDetector();
      }
      if (_faceDetector == null) {
        return {'faces': [], 'message': 'Face detector unavailable'};
      }

      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        return {'faces': [], 'message': 'No face detected'};
      }

      final face = faces.first;
      Map<String, dynamic> faceFeatures = {
        'hasSmile': (face.smilingProbability ?? 0.0) > 0.5,
        'smileProbability': face.smilingProbability ?? 0.0,
        'leftEyeOpen': face.leftEyeOpenProbability ?? 0.0,
        'rightEyeOpen': face.rightEyeOpenProbability ?? 0.0,
      };

      return {
        'faces': faces,
        'features': faceFeatures,
        'message': 'Face verified!'
      };
    } catch (e) {
      debugPrint("Face analysis error: $e");
      return {'faces': [], 'message': 'Face analysis failed: $e'};
    }
  }

  Future<void> _triggerSelfiePunch() async {
    if (isCheckedIn && !isPunchOutAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
              "Punch Out allowed between 9:00 AM and 6:00 PM!\n${getPunchOutStatus()}"),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (isCheckedIn && lastPunchType == 'PUNCH_OUT') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("You have already checked out today!"),
        ),
      );
      return;
    }

    try {
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        cameraStatus = await Permission.camera.request();
      }

      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.red,
              content: Text("Camera permission required.")),
        );
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (photo == null) return;

      File imageFile = File(photo.path);
      if (!await imageFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.red,
              content: Text("Captured image not found.")),
        );
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingCtx) => const Center(
          child: CircularProgressIndicator(color: _AdminPalette.goldAccent),
        ),
      );

      final result = await _analyzeFace(imageFile);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (result['faces'] == null || (result['faces'] as List).isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: _AdminPalette.cardBg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text("Face Not Detected",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
                "No face was detected in the photo. Do you want to proceed with the punch anyway?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child:
                const Text("Retry", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AdminPalette.primaryBrown,
                ),
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  final nextPunchType =
                  isCheckedIn ? 'PUNCH_OUT' : 'PUNCH_IN';
                  await _submitPunchApi(imageFile, nextPunchType);
                },
                child: const Text("Proceed",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return;
      }

      final bool hasSmile = result['features']?['hasSmile'] ?? false;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: _AdminPalette.cardBg,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSmile ? Icons.emoji_emotions : Icons.face,
                color: hasSmile ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasSmile ? "Face Verified with Smile!" : "Face Verified!",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person, size: 60),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _AdminPalette.bgWarm,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "📍 ${currentLiveAddress ?? 'N/A'}",
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "🕐 ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}",
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child:
              const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _AdminPalette.primaryBrown,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final nextPunchType = isCheckedIn ? 'PUNCH_OUT' : 'PUNCH_IN';
                await _submitPunchApi(imageFile, nextPunchType);
              },
              child: Text(
                isCheckedIn ? "Confirm Punch Out" : "Confirm Punch In",
                style: const TextStyle(color: _AdminPalette.goldLight),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selfie Error: ${e.toString()}")),
        );
      }
    }
  }

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================
  double get calculatedTotal {
    int qty = int.tryParse(_qtyController.text) ?? 0;
    return selectedProductPrice * qty;
  }

  double get totalMonthlySales {
    double total = 0.0;
    for (var report in dailyTaskHistory) {
      total += double.tryParse(report['total_amount'].toString()) ?? 0.0;
    }
    return total;
  }

  // ============================================================
  // ROLE-BASED LIVE LOCATION CARD
  // ============================================================
  Widget _buildRoleBasedLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AdminPalette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Live Hierarchy & Route Tracking",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _AdminPalette.inkDark,
                      ),
                    ),
                    Text(
                      "Role: $userRole • ${hierarchyList.length} User(s) Visible",
                      style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh,
                    size: 18, color: _AdminPalette.primaryBrown),
                onPressed: () {
                  setState(() => isLoadingHierarchy = true);
                  fetchHierarchyAndRoutes();
                },
                tooltip: "Refresh Hierarchy",
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGpsEnabled
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isGpsEnabled ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  isGpsEnabled ? "GPS ON" : "GPS OFF",
                  style: TextStyle(
                    fontSize: 10,
                    color: isGpsEnabled
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Logged-in user's true GPS Address via Geocoding
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle,
                        color: Colors.blue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Your Live Location ($userName • $userId)",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "📍 ${currentLiveAddress ?? 'Fetching...'}",
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          if (isLoadingHierarchy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                    color: _AdminPalette.goldAccent),
              ),
            )
          else if (hierarchyList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No team members found",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hierarchyList.length,
              itemBuilder: (context, index) {
                final item = hierarchyList[index];

                final String empId = item['emp_id']?.toString() ??
                    item['employee_id']?.toString() ??
                    item['id']?.toString() ??
                    'N/A';
                final String name = item['name']?.toString() ?? 'User';
                final String role = item['role']?.toString() ?? 'Salesman';
                final String assignedRoute = item['assigned_route']?.toString() ?? 'Not Assigned';

                // Show API location for other users
                final String listUserLiveLocation = item['city']?.toString() ?? item['address']?.toString() ?? 'Fetching route...';
                final bool isLive = (item['is_live'] == 1 || item['is_live'] == '1' || item['is_live'] == true);
                final isCurrentUser = (empId == userId);

                // Skip own entry since we already showed it at the top via raw geocoding
                if (isCurrentUser) return const SizedBox.shrink();

                return Card(
                  elevation: 0,
                  color: _AdminPalette.bgWarm,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: _AdminPalette.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: _AdminPalette.primaryBrown,
                        child: Text(
                          role.isNotEmpty
                              ? role.substring(0, 1).toUpperCase()
                              : "U",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        "$name ($empId) - $role",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            "📍 $listUserLiveLocation",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "🛣️ Route: $assignedRoute",
                            style: const TextStyle(
                              fontSize: 11,
                              color: _AdminPalette.primaryBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        isLive ? "Live" : "Offline",
                        style: TextStyle(
                          color: isLive ? Colors.green : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AdminPalette.bgWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _AdminPalette.darkHeaderTop,
                      _AdminPalette.darkHeaderBottom
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("$userRole Dashboard",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          icon: const Icon(Icons.inventory,
                              color: _AdminPalette.goldAccent),
                          onPressed: _showCatalogModal,
                          tooltip: "View Catalog",
                        ),
                        IconButton(
                          icon: const Icon(Icons.lock_reset,
                              color: _AdminPalette.goldAccent),
                          onPressed: _showChangePasswordModal,
                          tooltip: "Change Password",
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.redAccent),
                          onPressed: _showLogoutConfirmation,
                          tooltip: "Logout",
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<DateTime>(
                      stream: _clockStream,
                      initialData: DateTime.now(),
                      builder: (context, snapshot) {
                        final now = snapshot.data ?? DateTime.now();
                        final timeString =
                        DateFormat('hh:mm:ss a').format(now);
                        final dateString =
                        DateFormat('EEEE, dd MMMM yyyy').format(now);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: _AdminPalette.goldAccent,
                                      size: 16),
                                  const SizedBox(width: 6),
                                  Text(timeString,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                              Text(dateString,
                                  style: const TextStyle(
                                      color: _AdminPalette.goldLight,
                                      fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text("Emp ID: $userId",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        if (assignedRoute != null)
                          Text("Assigned Route: $assignedRoute",
                              style: const TextStyle(
                                  color: _AdminPalette.goldLight,
                                  fontSize: 11)),
                      ],
                    ),
                    _buildTopSummaryCard(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRoleBasedLocationCard(),
                    const SizedBox(height: 16),

                    // Leave Management Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _AdminPalette.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _AdminPalette.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Leave Management",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _AdminPalette.inkDark)),
                          Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.history,
                                      color: _AdminPalette.primaryBrown),
                                  onPressed: _showLeaveHistoryModal),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    _AdminPalette.primaryBrown),
                                onPressed: _showLeaveApplicationDialog,
                                child: const Text("Apply Leave",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attendance & Punch Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _AdminPalette.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _AdminPalette.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        "Attendance & Punch",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: _AdminPalette.inkDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints:
                                      const BoxConstraints(),
                                      icon: const Icon(Icons.history,
                                          color: _AdminPalette.primaryBrown,
                                          size: 20),
                                      onPressed:
                                      _showAttendanceHistoryModal,
                                      tooltip: "Attendance History",
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCheckedIn
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCheckedIn
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  child: Text(
                                    isCheckedIn
                                        ? "✅ Checked In"
                                        : "❌ Not Checked In",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isCheckedIn
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isCheckedIn) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPunchOutAllowed
                                    ? Colors.blue.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPunchOutAllowed
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                              ),
                              child: Text(
                                getPunchOutStatus(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isPunchOutAllowed
                                      ? Colors.blue.shade800
                                      : Colors.orange.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (lastPunchDate != null &&
                                lastPunchTime != null) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AdminPalette.cardHeaderBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Text("Date",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                          Text(
                                            lastPunchDate ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow:
                                            TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Text("Time",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                          Text(
                                            lastPunchTime ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow:
                                            TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Text("Day",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                          Text(
                                            lastPunchDay ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow:
                                            TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                          // Captured Image Display
                          if (capturedImageFile != null ||
                              (capturedPhotoUrl != null &&
                                  capturedPhotoUrl!.isNotEmpty)) ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    _AdminPalette.primaryBrown,
                                    _AdminPalette.goldAccent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(70),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(67),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: capturedImageFile != null
                                        ? Image.file(
                                      capturedImageFile!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return const Icon(Icons.person,
                                            size: 50, color: Colors.grey);
                                      },
                                    )
                                        : (capturedPhotoUrl != null &&
                                        capturedPhotoUrl!
                                            .isNotEmpty
                                        ? Image.network(
                                      capturedPhotoUrl!
                                          .startsWith('http')
                                          ? capturedPhotoUrl!
                                          : '$API_BASE_URL${capturedPhotoUrl!}',
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child,
                                          loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const Center(
                                          child:
                                          CircularProgressIndicator(
                                            color: _AdminPalette
                                                .goldAccent,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return const Icon(Icons.person,
                                            size: 50, color: Colors.grey);
                                      },
                                    )
                                        : const Icon(Icons.person,
                                        size: 50, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCheckedIn
                                    ? (isPunchOutAllowed
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600)
                                    : const Color(0xFF2E7D32),
                              ),
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                              label: Text(
                                isCheckedIn
                                    ? (isPunchOutAllowed
                                    ? "Punch Out (Selfie Verify)"
                                    : "Punch Out Restricted")
                                    : "Punch In (Selfie Verify)",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: isCheckedIn && !isPunchOutAllowed
                                  ? null
                                  : _triggerSelfiePunch,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isCheckedIn && lastPunchType == 'PUNCH_OUT')
                            const Text(
                              "✅ Already Checked Out Today",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daily Report Log Card
                    // ============================================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _AdminPalette.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _AdminPalette.border),
                      ),
                      child: Form(
                        key: _taskFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---- Header ----
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Daily Report Log",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _AdminPalette.inkDark,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.refresh,
                                          color: _AdminPalette.primaryBrown, size: 20),
                                      onPressed: () async {
                                        await _fetchDailyReports();
                                        setState(() {});
                                      },
                                      tooltip: "Refresh Firms",
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.history, color: Colors.grey),
                                      onPressed: _showDailyTaskHistoryModal,
                                      tooltip: "Order History",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // ============================================================
                            // FIRM NAME — Brown dropdown with checkboxes
                            // ============================================================
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ---- Trigger button ----
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _showFirmDropdown = !_showFirmDropdown);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _AdminPalette.primaryBrown,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _showFirmDropdown
                                            ? _AdminPalette.goldAccent
                                            : _AdminPalette.primaryBrown,
                                        width: _showFirmDropdown ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.business,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _isAddingNewFirm
                                                ? "Adding new firm..."
                                                : (_selectedFirmsMulti.isEmpty
                                                ? "Select Firm Name"
                                                : _selectedFirmsMulti.length == 1
                                                ? _selectedFirmsMulti.first
                                                : "${_selectedFirmsMulti.length} firms selected"),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          _showFirmDropdown
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ---- Expanded checkbox list ----
                                if (_showFirmDropdown) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _AdminPalette.primaryBrown,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                      Border.all(color: _AdminPalette.goldAccent, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Header row
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.list_alt,
                                                  color: _AdminPalette.goldLight, size: 16),
                                              const SizedBox(width: 6),
                                              const Expanded(
                                                child: Text(
                                                  "Registered Firms (from daily_reports)",
                                                  style: TextStyle(
                                                    color: _AdminPalette.goldLight,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (_registeredFirms.isNotEmpty)
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      if (_selectedFirmsMulti.length ==
                                                          _registeredFirms.length) {
                                                        _selectedFirmsMulti.clear();
                                                      } else {
                                                        _selectedFirmsMulti = Set<String>.from(
                                                            _registeredFirms);
                                                      }
                                                      _firmNameController.text =
                                                          _selectedFirmsMulti.join(', ');
                                                    });
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(0, 0),
                                                    tapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    _selectedFirmsMulti.length ==
                                                        _registeredFirms.length
                                                        ? "Clear All"
                                                        : "Select All",
                                                    style: const TextStyle(
                                                      color: _AdminPalette.goldAccent,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Divider(color: Colors.white24, height: 1),

                                        // Checkbox list
                                        if (_registeredFirms.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.all(14),
                                            child: Text(
                                              "No firms yet. Add your first firm below.",
                                              style: TextStyle(
                                                  color: Colors.white70, fontSize: 12),
                                            ),
                                          )
                                        else
                                          ConstrainedBox(
                                            constraints:
                                            const BoxConstraints(maxHeight: 220),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children:
                                                _registeredFirms.map((firm) {
                                                  final isChecked =
                                                  _selectedFirmsMulti.contains(firm);
                                                  return InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        if (isChecked) {
                                                          _selectedFirmsMulti.remove(firm);
                                                        } else {
                                                          _selectedFirmsMulti.add(firm);
                                                        }
                                                        _firmNameController.text =
                                                            _selectedFirmsMulti.join(', ');
                                                      });
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 10, vertical: 6),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            height: 24,
                                                            width: 24,
                                                            child: Checkbox(
                                                              value: isChecked,
                                                              activeColor: _AdminPalette
                                                                  .goldAccent,
                                                              checkColor: _AdminPalette
                                                                  .primaryBrown,
                                                              side: const BorderSide(
                                                                color: Colors.white,
                                                                width: 1.5,
                                                              ),
                                                              onChanged: (v) {
                                                                setState(() {
                                                                  if (v == true) {
                                                                    _selectedFirmsMulti
                                                                        .add(firm);
                                                                  } else {
                                                                    _selectedFirmsMulti
                                                                        .remove(firm);
                                                                  }
                                                                  _firmNameController
                                                                      .text =
                                                                      _selectedFirmsMulti
                                                                          .join(', ');
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              firm,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 13,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const Icon(Icons.store,
                                                              color: Colors.white54,
                                                              size: 14),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),

                                        const Divider(color: Colors.white24, height: 1),

                                        // Add New Firm
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _isAddingNewFirm = true;
                                              _showFirmDropdown = false;
                                              _selectedFirmsMulti.clear();
                                              _firmNameController.clear();
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            child: Row(
                                              children: [
                                                Icon(Icons.add_circle_outline,
                                                    color: _AdminPalette.goldAccent,
                                                    size: 18),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Add New Firm",
                                                  style: TextStyle(
                                                    color: _AdminPalette.goldAccent,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // ---- Manual input mode (new firm) ----
                                if (_isAddingNewFirm) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _firmNameController,
                                          decoration: InputDecoration(
                                            labelText: 'Enter New Firm Name',
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12)),
                                            isDense: true,
                                          ),
                                          validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Enter Firm Name'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _isAddingNewFirm = false;
                                            _firmNameController.clear();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ---- Mobile + PIN ----
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      labelText: 'Mobile No.',
                                      counterText: '',
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      isDense: true,
                                    ),
                                    validator: (v) => (v == null || v.length < 10)
                                        ? '10 Digits required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _pinCodeController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    decoration: InputDecoration(
                                      labelText: 'PIN Code',
                                      counterText: '',
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      isDense: true,
                                    ),
                                    validator: (v) =>
                                    (v == null || v.length < 6) ? 'Invalid PIN' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ---- Category ----
                            DropdownButtonFormField<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Product Category',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              items: productCatalog.keys
                                  .map((cat) => DropdownMenuItem(
                                  value: cat, child: Text(cat)))
                                  .toList(),
                              onChanged: (cat) {
                                if (cat != null) {
                                  setState(() {
                                    selectedCategory = cat;
                                    final list = productCatalog[cat];
                                    if (list != null && list.isNotEmpty) {
                                      selectedProductName = list.first['name'] as String;
                                      selectedProductPrice =
                                          (list.first['price'] as num).toDouble();
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // ---- Product ----
                            if (selectedCategory != null &&
                                productCatalog[selectedCategory] != null)
                              DropdownButtonFormField<String>(
                                value: selectedProductName,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Select Item',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                                items:
                                productCatalog[selectedCategory]!.map((prod) {
                                  return DropdownMenuItem<String>(
                                    value: prod['name'] as String,
                                    child: Text(
                                        "${prod['name']} - ₹${prod['price']}"),
                                  );
                                }).toList(),
                                onChanged: (prodName) {
                                  if (prodName != null) {
                                    final prod = productCatalog[selectedCategory]!
                                        .firstWhere((e) => e['name'] == prodName);
                                    setState(() {
                                      selectedProductName = prodName;
                                      selectedProductPrice =
                                          (prod['price'] as num).toDouble();
                                    });
                                  }
                                },
                              ),
                            const SizedBox(height: 12),

                            // ---- Quantity ----
                            TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter Qty' : null,
                            ),
                            const SizedBox(height: 12),

                            // ---- Total ----
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: _AdminPalette.cardHeaderBg,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Calculated Total:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _AdminPalette.inkDark),
                                  ),
                                  Text(
                                    "₹${calculatedTotal.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ---- Action Buttons ----
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _AdminPalette.primaryBrown,
                                      ),
                                      icon: const Icon(Icons.check_circle_outline,
                                          color: Colors.white, size: 18),
                                      label: const Text(
                                        "Save Order",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                      onPressed: () {
                                        if (_taskFormKey.currentState!.validate()) {
                                          _submitDailyReportApi();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _AdminPalette.whatsappGreen,
                                      ),
                                      icon: const Icon(Icons.send,
                                          color: Colors.white, size: 16),
                                      label: const Text(
                                        "WhatsApp",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11),
                                      ),
                                      onPressed: _sendWhatsAppOrderAndSave,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AdminPalette.cardHeaderBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AdminPalette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Column(
              children: [
                const Text("Monthly Sales",
                    style: TextStyle(
                        fontSize: 10, color: _AdminPalette.inkDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("₹${totalMonthlySales.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
          ),
          Container(height: 25, width: 1, color: _AdminPalette.border),
          Expanded(
            child: Column(
              children: [
                const Text("Daily Reports",
                    style: TextStyle(
                        fontSize: 10, color: _AdminPalette.inkDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("${dailyTaskHistory.length}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _AdminPalette.primaryBrown)),
              ],
            ),
          ),
          Container(height: 25, width: 1, color: _AdminPalette.border),
          Expanded(
            child: Column(
              children: [
                const Text("Active Team",
                    style: TextStyle(
                        fontSize: 10, color: _AdminPalette.inkDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("${hierarchyList.length}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}