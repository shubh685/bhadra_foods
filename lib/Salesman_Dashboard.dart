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
const String API_BASE_URL = 'http://192.168.0.102/bhadra_foods/';

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
    this.loggedInUserId = 'BHFSM:-01',
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

  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.1,
    ),
  );

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

  // Daily Reports
  List<Map<String, dynamic>> dailyTaskHistory = [];
  List<HierarchyUserLocation> hierarchyData = [];

  // Punch Status - Order Stats
  int totalOrders = 0;
  int pendingOrders = 0;
  int confirmOrders = 0;

  // Visibility Mapping based on Roles
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

    if (now.weekday == DateTime.sunday) {
      return false;
    }
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
    } else if (currentTimeInMinutes > endTime) {
      return "⛔ Punch Out closed (After 6 PM)";
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

    _initializeHierarchyData();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());

    _initLiveGpsTracking();
    _start1MinLocationTimer();
    _startPunchCheckTimer();

    _fetchProductCatalog();
    _fetchAttendanceStatus();
    _fetchDailyReports();
    _fetchAssignedRoute();
    _fetchLeaveHistory();
    _fetchOrderStats();
  }

  void _initializeHierarchyData() {
    hierarchyData = [
      HierarchyUserLocation(
        roleKey: 'Salesman',
        roleTitle: 'Salesman',
        name: 'Shubham Shah',
        userId: 'BHFSM:-01',
        themeColor: Colors.green,
        addressLocation: 'Fetching live position...',
        assignedRoute: '',
        isOnline: false,
      ),
      HierarchyUserLocation(
        roleKey: 'Sales Officer',
        roleTitle: 'Sales Officer',
        name: 'Amit Shah',
        userId: 'BHFSO:-01',
        themeColor: Colors.blue,
        addressLocation: 'Nari Chawkdi, Ring Road, Bhavnagar',
        assignedRoute: 'Ring Road Zone 1',
        latitude: 21.7645,
        longitude: 72.1519,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'ASM',
        roleTitle: 'Area Sales Manager',
        name: 'Rajesh Patel',
        userId: 'BHFAS:-01',
        themeColor: Colors.deepOrange,
        addressLocation: 'Waghawadi Road, Bhavnagar',
        assignedRoute: 'Bhavnagar Central',
        latitude: 21.7582,
        longitude: 72.1525,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'RSM',
        roleTitle: 'Regional Sales Manager',
        name: 'Vikas Mehta',
        userId: 'BHFRS:-01',
        themeColor: Colors.purple,
        addressLocation: 'Kalvibid Circle, Bhavnagar',
        assignedRoute: 'Saurashtra Region',
        latitude: 21.7538,
        longitude: 72.1492,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'ZSM',
        roleTitle: 'Zone Sales Manager',
        name: 'Suresh Kumar',
        userId: 'BHFZS:-01',
        themeColor: Colors.brown,
        addressLocation: 'Ghogha Circle, Bhavnagar',
        assignedRoute: 'Gujarat West Zone',
        latitude: 21.7465,
        longitude: 72.1551,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'Sales Head',
        roleTitle: 'Sales Head',
        name: 'Vikramaditya Roy',
        userId: 'BHFSH:-01',
        themeColor: Colors.red,
        addressLocation: 'Corporate HQ, Crest – 1, Bhavnagar',
        assignedRoute: 'All National Routes',
        latitude: 21.7623,
        longitude: 72.1537,
        isOnline: true,
      ),
    ];

    for (var item in hierarchyData) {
      if (item.userId == userId) item.isOnline = true;
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _minuteLocationTimer?.cancel();
    _punchCheckTimer?.cancel();
    _faceDetector.close();
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
      _fetchOrderStats();
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
                          _changePassword(userId, oldController.text, newController.text);
                          Navigator.pop(ctx);
                        } else if (newController.text.length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Password must be at least 4 characters!")),
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

  Future<void> _changePassword(String identifier, String oldPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${API_BASE_URL}change_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': identifier,
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
      final response = await http
          .get(Uri.parse("${API_BASE_URL}get_salesman_routes.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final users = data['data'] as List;
          for (var user in users) {
            if (user['emp_id'].toString() == userId) {
              setState(() {
                assignedRoute = user['assigned_route'] ?? 'Not Assigned';
                for (var item in hierarchyData) {
                  if (item.userId == userId) {
                    item.assignedRoute = assignedRoute!;
                  }
                }
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Route Fetch API Error: $e");
    }
  }

  Future<void> _fetchProductCatalog() async {
    try {
      final response = await http.get(Uri.parse("${API_BASE_URL}catelog.php"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
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

  Future<void> _fetchOrderStats() async {
    try {
      final response = await http
          .get(Uri.parse("${API_BASE_URL}manage_daily_reports.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          final reports = List<Map<String, dynamic>>.from(data['reports']);
          int total = reports.length;
          int pending = reports.where((r) =>
              (r['order_status'] ?? '').toString().toLowerCase().contains('pending')
          ).length;
          int confirm = reports.where((r) =>
              (r['order_status'] ?? '').toString().toLowerCase().contains('confirm')
          ).length;

          setState(() {
            totalOrders = total;
            pendingOrders = pending;
            confirmOrders = confirm;
          });
        }
      }
    } catch (e) {
      debugPrint("Order Stats API Error: $e");
    }
  }

  Future<void> _fetchAttendanceStatus() async {
    try {
      final response = await http
          .get(Uri.parse("${API_BASE_URL}get_attendance.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['attendance'] != null && mounted) {
          setState(() {
            isCheckedIn = data['attendance']['punch_type'] == 'PUNCH_IN';
            lastPunchType = data['attendance']['punch_type'];
            capturedPhotoUrl = data['attendance']['photo'];
            lastPunchDate = data['attendance']['punch_date'];
            lastPunchTime = data['attendance']['punch_time'];
            lastPunchDay = data['attendance']['day'];
          });
        } else {
          setState(() {
            isCheckedIn = false;
            lastPunchType = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Attendance API Error: $e");
    }
  }

  Future<void> _submitPunchApi(File photoFile, String punchType) async {
    try {
      var request = http.MultipartRequest(
          "POST", Uri.parse("${API_BASE_URL}punch_attendance.php"));
      request.fields['emp_id'] = userId;
      request.fields['role'] = userRole;
      request.fields['punch_type'] = punchType;

      request.files
          .add(await http.MultipartFile.fromPath('photo', photoFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              isCheckedIn = (punchType == 'PUNCH_IN');
              capturedImageFile = photoFile;
              lastPunchType = punchType;
              capturedPhotoUrl = data['photo_url'];
              lastPunchDate = data['punch_date'];
              lastPunchTime = data['punch_time'];
              lastPunchDay = data['day'];
            });
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(data['message'] ?? 'Punch updated successfully!'),
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

  // Leave Management
  Future<void> _fetchLeaveHistory() async {
    try {
      final response = await http
          .get(Uri.parse("${API_BASE_URL}manage_leaves.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            leaveHistory = List<Map<String, dynamic>>.from(data['leaves']);
          });
        }
      }
    } catch (e) {
      debugPrint("Leave History API Error: $e");
    }
  }

  Future<void> _submitLeaveApi(String type, String startDate, String endDate, String reason) async {
    try {
      final response = await http.post(
        Uri.parse("${API_BASE_URL}manage_leaves.php"),
        body: {
          'emp_id': userId,
          'leave_type': type,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _fetchLeaveHistory();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text("Leave Application Submitted!")),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(data['message'] ?? 'Failed to submit leave')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Failed to submit leave: $e")),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Leave Application",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedLeaveType,
                    dropdownColor: _AdminPalette.darkInputBg,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedLeaveType = val);
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
                      icon: const Icon(Icons.calendar_today, color: Colors.redAccent, size: 16),
                      label: Text(
                        _selectedLeaveDateRange == null
                            ? "Select Date Range"
                            : "${DateFormat('dd-MM-yyyy').format(_selectedLeaveDateRange!.start)} to ${DateFormat('dd-MM-yyyy').format(_selectedLeaveDateRange!.end)}",
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setDialogState(() => _selectedLeaveDateRange = picked);
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
                        child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
                        onPressed: () {
                          if (_selectedLeaveDateRange != null && _leaveReasonController.text.isNotEmpty) {
                            String start = "${_selectedLeaveDateRange!.start.year}-${_selectedLeaveDateRange!.start.month.toString().padLeft(2, '0')}-${_selectedLeaveDateRange!.start.day.toString().padLeft(2, '0')}";
                            String end = "${_selectedLeaveDateRange!.end.year}-${_selectedLeaveDateRange!.end.month.toString().padLeft(2, '0')}-${_selectedLeaveDateRange!.end.day.toString().padLeft(2, '0')}";

                            _submitLeaveApi(selectedLeaveType, start, end, _leaveReasonController.text);
                            _leaveReasonController.clear();
                            _selectedLeaveDateRange = null;
                            Navigator.pop(ctx);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                          }
                        },
                        child: const Text("Submit Leave", style: TextStyle(color: Colors.white)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _AdminPalette.bgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Leave History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
            const Divider(),
            Expanded(
              child: leaveHistory.isEmpty
                  ? const Center(child: Text("No leave history found"))
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
                    child: ListTile(
                      title: Text(item['leave_type'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("📅 ${item['start_date']} to ${item['end_date']}\n📝 ${item['reason']}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(item['status'] ?? 'Pending',
                            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // WhatsApp Order
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
          const SnackBar(content: Text("Unable to launch WhatsApp application.")),
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

  // Daily Reports
  Future<void> _submitDailyReportApi() async {
    try {
      final response = await http.post(
        Uri.parse("${API_BASE_URL}manage_daily_reports.php"),
        body: {
          'emp_id': userId,
          'firm_name': _firmNameController.text,
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
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _fetchDailyReports();
          _fetchOrderStats();
          _firmNameController.clear();
          _mobileController.clear();
          _pinCodeController.clear();
          _qtyController.text = '1';
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text("Order successfully logged in Database!")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text("Daily Report Order Error: $e")),
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

        if (data['status'] == 'success' && data['reports'] != null) {
          if (!mounted) return;
          setState(() {
            dailyTaskHistory = List<Map<String, dynamic>>.from(
              (data['reports'] as List).map((item) => Map<String, dynamic>.from(item)),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Daily Report Fetching Error: $e");
    }
  }

  void _showDailyTaskHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _AdminPalette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Daily Orders Logged",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: dailyTaskHistory.isEmpty
              ? const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No daily reports logged.",
                  textAlign: TextAlign.center))
              : ListView.separated(
            shrinkWrap: true,
            itemCount: dailyTaskHistory.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, idx) {
              final item = dailyTaskHistory[idx];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['firm_name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(
                    "Item: ${item['product_name'] ?? ''}\nQty: ${item['quantity']} × ₹${item['price']}\n📍 ${item['address'] ?? ''}",
                    style: const TextStyle(fontSize: 11)),
                trailing: Text("₹${item['total_amount']}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 13)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close")),
        ],
      ),
    );
  }

  // Location Tracking
  void _start1MinLocationTimer() {
    _minuteLocationTimer?.cancel();
    _minuteLocationTimer =
        Timer.periodic(const Duration(minutes: 1), (_) async {
          await _fetchAndUpdateCurrentLocation();
        });
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

      for (var item in hierarchyData) {
        if (item.userId == userId) {
          item.addressLocation = resolvedAddress;
          item.latitude = position.latitude;
          item.longitude = position.longitude;
          item.isOnline = true;
        }
      }
    });
  }

  // Face Detection
  Future<Map<String, dynamic>> _analyzeFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

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

    return {'faces': faces, 'features': faceFeatures, 'message': 'Face verified!'};
  }

  // Trigger Selfie Punch
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

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: _AdminPalette.goldAccent)),
      );

      final result = await _analyzeFace(imageFile);
      if (mounted) Navigator.pop(context);

      if (result['faces'].isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.red,
              content: Text("Face verification failed. Retry.")),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _AdminPalette.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(result['features']['hasSmile'] ? Icons.emoji_emotions : Icons.face,
                  color: result['features']['hasSmile'] ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(result['features']['hasSmile'] ? "Face Verified with Smile!" : "Face Verified!"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(imageFile,
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text("📍 Location: ${currentLiveAddress ?? 'N/A'}",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    "🕐 Time: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _AdminPalette.primaryBrown),
              onPressed: () async {
                Navigator.pop(ctx);
                final nextPunchType = isCheckedIn ? 'PUNCH_OUT' : 'PUNCH_IN';
                await _submitPunchApi(imageFile, nextPunchType);
              },
              child: Text(isCheckedIn ? "Confirm Punch Out" : "Confirm Punch In",
                  style: const TextStyle(color: _AdminPalette.goldLight)),
            )
          ],
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Selfie Error: $e")));
    }
  }

  // Computed Properties
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

  List<HierarchyUserLocation> getVisibleHierarchy() {
    final visibleRoles = roleVisibilityMap[userRole] ?? [userRole];
    return hierarchyData
        .where((item) => visibleRoles.contains(item.roleKey))
        .toList();
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Widget Builders
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
                    style: TextStyle(fontSize: 10, color: _AdminPalette.inkDark),
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
                    style: TextStyle(fontSize: 10, color: _AdminPalette.inkDark),
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
                    style: TextStyle(fontSize: 10, color: _AdminPalette.inkDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("${getVisibleHierarchy().length}",
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

  Widget _buildRoleBasedLocationCard() {
    final visibleList = getVisibleHierarchy();

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
                    const Text("Live Hierarchy & Route Tracking",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _AdminPalette.inkDark)),
                    Text(
                        "Role: $userRole • ${visibleList.length} User(s) Visible",
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                  isGpsEnabled ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isGpsEnabled ? Colors.green : Colors.red),
                ),
                child: Text(
                  isGpsEnabled ? "GPS ON" : "GPS OFF",
                  style: TextStyle(
                      fontSize: 10,
                      color: isGpsEnabled
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleList.length,
            itemBuilder: (context, index) {
              final item = visibleList[index];
              final isCurrentUser = item.userId == userId;

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
                      backgroundColor: item.themeColor,
                      child: Text(item.roleKey.substring(0, 1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text("${item.roleTitle} (${item.userId})",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📍 ${isCurrentUser && currentLiveAddress != null ? currentLiveAddress! : item.addressLocation}",
                          maxLines: 2,
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "🛣️ Route: ${isCurrentUser && assignedRoute != null ? assignedRoute : item.assignedRoute}",
                          style: const TextStyle(
                              fontSize: 11,
                              color: _AdminPalette.primaryBrown,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    trailing: Text(
                      item.isOnline ? "Live" : "Offline",
                      style: TextStyle(
                          color: item.isOnline ? Colors.green : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
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
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: _AdminPalette.goldAccent, size: 16),
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
                                  color: _AdminPalette.goldLight, fontSize: 11)),
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
                                    backgroundColor: _AdminPalette.primaryBrown),
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Attendance & Punch",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _AdminPalette.inkDark)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCheckedIn
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isCheckedIn
                                          ? Colors.green
                                          : Colors.red),
                                ),
                                child: Text(
                                  isCheckedIn ? "✅ Checked In" : "❌ Not Checked In",
                                  style: TextStyle(
                                      color: isCheckedIn
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isCheckedIn) ...[
                            Container(
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
                                        : Colors.orange),
                              ),
                              child: Text(
                                getPunchOutStatus(),
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
                            // Show Punch Details
                            if (lastPunchDate != null && lastPunchTime != null) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AdminPalette.cardHeaderBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Text("Date", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(lastPunchDate ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text("Time", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(lastPunchTime ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text("Day", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(lastPunchDay ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                          // Captured Image with Decorative Container
                          if (capturedImageFile != null || (capturedPhotoUrl != null && capturedPhotoUrl!.isNotEmpty)) ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
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
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: _AdminPalette.cardBg,
                                  backgroundImage: capturedImageFile != null
                                      ? FileImage(capturedImageFile!)
                                      : (capturedPhotoUrl != null && capturedPhotoUrl!.isNotEmpty
                                      ? NetworkImage("${API_BASE_URL}${capturedPhotoUrl!}")
                                      : null) as ImageProvider?,
                                  child: capturedImageFile == null && (capturedPhotoUrl == null || capturedPhotoUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Order Stats Row
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _AdminPalette.cardHeaderBg,
                                    _AdminPalette.bgWarm,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _AdminPalette.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem("Total", totalOrders, Colors.blue),
                                  _buildStatItem("Pending", pendingOrders, Colors.orange),
                                  _buildStatItem("Confirm", confirmOrders, Colors.green),
                                ],
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
                                    fontWeight: FontWeight.bold),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Daily Report Log",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _AdminPalette.inkDark)),
                                IconButton(
                                    icon: const Icon(Icons.history,
                                        color: Colors.grey),
                                    onPressed: _showDailyTaskHistoryModal),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _firmNameController,
                              decoration: InputDecoration(
                                labelText: 'Firm / Retailer Shop Name',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter Firm Name' : null,
                            ),
                            const SizedBox(height: 12),
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
                                          borderRadius:
                                          BorderRadius.circular(12)),
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
                                          borderRadius:
                                          BorderRadius.circular(12)),
                                      isDense: true,
                                    ),
                                    validator: (v) => (v == null || v.length < 6)
                                        ? 'Invalid PIN'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                                    selectedProductName = productCatalog[cat]!
                                        .first['name'] as String;
                                    selectedProductPrice = (productCatalog[cat]!
                                        .first['price'] as num)
                                        .toDouble();
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
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
                                items: productCatalog[selectedCategory]!
                                    .map((prod) {
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: _AdminPalette.cardHeaderBg,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Calculated Total:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _AdminPalette.inkDark)),
                                  Text("₹${calculatedTotal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        _AdminPalette.primaryBrown,
                                      ),
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: 18),
                                      label: const Text("Save Order",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                      onPressed: () {
                                        if (_taskFormKey.currentState!
                                            .validate()) {
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
                                        backgroundColor:
                                        _AdminPalette.whatsappGreen,
                                      ),
                                      icon: const Icon(Icons.send,
                                          color: Colors.white, size: 16),
                                      label: const Text("WhatsApp",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
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
}