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

// API Base URL - Update this with your server URL
const String API_BASE_URL = 'http://192.168.0.102/bhadra_foods/';

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

// Model for Salesman
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
  });

  factory SalesmanModel.fromJson(Map<String, dynamic> json) {
    return SalesmanModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      empId: json['emp_id'] ?? '',
      role: json['role'] ?? '',
      city: json['city'] ?? '',
      phone: json['mobile'] ?? '',
      email: json['email'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
      isLive: json['is_live'] == 1 || json['is_live'] == true,
      assignedRoute: json['assigned_route'] ?? '',
      liveLocation: json['live_location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': phone,
      'email': email,
      'city': city,
      'role': role,
      'assigned_route': assignedRoute,
    };
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
  AdminModel? adminData;

  // Loading states
  bool isLoadingSalesmen = false;
  bool isLoadingCatalog = false;
  bool isLoadingAdmin = false;
  String? errorMessage;

  // Leave Requests (Mock data for now - can be extended)
  final List<LeaveRequest> leaveList = [
    LeaveRequest(
      id: "LV-01",
      empName: "Rahul Sharma",
      empRole: "Salesman",
      date: "14 Sep 2026",
      reason: "Medical leave",
      status: "Pending",
    ),
    LeaveRequest(
      id: "LV-02",
      empName: "Amit Shah",
      empRole: "Sales Officer",
      date: "18 Sep 2026",
      reason: "Personal work",
      status: "Pending",
    ),
  ];

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
    _fetchAdminData();
    _fetchSalesmenData();
    _fetchCatalogData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  // ==================== SALESMAN CRUD OPERATIONS ====================

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

  // ==================== ASSIGN ROUTE API ====================

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

  // ==================== CATALOG CRUD OPERATIONS ====================

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

  // ==================== CHANGE PASSWORD API ====================

  Future<void> _changePassword(String identifier, String oldPassword, String newPassword) async {
    try {
      final data = {
        'identifier': identifier,
        'old_password': oldPassword,  // Fixed: Use 'old_password' key
        'new_password': newPassword,  // Fixed: Use 'new_password' key
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

  // ==================== UI METHODS ====================

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    String second = dt.second.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} • $hour:$minute:$second $period";
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
                child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 12)),
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
                Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => Login()));
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
              _buildNotificationItem("New Salesman Registration", "Rahul Sharma registered as Salesman", "2 min ago", Colors.green),
              const Divider(),
              _buildNotificationItem("Leave Request Pending", "Amit Shah applied for leave", "1 hour ago", Colors.orange),
              const Divider(),
              _buildNotificationItem("New Order Received", "Order #103 from Super Stockist", "3 hours ago", Colors.blue),
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

  Widget _buildNotificationItem(String title, String subtitle, String time, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.circle, color: color, size: 12),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text("$subtitle\n$time", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
              Navigator.pop(ctx);
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
                              // History Icon to view all products
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
                  isLoadingCatalog
                      ? const Center(child: CircularProgressIndicator())
                      : productCatalog.isEmpty
                      ? const Center(child: Text("No products found", style: TextStyle(color: Colors.grey)))
                      : Flexible(
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
              isLoadingSalesmen
                  ? const Center(child: CircularProgressIndicator())
                  : salesmenList.isEmpty
                  ? const Center(child: Text("No salesmen available", style: TextStyle(color: Colors.grey)))
                  : Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: salesmenList.length,
                    itemBuilder: (context, index) {
                      final sm = salesmenList[index];
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
                                      "${sm.name} (${sm.empId})",
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
                "Assigning route for: ${salesman.name} (${salesman.empId})",
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

  // ==================== SALESMAN MANAGEMENT MODAL ====================
  void _showSalesmenManagementModal({SalesmanModel? editItem}) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final phoneCtrl = TextEditingController(text: editItem?.phone ?? '');
    final emailCtrl = TextEditingController(text: editItem?.email ?? '');
    final cityCtrl = TextEditingController(text: editItem?.city ?? 'Bhavnagar');
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = editItem?.role ?? 'Salesman';
    bool isEditing = editItem != null;

    // For displaying employee ID when editing
    String displayEmpId = editItem?.empId ?? '';

    // Get role prefix for preview
    String getRolePrefix(String role) {
      switch(role) {
        case 'Salesman': return 'BHFSM';
        case 'Sales Officer': return 'BHFSO';
        case 'ASM': return 'BHFAS';
        case 'RSM': return 'BHFRS';
        case 'ZSM': return 'BHFZS';
        case 'Sales Head': return 'BHFSH';
        default: return 'BHFEMP';
      }
    }

    // Get sample Employee ID for preview
    String getSampleEmpId(String role) {
      String prefix = getRolePrefix(role);
      // Get count of existing users with this role
      int count = salesmenList.where((s) => s.role == role).length + 1;
      return '$prefix:-${count.toString().padLeft(2, '0')}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Calculate preview ID when role changes
          String previewEmpId = getSampleEmpId(selectedRole);

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
                            isEditing ? "Edit Salesman" : "Register New Salesman",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // History Icon to view all salesmen
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

                    // Show Employee ID when editing - FIXED: Show from database
                    if (isEditing && displayEmpId.isNotEmpty) ...[
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
                            const Text(
                              "Employee ID:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _AdminPalette.inkDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _AdminPalette.primaryBrown,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayEmpId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Show preview Employee ID for new registration
                    if (!isEditing) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.badge, size: 20, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  "Will be generated as:",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
                    ],

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
                            items: roleOptions.map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r, style: const TextStyle(fontSize: 14))
                            )).toList(),
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

                    // Show role hint
                    const SizedBox(height: 4),
                    Text(
                      "Role determines Employee ID prefix (e.g., BHFSM for Salesman, BHFSO for Sales Officer)",
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
                              empId: editItem?.empId ?? '',
                              role: selectedRole,
                              city: cityCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              lastUpdated: DateTime.now().toString(),
                              assignedRoute: editItem?.assignedRoute ?? '',
                            );

                            if (isEditing) {
                              // Update existing
                              salesman.id = editItem!.id;
                              salesman.empId = editItem.empId;
                              _updateSalesman(salesman);
                            } else {
                              // Add new - Employee ID will be generated by PHP
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
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  isLoadingSalesmen
                      ? const Center(child: CircularProgressIndicator())
                      : salesmenList.isEmpty
                      ? const Center(child: Text("No registered members", style: TextStyle(color: Colors.grey)))
                      : Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: salesmenList.length,
                        itemBuilder: (context, index) {
                          final sm = salesmenList[index];
                          // FIXED: Show emp_id from database, NOT the id
                          String displayEmpId = sm.empId.isNotEmpty ? sm.empId : 'N/A';

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
                                                // FIXED: Show emp_id from database
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
                                  // Live Status
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== LEAVE MANAGEMENT MODAL ====================

  void _showLeaveManagementModal() {
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
                              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.time_to_leave, color: Colors.amber),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Text("Leave Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  leaveList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No pending leave requests.", style: TextStyle(color: Colors.grey))),
                  )
                      : ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: leaveList.length,
                      itemBuilder: (ctx, idx) {
                        final item = leaveList[idx];
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text("${item.empName} (${item.empRole})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item.status == 'Approved'
                                            ? Colors.green.shade100
                                            : item.status == 'Rejected'
                                            ? Colors.red.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: TextStyle(
                                          color: item.status == 'Approved'
                                              ? Colors.green
                                              : item.status == 'Rejected'
                                              ? Colors.red
                                              : Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text("Date: ${item.date} | Reason: ${item.reason}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                if (item.status == 'Pending') ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            item.status = 'Rejected';
                                          });
                                          setModalState(() {});
                                        },
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text("Reject"),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            item.status = 'Approved';
                                          });
                                          setModalState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: _AdminPalette.primaryBrown),
                                        child: const Text("Approve", style: TextStyle(color: Colors.white)),
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                      child: isLoadingSalesmen
                          ? const Center(child: CircularProgressIndicator())
                          : salesmenList.isEmpty
                          ? const Center(child: Text("No salesmen available"))
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: salesmenList.length,
                        itemBuilder: (context, index) {
                          final sm = salesmenList[index];
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
                                          Text("ID: ${sm.empId}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                                if (sm.liveLocation.isNotEmpty) ...[
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
                                            "Live: ${sm.liveLocation}",
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
                    // Stats Row
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
                          Expanded(
                            child: InkWell(
                              onTap: () => _showSalesmenManagementModal(),
                              child: _buildBodyStat("${salesmenList.length}", "Salesmen", Icons.people_alt_outlined, Colors.purple),
                            ),
                          ),
                          Container(height: 30, width: 1, color: Colors.black12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showLeaveManagementModal(),
                              child: _buildBodyStat("${leaveList.length}", "Leaves", Icons.time_to_leave, Colors.amber.shade800),
                            ),
                          ),
                          Container(height: 30, width: 1, color: Colors.black12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showCatalogModal(),
                              child: _buildBodyStat("${productCatalog.length}", "Products", Icons.inventory_2, Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Section Title
                    Row(
                      children: [
                        Container(width: 4, height: 18, color: _AdminPalette.primaryBrown),
                        const SizedBox(width: 8),
                        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Grid of Action Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        _buildActionCard("Catalog", Icons.inventory_2_outlined, Colors.blue, _showCatalogModal),
                        _buildActionCard("Live Map", Icons.map_outlined, Colors.teal, _showLiveTrackingModal),
                        _buildActionCard("Manage Team", Icons.manage_accounts_outlined, Colors.purple, () => _showSalesmenManagementModal()),
                        _buildActionCard("Manage Leave", Icons.time_to_leave_outlined, Colors.amber.shade800, _showLeaveManagementModal),
                        _buildActionCard("Routes", Icons.route_outlined, Colors.teal, _showRouteManagementModal),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: _AdminPalette.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _AdminPalette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.withOpacity(0.9)), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// Leave Request Model
class LeaveRequest {
  final String id;
  final String empName;
  final String empRole;
  final String date;
  final String reason;
  String status;

  LeaveRequest({
    required this.id,
    required this.empName,
    required this.empRole,
    required this.date,
    required this.reason,
    this.status = 'Pending',
  });
}