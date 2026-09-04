import 'dart:async';
import 'dart:io';
import 'package:bhad_foods/Log_In.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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

// Model for reporting chain live positions with Proper Physical Address
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
    this.loggedInRole = 'ZSM',
    this.loggedInUserId = 'BHFZSM-01',
    this.loggedInUserName = 'Suresh Kumar',
    this.email = "abc@gmail.com"
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String userRole;
  late String userId;
  late String userName;

  bool isCheckedIn = false;
  late Stream<DateTime> _clockStream;
  StreamSubscription<Position>? _positionStreamSub;
  String? currentLiveAddress = "Fetching live GPS location...";
  double? currentLatitude;
  double? currentLongitude;
  bool isGpsEnabled = false;

  // Image Picker & Face Detector Setup
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

  // Form Controllers
  final _taskFormKey = GlobalKey<FormState>();
  final _firmNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  // Dynamic Product Catalog
  final Map<String, List<Map<String, dynamic>>> productCatalog = {
    'Khakhra': [
      {'name': 'Plain Khakhra', 'price': 70.00},
      {'name': 'Masala Khakhra', 'price': 80.00},
      {'name': 'Methi Khakhra', 'price': 85.00},
    ],
  };

  late String selectedCategory;
  late String selectedProductName;
  late double selectedProductPrice;

  // Leave Management State
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

  final List<Map<String, String>> leaveHistory = [
    {
      'type': 'Casual Leave',
      'dates': '12 Aug - 13 Aug 2026',
      'reason': 'Personal Work',
      'status': 'Approved'
    },
    {
      'type': 'Sick Leave',
      'dates': '02 Jul - 02 Jul 2026',
      'reason': 'Fever & Rest',
      'status': 'Approved'
    },
  ];

  // Daily Log History
  final List<Map<String, dynamic>> dailyTaskHistory = [
    {
      'firm': 'Shree Ji Decorators',
      'mobile': '9876543210',
      'pin': '364001',
      'category': 'Khakhra',
      'product': 'Plain Khakhra',
      'price': 70.00,
      'qty': 10,
      'total': 700.00,
      'time': '10:30 AM',
      'status': 'Order Taken',
    },
  ];

  // Hierarchy Chain Data with Proper Physical Addresses
  List<HierarchyUserLocation> hierarchyData = [];

  // Hierarchy Role Levels for Filter Logic
  final List<String> roleHierarchyOrder = [
    'Salesman',
    'SO',
    'ASM',
    'RSM',
    'ZSM',
    'SalesHead'
  ];

  // Role-based visibility mapping
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

    _initializeHierarchyData();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    selectedCategory = productCatalog.keys.first;
    selectedProductName = productCatalog[selectedCategory]!.first['name'] as String;
    selectedProductPrice = (productCatalog[selectedCategory]!.first['price'] as num).toDouble();

    _initLiveGpsTracking();
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

    // Find and update current user
    for (var item in hierarchyData) {
      if (item.roleKey == userRole) {
        item.isOnline = true;
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _faceDetector.close();
    _firmNameController.dispose();
    _mobileController.dispose();
    _pinCodeController.dispose();
    _qtyController.dispose();
    _leaveReasonController.dispose();
    super.dispose();
  }

  // Live Location & Reverse Geocoding Setup
  Future<void> _initLiveGpsTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        currentLiveAddress = "Location services are OFF. Please enable GPS.";
        isGpsEnabled = false;
      });
      _showPermissionSnackBar(
        "Location services are turned off. Please enable GPS to fetch your live location.",
        settingsLabel: "ENABLE",
        onSettingsPressed: () => Geolocator.openLocationSettings(),
      );
      return;
    }

    setState(() => isGpsEnabled = true);

    PermissionStatus permStatus = await Permission.locationWhenInUse.status;
    if (permStatus.isDenied) {
      permStatus = await Permission.locationWhenInUse.request();
    }

    if (permStatus.isPermanentlyDenied || permStatus.isRestricted) {
      if (!mounted) return;
      setState(() => currentLiveAddress = "Location permission denied. Enable it in app settings.");
      _showPermissionSnackBar(
        "Location permission is permanently denied. Please enable it from app settings.",
        settingsLabel: "SETTINGS",
        onSettingsPressed: () => openAppSettings(),
      );
      return;
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
        setState(() => currentLiveAddress = "Unable to fetch current location. Retrying in background...");
      }
    }

    await _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
          (Position position) => _updateAddressFromPosition(position),
      onError: (e) {
        if (mounted) {
          setState(() => currentLiveAddress = "Live location error: $e");
        }
      },
    );
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

      // Update current user's location in hierarchy
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

  void _showPermissionSnackBar(String message, {required String settingsLabel, required VoidCallback onSettingsPressed}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: settingsLabel,
          textColor: Colors.white,
          onPressed: onSettingsPressed,
        ),
      ),
    );
  }

  double get calculatedTotal {
    int qty = int.tryParse(_qtyController.text) ?? 0;
    return selectedProductPrice * qty;
  }

  List<HierarchyUserLocation> getVisibleHierarchy() {
    final visibleRoles = roleVisibilityMap[userRole] ?? [];
    return hierarchyData.where((item) {
      return visibleRoles.contains(item.roleKey);
    }).toList();
  }

  // Enhanced Face Detection with Smile and Features
  Future<Map<String, dynamic>> _analyzeFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      return {'faces': [], 'message': 'No face detected'};
    }

    final face = faces.first;
    Map<String, dynamic> faceFeatures = {
      'hasSmile': face.smilingProbability ?? 0.0 > 0.5,
      'smileProbability': face.smilingProbability ?? 0.0,
      'leftEyeOpen': face.leftEyeOpenProbability ?? 0.0,
      'rightEyeOpen': face.rightEyeOpenProbability ?? 0.0,
      'headAngle': {
        'yaw': face.headEulerAngleY ?? 0.0,
        'pitch': face.headEulerAngleX ?? 0.0,
        'roll': face.headEulerAngleZ ?? 0.0,
      },
      'hasGlasses': false, // ML Kit doesn't directly detect glasses
      'faceCount': faces.length,
    };

    return {'faces': faces, 'features': faceFeatures, 'message': 'Face detected successfully!'};
  }

  Future<void> _triggerSelfiePunch() async {
    try {
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        cameraStatus = await Permission.camera.request();
      }

      if (cameraStatus.isPermanentlyDenied || cameraStatus.isRestricted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text("Camera permission is permanently denied. Please enable it from app settings."),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: "SETTINGS",
              textColor: Colors.white,
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }

      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("Camera permission is required to punch in.")),
        );
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (photo == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Punch-in cancelled: no photo was captured.")),
        );
        return;
      }

      File imageFile = File(photo.path);
      if (!await imageFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Captured photo could not be read. Please try again."),
          ),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: _Palette.goldAccent),
        ),
      );

      final result = await _analyzeFace(imageFile);

      if (mounted) Navigator.pop(context);

      if (result['faces'].isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Face detection failed! Ensure adequate lighting and align face inside camera."),
          ),
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
              Icon(features['hasSmile'] ? Icons.emoji_emotions : Icons.face,
                  color: features['hasSmile'] ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(
                features['hasSmile'] ? "Face Verified with Smile!" : "Face Verified!",
                style: const TextStyle(color: _Palette.inkDark, fontWeight: FontWeight.bold),
              ),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _Palette.cardHeaderBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sentiment_satisfied, color: features['hasSmile'] ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            features['hasSmile'] ? "😊 Smiling! (${(features['smileProbability'] * 100).toStringAsFixed(0)}%)" : "😐 Not Smiling",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: features['hasSmile'] ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Eyes: ${features['leftEyeOpen'] > 0.5 ? '👁️ Open' : '🔒 Closed'} / ${features['rightEyeOpen'] > 0.5 ? '👁️ Open' : '🔒 Closed'}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.rotate_right, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            "Head: Yaw ${features['headAngle']['yaw'].toStringAsFixed(1)}°",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentLiveAddress ?? "Location not available",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _Palette.primaryBrown),
              icon: const Icon(Icons.check_circle, color: _Palette.goldLight, size: 18),
              label: Text(
                isCheckedIn ? "Confirm Punch Out" : "Confirm Punch In",
                style: const TextStyle(color: _Palette.goldLight),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => isCheckedIn = !isCheckedIn);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _Palette.primaryBrown,
                    content: Text(
                      isCheckedIn
                          ? "Punch In recorded! ${features['hasSmile'] ? '😊' : '😐'}"
                          : "Punch Out successful!",
                    ),
                  ),
                );
              },
            )
          ],
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing selfie: $e")),
      );
    }
  }

  // Role-based Location Card Widget
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Live Location Tracking",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.inkDark),
                  ),
                  Text(
                    "Role: $userRole • ${visibleList.length} members visible",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: isGpsEnabled ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentLiveAddress != null && userRole == 'Salesman')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "📍 My Live Location",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          currentLiveAddress!,
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleList.length,
            itemBuilder: (context, index) {
              final item = visibleList[index];
              final isCurrentUser = item.roleKey == userRole;
              final isLast = index == visibleList.length - 1;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue.shade50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrentUser ? Border.all(color: Colors.blue.shade300) : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: item.themeColor,
                              child: Text(
                                item.roleKey.substring(0, 1),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (item.isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.roleTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _Palette.inkDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.themeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isCurrentUser)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "YOU",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: isCurrentUser ? Colors.blue.shade700 : Colors.grey.shade600,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.addressLocation,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isCurrentUser ? Colors.blue.shade900 : _Palette.inkDark,
                                        fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.latitude != null && item.longitude != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    "📍 ${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}",
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.isOnline ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.isOnline ? Colors.green.shade400 : Colors.red.shade400,
                            ),
                          ),
                          child: Text(
                            item.isOnline ? "● Live" : "○ Offline",
                            style: TextStyle(
                              fontSize: 8,
                              color: item.isOnline ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      height: 4,
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void viewProductCatalog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: _Palette.bgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.menu_book, color: _Palette.primaryBrown, size: 24),
                SizedBox(width: 10),
                Text(
                  "Product Catalog & Pricing",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.inkDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: productCatalog.keys.length,
                itemBuilder: (context, index) {
                  String category = productCatalog.keys.elementAt(index);
                  List<Map<String, dynamic>> items = productCatalog[category]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _Palette.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _Palette.border),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0,
                      iconColor: _Palette.primaryBrown,
                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _Palette.inkDark, fontSize: 15),
                      ),
                      children: items.map((item) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.inventory_2_outlined, color: _Palette.primaryBrown, size: 18),
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: _Palette.inkDark)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _Palette.cardHeaderBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "₹${item['price']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        );
                      }).toList(),
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

  void _showPersonalDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _Palette.bgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: _Palette.goldLight,
                    child: Icon(Icons.person, size: 42, color: _Palette.primaryBrown),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                        const SizedBox(height: 2),
                        Text("Role: $userRole ($userId)", style: const TextStyle(fontSize: 13, color: _Palette.primaryBrown, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
              const Divider(height: 24),
              const Text("Personal & Contact Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
              const SizedBox(height: 10),
              _buildProfileInfoRow(Icons.phone, "Phone Number", "+91 98765 43210"),
              _buildProfileInfoRow(Icons.email, "Email Address", "user@decor.com"),
              _buildProfileInfoRow(Icons.alt_route, "Assigned Route", "Shastrinagar ➔ Nari Chawkdi ➔ Waghawadi road"),
              _buildProfileInfoRow(Icons.supervisor_account, "Reporting Officer", "Amit Shah (BHFSO-01)"),
              _buildProfileInfoRow(Icons.calendar_month, "Date of Joining", "15 Jan 2024"),
              const Divider(height: 24),
              ListTile(
                tileColor: _Palette.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _Palette.border)),
                leading: const Icon(Icons.menu_book, color: _Palette.primaryBrown),
                title: const Text("View Product Catalogs", style: TextStyle(fontWeight: FontWeight.w600, color: _Palette.inkDark)),
                subtitle: const Text("Explore available products & prices"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  viewProductCatalog();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: _Palette.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _Palette.border)),
                leading: const Icon(Icons.lock_reset, color: _Palette.primaryBrown),
                title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w600, color: _Palette.inkDark)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangePasswordModal();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                  label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => Login()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logged out successfully!")),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
              color: _Palette.cardBg,
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
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.lock_reset, color: _Palette.primaryBrown),
                      SizedBox(width: 8),
                      Text("Change Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldController,
                    obscureText: hideOld,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(hideOld ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => hideOld = !hideOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: hideNew,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(hideNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => hideNew = !hideNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: hideNew,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primaryBrown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (newController.text.isNotEmpty && newController.text == confirmController.text) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password changed successfully!")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Passwords do not match!")),
                          );
                        }
                      },
                      child: const Text("Update Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_late, color: Colors.redAccent, size: 22),
                        SizedBox(width: 8),
                        Text("Absence Request", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Employee ID: $userId",
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Type of Leave", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _Palette.darkInputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLeaveType,
                          dropdownColor: _Palette.darkInputBg,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: leaveTypes.map((type) {
                            return DropdownMenuItem(value: type, child: Text("• $type"));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedLeaveType = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("From Date to End Date", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setDialogState(() => _selectedLeaveDateRange = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _Palette.darkInputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedLeaveDateRange == null
                                      ? "Select Start Date"
                                      : "${_selectedLeaveDateRange!.start.day}/${_selectedLeaveDateRange!.start.month}/${_selectedLeaveDateRange!.start.year}",
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _selectedLeaveDateRange == null
                                      ? "to End Date"
                                      : "to ${_selectedLeaveDateRange!.end.day}/${_selectedLeaveDateRange!.end.month}/${_selectedLeaveDateRange!.end.year}",
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Reason For Leave", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _leaveReasonController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter reason for leave",
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: _Palette.darkInputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              if (_selectedLeaveDateRange != null && _leaveReasonController.text.isNotEmpty) {
                                setState(() {
                                  leaveHistory.insert(0, {
                                    'type': selectedLeaveType,
                                    'dates': "${_selectedLeaveDateRange!.start.day}/${_selectedLeaveDateRange!.start.month} - ${_selectedLeaveDateRange!.end.day}/${_selectedLeaveDateRange!.end.month}",
                                    'reason': _leaveReasonController.text,
                                    'status': 'Pending'
                                  });
                                  _leaveReasonController.clear();
                                  _selectedLeaveDateRange = null;
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Leave Application Submitted!")),
                                );
                              }
                            },
                            child: const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Leave History Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                Icon(Icons.history_edu, color: _Palette.primaryBrown),
              ],
            ),
            const Divider(),
            Expanded(
              child: leaveHistory.isEmpty
                  ? const Center(child: Text("No leave history available"))
                  : ListView.builder(
                itemCount: leaveHistory.length,
                itemBuilder: (ctx, idx) {
                  final item = leaveHistory[idx];
                  return Card(
                    color: _Palette.cardBg,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(item['type']!, style: const TextStyle(fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                      subtitle: Text("${item['dates']}\nReason: ${item['reason']}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item['status'] == 'Approved' ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['status']!,
                          style: TextStyle(
                            color: item['status'] == 'Approved' ? Colors.green.shade800 : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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

  void _showDailyTaskHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment_outlined, color: _Palette.primaryBrown),
            SizedBox(width: 8),
            Text("Daily Order Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
          ],
        ),
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
                title: Text(item['firm']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${item['category']} • ${item['product']}\nMob: ${item['mobile'] ?? 'N/A'} | PIN: ${item['pin'] ?? 'N/A'}\nQty: ${item['qty']} × ₹${item['price']}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("₹${item['total']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                    Text(item['time']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: _Palette.primaryBrown, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bgWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
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
                        IconButton(
                          icon: const Icon(Icons.manage_accounts, color: Colors.white),
                          onPressed: _showPersonalDetailsModal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: _showPersonalDetailsModal,
                          child: const CircleAvatar(
                            radius: 32,
                            backgroundColor: _Palette.goldLight,
                            child: Icon(Icons.person, size: 42, color: _Palette.primaryBrown),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _Palette.goldAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(userRole, style: const TextStyle(color: _Palette.inkDark, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),
                              Text("ID: $userId", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Role-based Location Card
                    _buildRoleBasedLocationCard(),
                    const SizedBox(height: 16),

                    // Metrics
                    Row(
                      children: [
                        _buildMetricCard("₹45,200", "This Month", Icons.currency_rupee, Colors.green),
                        const SizedBox(width: 8),
                        _buildMetricCard("1 / 5", "Rank", Icons.emoji_events_outlined, Colors.amber),
                        const SizedBox(width: 8),
                        _buildMetricCard("${dailyTaskHistory.length}", "Orders", Icons.shopping_bag_outlined, Colors.blue),
                        const SizedBox(width: 8),
                        _buildMetricCard("0", "Pending", Icons.assignment_outlined, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Leave Management
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
                          const Row(
                            children: [
                              Icon(Icons.event_available, color: _Palette.primaryBrown),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Leave Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _Palette.inkDark)),
                                  Text("Apply & view leave history", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history, color: _Palette.primaryBrown),
                                onPressed: _showLeaveHistoryModal,
                              ),
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

                    // Attendance & Punch
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
                              const Row(
                                children: [
                                  Icon(Icons.fingerprint, color: _Palette.primaryBrown),
                                  SizedBox(width: 8),
                                  Text("Attendance & Punch", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                                ],
                              ),
                              Text(
                                isCheckedIn ? "Checked In" : "Not Checked In",
                                style: TextStyle(color: isCheckedIn ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<DateTime>(
                            stream: _clockStream,
                            builder: (context, snapshot) {
                              DateTime now = snapshot.data ?? DateTime.now();
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: _Palette.primaryBrown, borderRadius: BorderRadius.circular(14)),
                                child: Column(
                                  children: [
                                    Text("${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)} ${now.year}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(
                                      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
                                      style: const TextStyle(color: _Palette.goldLight, fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
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
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 16),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "Face detection includes: Smile detection, Eye tracking, Head pose estimation",
                                    style: TextStyle(fontSize: 10, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daily Report Log
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
                                const Row(
                                  children: [
                                    Icon(Icons.edit_note, color: _Palette.primaryBrown),
                                    SizedBox(width: 8),
                                    Text("Daily Report Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.history, color: Colors.grey),
                                      tooltip: "Order History",
                                      onPressed: _showDailyTaskHistoryModal,
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _firmNameController,
                              decoration: InputDecoration(
                                labelText: 'Firm / Retailer Shop Name',
                                prefixIcon: const Icon(Icons.storefront, color: _Palette.primaryBrown),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
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
                                    decoration: InputDecoration(
                                      labelText: 'Mobile No.',
                                      counterText: '',
                                      prefixIcon: const Icon(Icons.phone_android, color: _Palette.primaryBrown),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      isDense: true,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Enter Mobile';
                                      if (v.length < 10) return 'Enter 10 digits';
                                      return null;
                                    },
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
                                      prefixIcon: const Icon(Icons.location_on_outlined, color: _Palette.primaryBrown),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      isDense: true,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Enter PIN';
                                      if (v.length < 6) return 'Invalid PIN';
                                      return null;
                                    },
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              items: productCatalog.keys.map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat, overflow: TextOverflow.ellipsis),
                              )).toList(),
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

                            DropdownButtonFormField<String>(
                              value: selectedProductName,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Product (With Rate)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              items: productCatalog[selectedCategory]!.map((prod) {
                                return DropdownMenuItem<String>(
                                  value: prod['name'] as String,
                                  child: Text(
                                    "${prod['name']} - ₹${prod['price']}",
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: const Icon(Icons.numbers, color: _Palette.primaryBrown),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => (v == null || v.isEmpty) ? 'Enter Quantity' : null,
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _Palette.cardHeaderBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Calculated Total Amount:", style: TextStyle(fontWeight: FontWeight.bold, color: _Palette.inkDark)),
                                  Text("₹${calculatedTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _Palette.primaryBrown,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                    label: const Text("Send Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      if (_taskFormKey.currentState!.validate()) {
                                        setState(() {
                                          dailyTaskHistory.insert(0, {
                                            'firm': _firmNameController.text,
                                            'mobile': _mobileController.text,
                                            'pin': _pinCodeController.text,
                                            'category': selectedCategory,
                                            'product': selectedProductName,
                                            'price': selectedProductPrice,
                                            'qty': int.parse(_qtyController.text),
                                            'total': calculatedTotal,
                                            'time': "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                                            'status': 'Order Taken',
                                          });
                                          _firmNameController.clear();
                                          _mobileController.clear();
                                          _pinCodeController.clear();
                                          _qtyController.text = '1';
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order recorded successfully!")));
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _Palette.whatsappGreen,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                    label: const Text("WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      if (_taskFormKey.currentState!.validate()) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Sharing order details for ${_firmNameController.text} on WhatsApp...")),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _Palette.primaryBrown),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _Palette.inkDark))),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String title, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: _Palette.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Palette.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _Palette.inkDark)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _getDayName(int day) {
    const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[day - 1];
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}