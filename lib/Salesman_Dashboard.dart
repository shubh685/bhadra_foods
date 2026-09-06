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

class _Palette {
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
    this.loggedInUserName = 'Suresh Kumar',
    this.email = "abc@gmail.com",
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String baseUrl = "http://10.0.2.2/bhadra_foods";

  late String userRole;
  late String userId;
  late String userName;
  late String userEmail;

  bool isCheckedIn = false;
  bool isLoadingData = true;
  late Stream<DateTime> _clockStream;
  StreamSubscription<Position>? _positionStreamSub;
  Timer? _minuteLocationTimer;

  String? currentLiveAddress = "Fetching live GPS location...";
  double? currentLatitude;
  double? currentLongitude;
  bool isGpsEnabled = false;

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
  List<Map<String, dynamic>> dailyTaskHistory = [];
  List<Map<String, dynamic>> attendanceHistory = [];
  List<HierarchyUserLocation> hierarchyData = [];

  final List<String> roleHierarchyOrder = ['Salesman', 'SO', 'ASM', 'RSM', 'ZSM', 'SalesHead'];

  Map<String, List<String>> get roleVisibilityMap => {
    'Salesman': ['Salesman'],
    'SO': ['Salesman', 'SO'],
    'ASM': ['Salesman', 'SO', 'ASM'],
    'RSM': ['Salesman', 'SO', 'ASM', 'RSM'],
    'ZSM': ['Salesman', 'SO', 'ASM', 'RSM', 'ZSM'],
    'SalesHead': ['Salesman', 'SO', 'ASM', 'RSM', 'ZSM', 'SalesHead'],
  };

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

    _fetchProductCatalog();
    _fetchAttendanceStatus();
    _fetchAttendanceHistory();
    _fetchLeaveHistory();
    _fetchDailyReports();
  }

  void _initializeHierarchyData() {
    hierarchyData = [
      HierarchyUserLocation(
        roleKey: 'Salesman',
        roleTitle: 'Salesman',
        name: 'Rahul Sharma',
        userId: 'BHFSM-01',
        themeColor: Colors.green,
        addressLocation: 'Fetching live position...',
        isOnline: false,
      ),
      HierarchyUserLocation(
        roleKey: 'SO',
        roleTitle: 'Sales Officer',
        name: 'Amit Shah',
        userId: 'BHFSO-01',
        themeColor: Colors.blue,
        addressLocation: 'Nari Chawkdi, Ring Road, Bhavnagar',
        latitude: 21.7645,
        longitude: 72.1519,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'ASM',
        roleTitle: 'Area Sales Manager',
        name: 'Rajesh Patel',
        userId: 'BHFASM-01',
        themeColor: Colors.deepOrange,
        addressLocation: 'Waghawadi Road, Near Jewel Circle, Bhavnagar',
        latitude: 21.7582,
        longitude: 72.1525,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'RSM',
        roleTitle: 'Regional Sales Manager',
        name: 'Vikas Mehta',
        userId: 'BHFRSM-01',
        themeColor: Colors.purple,
        addressLocation: 'Kalvibid Circle, Opp. ISKCON Temple, Bhavnagar',
        latitude: 21.7538,
        longitude: 72.1492,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'ZSM',
        roleTitle: 'Zone Sales Manager',
        name: 'Suresh Kumar',
        userId: 'BHFZSM-01',
        themeColor: Colors.brown,
        addressLocation: 'Ghogha Circle, Subhashnagar, Bhavnagar',
        latitude: 21.7465,
        longitude: 72.1551,
        isOnline: true,
      ),
      HierarchyUserLocation(
        roleKey: 'SalesHead',
        roleTitle: 'Sales Head',
        name: 'Vikramaditya Roy',
        userId: 'BHFSH-01',
        themeColor: Colors.red,
        addressLocation: 'Corporate HQ, Crest – 1, Waghawadi Road, Bhavnagar',
        latitude: 21.7623,
        longitude: 72.1537,
        isOnline: true,
      ),
    ];

    for (var item in hierarchyData) {
      if (item.roleKey == userRole) item.isOnline = true;
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _minuteLocationTimer?.cancel();
    _faceDetector.close();
    _firmNameController.dispose();
    _mobileController.dispose();
    _pinCodeController.dispose();
    _qtyController.dispose();
    _leaveReasonController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final Uri waUrl = Uri.parse("https://wa.me/919512312400");
    try {
      final bool launched = await launchUrl(
        waUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp application.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening WhatsApp: $e")),
        );
      }
    }
  }

  void _start1MinLocationTimer() {
    _minuteLocationTimer?.cancel();
    _minuteLocationTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _fetchAndUpdateCurrentLocation();
    });
  }

  Future<void> _fetchAndUpdateCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      await _updateAddressFromPosition(pos);
    } catch (e) {
      debugPrint("1-minute location refresh error: $e");
    }
  }

  Future<void> _fetchProductCatalog() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/catelog.php"));
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
                  selectedProductName = productCatalog[selectedCategory]!.first['name'];
                  selectedProductPrice = productCatalog[selectedCategory]!.first['price'];
                }
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Product Catalog API Error: $e");
    }
  }

  Future<void> _fetchAttendanceStatus() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_attendance.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['attendance'] != null && mounted) {
          setState(() {
            isCheckedIn = data['attendance']['punch_type'] == 'PUNCH_IN';
          });
        }
      }
    } catch (e) {
      debugPrint("Attendance API Error: $e");
    }
  }

  Future<void> _fetchAttendanceHistory() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_attendance_history.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            attendanceHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint("Attendance History API Error: $e");
    }
  }

  Future<void> _submitPunchApi(File photoFile, String punchType) async {
    try {
      var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/punch_attendance.php"));
      request.fields['emp_id'] = userId;
      request.fields['role'] = userRole;
      request.fields['latitude'] = (currentLatitude ?? 0.0).toString();
      request.fields['longitude'] = (currentLongitude ?? 0.0).toString();
      request.fields['punch_type'] = punchType;

      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              isCheckedIn = (punchType == 'PUNCH_IN');
            });
          }
          _fetchAttendanceHistory();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.green, content: Text(data['message'] ?? 'Punch recorded!')),
          );
        } else {
          throw Exception(data['message']);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Failed to submit punch: $e")),
      );
    }
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/manage_leaves.php?emp_id=$userId"));
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
        Uri.parse("$baseUrl/manage_leaves.php"),
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
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Failed to submit leave: $e")),
      );
    }
  }

  Future<void> _fetchDailyReports() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/manage_daily_reports.php?emp_id=$userId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            dailyTaskHistory = List<Map<String, dynamic>>.from(data['reports']);
          });
        }
      }
    } catch (e) {
      debugPrint("Daily Report API Error: $e");
    }
  }

  Future<void> _submitDailyReportApi() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/manage_daily_reports.php"),
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
          _firmNameController.clear();
          _mobileController.clear();
          _pinCodeController.clear();
          _qtyController.text = '1';
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text("Order recorded on server successfully!")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Failed to save order: $e")),
      );
    }
  }

  Future<void> _changePasswordApi(String oldPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/change_password.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'identifier': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      final data = json.decode(response.body);
      if (data['status'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.green, content: Text(data['message'] ?? 'Password updated successfully!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(data['message'] ?? 'Failed to update password.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Password Change Error: $e")),
      );
    }
  }

  Future<void> _initLiveGpsTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        currentLiveAddress = "Location services are OFF. Please enable GPS.";
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
      setState(() => currentLiveAddress = "Location permission denied.");
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
        final parts = [place.street, place.subLocality, place.locality, place.postalCode]
            .where((p) => p != null && p.trim().isNotEmpty)
            .toList();
        resolvedAddress = parts.isNotEmpty
            ? parts.join(', ')
            : "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      } else {
        resolvedAddress = "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      }
    } catch (e) {
      resolvedAddress = "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
    }

    if (!mounted) return;
    setState(() {
      currentLiveAddress = resolvedAddress;
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;

      for (var item in hierarchyData) {
        if (item.roleKey == userRole) {
          item.addressLocation = resolvedAddress;
          item.latitude = position.latitude;
          item.longitude = position.longitude;
          item.isOnline = true;
        }
      }
    });
  }

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
    final visibleRoles = roleVisibilityMap[userRole] ?? [];
    return hierarchyData.where((item) => visibleRoles.contains(item.roleKey)).toList();
  }

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
      'headAngle': {
        'yaw': face.headEulerAngleY ?? 0.0,
        'pitch': face.headEulerAngleX ?? 0.0,
        'roll': face.headEulerAngleZ ?? 0.0,
      },
    };

    return {'faces': faces, 'features': faceFeatures, 'message': 'Face detected successfully!'};
  }

  Future<void> _triggerSelfiePunch() async {
    try {
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        cameraStatus = await Permission.camera.request();
      }

      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("Camera permission required")),
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
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: _Palette.goldAccent)),
      );

      final result = await _analyzeFace(imageFile);
      if (mounted) Navigator.pop(context);

      if (result['faces'].isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("Face detection failed! Ensure face is clearly visible.")),
        );
        return;
      }

      if (!mounted) return;
      final features = result['features'];
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _Palette.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(features['hasSmile'] ? Icons.emoji_emotions : Icons.face, color: features['hasSmile'] ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(features['hasSmile'] ? "Face Verified with Smile!" : "Face Verified!"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(imageFile, height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text("Address: ${currentLiveAddress ?? 'N/A'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _Palette.primaryBrown),
              onPressed: () async {
                Navigator.pop(ctx);
                final nextPunchType = isCheckedIn ? 'PUNCH_OUT' : 'PUNCH_IN';
                await _submitPunchApi(imageFile, nextPunchType);
              },
              child: Text(isCheckedIn ? "Confirm Punch Out" : "Confirm Punch In", style: const TextStyle(color: _Palette.goldLight)),
            )
          ],
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selfie Error: $e")));
    }
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Change Password", style: TextStyle(color: _Palette.inkDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _Palette.primaryBrown),
            onPressed: () {
              if (oldPassController.text.isNotEmpty && newPassController.text.length >= 4) {
                Navigator.pop(ctx);
                _changePasswordApi(oldPassController.text, newPassController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New password must be at least 4 characters")),
                );
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showPersonalInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _Palette.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge, color: _Palette.primaryBrown),
              title: const Text("Employee ID"),
              subtitle: Text(userId, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: _Palette.primaryBrown),
              title: const Text("Full Name"),
              subtitle: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: _Palette.primaryBrown),
              title: const Text("Email Address"),
              subtitle: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.work, color: _Palette.primaryBrown),
              title: const Text("Assigned Designation"),
              subtitle: Text(userRole, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _Palette.primaryBrown),
                icon: const Icon(Icons.lock_reset, color: Colors.white),
                label: const Text("Change Password", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showChangePasswordDialog();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showProductCatalogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _Palette.bgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Product Catalog", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
            const Divider(),
            Expanded(
              child: rawProductList.isEmpty
                  ? const Center(child: Text("No products found in catalog."))
                  : ListView.builder(
                itemCount: rawProductList.length,
                itemBuilder: (ctx, idx) {
                  final item = rawProductList[idx];
                  return Card(
                    color: _Palette.cardBg,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: _Palette.cardHeaderBg,
                        child: Icon(Icons.inventory_2, color: _Palette.primaryBrown),
                      ),
                      title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Category: ${item['category']} | Sub: ${item['sub_category'] ?? 'N/A'}"),
                      trailing: Text("₹${item['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
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

  void _showAttendanceHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Attendance Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: attendanceHistory.isEmpty
              ? const Padding(padding: EdgeInsets.all(20.0), child: Text("No attendance records found.", textAlign: TextAlign.center))
              : ListView.separated(
            shrinkWrap: true,
            itemCount: attendanceHistory.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, idx) {
              final item = attendanceHistory[idx];
              final punchType = item['punch_type'] ?? 'PUNCH_IN';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  punchType == 'PUNCH_IN' ? Icons.login : Icons.logout,
                  color: punchType == 'PUNCH_IN' ? Colors.green : Colors.red,
                ),
                title: Text(punchType == 'PUNCH_IN' ? "Punch In" : "Punch Out", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${item['created_at'] ?? 'N/A'}\n${item['address'] ?? 'N/A'}"),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _buildTopSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.cardHeaderBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text("Monthly Sales", style: TextStyle(fontSize: 11, color: _Palette.inkDark)),
              const SizedBox(height: 4),
              Text("₹${totalMonthlySales.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          Container(height: 30, width: 1, color: _Palette.border),
          Column(
            children: [
              const Text("Daily Reports", style: TextStyle(fontSize: 11, color: _Palette.inkDark)),
              const SizedBox(height: 4),
              Text("${dailyTaskHistory.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.primaryBrown)),
            ],
          ),
          Container(height: 30, width: 1, color: _Palette.border),
          Column(
            children: [
              const Text("Visits Count", style: TextStyle(fontSize: 11, color: _Palette.inkDark)),
              const SizedBox(height: 4),
              Text("${getVisibleHierarchy().length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
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
        color: _Palette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Live Location Tracking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                  Text("Role: $userRole • ${visibleList.length} members visible", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGpsEnabled ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isGpsEnabled ? Colors.green.shade400 : Colors.red.shade400),
                ),
                child: Text(
                  isGpsEnabled ? "GPS ON" : "GPS OFF",
                  style: TextStyle(fontSize: 10, color: isGpsEnabled ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
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
              final isCurrentUser = item.roleKey == userRole;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: item.themeColor,
                  child: Text(item.roleKey.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                title: Text("${item.roleTitle} - ${item.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(isCurrentUser && currentLiveAddress != null ? currentLiveAddress! : item.addressLocation, maxLines: 2),
                trailing: Text(item.isOnline ? "Live" : "Offline", style: TextStyle(color: item.isOnline ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAbsenceRequestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: _Palette.darkModalBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Absence Request", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedLeaveType,
                    dropdownColor: _Palette.darkInputBg,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedLeaveType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _Palette.darkInputBg),
                    icon: const Icon(Icons.calendar_today, color: Colors.redAccent, size: 16),
                    label: Text(
                      _selectedLeaveDateRange == null
                          ? "Select Date Range"
                          : "${_selectedLeaveDateRange!.start.year}-${_selectedLeaveDateRange!.start.month}-${_selectedLeaveDateRange!.start.day} to ${_selectedLeaveDateRange!.end.year}-${_selectedLeaveDateRange!.end.month}-${_selectedLeaveDateRange!.end.day}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _leaveReasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Reason for Leave",
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
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
                          }
                        },
                        child: const Text("Submit", style: TextStyle(color: Colors.white)),
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
          color: _Palette.bgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Leave History Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
            const Divider(),
            Expanded(
              child: leaveHistory.isEmpty
                  ? const Center(child: Text("No leave history found"))
                  : ListView.builder(
                itemCount: leaveHistory.length,
                itemBuilder: (ctx, idx) {
                  final item = leaveHistory[idx];
                  return Card(
                    color: _Palette.cardBg,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(item['leave_type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${item['start_date']} to ${item['end_date']}\nReason: ${item['reason']}"),
                      trailing: Text(item['status'] ?? 'Pending', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
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

  void _showDailyTaskHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Daily Order Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: dailyTaskHistory.isEmpty
              ? const Padding(padding: EdgeInsets.all(20.0), child: Text("No orders logged yet.", textAlign: TextAlign.center))
              : ListView.separated(
            shrinkWrap: true,
            itemCount: dailyTaskHistory.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, idx) {
              final item = dailyTaskHistory[idx];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['firm_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${item['category']} • ${item['product_name']}\nQty: ${item['quantity']} × ₹${item['price']}"),
                trailing: Text("₹${item['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bgWarm,
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: _Palette.whatsappGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat, color: Colors.white, size: 28),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_Palette.darkHeaderTop, _Palette.darkHeaderBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$userRole Dashboard", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'info') {
                            _showPersonalInfoModal();
                          } else if (value == 'catalog') {
                            _showProductCatalogModal();
                          } else if (value == 'password') {
                            _showChangePasswordDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'info',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: _Palette.primaryBrown),
                                SizedBox(width: 8),
                                Text("Personal Info"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'catalog',
                            child: Row(
                              children: [
                                Icon(Icons.inventory, color: _Palette.primaryBrown),
                                SizedBox(width: 8),
                                Text("Product Catalog"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'password',
                            child: Row(
                              children: [
                                Icon(Icons.lock_reset, color: _Palette.primaryBrown),
                                SizedBox(width: 8),
                                Text("Change Password"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<DateTime>(
                    stream: _clockStream,
                    initialData: DateTime.now(),
                    builder: (context, snapshot) {
                      final now = snapshot.data ?? DateTime.now();
                      final timeString = DateFormat('hh:mm:ss a').format(now);
                      final dateString = DateFormat('EEEE, dd MMMM yyyy').format(now);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: _Palette.goldAccent, size: 18),
                                const SizedBox(width: 6),
                                Text(timeString, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Text(dateString, style: const TextStyle(color: _Palette.goldLight, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("Employee ID: $userId", style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _Palette.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _Palette.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Leave Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _Palette.inkDark)),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.history, color: _Palette.primaryBrown), onPressed: _showLeaveHistoryModal),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: _Palette.primaryBrown),
                              onPressed: _showAbsenceRequestDialog,
                              child: const Text("Apply", style: TextStyle(color: Colors.white, fontSize: 12)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _Palette.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _Palette.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Attendance & Punch", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.history, color: _Palette.primaryBrown, size: 22),
                                  onPressed: _showAttendanceHistoryModal,
                                ),
                                Text(isCheckedIn ? "Checked In" : "Not Checked In", style: TextStyle(color: isCheckedIn ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: isCheckedIn ? Colors.red.shade700 : const Color(0xFF2E7D32)),
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            label: Text(
                              isCheckedIn ? "Punch Out (Face Detection)" : "Punch In (Face Detection)",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _triggerSelfiePunch,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _Palette.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _Palette.border),
                    ),
                    child: Form(
                      key: _taskFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Daily Report Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                              IconButton(icon: const Icon(Icons.history, color: Colors.grey), onPressed: _showDailyTaskHistoryModal),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _firmNameController,
                            decoration: InputDecoration(labelText: 'Firm / Retailer Shop Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter Firm Name' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  decoration: InputDecoration(labelText: 'Mobile No.', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                                  validator: (v) => (v == null || v.length < 10) ? '10 Digits required' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _pinCodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(labelText: 'PIN Code', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                                  validator: (v) => (v == null || v.length < 6) ? 'Invalid PIN' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: 'Product Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                            items: productCatalog.keys.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                            onChanged: (cat) {
                              if (cat != null) {
                                setState(() {
                                  selectedCategory = cat;
                                  selectedProductName = productCatalog[cat]!.first['name'] as String;
                                  selectedProductPrice = (productCatalog[cat]!.first['price'] as num).toDouble();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          if (selectedCategory != null && productCatalog[selectedCategory] != null)
                            DropdownButtonFormField<String>(
                              value: selectedProductName,
                              isExpanded: true,
                              decoration: InputDecoration(labelText: 'Select Product', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                              items: productCatalog[selectedCategory]!.map((prod) {
                                return DropdownMenuItem<String>(
                                  value: prod['name'] as String,
                                  child: Text("${prod['name']} - ₹${prod['price']}"),
                                );
                              }).toList(),
                              onChanged: (prodName) {
                                if (prodName != null) {
                                  final prod = productCatalog[selectedCategory]!.firstWhere((e) => e['name'] == prodName);
                                  setState(() {
                                    selectedProductName = prodName;
                                    selectedProductPrice = (prod['price'] as num).toDouble();
                                  });
                                }
                              },
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter Qty' : null,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _Palette.cardHeaderBg, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Calculated Total:", style: TextStyle(fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                                Text("₹${calculatedTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: _Palette.primaryBrown, padding: const EdgeInsets.symmetric(vertical: 12)),
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                              label: const Text("Save Order Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (_taskFormKey.currentState!.validate()) {
                                  _submitDailyReportApi();
                                }
                              },
                            ),
                          )
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
    );
  }
}