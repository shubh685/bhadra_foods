import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ dart:io only on non-web
import 'dart:io' show File, Platform;

import 'Log_In.dart';

// API Base URL
const String API_BASE_URL = 'https://gray-dragonfly-662322.hostingersite.com/bhadra_foods/';

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

class DashboardScreen extends StatefulWidget {
  final String loggedInRole;
  final String loggedInUserId;
  final String loggedInUserName;
  final String email;
  final String mobile;
  const DashboardScreen({
    super.key,
    this.loggedInRole = 'S',
    this.loggedInUserId = '1',
    this.loggedInUserName = '1',
    this.email = "abc@gmail.com",
    this.mobile = "91256898756",
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
  bool _isCheckingFirm = false;
  bool _isFirmExisting = false;
  bool isCheckedIn = false;
  late Stream<DateTime> _clockStream;
  StreamSubscription<Position>? _positionStreamSub;
  Timer? _minuteLocationTimer;
  Timer? _punchCheckTimer;

  String? currentLiveAddress = "Fetching live GPS location...";
  double? currentLatitude;
  double? currentLongitude;
  bool isGpsEnabled = false;

  // ✅ Platform-safe "file" holders
  File? capturedImageFile;       // native only
  Uint8List? capturedImageBytes; // web + native (used for preview)
  String? capturedPhotoUrl;      // remote URL from server

  String? lastPunchType;
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
  final _addressController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  Map<String, List<Map<String, dynamic>>> productCatalog = {};
  List<Map<String, dynamic>> rawProductList = [];
  String? selectedCategory;
  String? selectedProductName;
  double selectedProductPrice = 0.0;

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

  final Set<String> _selectedFirmsMulti = {};
  bool _showFirmDropdown = false;

  List<Map<String, dynamic>> dailyTaskHistory = [];
  List<dynamic> hierarchyList = [];
  bool isLoadingHierarchy = true;

  final Set<String> _registeredFirms = {};
  bool _isAddingNewFirm = false;

  // Reentrancy + dispose guards
  bool _isPushingLocation = false;
  bool _isFetchingAttendance = false;
  bool _isDisposed = false;

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
    const startTime = 9 * 60;
    const endTime = 18 * 60;
    if (now.weekday == DateTime.sunday) return false;
    return currentTimeInMinutes >= startTime && currentTimeInMinutes <= endTime;
  }

  String getPunchOutStatus() {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    const endTime = 18 * 60;
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
  @override
  void initState() {
    super.initState();
    userRole = widget.loggedInRole;
    userId = widget.loggedInUserId;
    userName = widget.loggedInUserName;
    userEmail = widget.email;

    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());

    if (!kIsWeb) {
      _initFaceDetector();
    }

    _initLiveGpsTracking();
    _start1MinLocationTimer();
    _startPunchCheckTimer();

    _fetchProductCatalog();
    _fetchDailyReports();
    _fetchLeaveHistory();
    fetchHierarchyAndRoutes();

    // ✅ FIX: Fetch attendance AFTER assigned route resolves the correct emp_id/userId
    _fetchAssignedRoute().then((_) {
      _fetchAttendanceStatus();
    });
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

  // ═══════════════════════════════════════════════════
  // SAFE SETSTATE — prevents '!_debugDoingThisLayout'
  // ═══════════════════════════════════════════════════
  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        setState(fn);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _minuteLocationTimer?.cancel();
    _minuteLocationTimer = null;
    _punchCheckTimer?.cancel();
    _punchCheckTimer = null;

    _firmNameController.dispose();
    _mobileController.dispose();
    _pinCodeController.dispose();
    _addressController.dispose();
    _qtyController.dispose();
    _leaveReasonController.dispose();

    try {
      _faceDetector?.close();
    } catch (_) {}
    _faceDetector = null;

    super.dispose();
  }

  // ═══════════════════════════════════════════════════
  // HIERARCHY
  // ═══════════════════════════════════════════════════
  Future<void> fetchHierarchyAndRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
      );
      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true || jsonResponse['status'] == 'success') {
          final List data = jsonResponse['data'] ?? [];
          final visibleRoles = roleVisibilityMap[userRole] ?? [userRole];
          final filtered = data.where((item) {
            final role = item['role']?.toString() ?? '';
            return visibleRoles.contains(role);
          }).toList();

          _safeSetState(() {
            hierarchyList = filtered;
            isLoadingHierarchy = false;
          });
        } else {
          _safeSetState(() => isLoadingHierarchy = false);
        }
      }
    } catch (e) {
      debugPrint("Error fetching live hierarchy: $e");
      _safeSetState(() => isLoadingHierarchy = false);
    }
  }

  Future<void> _refreshHierarchyLiveLocations() async {
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
      );
      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true || jsonResponse['status'] == 'success') {
          final List data = jsonResponse['data'] ?? [];
          final visibleRoles = roleVisibilityMap[userRole] ?? [userRole];
          final filtered = data.where((item) {
            final role = item['role']?.toString() ?? '';
            return visibleRoles.contains(role);
          }).toList();

          _safeSetState(() => hierarchyList = filtered);
        }
      }
    } catch (e) {
      debugPrint("Hierarchy live refresh error: $e");
    }
  }

  void _startPunchCheckTimer() {
    _punchCheckTimer?.cancel();
    _punchCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isDisposed || !mounted) return;
      _fetchAttendanceStatus();
    });
  }

  // ═══════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CHANGE PASSWORD
  // ═══════════════════════════════════════════════════
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
    ).whenComplete(() {
      oldController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
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
      if (_isDisposed || !mounted) return;

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
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password Change Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchAssignedRoute() async {
    try {
      final response = await http.get(
        Uri.parse("${API_BASE_URL}manage_salesman.php"),
      );
      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == true || data['status'] == 'success') &&
            data['data'] != null) {
          final users = data['data'] as List;
          Map<String, dynamic>? matchedUser;

          for (var user in users) {
            final fetchedEmpId = user['emp_id']?.toString() ?? '';
            final fetchedEmail = user['email']?.toString() ?? '';
            final fetchedName = user['name']?.toString() ?? '';

            if (fetchedEmpId == userId) {
              matchedUser = user;
              break;
            }
            if (fetchedEmail.isNotEmpty &&
                fetchedEmail.toLowerCase() == userEmail.toLowerCase()) {
              matchedUser = user;
              break;
            }
            if (fetchedName.isNotEmpty &&
                fetchedName.toLowerCase() == userName.toLowerCase()) {
              matchedUser = user;
            }
          }

          final Map<String, dynamic>? matched = matchedUser;
          if (matched != null && mounted && !_isDisposed) {
            final actualEmpId = matched['emp_id']?.toString() ?? '';
            final actualRoute =
                matched['assigned_route']?.toString() ?? 'Not Assigned';
            final actualName = matched['name']?.toString() ?? '';
            final actualEmail = matched['email']?.toString() ?? '';

            _safeSetState(() {
              if (actualEmpId.isNotEmpty) userId = actualEmpId;
              assignedRoute = actualRoute;
              if (actualName.isNotEmpty) userName = actualName;
              if (actualEmail.isNotEmpty) userEmail = actualEmail;
            });

            _fetchAttendanceStatus();
            _fetchLeaveHistory();
            _fetchDailyReports();
          }
        }
      }
    } catch (e) {
      debugPrint("Route Fetch Error: $e");
    }
  }

  // ═══════════════════════════════════════════════════
  // PRODUCT CATALOG
  // ═══════════════════════════════════════════════════
  Future<void> _fetchProductCatalog() async {
    try {
      final response = await http.get(Uri.parse("${API_BASE_URL}catelog.php"));
      if (_isDisposed || !mounted) return;

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

          _safeSetState(() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Product Catalog",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _AdminPalette.inkDark)),
              ],
            ),
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

  // ═══════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════
  Future<void> _fetchAttendanceStatus() async {
    if (_isFetchingAttendance) return;
    if (_isDisposed || !mounted) return;

    _isFetchingAttendance = true;
    try {
      // ✅ Pass both emp_id and user_id to cover backend query variations
      final url = Uri.parse(
          "${API_BASE_URL}get_attendance.php?emp_id=${Uri.encodeComponent(userId)}&user_id=${Uri.encodeComponent(userId)}");
      debugPrint("🔍 Fetching attendance for identifier: $userId from $url");

      final response = await http.get(url);

      if (!mounted || _isDisposed) return;
      if (response.statusCode != 200) {
        debugPrint("❌ Attendance HTTP Error: ${response.statusCode}");
        return;
      }

      final dynamic decodedBody = json.decode(response.body);
      debugPrint("📥 Attendance API Response: ${response.body}");

      Map<String, dynamic> data = {};
      if (decodedBody is Map<String, dynamic>) {
        data = decodedBody;
      } else if (decodedBody is List) {
        data = {'history': decodedBody};
      }

      // ✅ Safely extract list from various possible response keys
      final List rawList = (data['history'] ??
          data['data'] ??
          data['attendance'] ??
          data['records'] ??
          []) as List;

      if (!mounted || _isDisposed) return;

      if (rawList.isEmpty) {
        debugPrint("⚠️ Attendance list is empty for emp_id: $userId");
        _safeSetState(() {
          attendanceHistory = [];
          isCheckedIn = false;
          lastPunchType = null;
          capturedPhotoUrl = null;
          lastPunchDate = null;
          lastPunchTime = null;
          lastPunchDay = null;
        });
        return;
      }

      final List<Map<String, dynamic>> typed = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // ✅ Filter records belonging to this user (in case API returned all)
      final String currentUserId = userId.trim();
      final List<Map<String, dynamic>> mine = typed.where((row) {
        final emp = (row['emp_id']?.toString() ?? '').trim();
        final uid = (row['user_id']?.toString() ?? '').trim();
        return emp == currentUserId || uid == currentUserId;
      }).toList();

      final List<Map<String, dynamic>> effective = mine.isNotEmpty ? mine : typed;
      final Map<String, dynamic> latest = effective.first;

      final String latestPunchType = (latest['punch_type']?.toString() ??
          latest['type']?.toString() ??
          latest['status']?.toString() ??
          '')
          .toUpperCase();

      String? displayPhoto;
      final String rawPhoto = latest['photo']?.toString() ??
          latest['image']?.toString() ??
          latest['photo_url']?.toString() ??
          '';
      if (rawPhoto.isNotEmpty) {
        final parts = rawPhoto
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) displayPhoto = parts.last;
      }

      final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String latestDate = latest['punch_date']?.toString() ??
          latest['date']?.toString() ??
          latest['created_at']?.toString()?.split(' ').first ??
          '';
      final bool isToday = latestDate == todayStr;

      final String fetchedTime = latest['punch_time']?.toString() ??
          latest['time']?.toString() ??
          (latest['created_at']?.toString()?.contains(' ') == true
              ? latest['created_at'].toString().split(' ').last
              : '');

      String fetchedDay = latest['day']?.toString() ?? '';
      if (fetchedDay.isEmpty && latestDate.isNotEmpty) {
        try {
          fetchedDay = DateFormat('EEEE').format(DateTime.parse(latestDate));
        } catch (_) {}
      }

      _safeSetState(() {
        attendanceHistory = effective;
        isCheckedIn = isToday && latestPunchType == 'PUNCH_IN';
        lastPunchType = latestPunchType.isEmpty ? null : latestPunchType;
        capturedPhotoUrl = isToday ? displayPhoto : null;
        lastPunchDate = latestDate;
        lastPunchTime = fetchedTime;
        lastPunchDay = fetchedDay;
      });
    } catch (e) {
      debugPrint("❌ Attendance API Parsing Error: $e");
    } finally {
      _isFetchingAttendance = false;
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
                        icon: const Icon(Icons.refresh,
                            color: _AdminPalette.primaryBrown),
                        onPressed: () async {
                          await _fetchAttendanceStatus();
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
                child: attendanceHistory.isEmpty
                    ? const Center(child: Text("No attendance history found"))
                    : ListView.builder(
                  itemCount: attendanceHistory.length,
                  itemBuilder: (ctx, idx) {
                    final item = attendanceHistory[idx];
                    final pType = (item['punch_type']?.toString() ??
                        item['type']?.toString() ??
                        '').toUpperCase();
                    final isPunchIn = pType == 'PUNCH_IN';
                    final String rawPhoto = item['photo']?.toString() ??
                        item['image']?.toString() ??
                        '';

                    String? displayPhoto;
                    if (rawPhoto.isNotEmpty) {
                      final photos = rawPhoto
                          .split(',')
                          .map((p) => p.trim())
                          .where((p) => p.isNotEmpty)
                          .toList();
                      if (photos.isNotEmpty) displayPhoto = photos.last;
                    }

                    final String photoUrl = displayPhoto != null
                        ? (displayPhoto.startsWith('http')
                        ? displayPhoto
                        : '$API_BASE_URL$displayPhoto')
                        : '';

                    return Card(
                      color: _AdminPalette.cardBg,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPunchIn
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isPunchIn
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  child: Icon(
                                    isPunchIn ? Icons.login : Icons.logout,
                                    color: isPunchIn ? Colors.green : Colors.red,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPunchIn ? "Punch In" : "Punch Out",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        "ID: ${item['id'] ?? '-'} | Emp: ${item['emp_id'] ?? '-'}",
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (photoUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      photoUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.person,
                                            size: 28, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildAttendanceDetailRow(
                              Icons.calendar_today,
                              "Date",
                              item['punch_date']?.toString() ?? item['date']?.toString() ?? '--',
                            ),
                            _buildAttendanceDetailRow(
                              Icons.access_time,
                              "Time",
                              item['punch_time']?.toString() ?? item['time']?.toString() ?? '--',
                            ),
                            _buildAttendanceDetailRow(
                              Icons.today,
                              "Day",
                              item['day']?.toString() ?? '--',
                            ),
                            _buildAttendanceDetailRow(
                              Icons.badge,
                              "Role",
                              item['role']?.toString() ?? '--',
                            ),
                            _buildAttendanceDetailRow(
                              Icons.location_on,
                              "Address",
                              item['address']?.toString() ?? '--',
                            ),
                            _buildAttendanceDetailRow(
                              Icons.my_location,
                              "Latitude",
                              item['latitude']?.toString() ?? '--',
                            ),
                            _buildAttendanceDetailRow(
                              Icons.my_location,
                              "Longitude",
                              item['longitude']?.toString() ?? '--',
                            ),
                            _buildAttendanceDetailRow(
                              Icons.update,
                              "Updated At",
                              item['updated_at']?.toString() ??
                                  item['created_at']?.toString() ??
                                  '--',
                            ),
                          ],
                        ),
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

  bool get isPunchInAllowed {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) return false;
    final minutes = now.hour * 60 + now.minute;
    return minutes < (18 * 60);
  }

  bool get showPunchInButton => !isCheckedIn && isPunchInAllowed;

  Widget _buildAttendanceDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: _AdminPalette.primaryBrown),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value.isEmpty || value == 'null') ? '--' : value,
              style: const TextStyle(
                fontSize: 11,
                color: _AdminPalette.inkDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // PUNCH ATTENDANCE
  // ═══════════════════════════════════════════════════
  Future<void> _submitPunchApi(
      XFile? photoXFile,
      String punchType, {
        bool isAuto = false,
      }) async {
    try {
      var request = http.MultipartRequest(
          "POST", Uri.parse("${API_BASE_URL}punch_attendance.php"));
      request.fields['emp_id'] = userId;
      request.fields['role'] = userRole;
      request.fields['punch_type'] = punchType;
      request.fields['device_date'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      request.fields['device_time'] = DateFormat('HH:mm:ss').format(DateTime.now());
      request.fields['is_auto'] = isAuto ? '1' : '0';

      if (photoXFile != null) {
        if (kIsWeb) {
          final bytes = await photoXFile.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: photoXFile.name,
          ));
        } else {
          final f = File(photoXFile.path);
          if (await f.exists()) {
            request.files.add(await http.MultipartFile.fromPath('photo', f.path));
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' || data['status'] == true) {
          _safeSetState(() {
            isCheckedIn = (punchType == 'PUNCH_IN');
            lastPunchType = punchType;
            if (punchType == 'PUNCH_IN') {
              capturedPhotoUrl = data['photo_url'] ?? capturedPhotoUrl;
            }
            lastPunchDate = data['punch_date'] ??
                DateFormat('yyyy-MM-dd').format(DateTime.now());
            lastPunchTime = data['punch_time'] ??
                DateFormat('HH:mm:ss').format(DateTime.now());
            lastPunchDay =
                data['day'] ?? DateFormat('EEEE').format(DateTime.now());
          });

          if (!mounted || _isDisposed) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(data['message'] ??
                  (isAuto
                      ? 'Auto-Punched out successfully!'
                      : 'Punch recorded successfully!')),
            ),
          );
          _fetchAttendanceStatus();
        } else {
          if (!mounted || _isDisposed) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(data['message'] ?? 'Punch failed!'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("Punch Submission Error: $e")),
      );
    }
  }

  // ═══════════════════════════════════════════════════
  // LEAVE MANAGEMENT
  // ═══════════════════════════════════════════════════
  Future<void> _fetchLeaveHistory() async {
    try {
      final response = await http.get(
        Uri.parse("${API_BASE_URL}manage_leaves.php?emp_id=$userId"),
      );
      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == true || data['status'] == 'success') &&
            mounted &&
            !_isDisposed) {
          _safeSetState(() {
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
      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          await _fetchLeaveHistory();
          if (!mounted || _isDisposed) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text("Leave Application Submitted!")),
          );
        } else {
          if (!mounted || _isDisposed) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.red,
                content: Text(data['message'] ?? 'Failed to submit leave')),
          );
        }
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
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
                      if (val != null) {
                        try {
                          setDialogState(() => selectedLeaveType = val);
                        } catch (_) {}
                      }
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
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null && context.mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              try {
                                setDialogState(() => _selectedLeaveDateRange = picked);
                              } catch (_) {}
                            }
                          });
                        }
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
                      if (item['status'] == 'Approved') statusColor = Colors.green;
                      if (item['status'] == 'Rejected') statusColor = Colors.red;

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
                                  : item['leave_type'] == 'Maternity Leave'
                                  ? Icons.family_restroom
                                  : item['leave_type'] == 'Paternity Leave'
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
                        _buildLeaveStatSalesman("Total", leaveHistory.length, Colors.grey),
                        _buildLeaveStatSalesman(
                            "Pending",
                            leaveHistory.where((l) => l['status'] == 'Pending').length,
                            Colors.orange),
                        _buildLeaveStatSalesman(
                            "Approved",
                            leaveHistory.where((l) => l['status'] == 'Approved').length,
                            Colors.green),
                        _buildLeaveStatSalesman(
                            "Rejected",
                            leaveHistory.where((l) => l['status'] == 'Rejected').length,
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
        Text(count.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // FIRM CHECK & ORDER
  // ═══════════════════════════════════════════════════
  Future<bool> _checkFirmExists(String firmName) async {
    if (firmName.trim().isEmpty) return false;
    if (_isDisposed || !mounted) return false;

    _safeSetState(() => _isCheckingFirm = true);
    try {
      final uri = Uri.parse(
        "${API_BASE_URL}manage_daily_reports.php"
            "?action=verify"
            "&emp_id=${Uri.encodeComponent(userId)}"
            "&firm_name=${Uri.encodeComponent(firmName.trim())}",
      );
      final response = await http.get(uri);
      if (_isDisposed || !mounted) return false;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] == true;
      }
    } catch (e) {
      debugPrint("Check Firm Error: $e");
    } finally {
      _safeSetState(() => _isCheckingFirm = false);
    }
    return false;
  }

  Future<void> _handleSendOrderAndWhatsApp() async {
    final firmName = _firmNameController.text.trim();
    final List<String> firmsToSubmit = _selectedFirmsMulti.isNotEmpty
        ? _selectedFirmsMulti.toList()
        : (firmName.isNotEmpty ? [firmName] : []);

    if (firmsToSubmit.isEmpty) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text("Please select or enter a firm name."),
          ),
        );
      }
      return;
    }

    if (_selectedFirmsMulti.isEmpty && firmName.isNotEmpty) {
      final bool exists = await _checkFirmExists(firmName);
      if (!mounted || _isDisposed) return;

      if (!exists) {
        if (_mobileController.text.trim().isEmpty ||
            _pinCodeController.text.trim().isEmpty ||
            _addressController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text(
                  "New firm detected! Please enter Mobile, PIN Code, and Address."),
            ),
          );
          return;
        }
      }
    }

    if (_taskFormKey.currentState?.validate() != true) return;

    int successCount = 0;
    String lastMessage = '';
    String? lastError;

    for (final singleFirm in firmsToSubmit) {
      try {
        final response = await http.post(
          Uri.parse("${API_BASE_URL}manage_daily_reports.php"),
          body: {
            'emp_id': userId,
            'firm_name': singleFirm,
            'mobile': _mobileController.text.trim(),
            'pin_code': _pinCodeController.text.trim(),
            'address': _addressController.text.trim(),
            'category': selectedCategory ?? '',
            'product_name': selectedProductName ?? '',
            'price': selectedProductPrice.toString(),
            'quantity': _qtyController.text,
            'total_amount': calculatedTotal.toString(),
          },
        );
        if (_isDisposed || !mounted) return;

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == true || data['status'] == 'success') {
            successCount++;
            lastMessage = data['message'] ?? 'Order successfully logged!';
            _registeredFirms.add(singleFirm);
          } else {
            lastError = data['message'] ?? 'Failed to save order';
          }
        } else {
          lastError = 'Server error: ${response.statusCode}';
        }
      } catch (e) {
        lastError = "Order Submission Error: $e";
      }
    }

    if (!mounted || _isDisposed) return;

    if (successCount > 0) {
      await _fetchDailyReports();

      final String mobile = _mobileController.text.trim();
      final String pinCode = _pinCodeController.text.trim();
      final String address = _addressController.text.trim();
      final String productName = selectedProductName ?? '';
      final String qty = _qtyController.text;
      final String total = calculatedTotal.toStringAsFixed(2);
      final String targetFirm = firmsToSubmit.join(', ');

      _firmNameController.clear();
      _mobileController.clear();
      _pinCodeController.clear();
      _addressController.clear();
      _qtyController.text = '1';

      _safeSetState(() {
        _isAddingNewFirm = false;
        _showFirmDropdown = false;
        _selectedFirmsMulti.clear();
        _isFirmExisting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(lastMessage.isNotEmpty
              ? lastMessage
              : "Order submitted & redirecting to WhatsApp!"),
        ),
      );

      final message = """
*New Order Request*
━━━━━━━━━━━━━━━━━━
*Firm:* $targetFirm
*Mobile:* $mobile
*PIN Code:* $pinCode
*Firm Address:* $address
*Item Name:* $productName
*Quantity:* $qty
*Total Amount:* ₹$total
━━━━━━━━━━━━━━━━━━
*Sales Representative:* $userName ($userId)
*Timestamp:* ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}
""";

      final encodedMessage = Uri.encodeFull(message);
      final waUrl = Uri.parse("https://wa.me/919512312400?text=$encodedMessage");

      try {
        final bool launched =
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        if (!launched && mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Unable to launch WhatsApp application.")),
          );
        }
      } catch (e) {
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("WhatsApp launch failed: $e")),
          );
        }
      }
    } else if (lastError != null && mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(lastError)),
      );
    }
  }

  Future<void> _fetchDailyReports() async {
    try {
      final response = await http.get(
        Uri.parse("${API_BASE_URL}manage_daily_reports.php?emp_id=$userId"),
      );
      if (_isDisposed || !mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == true || data['status'] == 'success') &&
            data['reports'] != null) {
          if (!mounted || _isDisposed) return;
          _safeSetState(() {
            dailyTaskHistory = List<Map<String, dynamic>>.from(
              (data['reports'] as List)
                  .map((item) => Map<String, dynamic>.from(item)),
            );
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
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final item in dailyTaskHistory) {
            final firm = (item['firm_name']?.toString().trim().isNotEmpty ?? false)
                ? item['firm_name'].toString().trim()
                : 'Unnamed Firm';
            grouped.putIfAbsent(firm, () => []).add(item);
          }

          return Dialog(
            backgroundColor: _AdminPalette.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daily Orders Logged",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _AdminPalette.inkDark,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: _AdminPalette.primaryBrown),
                            onPressed: () async {
                              await _fetchDailyReports();
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
                          maxHeight: MediaQuery.of(context).size.height * 0.55,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: grouped.length,
                          itemBuilder: (ctx, groupIdx) {
                            final firmName = grouped.keys.elementAt(groupIdx);
                            final firmOrders = grouped[firmName]!;

                            double firmTotal = 0.0;
                            for (final o in firmOrders) {
                              firmTotal += double.tryParse(
                                  o['total_amount']?.toString() ?? '0') ??
                                  0.0;
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _AdminPalette.bgWarm,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _AdminPalette.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: _AdminPalette.cardHeaderBg,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(14)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.store,
                                            color: _AdminPalette.primaryBrown,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                firmName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: _AdminPalette.inkDark,
                                                ),
                                              ),
                                              Text(
                                                "${firmOrders.length} order${firmOrders.length == 1 ? '' : 's'} • ₹${firmTotal.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.green),
                                          ),
                                          child: Text(
                                            "₹${firmTotal.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...firmOrders.map((item) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: _AdminPalette.border,
                                              width: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.receipt_long,
                                              color: Colors.green, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "📦 ${item['category'] ?? ''} • ${item['product_name'] ?? ''}",
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                      FontWeight.w500),
                                                ),
                                                Text(
                                                  "Qty: ${item['quantity'] ?? '0'} × ₹${item['price'] ?? '0'}",
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey),
                                                ),
                                                Text(
                                                  "📞 ${item['mobile'] ?? 'N/A'}",
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey),
                                                ),
                                                Text(
                                                  "🕐 ${item['created_at'] ?? ''}",
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "₹${item['total_amount'] ?? '0'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // GPS TIMERS
  // ═══════════════════════════════════════════════════
  void _start1MinLocationTimer() {
    _minuteLocationTimer?.cancel();
    _minuteLocationTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_isDisposed || !mounted) return;
      await _fetchAndUpdateCurrentLocation();
      if (_isDisposed || !mounted) return;
      await _refreshHierarchyLiveLocations();
      if (_isDisposed || !mounted) return;
      _checkAutoPunchOut();
    });
  }

  bool get isAutoPunchOutDue {
    final now = DateTime.now();
    if (!isCheckedIn) return false;
    if (now.weekday == DateTime.sunday) return false;
    if (lastPunchType == 'PUNCH_OUT') return false;
    return now.hour >= 18;
  }

  Future<void> _checkAutoPunchOut() async {
    if (_isDisposed || !mounted) return;
    if (!isAutoPunchOutDue) return;

    debugPrint("🔄 Auto punch-out triggered at ${DateTime.now()}");
    await _submitPunchApi(null, 'PUNCH_OUT', isAuto: true);
    await _fetchAttendanceStatus();
  }

  String getPunchInStatusMessage() {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) {
      return "⛔ Sunday — Punch In not allowed";
    }
    final minutes = now.hour * 60 + now.minute;
    const endTime = 18 * 60;
    if (minutes >= endTime) {
      return "⏰ Punch In closed for today (after 6:00 PM)";
    }
    final remaining = endTime - minutes;
    return "✅ Punch In available (closes in ${remaining ~/ 60}h ${remaining % 60}m)";
  }

  Future<void> _fetchAndUpdateCurrentLocation() async {
    if (_isDisposed || !mounted) return;

    try {
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
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
    if (_isDisposed || !mounted) return;

    if (!kIsWeb) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _safeSetState(() {
          currentLiveAddress = "GPS location disabled";
          isGpsEnabled = false;
        });
        return;
      }
    }

    _safeSetState(() => isGpsEnabled = true);

    if (!kIsWeb) {
      PermissionStatus permStatus = await Permission.locationWhenInUse.status;
      if (permStatus.isDenied) {
        permStatus = await Permission.locationWhenInUse.request();
      }
      if (!permStatus.isGranted) {
        _safeSetState(() => currentLiveAddress = "Location permission denied");
        return;
      }
    }

    try {
      final Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      await _updateAddressFromPosition(initialPosition);
    } catch (e) {
      _safeSetState(
              () => currentLiveAddress = "Unable to fetch GPS position.");
    }

    await _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!_isDisposed && mounted) {
        _updateAddressFromPosition(position);
      }
    });
  }

  Future<void> _updateAddressFromPosition(Position position) async {
    if (_isDisposed || !mounted) return;

    String resolvedAddress = currentLiveAddress ?? 'Fetching address...';
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (_isDisposed || !mounted) return;

      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final List<String> parts = [];

        final street = [
          p.name,
          p.street,
          p.subLocality,
        ]
            .where((s) => s != null && s.trim().isNotEmpty)
            .map((s) => s!.trim())
            .toSet()
            .toList();
        if (street.isNotEmpty) parts.add(street.join(', '));

        if (p.locality != null && p.locality!.trim().isNotEmpty) {
          parts.add(p.locality!.trim());
        }
        if (p.subAdministrativeArea != null &&
            p.subAdministrativeArea!.trim().isNotEmpty) {
          parts.add(p.subAdministrativeArea!.trim());
        }
        if (p.administrativeArea != null &&
            p.administrativeArea!.trim().isNotEmpty) {
          parts.add(p.administrativeArea!.trim());
        }
        if (p.postalCode != null && p.postalCode!.trim().isNotEmpty) {
          parts.add(p.postalCode!.trim());
        }
        if (p.country != null && p.country!.trim().isNotEmpty) {
          parts.add(p.country!.trim());
        }

        if (parts.isNotEmpty) {
          resolvedAddress = parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
      resolvedAddress =
      "Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}";
    }

    if (!mounted || _isDisposed) return;

    _safeSetState(() {
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      currentLiveAddress = resolvedAddress;
      isGpsEnabled = true;
    });
  }

  // ═══════════════════════════════════════════════════
  // FACE + SELFIE PUNCH (WEB-SAFE)
  // ═══════════════════════════════════════════════════
  Future<Map<String, dynamic>> _analyzeFace(XFile imageFile) async {
    if (kIsWeb) {
      return {
        'faces': [],
        'message': 'Face detection not available on web'
      };
    }

    try {
      if (_faceDetector == null || !_faceDetectorInitialized) {
        await _initFaceDetector();
      }
      if (_faceDetector == null) {
        return {'faces': [], 'message': 'Face detector unavailable'};
      }

      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        return {'faces': [], 'message': 'No face detected'};
      }

      final face = faces.first;
      return {
        'faces': faces,
        'features': {
          'hasSmile': (face.smilingProbability ?? 0.0) > 0.5,
        },
        'message': 'Face verified!'
      };
    } catch (e) {
      debugPrint("Face analysis error: $e");
      return {'faces': [], 'message': 'Face analysis failed: $e'};
    }
  }

  Future<void> _triggerSelfiePunch() async {
    if (_isDisposed || !mounted) return;

    if (isCheckedIn) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content:
          Text("You are already checked in.\nAuto punch-out at 6:00 PM."),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (lastPunchType == 'PUNCH_OUT') {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("You have already punched out today!"),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!isPunchInAllowed) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            DateTime.now().weekday == DateTime.sunday
                ? "Punch In not allowed on Sunday."
                : "Punch In closed for today (after 6:00 PM).",
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      if (!kIsWeb) {
        PermissionStatus cameraStatus = await Permission.camera.status;
        if (cameraStatus.isDenied) {
          cameraStatus = await Permission.camera.request();
        }
        if (!cameraStatus.isGranted) {
          if (!mounted || _isDisposed) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.red,
                content: Text("Camera permission required.")),
          );
          return;
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (photo == null) return;
      if (_isDisposed || !mounted) return;

      BuildContext? loadingDialogContext;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingCtx) {
          loadingDialogContext = loadingCtx;
          return const Center(
            child: CircularProgressIndicator(color: _AdminPalette.goldAccent),
          );
        },
      );

      final result = await _analyzeFace(photo);

      if (loadingDialogContext != null && loadingDialogContext!.mounted) {
        try {
          Navigator.of(loadingDialogContext!).pop();
        } catch (_) {}
      }

      if (!mounted || _isDisposed) return;

      if (result['faces'] == null || (result['faces'] as List).isEmpty) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: _AdminPalette.cardBg,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text("Face Not Detected",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  await _submitPunchApi(photo, 'PUNCH_IN');
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

      if (!mounted || _isDisposed) return;
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
                      child: kIsWeb
                          ? FutureBuilder<Uint8List>(
                        future: photo.readAsBytes(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return Image.memory(snap.data!,
                              fit: BoxFit.cover);
                        },
                      )
                          : Image.file(
                        File(photo.path),
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
                await _submitPunchApi(photo, 'PUNCH_IN');
              },
              child: const Text(
                "Confirm Punch In",
                style: TextStyle(color: _AdminPalette.goldLight),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selfie Error: ${e.toString()}")),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // COMPUTED
  // ═══════════════════════════════════════════════════
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

  Widget _buildCapturedPreview() {
    if (capturedPhotoUrl != null && capturedPhotoUrl!.isNotEmpty) {
      final String fullUrl = capturedPhotoUrl!.startsWith('http')
          ? capturedPhotoUrl!
          : '$API_BASE_URL$capturedPhotoUrl';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.person, size: 50, color: Colors.grey),
        ),
      );
    } else if (capturedImageBytes != null) {
      return Image.memory(capturedImageBytes!, fit: BoxFit.cover);
    } else if (!kIsWeb && capturedImageFile != null) {
      return Image.file(capturedImageFile!, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }

  Widget _buildTopSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: _AdminPalette.goldAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("Monthly Orders", "${dailyTaskHistory.length}",
              Icons.shopping_cart),
          Container(width: 1, height: 35, color: Colors.white24),
          _buildSummaryItem("Total Sales",
              "₹${totalMonthlySales.toStringAsFixed(0)}", Icons.payments),
          Container(width: 1, height: 35, color: Colors.white24),
          _buildSummaryItem("Leaves Logged", "${leaveHistory.length}",
              Icons.event_note),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _AdminPalette.goldAccent, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // ROLE-BASED LIVE LOCATION CARD
  // ═══════════════════════════════════════════════════
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
              const Icon(Icons.my_location,
                  color: Colors.redAccent, size: 20),
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
                  if (mounted && !_isDisposed) {
                    _safeSetState(() => isLoadingHierarchy = true);
                    fetchHierarchyAndRoutes();
                  }
                },
                tooltip: "Refresh Hierarchy",
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
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
                    Expanded(
                      child: Text(
                        "Your Live Location ($userName • $userId)",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                final String route =
                    item['assigned_route']?.toString() ?? 'Not Assigned';

                final double? lat =
                double.tryParse(item['latitude']?.toString() ?? '');
                final double? lng =
                double.tryParse(item['longitude']?.toString() ?? '');

                String liveLocation;
                if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
                  liveLocation =
                  "Lat: ${lat.toStringAsFixed(5)}, Long: ${lng.toStringAsFixed(5)}";
                } else {
                  liveLocation = currentLiveAddress ?? 'Location not available';
                }

                final String lastUpdated =
                    item['last_updated']?.toString() ?? '';
                final bool isLive = (item['is_live'] == 1 ||
                    item['is_live'] == '1' ||
                    item['is_live'] == true);
                final bool isCurrentUser = (empId == userId);

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
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _AdminPalette.primaryBrown,
                              child: Text(
                                role.isNotEmpty
                                    ? role.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "$name ($empId)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? Colors.green.shade50
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                  isLive ? Colors.green : Colors.grey,
                                ),
                              ),
                              child: Text(
                                isLive ? "● Live" : "○ Offline",
                                style: TextStyle(
                                  color: isLive
                                      ? Colors.green.shade800
                                      : Colors.grey.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.badge,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "Role: $role",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Location: $liveLocation",
                                style: const TextStyle(fontSize: 11),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.route,
                                size: 12,
                                color: _AdminPalette.primaryBrown),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Route: $route",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _AdminPalette.primaryBrown,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (lastUpdated.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.update,
                                  size: 11, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Updated: $lastUpdated",
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AdminPalette.bgWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
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
                        final timeString = DateFormat('hh:mm:ss a').format(now);
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

              // BODY
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRoleBasedLocationCard(),
                    const SizedBox(height: 16),

                    // LEAVE CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _AdminPalette.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _AdminPalette.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              "Leave Management",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _AdminPalette.inkDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment:
                              WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.history,
                                      color: _AdminPalette.primaryBrown),
                                  onPressed: _showLeaveHistoryModal,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    _AdminPalette.primaryBrown,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _showLeaveApplicationDialog,
                                  child: const Text(
                                    "Apply Leave",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ATTENDANCE CARD
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
                                          color:
                                          _AdminPalette.primaryBrown,
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
                                            : Colors.red),
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

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCheckedIn
                                  ? Colors.blue.shade50
                                  : (isPunchInAllowed
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCheckedIn
                                    ? Colors.blue
                                    : (isPunchInAllowed
                                    ? Colors.green
                                    : Colors.orange),
                              ),
                            ),
                            child: Text(
                              isCheckedIn
                                  ? getPunchOutStatus()
                                  : getPunchInStatusMessage(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isCheckedIn
                                    ? Colors.blue.shade800
                                    : (isPunchInAllowed
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800),
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
                                        Text(lastPunchDate ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow:
                                            TextOverflow.ellipsis),
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
                                        Text(lastPunchTime ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow:
                                            TextOverflow.ellipsis),
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
                                        Text(lastPunchDay ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow:
                                            TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          if ((!kIsWeb && capturedImageFile != null) ||
                              (capturedImageBytes != null) ||
                              (capturedPhotoUrl != null &&
                                  capturedPhotoUrl!.isNotEmpty)) ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    _AdminPalette.primaryBrown,
                                    _AdminPalette.goldAccent
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
                                    child: _buildCapturedPreview(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (showPunchInButton)
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF2E7D32),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                                label: const Text(
                                  "Punch In (Selfie Verify)",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: _triggerSelfiePunch,
                              ),
                            )
                          else if (!isCheckedIn &&
                              lastPunchType == 'PUNCH_OUT')
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Punched Out Successfully Today",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isCheckedIn)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.timer,
                                        color: Colors.blue, size: 18),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "Auto Punch Out at 6:00 PM",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade400),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_clock,
                                        color: Colors.grey.shade700,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        DateTime.now().weekday ==
                                            DateTime.sunday
                                            ? "Punch In Not Available on Sunday"
                                            : "Punch In Closed (After 6:00 PM)",
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DAILY REPORT CARD
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
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                                          color:
                                          _AdminPalette.primaryBrown,
                                          size: 20),
                                      onPressed: () async {
                                        await _fetchDailyReports();
                                      },
                                      tooltip: "Refresh Firms",
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.history,
                                          color: Colors.grey),
                                      onPressed:
                                      _showDailyTaskHistoryModal,
                                      tooltip: "Order History",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            GestureDetector(
                              onTap: () {
                                _safeSetState(() => _showFirmDropdown =
                                !_showFirmDropdown);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: _AdminPalette.primaryBrown,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedFirmsMulti.isNotEmpty
                                            ? "Selected: ${_selectedFirmsMulti.join(', ')}"
                                            : "Select Registered Firm(s)",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      _showFirmDropdown
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_showFirmDropdown) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AdminPalette.bgWarm,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                  Border.all(color: _AdminPalette.border),
                                ),
                                child: Column(
                                  children: [
                                    ..._registeredFirms.map((firm) {
                                      final isSel =
                                      _selectedFirmsMulti.contains(firm);
                                      return CheckboxListTile(
                                        title: Text(firm,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500)),
                                        value: isSel,
                                        activeColor:
                                        _AdminPalette.primaryBrown,
                                        onChanged: (val) {
                                          _safeSetState(() {
                                            if (val == true) {
                                              _selectedFirmsMulti.add(firm);
                                              _firmNameController.text = firm;
                                            } else {
                                              _selectedFirmsMulti.remove(firm);
                                              if (_selectedFirmsMulti
                                                  .isNotEmpty) {
                                                _firmNameController.text =
                                                    _selectedFirmsMulti.first;
                                              } else {
                                                _firmNameController.clear();
                                              }
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                    const Divider(),
                                    TextButton.icon(
                                      icon: const Icon(Icons.add,
                                          color: _AdminPalette.primaryBrown),
                                      label: const Text(
                                          "Add New Firm Name",
                                          style: TextStyle(
                                              color: _AdminPalette.primaryBrown,
                                              fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        _safeSetState(() {
                                          _isAddingNewFirm = true;
                                          _showFirmDropdown = false;
                                          _selectedFirmsMulti.clear();
                                          _firmNameController.clear();
                                        });
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ],

                            if (_isAddingNewFirm ||
                                _registeredFirms.isEmpty) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _firmNameController,
                                decoration: InputDecoration(
                                  labelText: "New Firm Name *",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  suffixIcon: _isCheckingFirm
                                      ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                      : null,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? "Firm name required"
                                    : null,
                                onChanged: (val) async {
                                  if (val.trim().length > 2) {
                                    bool exists =
                                    await _checkFirmExists(val.trim());
                                    _safeSetState(() {
                                      _isFirmExisting = exists;
                                    });
                                  }
                                },
                              ),
                            ],

                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Mobile Number",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pinCodeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "PIN Code",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: "Address",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // PRODUCT CATEGORY DROPDOWN
                            DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: InputDecoration(
                                labelText: "Category",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: productCatalog.keys
                                  .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _safeSetState(() {
                                    selectedCategory = val;
                                    final items = productCatalog[val] ?? [];
                                    if (items.isNotEmpty) {
                                      selectedProductName = items.first['name'];
                                      selectedProductPrice =
                                      items.first['price'];
                                    } else {
                                      selectedProductName = null;
                                      selectedProductPrice = 0.0;
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // PRODUCT ITEM DROPDOWN
                            DropdownButtonFormField<String>(
                              value: selectedProductName,
                              decoration: InputDecoration(
                                labelText: "Product Name",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: (productCatalog[selectedCategory] ?? [])
                                  .map((p) => DropdownMenuItem<String>(
                                value: p['name'].toString(),
                                child: Text("${p['name']} (₹${p['price']})"),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final selected =
                                  (productCatalog[selectedCategory] ?? [])
                                      .firstWhere((p) => p['name'] == val);
                                  _safeSetState(() {
                                    selectedProductName = val;
                                    selectedProductPrice = selected['price'];
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // QUANTITY INPUT
                            TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Quantity",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (_) {
                                _safeSetState(() {});
                              },
                            ),
                            const SizedBox(height: 16),

                            // TOTAL SUMMARY DISPLAY
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _AdminPalette.cardHeaderBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _AdminPalette.border),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total Calculated Amount:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
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
                            const SizedBox(height: 16),

                            // SUBMIT BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  _AdminPalette.whatsappGreen,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.send, color: Colors.white),
                                label: const Text(
                                  "Submit Order & WhatsApp",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                onPressed: _handleSendOrderAndWhatsApp,
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
          ),
        ),
      ),
    );
  }
}