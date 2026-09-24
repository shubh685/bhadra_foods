import 'dart:async';
import 'package:bhad_foods/Log_In.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
const String API_BASE_URL = 'http://192.168.0.115/bhadra_foods/';

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

// Model for Salesman mapped directly to MySQL table 'manage_salesmna'
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
  });

  factory SalesmanModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    if (json['latitude'] != null && json['latitude'] != '') {
      try {
        lat = double.tryParse(json['latitude'].toString());
      } catch (_) {
        lat = null;
      }
    } else if (json['lat'] != null && json['lat'] != '') {
      try {
        lat = double.tryParse(json['lat'].toString());
      } catch (_) {
        lat = null;
      }
    }

    double? lng;
    if (json['longitude'] != null && json['longitude'] != '') {
      try {
        lng = double.tryParse(json['longitude'].toString());
      } catch (_) {
        lng = null;
      }
    } else if (json['lng'] != null && json['lng'] != '') {
      try {
        lng = double.tryParse(json['lng'].toString());
      } catch (_) {
        lng = null;
      }
    }

    return SalesmanModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      empId: json['emp_id']?.toString() ?? '',
      role: json['role'] ?? '',
      city: json['city'] ?? '',
      phone: json['mobile'] ?? '',
      email: json['email'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
      isLive: json['is_live'] == 1 || json['is_live'] == true,
      assignedRoute: json['assigned_route'] ?? '',
      liveLocation: json['live_location'] ?? '',
      latitude: lat,
      longitude: lng,
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
class AttendanceRecord {
  String id;
  String empId;
  String role;
  String photo;
  String punchType;
  String punchDate;
  String punchTime;
  String day;
  String createdAt;

  AttendanceRecord({
    required this.id,
    required this.empId,
    required this.role,
    required this.photo,
    required this.punchType,
    required this.punchDate,
    required this.punchTime,
    required this.day,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      empId: json['emp_id']?.toString() ?? '',
      role: json['role'] ?? '',
      photo: json['photo'] ?? '',
      punchType: json['punch_type'] ?? '',
      punchDate: json['punch_date'] ?? '',
      punchTime: json['punch_time'] ?? '',
      day: json['day'] ?? '',
      createdAt: json['created_at'] ?? '',
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

  ProductItem({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.name,
    required this.price,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id']?.toString() ?? '',
      category: json['category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'sub_category': subCategory,
      'name': name,
      'price': price,
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

  // API Data Lists
  List<SalesmanModel> salesmenList = [];
  List<ProductItem> productCatalog = [];
  List<AttendanceRecord> attendanceHistory = [];
  List<DailyReport> dailyReports = [];
  List<LeaveRequest> leaveList = [];
  AdminModel? adminData;

  // Selected Employee filter for feed
  String _selectedEmpIdFilter = 'all';

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
  }

  @override
  void dispose() {
    _timer.cancel();
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
            salesmenList = users.map((json) => SalesmanModel.fromJson(json)).toList();
            isLoadingSalesmen = false;
          });
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
            productCatalog = products.map((json) => ProductItem.fromJson(json)).toList();
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
      final queryParam = (empId.isEmpty || empId == 'all') ? 'all' : Uri.encodeComponent(empId);
      final response = await http.get(
        Uri.parse('${API_BASE_URL}get_attendance.php?emp_id=$queryParam'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          final List<dynamic> history = data['history'] ?? data['data'] ?? [];
          setState(() {
            attendanceHistory = history.map((j) => AttendanceRecord.fromJson(j)).toList();
            isLoadingAttendance = false;
          });
        } else {
          setState(() {
            attendanceHistory = [];
            isLoadingAttendance = false;
          });
        }
      } else {
        setState(() {
          attendanceHistory = [];
          isLoadingAttendance = false;
        });
      }
    } catch (e) {
      setState(() {
        attendanceHistory = [];
        isLoadingAttendance = false;
      });
    }
  }

  Future<void> _fetchDailyReports(String empId) async {
    setState(() => isLoadingReports = true);
    try {
      final queryParam = (empId.isEmpty || empId == 'all') ? 'all' : Uri.encodeComponent(empId);
      final response = await http.get(
        Uri.parse('${API_BASE_URL}manage_daily_reports.php?emp_id=$queryParam'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          final List<dynamic> reports = data['reports'] ?? data['data'] ?? [];
          setState(() {
            dailyReports = reports.map((j) => DailyReport.fromJson(j)).toList();
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
                'emp_name': leaf['emp_name'] ?? empInfo['name'] ?? leaf['emp_id'] ?? 'Staff',
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

  Future<void> _updateLeaveStatus(String leaveId, String empId, String status) async {
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
                content: Text(result['message'] ?? 'Leave $status successfully'),
                backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
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
              SnackBar(content: Text(result['message'] ?? 'Salesman added successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to add salesman')),
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
              SnackBar(content: Text(result['message'] ?? 'Salesman updated successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to update salesman')),
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
              SnackBar(content: Text(result['message'] ?? 'Salesman deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to delete salesman')),
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
              SnackBar(content: Text(result['message'] ?? 'Route assigned successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to assign route')),
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
              SnackBar(content: Text(result['message'] ?? 'Product added successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to add product')),
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
              SnackBar(content: Text(result['message'] ?? 'Product updated successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to update product')),
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
              SnackBar(content: Text(result['message'] ?? 'Product deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Failed to delete product')),
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

  Future<void> _changePassword(String identifier, String oldPassword, String newPassword) async {
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
              backgroundColor: result['status'] == true ? Colors.green : Colors.red,
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

  // ==================== UI HELPER METHODS ====================

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    String second = dt.second.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} • $hour:$minute:$second $period";
  }

  Widget _buildLeaveStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBodyStat(String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _AdminPalette.inkDark)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _AdminPalette.inkDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ACTIVITY & MANAGEMENT DIALOG ====================

  void _showActivityManagementDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _AdminPalette.bgWarm,
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
                  const Row(
                    children: [
                      Icon(Icons.dashboard_customize, color: _AdminPalette.primaryBrown, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Activity & Management",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              // Option Cards
              _buildDialogOptionCard(
                ctx,
                title: "Leave Approvals",
                subtitle: "${leaveList.where((l) => l.status == 'Pending').length} pending requests",
                icon: Icons.time_to_leave,
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  _showLeavesDialog();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOptionCard(
                ctx,
                title: "Attendance Records",
                subtitle: "${attendanceHistory.length} records found",
                icon: Icons.how_to_reg,
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  _showAttendanceDialog();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOptionCard(
                ctx,
                title: "Daily Reports",
                subtitle: "${dailyReports.length} reports available",
                icon: Icons.assessment,
                color: Colors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDailyReportsDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOptionCard(
      BuildContext ctx, {
        required String title,
        required String subtitle,
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
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _AdminPalette.inkDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== LEAVES DIALOG ====================

  void _showLeavesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      const Row(
                        children: [
                          Icon(Icons.time_to_leave, color: Colors.orange, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Leave Approvals",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: _AdminPalette.primaryBrown),
                            onPressed: () {
                              _fetchAllLeaves().then((_) {
                                setDialogState(() {});
                              });
                            },
                            tooltip: "Refresh",
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingLeaves)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (leaveList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No leave requests found.", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: leaveList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = leaveList[index];
                            Color statusColor = item.status == 'Approved'
                                ? Colors.green
                                : item.status == 'Rejected'
                                ? Colors.red
                                : Colors.amber.shade800;

                            String empFormattedId = _formatEmpId(item.empId, item.empRole);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _AdminPalette.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _AdminPalette.primaryBrown.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    empFormattedId,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _AdminPalette.primaryBrown,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  item.empRole,
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor, width: 1),
                                        ),
                                        child: Text(
                                          item.status,
                                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${item.leaveType} • ${item.startDate} to ${item.endDate}",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Reason: ${item.reason}",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.status == 'Pending') ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            _updateLeaveStatus(item.id, item.empId, 'Rejected').then((_) {
                                              setDialogState(() {});
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text("Reject", style: TextStyle(fontSize: 11)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            _updateLeaveStatus(item.id, item.empId, 'Approved').then((_) {
                                              setDialogState(() {});
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _AdminPalette.primaryBrown,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text("Approve", style: TextStyle(color: Colors.white, fontSize: 11)),
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

  // ==================== ATTENDANCE DIALOG ====================

  void _showAttendanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      const Row(
                        children: [
                          Icon(Icons.how_to_reg, color: Colors.blue, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Attendance Records",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: _AdminPalette.primaryBrown),
                            onPressed: () {
                              _fetchAttendanceData(_selectedEmpIdFilter).then((_) {
                                setDialogState(() {});
                              });
                            },
                            tooltip: "Refresh",
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingAttendance)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (attendanceHistory.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No attendance records found.", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: attendanceHistory.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final att = attendanceHistory[index];
                            bool isPunchIn = att.punchType == 'PUNCH_IN';
                            String empFormattedId = _formatEmpId(att.empId, att.role);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _AdminPalette.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isPunchIn ? Colors.green.shade50 : Colors.orange.shade50,
                                    child: Icon(
                                      isPunchIn ? Icons.login : Icons.logout,
                                      color: isPunchIn ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              att.punchType,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isPunchIn ? Colors.green.shade800 : Colors.orange.shade800,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                empFormattedId,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _AdminPalette.primaryBrown,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Time: ${att.punchTime} • Date: ${att.punchDate} (${att.day})",
                                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                                        ),
                                      ],
                                    ),
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

  // ==================== DAILY REPORTS DIALOG ====================

  void _showDailyReportsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      const Row(
                        children: [
                          Icon(Icons.assessment, color: Colors.green, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Daily Reports",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: _AdminPalette.primaryBrown),
                            onPressed: () {
                              _fetchDailyReports(_selectedEmpIdFilter).then((_) {
                                setDialogState(() {});
                              });
                            },
                            tooltip: "Refresh",
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingReports)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (dailyReports.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No daily reports found.", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: dailyReports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final report = dailyReports[index];
                            String empFormattedId = _formatEmpId(report.empId, 'Salesman');

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _AdminPalette.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Product: ${report.productName}",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _AdminPalette.primaryBrown.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          empFormattedId,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _AdminPalette.primaryBrown,
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
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                      const Icon(Icons.phone, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(report.mobile, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          report.createdAt,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  // ==================== OPTION MENU ====================

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
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Menu Options",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications, color: Colors.blue),
              ),
              title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("View all notifications"),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${leaveList.where((l) => l.status == 'Pending').length}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showNotificationsModal();
              },
            ),

            const Divider(),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AdminPalette.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: _AdminPalette.primaryBrown),
              ),
              title: const Text("View Profile", style: TextStyle(fontWeight: FontWeight.w600)),
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
              title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.w600)),
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
              title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
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

  void _showNotificationsModal() {
    final pendingLeaves = leaveList.where((l) => l.status == 'Pending').toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _AdminPalette.bgWarm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.blue),
            SizedBox(width: 8),
            Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pendingLeaves.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No pending notifications", style: TextStyle(color: Colors.grey)),
                )
              else
                ...pendingLeaves.map((leave) => _buildNotificationItem(
                  "Leave Request Pending",
                  "${leave.empName} (${leave.empRole}) applied for ${leave.leaveType} leave\n${leave.startDate} - ${leave.endDate}",
                  leave.reason,
                  Colors.orange,
                )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: _AdminPalette.primaryBrown)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, String reason, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.circle, color: color, size: 12),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text("$subtitle\nReason: $reason", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: _AdminPalette.primaryBrown,
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminData?.name ?? "Admin User",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                        ),
                        Text(
                          adminData?.empId ?? "BHFADMIN-01",
                          style: const TextStyle(fontSize: 13, color: _AdminPalette.primaryBrown),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _AdminPalette.accentBadge,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            adminData?.role ?? "Super Admin",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text("Admin Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
              const SizedBox(height: 10),
              _buildProfileInfoRow(Icons.person, "Full Name", adminData?.name ?? "Admin User"),
              _buildProfileInfoRow(Icons.email, "Email", adminData?.email ?? "admin@bhadrafoods.com"),
              _buildProfileInfoRow(Icons.phone, "Phone", adminData?.mobile ?? "+91 98765 43210"),
              _buildProfileInfoRow(Icons.location_on, "Location", adminData?.city ?? "Bhavnagar, Gujarat"),
              if (adminData?.lastUpdated != null && adminData!.lastUpdated.isNotEmpty)
                _buildProfileInfoRow(Icons.access_time, "Last Updated", adminData!.lastUpdated),
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
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: _AdminPalette.inkDark))),
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
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.lock_reset, color: _AdminPalette.primaryBrown),
                      SizedBox(width: 8),
                      Text("Change Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
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
                        backgroundColor: _AdminPalette.primaryBrown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (newController.text.isNotEmpty && newController.text == confirmController.text) {
                          String identifier = adminData?.empId ?? adminData?.email ?? '';
                          if (identifier.isNotEmpty) {
                            _changePassword(identifier, oldController.text, newController.text);
                          }
                          Navigator.pop(ctx);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Passwords do not match!")),
                          );
                        }
                      },
                      child: const Text("Update Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text("Logout Confirmation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.8)),
          ],
        ),
        content: const Text("Are you sure you want to logout from admin panel?"),
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
              Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => const Login()));
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
    final priceController = TextEditingController(text: editItem != null ? editItem.price.toStringAsFixed(0) : '');
    String selectedCat = editItem?.category ?? "Main Item";
    String selectedSubCat = editItem?.subCategory ?? "Khakhra";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.inventory_2, color: Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  editItem == null ? "Add Product" : "Edit Product",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.history, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showCatalogHistoryModal();
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCat,
                      decoration: InputDecoration(
                        labelText: "Category",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Main Item", child: Text("Main Item")),
                        DropdownMenuItem(value: "Celebration Box", child: Text("Celebration Box")),
                      ],
                      onChanged: (v) {
                        setModalState(() {
                          selectedCat = v!;
                          selectedSubCat = selectedCat == "Main Item" ? "Khakhra" : "Gift Packs";
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedSubCat,
                      decoration: InputDecoration(
                        labelText: "Sub Category",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: selectedCat == "Main Item"
                          ? const [
                        DropdownMenuItem(value: "Khakhra", child: Text("Khakhra")),
                        DropdownMenuItem(value: "Bhakhari", child: Text("Bhakhari")),
                        DropdownMenuItem(value: "Bites", child: Text("Bites")),
                      ]
                          : const [
                        DropdownMenuItem(value: "Gift Packs", child: Text("Gift Packs")),
                        DropdownMenuItem(value: "Festive Edition", child: Text("Festive Edition")),
                      ],
                      onChanged: (v) => setModalState(() => selectedSubCat = v!),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Product Name",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Price (₹)",
                        prefixIcon: const Icon(Icons.currency_rupee, color: _AdminPalette.primaryBrown),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AdminPalette.primaryBrown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                            final product = ProductItem(
                              id: editItem?.id ?? '',
                              category: selectedCat,
                              subCategory: selectedSubCat,
                              name: nameController.text.trim(),
                              price: double.parse(priceController.text.trim()),
                            );

                            if (editItem != null) {
                              _updateProduct(product);
                            } else {
                              _addProduct(product);
                            }
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          editItem == null ? "+ Add to Catalog" : "Update Item",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.history, color: Colors.blue),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Text(
                                "Product Catalog",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingCatalog)
                    const Center(child: CircularProgressIndicator())
                  else if (productCatalog.isEmpty)
                    const Center(child: Text("No products found", style: TextStyle(color: Colors.grey)))
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: productCatalog.length,
                          itemBuilder: (context, index) {
                            final p = productCatalog[index];
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text("${p.category} • ${p.subCategory}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          Text("₹${p.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _showCatalogModal(editItem: p);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.route, color: Colors.teal),
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            "Route Management",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoadingSalesmen)
                const Center(child: CircularProgressIndicator())
              else if (salesmenList.isEmpty)
                const Center(child: Text("No salesmen available", style: TextStyle(color: Colors.grey)))
              else
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: salesmenList.length,
                      itemBuilder: (context, index) {
                        final sm = salesmenList[index];
                        String formattedEmpId = _formatEmpId(sm.empId, sm.role);

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                      child: Icon(Icons.person, size: 16, color: _AdminPalette.primaryBrown),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "${sm.name} ($formattedEmpId)",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.route, size: 16, color: _AdminPalette.primaryBrown),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Route: ${sm.assignedRoute.isNotEmpty ? sm.assignedRoute : 'Not assigned'}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                      onPressed: () => _showAssignRouteModal(sm),
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
    final routeController = TextEditingController(text: salesman.assignedRoute);
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.route, color: _AdminPalette.primaryBrown),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AdminPalette.primaryBrown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (routeController.text.trim().isNotEmpty) {
                        _assignRoute(salesman.empId, routeController.text.trim());
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a route")),
                        );
                      }
                    },
                    child: const Text("Assign Route", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SALESMAN MANAGEMENT MODAL WITH BHFSM-01 GENERATION ====================

  void _showSalesmenManagementModal({SalesmanModel? editItem}) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final phoneCtrl = TextEditingController(text: editItem?.phone ?? '');
    final emailCtrl = TextEditingController(text: editItem?.email ?? '');
    final cityCtrl = TextEditingController(text: editItem?.city ?? 'Bhavnagar');
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = editItem?.role ?? 'Salesman';
    bool isEditing = editItem != null;

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
          String previewEmpId = isEditing ? displayEmpId : generateEmpId(selectedRole);

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
                            isEditing ? "Edit Salesman Profile" : "Register New Salesman",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history, color: _AdminPalette.primaryBrown),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showSalesmenHistoryModal();
                              },
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _AdminPalette.primaryBrown.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _AdminPalette.primaryBrown.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 20, color: _AdminPalette.primaryBrown),
                              const SizedBox(width: 8),
                              Text(
                                isEditing ? "Employee ID:" : "Formatted Emp ID:",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _AdminPalette.inkDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Full Name is required" : null,
                      decoration: InputDecoration(
                        labelText: "Full Name *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Mobile Number is required";
                        if (v.trim().length < 10) return "Enter a valid 10-digit mobile number";
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Mobile No. *",
                        prefixText: "+91 ",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Email Address is required";
                        if (!v.contains('@') || !v.contains('.')) return "Enter a valid email address";
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Email Address *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: roleOptions
                                .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r, style: const TextStyle(fontSize: 14)),
                            ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() {
                                  selectedRole = v;
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Formatted Emp ID stored into manage_salesmna.php table (e.g. BHFSM-01)",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    if (!isEditing) ...[
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password (default: 123456)",
                          hintText: "Leave empty for default password",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.lock, color: _AdminPalette.primaryBrown),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AdminPalette.primaryBrown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
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
                              _addSalesman(salesman, passwordCtrl.text.isNotEmpty ? passwordCtrl.text : '123456');
                            }
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          isEditing ? "Update Profile" : "Register Member",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: _AdminPalette.bgWarm,
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
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AdminPalette.primaryBrown.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.people, color: _AdminPalette.primaryBrown),
                              ),
                              const SizedBox(width: 10),
                              const Flexible(
                                child: Text(
                                  "Registered Members",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
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
                              icon: const Icon(Icons.refresh, color: _AdminPalette.primaryBrown),
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
                      const Center(child: Text("No registered members", style: TextStyle(color: Colors.grey)))
                    else
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.55,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: salesmenList.length,
                            itemBuilder: (context, index) {
                              final sm = salesmenList[index];
                              String displayEmpId = _formatEmpId(sm.empId, sm.role);

                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: sm.isLive ? Colors.green.shade100 : Colors.red.shade100,
                                            child: Icon(
                                              Icons.person,
                                              size: 20,
                                              color: sm.isLive ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      sm.name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _AdminPalette.primaryBrown,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        displayEmpId,
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
                                                  "Role: ${sm.role} • City: ${sm.city}",
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                                ),
                                                Text(
                                                  "Phone: ${sm.phone} | Email: ${sm.email}",
                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                ),
                                                if (sm.assignedRoute.isNotEmpty)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.teal.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.teal.shade200),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.route, size: 12, color: Colors.teal.shade700),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            sm.assignedRoute,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.teal.shade700,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
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
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(6),
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _showSalesmenManagementModal(editItem: sm);
                                                },
                                              ),
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(6),
                                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                                onPressed: () {
                                                  _deleteSalesman(sm.empId);
                                                  Navigator.pop(ctx);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: sm.isLive ? Colors.green.shade50 : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              sm.isLive ? "● Live" : "○ Offline",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: sm.isLive ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Updated: ${sm.lastUpdated}",
                                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
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
                    if (salesmenList.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _AdminPalette.cardBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLeaveStat("Total", salesmenList.length, Colors.grey),
                            _buildLeaveStat("Live", salesmenList.where((s) => s.isLive).length, Colors.green),
                            _buildLeaveStat("Offline", salesmenList.where((s) => !s.isLive).length, Colors.red),
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
        );
      },
    );
  }

  // ==================== LIVE TRACKING MODAL ====================

  void _showLiveTrackingModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: _AdminPalette.bgWarm,
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.map_outlined, color: Colors.teal),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Live Salesman", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark), overflow: TextOverflow.ellipsis),
                                  Text("Tracking Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: _AdminPalette.primaryBrown),
                            onPressed: () {
                              _fetchSalesmenData().then((_) {
                                setModalState(() {});
                              });
                            },
                            tooltip: "Refresh",
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingSalesmen)
                    const Center(child: CircularProgressIndicator())
                  else if (salesmenList.isEmpty)
                    const Center(child: Text("No salesmen available"))
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: salesmenList.length,
                          itemBuilder: (context, index) {
                            final sm = salesmenList[index];
                            String formattedEmpId = _formatEmpId(sm.empId, sm.role);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.teal.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Color(0xFFC8E6C9),
                                        child: Icon(Icons.person, color: _AdminPalette.accentBadge),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("${sm.name} (${sm.role})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                            Text("ID: $formattedEmpId", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: sm.isLive ? Colors.green.shade100 : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          sm.isLive ? "Live" : "Offline",
                                          style: TextStyle(
                                            color: sm.isLive ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (sm.liveLocation.isNotEmpty || (sm.latitude != null && sm.longitude != null)) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              sm.liveLocation.isNotEmpty
                                                  ? "Live: ${sm.liveLocation}"
                                                  : (sm.latitude != null && sm.longitude != null)
                                                  ? "Lat: ${sm.latitude!.toStringAsFixed(6)}, Lng: ${sm.longitude!.toStringAsFixed(6)}"
                                                  : "No location data",
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("City: ${sm.city}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text("Updated: ${sm.lastUpdated}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
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

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AdminPalette.bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_AdminPalette.darkHeaderTop, _AdminPalette.darkHeaderBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                const CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Color(0xFFEADBCE),
                                  child: Icon(Icons.store, size: 30, color: _AdminPalette.primaryBrown),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: _AdminPalette.accentBadge, shape: BoxShape.circle),
                                    child: const Icon(Icons.visibility, size: 10, color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLoadingAdmin ? "Loading..." : (adminData?.name ?? "Bhadra Foods"),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: _AdminPalette.accentBadge, borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          adminData?.role ?? "Supplier",
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          adminData?.city ?? "Bhavnagar, Gujarat",
                                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: _showOptionsMenu,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_filled, color: _AdminPalette.accentBadge, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatDateTime(_currentTime),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: isLoadingSalesmen
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(child: Text("Error: $errorMessage", style: const TextStyle(color: Colors.red)))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Summary Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _AdminPalette.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _AdminPalette.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBodyStat("${salesmenList.length}", "Staff", Icons.people, _AdminPalette.primaryBrown),
                          Container(height: 30, width: 1, color: _AdminPalette.border),
                          _buildBodyStat("${salesmenList.where((s) => s.isLive).length}", "Live", Icons.sensors, Colors.green),
                          Container(height: 30, width: 1, color: _AdminPalette.border),
                          _buildBodyStat("${productCatalog.length}", "Items", Icons.inventory_2, Colors.blue),
                          Container(height: 30, width: 1, color: _AdminPalette.border),
                          _buildBodyStat("${leaveList.where((l) => l.status == 'Pending').length}", "Pending", Icons.hourglass_top, Colors.amber.shade800),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Management Action Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildActionCard("Manage Salesmen", Icons.person_add_alt_1, _AdminPalette.primaryBrown, _showSalesmenManagementModal),
                        _buildActionCard("Product Catalog", Icons.inventory, Colors.blue, _showCatalogModal),
                        _buildActionCard("Assign Routes", Icons.alt_route, Colors.teal, _showRouteManagementModal),
                        _buildActionCard("Live Tracking", Icons.my_location, Colors.green, _showLiveTrackingModal),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Activity & Management Card - Opens Dialog View
                    _buildActivityManagementCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Activity & Management Card (Opens Dialog)
  Widget _buildActivityManagementCard() {
    int pendingLeavesCount = leaveList.where((l) => l.status == 'Pending').length;

    return Container(
      decoration: BoxDecoration(
        color: _AdminPalette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AdminPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showActivityManagementDialog,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _AdminPalette.primaryBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize,
                    color: _AdminPalette.primaryBrown,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Activity & Management",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _AdminPalette.inkDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Leaves • Attendance • Reports",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (pendingLeavesCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$pendingLeavesCount Pending",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            "${attendanceHistory.length} Attendance • ${dailyReports.length} Reports",
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: _AdminPalette.primaryBrown,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}