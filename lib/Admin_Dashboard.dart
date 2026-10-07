import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bhad_foods/Log_In.dart';

class _AdminPalette {
  static const darkHeaderTop = Color(0xFF3D2314);
  static const darkHeaderBottom = Color(0xFF28140A);
  static const primaryBrown = Color(0xFF542E16);
  static const bgWarm = Color(0xFFFFFDF7);
  static const cardBg = Color(0xFFFFFFFF);
  static const border = Color(0xFFEFE6D5);
  static const inkDark = Color(0xFF2B1810);
  static const accentBadge = Color(0xFFF3C262);
}

// API Base URL
const String API_BASE_URL = 'http://10.249.124.78/bhadra_foods/';

// Model for Admin User
class AdminModel {
  String id;
  String name;
  String empId;
  String mobile;
  String email;
  String city;
  String role;
  String lastUpdated;

  AdminModel({
    required this.id,
    required this.name,
    required this.empId,
    required this.mobile,
    required this.email,
    required this.city,
    required this.role,
    required this.lastUpdated,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      empId: json['emp_id'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      role: json['role'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

// Model for Salesman mapped directly to MySQL table 'manage_salesman'
class SalesmanModel {
  String id;
  String name;
  String empId;
  String role;
  String city;
  String phone;
  String email;
  String lastUpdated;
  bool isLive;
  String assignedRoute;
  String liveLocation;
  double? latitude;
  double? longitude;

  String address;
  String liveAddress;

  SalesmanModel({
    required this.id,
    required this.name,
    required this.empId,
    required this.role,
    required this.city,
    required this.phone,
    required this.email,
    required this.lastUpdated,
    this.isLive = true,
    this.assignedRoute = '',
    this.liveLocation = '',
    this.latitude,
    this.longitude,
    this.address = '',
    this.liveAddress = '',
  });

  factory SalesmanModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    if (json['latitude'] != null && json['latitude'] != '') {
      lat = double.tryParse(json['latitude'].toString());
    } else if (json['lat'] != null && json['lat'] != '') {
      lat = double.tryParse(json['lat'].toString());
    }

    double? lng;
    if (json['longitude'] != null && json['longitude'] != '') {
      lng = double.tryParse(json['longitude'].toString());
    } else if (json['lng'] != null && json['lng'] != '') {
      lng = double.tryParse(json['lng'].toString());
    }

    return SalesmanModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      empId: json['emp_id']?.toString() ?? '',
      role: json['role'] ?? '',
      city: json['city'] ?? '',
      phone: json['mobile'] ?? '',
      email: json['email'] ?? '',
      lastUpdated: json['last_updated'] ?? json['updated_at'] ?? '',
      isLive: json['is_live'] == 1 || json['is_live'] == true,
      assignedRoute: json['assigned_route'] ?? '',
      liveLocation: json['live_location'] ?? json['location'] ?? '',
      latitude: lat,
      longitude: lng,
      address: json['address']?.toString().trim() ?? '',
      liveAddress: json['live_address']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emp_id': empId,
      'name': name,
      'mobile': phone,
      'email': email,
      'city': city,
      'role': role,
      'assigned_route': assignedRoute,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Model for Attendance mapped directly to MySQL table 'attendance'
// Model for Attendance mapped directly to MySQL table 'attendance'
class AttendanceRecord {
  String id;
  String empId;
  String userId;
  String role;
  String photo;
  String punchType;
  String punchDate;
  String punchTime;
  String day;
  String address;
  String latitude;
  String longitude;
  String createdAt;
  String updatedAt;

  AttendanceRecord({
    required this.id,
    required this.empId,
    required this.userId,
    required this.role,
    required this.photo,
    required this.punchType,
    required this.punchDate,
    required this.punchTime,
    required this.day,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      empId: json['emp_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      photo: json['photo']?.toString() ??
          json['image']?.toString() ??
          json['photo_url']?.toString() ??
          '',
      punchType: (json['punch_type']?.toString() ??
          json['type']?.toString() ??
          json['status']?.toString() ??
          '')
          .toUpperCase(),
      punchDate: json['punch_date']?.toString() ??
          json['date']?.toString() ??
          json['created_at']?.toString()?.split(' ').first ??
          '',
      punchTime: json['punch_time']?.toString() ??
          json['time']?.toString() ??
          (json['created_at']?.toString()?.contains(' ') == true
              ? json['created_at'].toString().split(' ').last
              : ''),
      day: json['day']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ??
          json['created_at']?.toString() ??
          '',
    );
  }
}
// Model for Product Catalog
class ProductItem {
  String id;
  String category;
  String subCategory;
  String name;
  double price;
  String description;

  ProductItem({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.name,
    required this.price,
    this.description = '',
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id']?.toString() ?? '',
      category: json['category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'sub_category': subCategory,
      'name': name,
      'price': price,
      'description': description,
    };
  }
}

// Model for Daily Report mapped directly to MySQL table 'daily_report'
class DailyReport {
  String id;
  String empId;
  String firmName;
  String mobile;
  String pinCode;
  String category;
  String productName;
  double price;
  int quantity;
  double totalAmount;
  String? latitude;
  String? longitude;
  String address;
  String createdAt;

  DailyReport({
    required this.id,
    required this.empId,
    required this.firmName,
    required this.mobile,
    required this.pinCode,
    required this.category,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.totalAmount,
    this.latitude,
    this.longitude,
    required this.address,
    required this.createdAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id']?.toString() ?? '',
      empId: json['emp_id']?.toString() ?? '',
      firmName: json['firm_name'] ?? '',
      mobile: json['mobile'] ?? '',
      pinCode: json['pin_code'] ?? '',
      category: json['category'] ?? '',
      productName: json['product_name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      address: json['address'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

// Model for Leave Request mapped directly to MySQL table 'manage_leaves'
class LeaveRequest {
  String id;
  String empId;
  String empName;
  String empRole;
  String leaveType;
  String startDate;
  String endDate;
  String reason;
  String status;
  String createdAt;

  LeaveRequest({
    required this.id,
    required this.empId,
    required this.empName,
    required this.empRole,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      empId: json['emp_id']?.toString() ?? '',
      empName: json['emp_name'] ?? '',
      empRole: json['emp_role'] ?? '',
      leaveType: json['leave_type'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  Timer? _locationRefreshTimer;
  // Auto password generation
  bool isGeneratingPassword = false;
  String generatedPassword = '';
  bool showGeneratedPassword = false;

  // API Data Lists
  List<SalesmanModel> salesmenList = [];
  List<ProductItem> productCatalog = [];
  List<AttendanceRecord> attendanceHistory = [];
  List<DailyReport> dailyReports = [];
  List<LeaveRequest> leaveList = [];
  AdminModel? adminData;

  // Selected Employee filter for feed
  String _selectedEmpIdFilter = 'all';

  // Selected Role filter for Salesman Tracking Cards
  String _selectedRoleFilter = 'All';

  // Location details map
  Map<String, String> _geocodedAddresses = {};
  bool _isFetchingLocation = false;

  // Loading states
  bool isLoadingSalesmen = false;
  bool isLoadingCatalog = false;
  bool isLoadingAdmin = false;
  bool isLoadingAttendance = false;
  bool isLoadingReports = false;
  bool isLoadingLeaves = false;
  String? errorMessage;

  final List<String> roleOptions = [
    "Salesman",
    "Sales Officer",
    "ASM",
    "RSM",
    "ZSM",
    "Sales Head",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _loadAllData();
    _locationRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted && !isLoadingSalesmen) {
        _fetchSalesmenData();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _locationRefreshTimer?.cancel();
    super.dispose();
  }

  // Helper method to format Employee IDs consistently (e.g. BHFSM-01)
  String _formatEmpId(String rawEmpId, String role) {
    if (rawEmpId.isEmpty) return 'BHFEMP-01';

    String cleaned = rawEmpId.replaceAll(':-', '-').replaceAll(':', '-');
    if (cleaned.contains('-')) return cleaned;

    String prefix;
    switch (role) {
      case 'Salesman':
        prefix = 'BHFSM';
        break;
      case 'Sales Officer':
        prefix = 'BHFSO';
        break;
      case 'ASM':
        prefix = 'BHFAS';
        break;
      case 'RSM':
        prefix = 'BHFRS';
        break;
      case 'ZSM':
        prefix = 'BHFZS';
        break;
      case 'Sales Head':
        prefix = 'BHFSH';
        break;
      default:
        prefix = 'BHFEMP';
    }

    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '$prefix-${cleaned.padLeft(2, '0')}';
    }
    return cleaned;
  }

  // ==================== GEOLOCATOR & GEOCODING METHODS ====================

  /// Checks if a string is a usable address (not a placeholder)
  bool _isUsableAddress(String s) {
    if (s.trim().isEmpty) return false;
    final t = s.trim().toLowerCase();
    if (t.startsWith('fetching')) return false;
    if (t.startsWith('gps')) return false;
    if (t.startsWith('location permission')) return false;
    if (t.startsWith('unable to fetch')) return false;
    if (t == 'location pending') return false;
    if (t == 'location not available') return false;
    if (t == 'n/a') return false;
    if (t.startsWith('lat:') && t.contains('long:')) return false;
    return true;
  }

  /// Builds a full readable address from a Placemark
  String _buildAddressFromPlacemark(Placemark p) {
    final parts = <String>[];

    final streetParts = <String>[];
    if (p.name != null && p.name!.trim().isNotEmpty) {
      streetParts.add(p.name!.trim());
    }
    if (p.street != null && p.street!.trim().isNotEmpty) {
      final st = p.street!.trim();
      if (!streetParts.contains(st)) streetParts.add(st);
    }
    if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
      final sl = p.subLocality!.trim();
      if (!streetParts.contains(sl)) streetParts.add(sl);
    }
    if (streetParts.isNotEmpty) parts.add(streetParts.join(', '));

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

    return parts.join(', ');
  }

  /// Reverse geocodes lat/lng to full address
  Future<String> _reverseGeocode(double lat, double lng) async {
    final fallback =
        "Lat: ${lat.toStringAsFixed(5)}, Long: ${lng.toStringAsFixed(5)}";
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final addr = _buildAddressFromPlacemark(placemarks.first);
        if (addr.trim().isNotEmpty) return addr;
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }
    return fallback;
  }

  Future<void> _fetchSalesmanLocation(SalesmanModel salesman) async {
    setState(() => _isFetchingLocation = true);
    await _autoFetchAllLocations();

    try {
      double? lat = salesman.latitude;
      double? lng = salesman.longitude;

      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Location services are disabled.')),
            );
          }
          setState(() => _isFetchingLocation = false);
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isFetchingLocation = false);
          return;
        }

        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = pos.latitude;
        lng = pos.longitude;

        salesman.latitude = lat;
        salesman.longitude = lng;
      }

      String resolved = await _reverseGeocode(lat!, lng!);

      if (!mounted) return;
      setState(() {
        _geocodedAddresses[salesman.empId] = resolved;
        salesman.liveLocation = resolved;
        salesman.lastUpdated = DateTime.now().toString();
        _isFetchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated location for ${salesman.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  // ==================== LOAD ALL DATA ====================

  Future<void> _loadAllData() async {
    await _fetchAdminData();
    await _fetchSalesmenData();
    await _fetchCatalogData();
    await _fetchAllLeaves();
    await _fetchAttendanceData(_selectedEmpIdFilter);
    await _fetchDailyReports(_selectedEmpIdFilter);
  }

  // ==================== API CALLS ====================

  Future<void> _fetchAdminData() async {
    setState(() => isLoadingAdmin = true);
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}get_admin.php?role=admin'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            adminData = AdminModel.fromJson(data['data']);
            isLoadingAdmin = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load admin data';
            isLoadingAdmin = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoadingAdmin = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: $e';
        isLoadingAdmin = false;
      });
    }
  }

  Future<void> _fetchSalesmenData() async {
    setState(() => isLoadingSalesmen = true);
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final List<dynamic> users = data['data'] ?? [];
          setState(() {
            salesmenList =
                users.map((json) => SalesmanModel.fromJson(json)).toList();
            isLoadingSalesmen = false;
          });

          // Auto-geocode every salesman (full addresses)
          await _geocodeAllSalesmen();
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load salesmen';
            isLoadingSalesmen = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoadingSalesmen = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: $e';
        isLoadingSalesmen = false;
      });
    }
  }

  Future<void> _fetchCatalogData() async {
    setState(() => isLoadingCatalog = true);
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}catelog.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final List<dynamic> products = data['data'] ?? [];
          setState(() {
            productCatalog =
                products.map((json) => ProductItem.fromJson(json)).toList();
            isLoadingCatalog = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load catalog';
            isLoadingCatalog = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoadingCatalog = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: $e';
        isLoadingCatalog = false;
      });
    }
  }

  Future<void> _fetchAttendanceData(String empId) async {
    setState(() => isLoadingAttendance = true);
    try {
      final queryParam =
      (empId.isEmpty || empId == 'all') ? 'all' : Uri.encodeComponent(empId);
      final url = Uri.parse(
          '${API_BASE_URL}get_attendance.php?emp_id=$queryParam&user_id=$queryParam');
      debugPrint("🔍 Admin fetching attendance from $url");

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Attendance HTTP Error: ${response.statusCode}");
        setState(() {
          attendanceHistory = [];
          isLoadingAttendance = false;
        });
        return;
      }

      final dynamic decodedBody = json.decode(response.body);
      debugPrint("📥 Admin Attendance API Response: ${response.body}");

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

      if (rawList.isEmpty) {
        debugPrint("⚠️ Admin attendance list is empty for emp_id: $empId");
        setState(() {
          attendanceHistory = [];
          isLoadingAttendance = false;
        });
        return;
      }

      final List<Map<String, dynamic>> typed = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // ✅ If filtering a specific emp, keep only matching rows
      List<Map<String, dynamic>> effective = typed;
      if (empId.isNotEmpty && empId != 'all') {
        final String target = empId.trim();
        final List<Map<String, dynamic>> mine = typed.where((row) {
          final emp = (row['emp_id']?.toString() ?? '').trim();
          final uid = (row['user_id']?.toString() ?? '').trim();
          return emp == target || uid == target;
        }).toList();
        if (mine.isNotEmpty) effective = mine;
      }

      // ✅ Sort by id DESC so latest entries come first (Salesman Dashboard behavior)
      effective.sort((a, b) {
        final aId = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
        final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
        return bId.compareTo(aId);
      });

      setState(() {
        attendanceHistory =
            effective.map((j) => AttendanceRecord.fromJson(j)).toList();
        isLoadingAttendance = false;
      });

      debugPrint("✅ Admin attendance loaded: ${attendanceHistory.length} records");
    } catch (e) {
      debugPrint("❌ Admin Attendance API Parsing Error: $e");
      setState(() {
        attendanceHistory = [];
        isLoadingAttendance = false;
      });
    }
  }

  Future<void> _fetchDailyReports(String empId) async {
    setState(() => isLoadingReports = true);
    try {
      final queryParam =
      (empId.isEmpty || empId == 'all') ? 'all' : Uri.encodeComponent(empId);
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_daily_reports.php?emp_id=$queryParam'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          final List<dynamic> reports = data['reports'] ?? data['data'] ?? [];
          setState(() {
            dailyReports =
                reports.map((j) => DailyReport.fromJson(j)).toList();
            isLoadingReports = false;
          });
        } else {
          setState(() {
            dailyReports = [];
            isLoadingReports = false;
          });
        }
      } else {
        setState(() {
          dailyReports = [];
          isLoadingReports = false;
        });
      }
    } catch (e) {
      setState(() {
        dailyReports = [];
        isLoadingReports = false;
      });
    }
  }

  Future<void> _fetchAllLeaves() async {
    setState(() => isLoadingLeaves = true);
    try {
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_leaves.php?emp_id=all'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          final List<dynamic> leaves = data['leaves'] ?? data['data'] ?? [];

          final Map<String, Map<String, String>> salesmanMap = {};
          for (var sm in salesmenList) {
            salesmanMap[sm.empId] = {
              'name': sm.name,
              'role': sm.role,
            };
          }

          setState(() {
            leaveList = leaves.map((leaf) {
              final empInfo = salesmanMap[leaf['emp_id']] ?? {};
              return LeaveRequest.fromJson({
                ...leaf,
                'emp_name': leaf['emp_name'] ??
                    empInfo['name'] ??
                    leaf['emp_id'] ??
                    'Staff',
                'emp_role': leaf['emp_role'] ?? empInfo['role'] ?? 'Salesman',
              });
            }).toList();
            isLoadingLeaves = false;
          });
        } else {
          setState(() {
            leaveList = [];
            isLoadingLeaves = false;
          });
        }
      } else {
        setState(() {
          leaveList = [];
          isLoadingLeaves = false;
        });
      }
    } catch (e) {
      setState(() {
        leaveList = [];
        isLoadingLeaves = false;
      });
    }
  }

  Future<void> _updateLeaveStatus(
      String leaveId, String empId, String status) async {
    try {
      final data = {
        'leave_id': leaveId,
        'emp_id': empId,
        'status': status,
      };

      final response = await http.put(
        Uri.parse('${API_BASE_URL}manage_leaves.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true || result['status'] == 'success') {
          await _fetchAllLeaves();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                Text(result['message'] ?? 'Leave $status successfully'),
                backgroundColor:
                status == 'Approved' ? Colors.green : Colors.red,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update leave'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addSalesman(SalesmanModel salesman, String password) async {
    try {
      final data = salesman.toJson();
      data['password'] = password;

      final response = await http.post(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          await _fetchSalesmenData();
          await _fetchAllLeaves();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      result['message'] ?? 'Salesman added successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(result['message'] ?? 'Failed to add salesman')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateSalesman(SalesmanModel salesman) async {
    try {
      final data = salesman.toJson();
      data['emp_id'] = salesman.empId;

      final response = await http.put(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          await _fetchSalesmenData();
          await _fetchAllLeaves();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      result['message'] ?? 'Salesman updated successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(result['message'] ?? 'Failed to update salesman')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteSalesman(String empId) async {
    try {
      final response = await http.delete(
        Uri.parse('${API_BASE_URL}manage_salesman.php?emp_id=$empId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          await _fetchSalesmenData();
          await _fetchAllLeaves();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      result['message'] ?? 'Salesman deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(result['message'] ?? 'Failed to delete salesman')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _assignRoute(String empId, String route) async {
    try {
      final data = {
        'emp_id': empId,
        'assigned_route': route,
        'assigned_route_only': true,
      };

      final response = await http.put(
        Uri.parse('${API_BASE_URL}manage_salesman.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          await _fetchSalesmenData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      result['message'] ?? 'Route assigned successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(result['message'] ?? 'Failed to assign route')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addProduct(ProductItem product) async {
    try {
      final data = product.toJson();

      final response = await http.post(
        Uri.parse('${API_BASE_URL}catelog.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          await _fetchCatalogData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      result['message'] ?? 'Product added successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(result['message'] ?? 'Failed to add product')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateProduct(ProductItem product) async {
    try {
      final data = product.toJson();
      data['id'] = product.id;

      final response = await http.put(
        Uri.parse('${API_BASE_URL}catelog.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          await _fetchCatalogData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      result['message'] ?? 'Product updated successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(result['message'] ?? 'Failed to update product')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${API_BASE_URL}catelog.php?id=$productId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          await _fetchCatalogData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      result['message'] ?? 'Product deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text(result['message'] ?? 'Failed to delete product')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _changePassword(
      String identifier, String oldPassword, String newPassword) async {
    try {
      final data = {
        'identifier': identifier,
        'role': 'admin',
        'old_password': oldPassword,
        'new_password': newPassword,
      };

      final response = await http.post(
        Uri.parse('${API_BASE_URL}change_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Password changed'),
              backgroundColor:
              result['status'] == true ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ==================== AUTO PASSWORD GENERATION ====================

  Future<String?> _generateAutoPassword(
      String role,
      String empId, {
        String name = '',
      }) async {
    try {
      setState(() {
        isGeneratingPassword = true;
        generatedPassword = '';
        showGeneratedPassword = false;
      });

      final response = await http.post(
        Uri.parse('${API_BASE_URL}auto_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'role': role,
          'emp_id': empId,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true && result['data'] != null) {
          final pwd = result['data']['password']?.toString() ?? '';
          setState(() {
            generatedPassword = pwd;
            showGeneratedPassword = true;
            isGeneratingPassword = false;
          });
          return pwd;
        } else {
          setState(() => isGeneratingPassword = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                Text(result['message'] ?? 'Failed to generate password'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      } else {
        setState(() => isGeneratingPassword = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      setState(() => isGeneratingPassword = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  // ==================== UI HELPER METHODS ====================

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    String hour =
    (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    String second = dt.second.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} • $hour:$minute:$second $period";
  }

  String _formatTimeString(String rawDateTime) {
    if (rawDateTime.isEmpty) return 'Just now';
    try {
      DateTime dt = DateTime.parse(rawDateTime);
      String hour =
      (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
      String minute = dt.minute.toString().padLeft(2, '0');
      String period = dt.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $period";
    } catch (_) {
      return rawDateTime;
    }
  }

  Widget _buildLeaveStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style:
          TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBodyStat(
      String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _AdminPalette.inkDark)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _AdminPalette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _AdminPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _AdminPalette.inkDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== LIVE SALESMAN TRACKING CARD WIDGET ====================

  Widget _buildSalesmanLiveTrackingCard(SalesmanModel salesman) {
    String formattedEmpId = _formatEmpId(salesman.empId, salesman.role);

    // LIVE LOCATION RESOLUTION — priority order:
    // 1. _geocodedAddresses[empId] (freshly geocoded full address)
    // 2. salesman.address (pushed by Salesman Dashboard)
    // 3. salesman.liveAddress (alias field)
    // 4. salesman.liveLocation (generic API field)
    // 5. Lat/Long pair
    // 6. "Location Pending"

    final String? cached = _geocodedAddresses[salesman.empId];

    String displayLocation;
    if (cached != null && _isUsableAddress(cached)) {
      displayLocation = cached;
    } else if (_isUsableAddress(salesman.address)) {
      displayLocation = salesman.address.trim();
    } else if (_isUsableAddress(salesman.liveAddress)) {
      displayLocation = salesman.liveAddress.trim();
    } else if (_isUsableAddress(salesman.liveLocation)) {
      displayLocation = salesman.liveLocation.trim();
    } else if (salesman.latitude != null &&
        salesman.longitude != null &&
        salesman.latitude != 0.0 &&
        salesman.longitude != 0.0) {
      displayLocation =
      "Lat: ${salesman.latitude!.toStringAsFixed(5)}, Long: ${salesman.longitude!.toStringAsFixed(5)}";
    } else {
      displayLocation = 'Location Pending';
    }

    String updatedTimeText = _formatTimeString(salesman.lastUpdated);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AdminPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                salesman.isLive ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  Icons.person,
                  color: salesman.isLive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            salesman.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _AdminPalette.inkDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _AdminPalette.primaryBrown,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            formattedEmpId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${salesman.role} • ${salesman.city}",
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: salesman.isLive
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: salesman.isLive ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: salesman.isLive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      salesman.isLive ? 'LIVE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color:
                        salesman.isLive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _AdminPalette.bgWarm,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AdminPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: _AdminPalette.primaryBrown),
                    const SizedBox(width: 6),
                    const Text(
                      "Live Location:",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _AdminPalette.inkDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.my_location,
                          size: 16, color: _AdminPalette.primaryBrown),
                      onPressed: () => _fetchSalesmanLocation(salesman),
                      tooltip: "Refresh Location",
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  displayLocation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _AdminPalette.inkDark,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                "Updated: $updatedTimeText",
                style:
                TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Icon(Icons.route,
                  size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  salesman.assignedRoute.isNotEmpty
                      ? salesman.assignedRoute
                      : 'No route assigned',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== GEOCODING METHODS ====================

  Future<void> _resolveAddressesForSalesmen() async {
    for (var salesman in salesmenList) {
      if (salesman.address.trim().isNotEmpty ||
          salesman.liveAddress.trim().isNotEmpty) {
        continue;
      }

      if (salesman.latitude != null && salesman.longitude != null) {
        try {
          final addr = await _reverseGeocode(
              salesman.latitude!, salesman.longitude!);
          if (mounted && addr.trim().isNotEmpty) {
            setState(() {
              _geocodedAddresses[salesman.empId] = addr;
            });
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _geocodeAllSalesmen() async {
    if (salesmenList.isEmpty) return;

    bool updated = false;

    for (final salesman in salesmenList) {
      // Skip if we already have a valid cached address
      if (_geocodedAddresses.containsKey(salesman.empId) &&
          _geocodedAddresses[salesman.empId]!.trim().isNotEmpty) {
        continue;
      }

      // If the salesman's own dashboard already pushed a full address, use it
      if (_isUsableAddress(salesman.address)) {
        _geocodedAddresses[salesman.empId] = salesman.address.trim();
        updated = true;
        continue;
      }
      if (_isUsableAddress(salesman.liveAddress)) {
        _geocodedAddresses[salesman.empId] = salesman.liveAddress.trim();
        updated = true;
        continue;
      }

      // Need lat/lng to reverse-geocode
      final lat = salesman.latitude;
      final lng = salesman.longitude;
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
        continue;
      }

      // Reverse-geocode this salesman's coordinates to full address
      try {
        final resolved = await _reverseGeocode(lat, lng);
        if (resolved.trim().isNotEmpty) {
          _geocodedAddresses[salesman.empId] = resolved;
          updated = true;
        }
      } catch (e) {
        debugPrint("Geocode failed for ${salesman.empId}: $e");
        _geocodedAddresses[salesman.empId] =
        "Lat: ${lat.toStringAsFixed(5)}, Long: ${lng.toStringAsFixed(5)}";
        updated = true;
      }
    }

    // Refresh UI once at the end (avoids flicker on every row)
    if (updated && mounted) {
      setState(() {});
    }
  }

  // ==================== SEPARATE DIALOGS FOR EACH SECTION ====================

  /// ✅ Auto-fetch live location for all role-based salesmen
  Future<void> _autoFetchAllLocations() async {
    if (salesmenList.isEmpty) return;

    for (final salesman in salesmenList) {
      // Skip if we already have a usable address
      if (_isUsableAddress(salesman.address) ||
          _isUsableAddress(salesman.liveAddress) ||
          (_geocodedAddresses[salesman.empId] != null &&
              _isUsableAddress(_geocodedAddresses[salesman.empId]!))) {
        continue;
      }

      // If lat/lng exist, reverse geocode them
      if (salesman.latitude != null &&
          salesman.longitude != null &&
          salesman.latitude != 0.0 &&
          salesman.longitude != 0.0) {
        try {
          final addr = await _reverseGeocode(
              salesman.latitude!, salesman.longitude!);
          if (mounted) {
            setState(() {
              _geocodedAddresses[salesman.empId] = addr;
            });
          }
        } catch (_) {}
      }
    }
  }

  void _showLeavesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      const Row(
                        children: [
                          Icon(Icons.time_to_leave,
                              color: Colors.orange, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Leave Approvals",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _AdminPalette.inkDark),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: _AdminPalette.primaryBrown),
                            onPressed: () {
                              _fetchAllLeaves().then((_) {
                                setDialogState(() {});
                              });
                            },
                            tooltip: "Refresh",
                          ),
                          IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingLeaves)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator()))
                  else if (leaveList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No leave requests found.",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height * 0.6),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: leaveList.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = leaveList[index];
                            Color statusColor = item.status == 'Approved'
                                ? Colors.green
                                : item.status == 'Rejected'
                                ? Colors.red
                                : Colors.amber.shade800;

                            String empFormattedId =
                            _formatEmpId(item.empId, item.empRole);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                Border.all(color: _AdminPalette.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.empName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: _AdminPalette.inkDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _AdminPalette
                                                        .primaryBrown
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        4),
                                                  ),
                                                  child: Text(
                                                    empFormattedId,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: _AdminPalette
                                                          .primaryBrown,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  item.empRole,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                          statusColor.withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          border: Border.all(
                                              color: statusColor, width: 1),
                                        ),
                                        child: Text(
                                          item.status,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month,
                                          size: 14,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${item.leaveType} • ${item.startDate} to ${item.endDate}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Reason: ${item.reason}",
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.status == 'Pending') ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            _updateLeaveStatus(item.id,
                                                item.empId, 'Rejected')
                                                .then((_) {
                                              setDialogState(() {});
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text("Reject",
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            _updateLeaveStatus(item.id,
                                                item.empId, 'Approved')
                                                .then((_) {
                                              setDialogState(() {});
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            _AdminPalette.primaryBrown,
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                            MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text("Approve",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== ATTENDANCE DIALOG (FIXED) ====================

  // ==================== ATTENDANCE DIALOG (SALESMAN-STYLE) ====================

  /// Small reusable detail row for the attendance card
  Widget _buildAttendanceDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: _AdminPalette.primaryBrown),
          const SizedBox(width: 6),
          SizedBox(
            width: 82,
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

  void _showAttendanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
            insetPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.95,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.how_to_reg,
                                color: Colors.blue, size: 24),
                            SizedBox(width: 10),
                            Text(
                              "Attendance Records",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _AdminPalette.inkDark),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: _AdminPalette.primaryBrown),
                              onPressed: () async {
                                await _fetchAttendanceData(_selectedEmpIdFilter);
                                if (ctx.mounted) setDialogState(() {});
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
                    if (isLoadingAttendance)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (attendanceHistory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text("No attendance records found.",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: attendanceHistory.length,
                          itemBuilder: (context, index) {
                            final item = attendanceHistory[index];
                            final bool isPunchIn =
                                item.punchType == 'PUNCH_IN';

                            // ✅ Resolve photo URL exactly like Salesman Dashboard
                            String? displayPhoto;
                            if (item.photo.isNotEmpty) {
                              final photos = item.photo
                                  .split(',')
                                  .map((p) => p.trim())
                                  .where((p) => p.isNotEmpty)
                                  .toList();
                              if (photos.isNotEmpty) {
                                displayPhoto = photos.last;
                              }
                            }
                            final String photoUrl = displayPhoto != null
                                ? (displayPhoto.startsWith('http')
                                ? displayPhoto
                                : '$API_BASE_URL$displayPhoto')
                                : '';

                            final String empFormattedId =
                            _formatEmpId(item.empId, item.role);

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
                                            isPunchIn
                                                ? Icons.login
                                                : Icons.logout,
                                            color: isPunchIn
                                                ? Colors.green
                                                : Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isPunchIn
                                                    ? "Punch In"
                                                    : "Punch Out",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                              Text(
                                                "ID: ${item.id.isEmpty ? '-' : item.id} | Emp: ${item.empId.isEmpty ? '-' : item.empId}",
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (photoUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            child: Image.network(
                                              photoUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  progress) {
                                                if (progress == null)
                                                  return child;
                                                return const SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: Center(
                                                    child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    color:
                                                    Colors.grey.shade200,
                                                    child: const Icon(
                                                        Icons.person,
                                                        size: 28,
                                                        color: Colors.grey),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // ✅ Detail rows — same as Salesman Dashboard
                                    _buildAttendanceDetailRow(
                                      Icons.calendar_today,
                                      "Date",
                                      item.punchDate,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.access_time,
                                      "Time",
                                      item.punchTime,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.today,
                                      "Day",
                                      item.day,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.badge,
                                      "Role",
                                      item.role,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.confirmation_number,
                                      "Emp ID",
                                      empFormattedId,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.location_on,
                                      "Address",
                                      item.address,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.my_location,
                                      "Latitude",
                                      item.latitude,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.my_location,
                                      "Longitude",
                                      item.longitude,
                                    ),
                                    _buildAttendanceDetailRow(
                                      Icons.update,
                                      "Updated At",
                                      item.updatedAt,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== DAILY REPORTS DIALOG ====================

  void _showDailyReportsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      const Row(
                        children: [
                          Icon(Icons.assessment,
                              color: Colors.green, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Daily Reports",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _AdminPalette.inkDark),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: _AdminPalette.primaryBrown),
                            onPressed: () {
                              _fetchDailyReports(_selectedEmpIdFilter)
                                  .then((_) {
                                setDialogState(() {});
                              });
                            },
                            tooltip: "Refresh",
                          ),
                          IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingReports)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator()))
                  else if (dailyReports.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No daily reports found.",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height * 0.6),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: dailyReports.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final report = dailyReports[index];
                            String empFormattedId =
                            _formatEmpId(report.empId, 'Salesman');

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                Border.all(color: _AdminPalette.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          report.firmName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: _AdminPalette.inkDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          report.category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Product: ${report.productName}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _AdminPalette.primaryBrown
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          empFormattedId,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                            _AdminPalette.primaryBrown,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        "₹${report.price.toStringAsFixed(0)} × ${report.quantity}",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Total: ₹${report.totalAmount.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(report.mobile,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.access_time,
                                          size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          report.createdAt,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== OPTION MENU (Product Catalog History added, Notifications removed) ====================

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _AdminPalette.bgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const Text(
              "Menu Options",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _AdminPalette.inkDark),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AdminPalette.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person,
                    color: _AdminPalette.primaryBrown),
              ),
              title: const Text("View Profile",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Admin profile details"),
              onTap: () {
                Navigator.pop(ctx);
                _showProfileModal();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_reset, color: Colors.orange),
              ),
              title: const Text("Change Password",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Update your password"),
              onTap: () {
                Navigator.pop(ctx);
                _showChangePasswordModal();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text("Logout",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text("Sign out from admin panel"),
              onTap: () {
                Navigator.pop(ctx);
                _showLogoutConfirmation();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==================== PROFILE MODAL ====================

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _AdminPalette.bgWarm,
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
                  decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: _AdminPalette.primaryBrown,
                    child: Icon(Icons.admin_panel_settings,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminData?.name ?? "Admin User",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _AdminPalette.inkDark),
                        ),
                        Text(
                          adminData?.empId ?? "BHFADMIN-01",
                          style: const TextStyle(
                              fontSize: 13,
                              color: _AdminPalette.primaryBrown),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _AdminPalette.accentBadge,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            adminData?.role ?? "Super Admin",
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _AdminPalette.inkDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text("Admin Details",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _AdminPalette.inkDark)),
              const SizedBox(height: 10),
              _buildProfileInfoRow(Icons.person, "Full Name",
                  adminData?.name ?? "Admin User"),
              _buildProfileInfoRow(Icons.email, "Email",
                  adminData?.email ?? "admin@bhadrafoods.com"),
              _buildProfileInfoRow(Icons.phone, "Phone",
                  adminData?.mobile ?? "+91 98765 43210"),
              _buildProfileInfoRow(Icons.location_on, "Location",
                  adminData?.city ?? "Bhavnagar, Gujarat"),
              if (adminData?.lastUpdated != null &&
                  adminData!.lastUpdated.isNotEmpty)
                _buildProfileInfoRow(Icons.access_time, "Last Updated",
                    adminData!.lastUpdated),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _AdminPalette.primaryBrown),
          const SizedBox(width: 10),
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, color: _AdminPalette.inkDark))),
        ],
      ),
    );
  }

  // ==================== CHANGE PASSWORD MODAL ====================

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
                      Icon(Icons.lock_reset,
                          color: _AdminPalette.primaryBrown),
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
                            newController.text == confirmController.text) {
                          String identifier =
                              adminData?.empId ?? adminData?.email ?? '';
                          if (identifier.isNotEmpty) {
                            _changePassword(identifier, oldController.text,
                                newController.text);
                          }
                          Navigator.pop(ctx);
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

  // ==================== LOGOUT ====================

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
        content:
        const Text("Are you sure you want to logout from admin panel?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
            const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                  ctx, MaterialPageRoute(builder: (ctx) => const Login()));
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

  // ==================== CATALOG MODAL WITH FULL CRUD ====================

  void _showCatalogModal({ProductItem? editItem}) {
    final nameController = TextEditingController(text: editItem?.name ?? '');
    final priceController = TextEditingController(
        text: editItem != null ? editItem.price.toStringAsFixed(0) : '');
    final descController =
    TextEditingController(text: editItem?.description ?? '');

    String selectedCat = editItem?.category ?? "Main Item";
    String selectedSubCat = editItem?.subCategory ?? "Khakhra";

    if (selectedCat == "Celebration Box") {
      selectedSubCat = "Celebration Box";
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final bool isCelebrationBox = selectedCat == "Celebration Box";

          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.inventory_2,
                                    color: Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  editItem == null
                                      ? "Add Product"
                                      : "Edit Product",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _AdminPalette.inkDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.history,
                                    color: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showCatalogHistoryModal();
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCat,
                      decoration: InputDecoration(
                        labelText: "Category",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "Main Item", child: Text("Main Item")),
                        DropdownMenuItem(
                            value: "Celebration Box",
                            child: Text("Celebration Box")),
                      ],
                      onChanged: (v) {
                        setModalState(() {
                          selectedCat = v!;
                          if (selectedCat == "Main Item") {
                            selectedSubCat = "Khakhra";
                          } else {
                            selectedSubCat = "Celebration Box";
                          }
                        });
                      },
                    ),
                    if (!isCelebrationBox) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedSubCat,
                        decoration: InputDecoration(
                          labelText: "Sub Category",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: "Khakhra", child: Text("Khakhra")),
                          DropdownMenuItem(
                              value: "Bhakhari", child: Text("Bhakhari")),
                          DropdownMenuItem(
                              value: "Bites", child: Text("Bites")),
                        ],
                        onChanged: (v) =>
                            setModalState(() => selectedSubCat = v!),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: isCelebrationBox
                            ? "Celebration Box Name *"
                            : "Product Name *",
                        hintText: isCelebrationBox
                            ? "e.g. Diwali Family Combo"
                            : "Product Name",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Price (₹) *",
                        hintText: "Price (₹)",
                        prefixIcon: const Icon(Icons.currency_rupee,
                            color: _AdminPalette.primaryBrown),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (isCelebrationBox) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText:
                          "Items Included in this Celebration Box *",
                          hintText:
                          "e.g. Assorted Khakhra, Bhakhari, Bites, Dry Fruits & Festive Sweets",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.card_giftcard,
                                color: _AdminPalette.primaryBrown),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 12, color: Colors.blue.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "List the items that will be included in this Celebration Box",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
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
                          if (nameController.text.isEmpty ||
                              priceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text("Please fill name and price")),
                            );
                            return;
                          }
                          if (isCelebrationBox &&
                              descController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Please list the items included in this Celebration Box")),
                            );
                            return;
                          }

                          final product = ProductItem(
                            id: editItem?.id ?? '',
                            category: selectedCat,
                            subCategory: isCelebrationBox
                                ? "Celebration Box"
                                : selectedSubCat,
                            name: nameController.text.trim(),
                            price: double.tryParse(
                                priceController.text.trim()) ??
                                0,
                            description: descController.text.trim(),
                          );

                          if (editItem != null) {
                            _updateProduct(product);
                          } else {
                            _addProduct(product);
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          editItem == null
                              ? "+ Add to Catalog"
                              : "Update Item",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== CATALOG HISTORY MODAL ====================

  void _showCatalogHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.history,
                                  color: Colors.blue),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Text(
                                "Product Catalog",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _AdminPalette.inkDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingCatalog)
                    const Center(child: CircularProgressIndicator())
                  else if (productCatalog.isEmpty)
                    const Center(
                        child: Text("No products found",
                            style: TextStyle(color: Colors.grey)))
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height * 0.55),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: productCatalog.length,
                          itemBuilder: (context, index) {
                            final p = productCatalog[index];
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          Text(
                                              "${p.category} • ${p.subCategory}",
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey)),
                                          Text(
                                              "₹${p.price.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight:
                                                  FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue, size: 20),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _showCatalogModal(editItem: p);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20),
                                          onPressed: () {
                                            _deleteProduct(p.id);
                                            Navigator.pop(ctx);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  // ==================== ROUTE MANAGEMENT MODAL ====================

  void _showRouteManagementModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _AdminPalette.bgWarm,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.route, color: Colors.teal),
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            "Route Management",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _AdminPalette.inkDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoadingSalesmen)
                const Center(child: CircularProgressIndicator())
              else if (salesmenList.isEmpty)
                const Center(
                    child: Text("No salesmen available",
                        style: TextStyle(color: Colors.grey)))
              else
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: salesmenList.length,
                      itemBuilder: (context, index) {
                        final sm = salesmenList[index];
                        String formattedEmpId =
                        _formatEmpId(sm.empId, sm.role);

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Color(0xFFEADBCE),
                                      child: Icon(Icons.person,
                                          size: 16,
                                          color: _AdminPalette.primaryBrown),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "${sm.name} ($formattedEmpId)",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.route,
                                        size: 16,
                                        color: _AdminPalette.primaryBrown),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Route: ${sm.assignedRoute.isNotEmpty ? sm.assignedRoute : 'Not assigned'}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 18, color: Colors.blue),
                                      onPressed: () =>
                                          _showAssignRouteModal(sm),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ASSIGN ROUTE MODAL ====================

  void _showAssignRouteModal(SalesmanModel salesman) {
    final routeController =
    TextEditingController(text: salesman.assignedRoute);
    String formattedEmpId = _formatEmpId(salesman.empId, salesman.role);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _AdminPalette.bgWarm,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.route, color: _AdminPalette.primaryBrown),
                  SizedBox(width: 8),
                  Text(
                    "Assign Route",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _AdminPalette.inkDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Assigning route for: ${salesman.name} ($formattedEmpId)",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter route waypoints (use -> as separator)",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: routeController,
                decoration: InputDecoration(
                  hintText: "e.g., Shastrinagar -> Nari Chawkdi",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.route,
                      color: _AdminPalette.primaryBrown),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AdminPalette.primaryBrown,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (routeController.text.trim().isNotEmpty) {
                        _assignRoute(
                            salesman.empId, routeController.text.trim());
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter a route")),
                        );
                      }
                    },
                    child: const Text("Assign Route",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SALESMAN MANAGEMENT MODAL ====================

  void _showSalesmenManagementModal({SalesmanModel? editItem}) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final phoneCtrl = TextEditingController(text: editItem?.phone ?? '');
    final emailCtrl = TextEditingController(text: editItem?.email ?? '');
    final cityCtrl =
    TextEditingController(text: editItem?.city ?? 'Bhavnagar');
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = editItem?.role ?? 'Salesman';
    bool isEditing = editItem != null;

    generatedPassword = '';
    showGeneratedPassword = false;

    String getRolePrefix(String role) {
      switch (role) {
        case 'Salesman':
          return 'BHFSM';
        case 'Sales Officer':
          return 'BHFSO';
        case 'ASM':
          return 'BHFAS';
        case 'RSM':
          return 'BHFRS';
        case 'ZSM':
          return 'BHFZS';
        case 'Sales Head':
          return 'BHFSH';
        default:
          return 'BHFEMP';
      }
    }

    String generateEmpId(String role) {
      String prefix = getRolePrefix(role);
      int count = salesmenList.where((s) => s.role == role).length + 1;
      return '$prefix-${count.toString().padLeft(2, '0')}';
    }

    String displayEmpId = isEditing
        ? _formatEmpId(editItem.empId, editItem.role)
        : generateEmpId(selectedRole);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          String previewEmpId =
          isEditing ? displayEmpId : generateEmpId(selectedRole);

          void applyAutoPassword(String pwd) {
            passwordCtrl.text = pwd;
            setModalState(() {
              showGeneratedPassword = true;
            });
          }

          final bool canGenerateAuto =
              nameCtrl.text.trim().isNotEmpty && !isGeneratingPassword;

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
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            isEditing
                                ? "Edit Salesman Profile"
                                : "Register New Salesman",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _AdminPalette.inkDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history,
                                  color: _AdminPalette.primaryBrown),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showSalesmenHistoryModal();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                        _AdminPalette.primaryBrown.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _AdminPalette.primaryBrown
                                .withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge,
                                  size: 20,
                                  color: _AdminPalette.primaryBrown),
                              const SizedBox(width: 8),
                              Text(
                                isEditing
                                    ? "Employee ID:"
                                    : "Formatted Emp ID:",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _AdminPalette.inkDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _AdminPalette.primaryBrown,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              previewEmpId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Full Name is required"
                          : null,
                      onChanged: (_) {
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: "Full Name *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return "Mobile Number is required";
                        if (v.trim().length < 10)
                          return "Enter a valid 10-digit mobile number";
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Mobile No. *",
                        prefixText: "+91 ",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return "Email Address is required";
                        if (!v.contains('@') || !v.contains('.'))
                          return "Enter a valid email address";
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Email Address *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedRole,
                            decoration: InputDecoration(
                              labelText: "Role *",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: roleOptions
                                .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r,
                                  style: const TextStyle(
                                      fontSize: 14)),
                            ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() {
                                  selectedRole = v;
                                  generatedPassword = '';
                                  showGeneratedPassword = false;
                                  passwordCtrl.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            decoration: InputDecoration(
                              labelText: "City/Zone",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Formatted Emp ID stored into users table (e.g. BHFSM-01)",
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    if (!isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: passwordCtrl,
                              obscureText: false,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Auto Password",
                                hintText: "Tap ⚡ Auto to generate",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.lock,
                                    color: _AdminPalette.primaryBrown),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canGenerateAuto
                                    ? _AdminPalette.accentBadge
                                    : Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: canGenerateAuto
                                  ? () async {
                                final pwd =
                                await _generateAutoPassword(
                                  selectedRole,
                                  previewEmpId,
                                  name: nameCtrl.text.trim(),
                                );
                                if (pwd != null && pwd.isNotEmpty) {
                                  applyAutoPassword(pwd);
                                }
                              }
                                  : null,
                              child: isGeneratingPassword
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _AdminPalette.inkDark,
                                ),
                              )
                                  : const Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bolt,
                                      color: _AdminPalette.inkDark,
                                      size: 20),
                                  Text(
                                    "Auto",
                                    style: TextStyle(
                                      color: _AdminPalette.inkDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (nameCtrl.text.trim().isEmpty)
                        Padding(
                          padding:
                          const EdgeInsets.only(bottom: 6, left: 4),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 12, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Enter Full Name first to enable Auto password",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (generatedPassword.isNotEmpty &&
                          passwordCtrl.text == generatedPassword)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border:
                            Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Auto password ready",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      generatedPassword,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
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
                          if (formKey.currentState!.validate()) {
                            if (!isEditing) {
                              if (passwordCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please tap ⚡ Auto to generate password"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }

                            final finalPassword =
                            passwordCtrl.text.isNotEmpty
                                ? passwordCtrl.text.trim()
                                : '123456';

                            final salesman = SalesmanModel(
                              id: editItem?.id ?? '',
                              name: nameCtrl.text.trim(),
                              empId: previewEmpId,
                              role: selectedRole,
                              city: cityCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              lastUpdated: DateTime.now().toString(),
                              assignedRoute: editItem?.assignedRoute ?? '',
                            );

                            if (isEditing) {
                              salesman.id = editItem!.id;
                              _updateSalesman(salesman);
                            } else {
                              _addSalesman(salesman, finalPassword);
                            }
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          isEditing ? "Update Profile" : "Register Member",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== SALESMEN HISTORY MODAL ====================

  void _showSalesmenHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: _AdminPalette.bgWarm,
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
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AdminPalette.primaryBrown
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.people,
                                    color: _AdminPalette.primaryBrown),
                              ),
                              const SizedBox(width: 10),
                              const Flexible(
                                child: Text(
                                  "Registered Members",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _AdminPalette.inkDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: _AdminPalette.primaryBrown),
                              onPressed: () {
                                _fetchSalesmenData().then((_) {
                                  setModalState(() {});
                                });
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
                    const SizedBox(height: 16),
                    if (isLoadingSalesmen)
                      const Center(child: CircularProgressIndicator())
                    else if (salesmenList.isEmpty)
                      const Center(
                          child: Text("No registered members",
                              style: TextStyle(color: Colors.grey)))
                    else
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                            MediaQuery.of(context).size.height * 0.55,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: salesmenList.length,
                            itemBuilder: (context, index) {
                              final sm = salesmenList[index];
                              String displayEmpId =
                              _formatEmpId(sm.empId, sm.role);

                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: sm.isLive
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                            child: Icon(
                                              Icons.person,
                                              size: 20,
                                              color: sm.isLive
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      sm.name,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          fontSize: 14),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _AdminPalette
                                                            .primaryBrown,
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(4),
                                                      ),
                                                      child: Text(
                                                        displayEmpId,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Role: ${sm.role} • City: ${sm.city}",
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .grey.shade700),
                                                ),
                                                Text(
                                                  "Phone: ${sm.phone} | Email: ${sm.email}",
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors
                                                          .grey.shade600),
                                                ),
                                                if (sm.assignedRoute
                                                    .isNotEmpty)
                                                  Container(
                                                    margin:
                                                    const EdgeInsets.only(
                                                        top: 4),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color:
                                                      Colors.teal.shade50,
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          4),
                                                      border: Border.all(
                                                          color: Colors
                                                              .teal.shade200),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                      MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.route,
                                                            size: 12,
                                                            color: Colors.teal
                                                                .shade700),
                                                        const SizedBox(
                                                            width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            sm.assignedRoute,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.teal
                                                                  .shade700,
                                                            ),
                                                            overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                constraints:
                                                const BoxConstraints(),
                                                padding:
                                                const EdgeInsets.all(6),
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.blue,
                                                    size: 18),
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _showSalesmenManagementModal(
                                                      editItem: sm);
                                                },
                                              ),
                                              IconButton(
                                                constraints:
                                                const BoxConstraints(),
                                                padding:
                                                const EdgeInsets.all(6),
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                    size: 18),
                                                onPressed: () {
                                                  _deleteSalesman(sm.empId);
                                                  Navigator.pop(ctx);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
        );
      },
    );
  }

  // ==================== BUILD MAIN DASHBOARD ====================

  @override
  Widget build(BuildContext context) {
    List<SalesmanModel> filteredSalesmen = _selectedRoleFilter == 'All'
        ? salesmenList
        : salesmenList.where((s) => s.role == _selectedRoleFilter).toList();

    return Scaffold(
      backgroundColor: _AdminPalette.bgWarm,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // HEADER SECTION
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: _AdminPalette.accentBadge,
                              child: Icon(Icons.admin_panel_settings,
                                  color: _AdminPalette.inkDark),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminData?.name ?? "Admin Control Center",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  adminData?.role ?? "Super Admin",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: _showOptionsMenu,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(_currentTime),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // DASHBOARD CONTENT
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QUICK ACTION BUTTONS
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildActionCard(
                            "Add Salesman",
                            Icons.person_add,
                            Colors.blue,
                                () => _showSalesmenManagementModal()),
                        _buildActionCard("Catalog", Icons.inventory,
                            Colors.purple, () => _showCatalogModal()),
                        _buildActionCard(
                            "Assign Route",
                            Icons.alt_route,
                            Colors.teal,
                                () => _showRouteManagementModal()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SEPARATE ACTIVITY OVERVIEW CARDS
                    Row(
                      children: [
                        // LEAVES CARD
                        Expanded(
                          child: _buildSeparateActivityCard(
                            title: "Leave Requests",
                            count: leaveList
                                .where((l) => l.status == 'Pending')
                                .length,
                            total: leaveList.length,
                            icon: Icons.time_to_leave,
                            color: Colors.orange,
                            onTap: _showLeavesDialog,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // ATTENDANCE CARD
                        Expanded(
                          child: _buildSeparateActivityCard(
                            title: "Attendance",
                            count: attendanceHistory.length,
                            total: attendanceHistory.length,
                            icon: Icons.how_to_reg,
                            color: Colors.blue,
                            onTap: () {
                              _fetchAttendanceData(_selectedEmpIdFilter);
                              _showAttendanceDialog();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // REPORTS CARD
                        Expanded(
                          child: _buildSeparateActivityCard(
                            title: "Daily Reports",
                            count: dailyReports.length,
                            total: dailyReports.length,
                            icon: Icons.assessment,
                            color: Colors.green,
                            onTap: _showDailyReportsDialog,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ROLE-BASED LIVE TRACKING HEADER & FILTERS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Live Salesman Tracking",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _AdminPalette.inkDark),
                        ),
                        Row(
                          children: [
                            if (_isFetchingLocation)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: _AdminPalette.primaryBrown),
                              onPressed: _fetchSalesmenData,
                              tooltip: "Refresh Location Data",
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ROLE FILTER CHIPS
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          "All",
                          ...roleOptions,
                        ].map((role) {
                          bool isSelected = _selectedRoleFilter == role;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(role),
                              selected: isSelected,
                              selectedColor: _AdminPalette.primaryBrown,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : _AdminPalette.inkDark,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? _AdminPalette.primaryBrown
                                      : _AdminPalette.border,
                                ),
                              ),
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedRoleFilter = role;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ROLE BASED SALESMAN CARDS LIST
                    if (isLoadingSalesmen)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator()))
                    else if (filteredSalesmen.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _AdminPalette.border),
                        ),
                        child: const Center(
                          child: Text(
                            "No active staff found for this role.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSalesmen.length,
                        itemBuilder: (context, index) {
                          return _buildSalesmanLiveTrackingCard(
                              filteredSalesmen[index]);
                        },
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

  /// Separate activity card widget for leaves, attendance & reports
  Widget _buildSeparateActivityCard({
    required String title,
    required int count,
    required int total,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _AdminPalette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _AdminPalette.inkDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "$count records",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}