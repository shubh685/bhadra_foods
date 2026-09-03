import 'dart:async';
import 'package:flutter/material.dart';

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

// Model for Super Stockist Registration & Management
class SuperStockistModel {
  String id;
  String personName;
  String firmName;
  String mobile;
  String email;
  String gstNumber;
  String city;
  String state;
  String pincode;
  bool hasWarehouse;

  SuperStockistModel({
    required this.id,
    required this.personName,
    required this.firmName,
    required this.mobile,
    required this.email,
    required this.gstNumber,
    required this.city,
    required this.state,
    required this.pincode,
    required this.hasWarehouse,
  });
}

// Model for Salesman Management & Registration
class SalesmanModel {
  String id;
  String name;
  String role; // Salesman, SO, ASM, RSM, ZSM, Sales Head
  String city;
  String phone;
  String email;
  String lastUpdated;
  bool isLive;
  String assignedRoute; // Added route field

  SalesmanModel({
    required this.id,
    required this.name,
    required this.role,
    required this.city,
    required this.phone,
    required this.email,
    required this.lastUpdated,
    this.isLive = true,
    this.assignedRoute = '',
  });
}

// Model for Product Catalog Maintenance
class ProductItem {
  String id;
  String category; // 'Main Item' or 'Celebration Box'
  String subCategory; // 'Khakhra', 'Bhakhari', 'Bites'
  String name; // Flavour Name or Box Name
  double price;

  ProductItem({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.name,
    required this.price,
  });
}

// Model for Leave Requests
class LeaveRequest {
  final String id;
  final String empName;
  final String empRole;
  final String date;
  final String reason;
  String status; // 'Pending', 'Approved', 'Rejected'

  LeaveRequest({
    required this.id,
    required this.empName,
    required this.empRole,
    required this.date,
    required this.reason,
    this.status = 'Pending',
  });
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  // Super Stockist Dynamic List
  final List<SuperStockistModel> stockistList = [
    SuperStockistModel(
      id: "BHFSS-01",
      personName: "Rajesh Bhai",
      firmName: "Bhadra Enterprises",
      mobile: "9825012345",
      email: "rajesh@bhadraent.com",
      gstNumber: "24AAAAA0000A1Z5",
      city: "Bhavnagar",
      state: "Gujarat",
      pincode: "364001",
      hasWarehouse: true,
    ),
  ];

  // Salesmen Dynamic Data Management with Routes
  final List<SalesmanModel> salesmenList = [
    SalesmanModel(
      id: "BHFSM-01",
      name: "Rahul Sharma",
      role: "Salesman",
      city: "Bhavnagar",
      phone: "9876543210",
      email: "rahul.s@bhadrafoods.com",
      lastUpdated: "11:13:45 PM",
      isLive: true,
      assignedRoute: "Press Quarter -> Nari Chawkdi -> Shihor -> Palitana",
    ),
    SalesmanModel(
      id: "BHFSO-01",
      name: "Amit Shah",
      role: "Sales Officer",
      city: "Ahmedabad",
      phone: "9898989898",
      email: "amit.shah@bhadrafoods.com",
      lastUpdated: "10:45:12 AM",
      isLive: true,
      assignedRoute: "Ahmedabad City -> Naroda -> Gandhinagar",
    ),
  ];

  // Product Catalog Maintenance Data
  final List<ProductItem> productCatalog = [
    ProductItem(id: "1", category: "Main Item", subCategory: "Khakhra", name: "Plain Khakhra", price: 120.0),
    ProductItem(id: "2", category: "Main Item", subCategory: "Khakhra", name: "Manchurian Khakhra", price: 140.0),
    ProductItem(id: "3", category: "Main Item", subCategory: "Khakhra", name: "Masala Khakhra", price: 135.0),
    ProductItem(id: "4", category: "Main Item", subCategory: "Bhakhari", name: "Plain Bhakhari", price: 150.0),
    ProductItem(id: "5", category: "Main Item", subCategory: "Bhakhari", name: "Masala Bhakhari", price: 165.0),
    ProductItem(id: "6", category: "Main Item", subCategory: "Bhakhari", name: "Methi Bhakhari", price: 160.0),
    ProductItem(id: "7", category: "Main Item", subCategory: "Bites", name: "Cheese Bites", price: 180.0),
    ProductItem(id: "8", category: "Main Item", subCategory: "Bites", name: "Pizza Bites", price: 195.0),
    ProductItem(id: "9", category: "Celebration Box", subCategory: "Gift Packs", name: "Royal Festivity Box", price: 750.0),
    ProductItem(id: "10", category: "Celebration Box", subCategory: "Gift Packs", name: "Mini Celebration Box", price: 450.0),
  ];

  // Leave Requests Data
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

  final List<String> catalogCategories = ["Main Item", "Celebration Box"];
  final List<String> mainItemSubCategories = ["Khakhra", "Bhakhari", "Bites"];
  final List<String> celebrationSubCategories = ["Gift Packs", "Festive Edition"];
  final List<String> roleOptions = [
    "Salesman",
    "Sales Officer",
    "ASM",
    "RSM",
    "ZSM",
    "Sales Head",
  ];

  int deliveryCount = 2;

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
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    String second = dt.second.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} • $hour:$minute:$second $period";
  }

  // --- OPTION MENU WITH NOTIFICATIONS, PROFILE, CHANGE PASSWORD, LOGOUT ---
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

            // Notifications
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

            // View Profile
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

            // Change Password
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

            // View Product Catalog
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2, color: Colors.blue),
              ),
              title: const Text("Product Catalog", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("View & manage products"),
              onTap: () {
                Navigator.pop(ctx);
                _showCatalogModal();
              },
            ),

            const Divider(),

            // Logout
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
                        const Text("Admin User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
                        const Text("BHFADMIN-01", style: TextStyle(fontSize: 13, color: _AdminPalette.primaryBrown)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _AdminPalette.accentBadge,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("Super Admin", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text("Admin Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
              const SizedBox(height: 10),
              _buildProfileInfoRow(Icons.person, "Full Name", "Admin User"),
              _buildProfileInfoRow(Icons.email, "Email", "admin@bhadrafoods.com"),
              _buildProfileInfoRow(Icons.phone, "Phone", "+91 98765 43210"),
              _buildProfileInfoRow(Icons.business, "Company", "Bhadra Foods"),
              _buildProfileInfoRow(Icons.location_on, "Location", "Bhavnagar, Gujarat"),
              _buildProfileInfoRow(Icons.calendar_month, "Joined", "01 Jan 2024"),
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
              // Navigate to Login page - you'll need to import your Login class
              // Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => Login()));
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

  // --- SUPER STOCKIST REGISTRATION & MANAGEMENT MODAL ---
  void _showSuperStockistModal({SuperStockistModel? editItem}) {
    final personCtrl = TextEditingController(text: editItem?.personName ?? '');
    final firmCtrl = TextEditingController(text: editItem?.firmName ?? '');
    final mobileCtrl = TextEditingController(text: editItem?.mobile ?? '');
    final emailCtrl = TextEditingController(text: editItem?.email ?? '');
    final gstCtrl = TextEditingController(text: editItem?.gstNumber ?? '');
    final cityCtrl = TextEditingController(text: editItem?.city ?? '');
    final stateCtrl = TextEditingController(text: editItem?.state ?? 'Gujarat');
    final pincodeCtrl = TextEditingController(text: editItem?.pincode ?? '');
    bool hasWarehouse = editItem?.hasWarehouse ?? true;

    final formKey = GlobalKey<FormState>();

    String generateStockistId() {
      if (editItem != null) return editItem.id;
      final count = stockistList.length + 1;
      return "BHFSS-${count.toString().padLeft(2, '0')}";
    }

    void showStockistHistoryDialog() {
      showDialog(
        context: context,
        builder: (histCtx) => StatefulBuilder(
          builder: (context, setHistState) {
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
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.storefront, color: Colors.indigo),
                              ),
                              const SizedBox(width: 10),
                              const Flexible(
                                child: Text(
                                  "Registered Super Stockists",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _AdminPalette.inkDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(histCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    stockistList.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text("No Super Stockists registered yet.", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                        : Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: stockistList.length,
                          itemBuilder: (ctx, idx) {
                            final item = stockistList[idx];
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.indigo.shade50,
                                      child: const Icon(Icons.business, color: Colors.indigo, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${item.firmName} (${item.id})",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text("Contact: ${item.personName} • ${item.mobile}", style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                          Text("GST: ${item.gstNumber}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                          Text("Location: ${item.city}, ${item.state} (${item.pincode})", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.hasWarehouse ? Colors.green.shade50 : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.hasWarehouse ? "Warehouse Available" : "No Warehouse",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: item.hasWarehouse ? Colors.green : Colors.orange,
                                              ),
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
                                            Navigator.pop(histCtx);
                                            Navigator.pop(context);
                                            _showSuperStockistModal(editItem: item);
                                          },
                                        ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              stockistList.removeAt(idx);
                                            });
                                            setHistState(() {});
                                          },
                                        ),
                                      ],
                                    )
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentId = generateStockistId();

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
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  editItem == null ? "Super Stockist Reg." : "Edit Super Stockist",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: "Super Stockist History",
                                icon: const Icon(Icons.history, color: Colors.indigo),
                                onPressed: showStockistHistoryDialog,
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: personCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Person's Name is required" : null,
                      decoration: InputDecoration(
                        labelText: "Person's Name *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: firmCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Firm Name is required" : null,
                      decoration: InputDecoration(
                        labelText: "Firm Name *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: mobileCtrl,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? "Mobile is required" : null,
                            decoration: InputDecoration(
                              labelText: "Mobile Number *",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.trim().isEmpty) ? "Email is required" : null,
                            decoration: InputDecoration(
                              labelText: "Email Address *",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: gstCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "GST Number is required" : null,
                      decoration: InputDecoration(
                        labelText: "GST Number *",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? "City required" : null,
                            decoration: InputDecoration(
                              labelText: "City *",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            controller: stateCtrl,
                            decoration: InputDecoration(
                              labelText: "State",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            controller: pincodeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Pincode",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Warehouse Available?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Switch(
                            value: hasWarehouse,
                            activeColor: Colors.indigo,
                            onChanged: (val) {
                              setModalState(() {
                                hasWarehouse = val;
                              });
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              if (editItem != null) {
                                editItem.personName = personCtrl.text.trim();
                                editItem.firmName = firmCtrl.text.trim();
                                editItem.mobile = mobileCtrl.text.trim();
                                editItem.email = emailCtrl.text.trim();
                                editItem.gstNumber = gstCtrl.text.trim();
                                editItem.city = cityCtrl.text.trim();
                                editItem.state = stateCtrl.text.trim();
                                editItem.pincode = pincodeCtrl.text.trim();
                                editItem.hasWarehouse = hasWarehouse;
                              } else {
                                stockistList.add(
                                  SuperStockistModel(
                                    id: currentId,
                                    personName: personCtrl.text.trim(),
                                    firmName: firmCtrl.text.trim(),
                                    mobile: mobileCtrl.text.trim(),
                                    email: emailCtrl.text.trim(),
                                    gstNumber: gstCtrl.text.trim(),
                                    city: cityCtrl.text.trim(),
                                    state: stateCtrl.text.trim(),
                                    pincode: pincodeCtrl.text.trim(),
                                    hasWarehouse: hasWarehouse,
                                  ),
                                );
                              }
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          editItem == null ? "Save Super Stockist" : "Update Super Stockist",
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

  // --- CATALOG MODAL WITH HISTORY & EDITING ---
  void _showCatalogModal({ProductItem? editItem}) {
    final nameController = TextEditingController(text: editItem?.name ?? '');
    final priceController = TextEditingController(text: editItem != null ? editItem.price.toStringAsFixed(0) : '');
    String selectedCat = editItem?.category ?? catalogCategories.first;
    String selectedSubCat = editItem?.subCategory ?? (selectedCat == "Main Item" ? mainItemSubCategories.first : celebrationSubCategories.first);

    void showCatalogHistoryDialog() {
      showDialog(
        context: context,
        builder: (histCtx) => StatefulBuilder(
          builder: (context, setHistState) {
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
                                child: Text("Product Catalog History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(histCtx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: productCatalog.length,
                          itemBuilder: (context, idx) {
                            final p = productCatalog[idx];
                            bool isCelebration = p.category == "Celebration Box";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isCelebration ? Colors.amber.shade50.withOpacity(0.6) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isCelebration ? Colors.amber.shade300 : Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCelebration ? Icons.card_giftcard : Icons.inventory_2_outlined,
                                          color: isCelebration ? Colors.amber.shade900 : Colors.blue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                              if (!isCelebration)
                                                Text("${p.category} • ${p.subCategory}", style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)
                                              else
                                                const Text("Celebration Pack", style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Text("₹${p.price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                        onPressed: () {
                                          Navigator.pop(histCtx);
                                          Navigator.pop(context);
                                          _showCatalogModal(editItem: p);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            productCatalog.removeAt(idx);
                                          });
                                          setHistState(() {});
                                        },
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
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          List<String> currentSubCats = selectedCat == "Main Item" ? mainItemSubCategories : celebrationSubCategories;
          if (!currentSubCats.contains(selectedSubCat)) {
            selectedSubCat = currentSubCats.first;
          }

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
                                  editItem == null ? "Product Catalog" : "Edit Product Item",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: "View Catalog History",
                                icon: const Icon(Icons.history, color: Colors.blue),
                                onPressed: showCatalogHistoryDialog,
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
                        labelText: "Catalog Type",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: catalogCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) {
                        setModalState(() {
                          selectedCat = v!;
                          selectedSubCat = selectedCat == "Main Item" ? mainItemSubCategories.first : celebrationSubCategories.first;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (selectedCat == "Main Item") ...[
                      DropdownButtonFormField<String>(
                        value: selectedSubCat,
                        decoration: InputDecoration(
                          labelText: "Main Item Type (Khakhra, Bhakhari, Bites)",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: mainItemSubCategories.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setModalState(() => selectedSubCat = v!),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: selectedCat == "Celebration Box" ? "Celebration Box Name" : "Item Flavour (e.g., Plain Khakhra, Manchurian Khakhra)",
                        prefixIcon: Icon(selectedCat == "Celebration Box" ? Icons.card_giftcard : Icons.fastfood, color: _AdminPalette.primaryBrown),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Rate (₹)",
                        prefixIcon: const Icon(Icons.currency_rupee, color: _AdminPalette.primaryBrown),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                            setState(() {
                              if (editItem != null) {
                                editItem.category = selectedCat;
                                editItem.subCategory = selectedSubCat;
                                editItem.name = nameController.text.trim();
                                editItem.price = double.parse(priceController.text.trim());
                              } else {
                                productCatalog.add(
                                  ProductItem(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    category: selectedCat,
                                    subCategory: selectedSubCat,
                                    name: nameController.text.trim(),
                                    price: double.parse(priceController.text.trim()),
                                  ),
                                );
                              }
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(editItem == null ? "+ Add to Catalog" : "Update Item", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // --- LIVE MAP TRACKING MODAL WITH ROUTE & HISTORY ---
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
                                  Text("Tracking & Route Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark), overflow: TextOverflow.ellipsis),
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
                      child: ListView.builder(
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
                                          Text("ID: ${sm.id}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: const Text("Live", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Assigned Route
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _AdminPalette.primaryBrown.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _AdminPalette.primaryBrown.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.route, size: 16, color: _AdminPalette.primaryBrown),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Assigned Route",
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                            ),
                                            Text(
                                              sm.assignedRoute.isNotEmpty ? sm.assignedRoute : "No route assigned",
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _AdminPalette.inkDark),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("City: ${sm.city}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text("Updated: ${sm.lastUpdated}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                // History Icon
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.history, color: _AdminPalette.primaryBrown, size: 20),
                                      tooltip: "View Salesman History",
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _showSalesmanHistoryModal(sm);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  // --- SALESMAN HISTORY MODAL ---
  void _showSalesmanHistoryModal(SalesmanModel salesman) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _AdminPalette.primaryBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.history, color: _AdminPalette.primaryBrown),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Salesman Details",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              _buildHistoryDetailRow("Name", salesman.name),
              _buildHistoryDetailRow("ID", salesman.id),
              _buildHistoryDetailRow("Role", salesman.role),
              _buildHistoryDetailRow("City", salesman.city),
              _buildHistoryDetailRow("Phone", salesman.phone),
              _buildHistoryDetailRow("Email", salesman.email),
              _buildHistoryDetailRow("Status", salesman.isLive ? "🟢 Active" : "🔴 Inactive"),
              const Divider(),
              const Text("Assigned Route:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _AdminPalette.primaryBrown.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _AdminPalette.primaryBrown.withOpacity(0.2)),
                ),
                child: Text(
                  salesman.assignedRoute.isNotEmpty ? salesman.assignedRoute : "No route assigned",
                  style: const TextStyle(fontSize: 13, color: _AdminPalette.inkDark),
                ),
              ),
              const SizedBox(height: 8),
              Text("Last Updated: ${salesman.lastUpdated}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: _AdminPalette.inkDark)),
          ),
        ],
      ),
    );
  }

  // --- LEAVE MANAGEMENT MODAL ---
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

  // --- SALESMAN MANAGEMENT & REGISTRATION MODAL WITH ROUTE ---
  void _showSalesmenManagementModal({SalesmanModel? editItem}) {
    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final phoneCtrl = TextEditingController(text: editItem?.phone ?? '');
    final emailCtrl = TextEditingController(text: editItem?.email ?? '');
    final cityCtrl = TextEditingController(text: editItem?.city ?? 'Bhavnagar');
    final routeCtrl = TextEditingController(text: editItem?.assignedRoute ?? '');

    final formKey = GlobalKey<FormState>();
    String selectedRole = editItem?.role ?? (roleOptions.contains('Salesman') ? 'Salesman' : roleOptions.first);

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
      final prefix = getRolePrefix(role);
      final count = salesmenList.where((e) => e.role == role).length + (editItem != null && editItem.role == role ? 0 : 1);
      return "$prefix-${count.toString().padLeft(2, '0')}";
    }

    void showHistoryDialog() {
      showDialog(
        context: context,
        builder: (histCtx) => StatefulBuilder(
          builder: (context, setHistState) {
            final screenHeight = MediaQuery.of(context).size.height;

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
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(histCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    salesmenList.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text("No registered members found.", style: TextStyle(color: Colors.grey))),
                    )
                        : Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: salesmenList.length,
                          itemBuilder: (ctx, idx) {
                            final item = salesmenList[idx];
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Color(0xFFEADBCE),
                                          child: Icon(Icons.person, size: 20, color: _AdminPalette.primaryBrown),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${item.name} (${item.id})",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const SizedBox(height: 2),
                                              Text("Role: ${item.role} • Zone: ${item.city}", style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                              Text("Ph: ${item.phone} | ${item.email}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
                                                Navigator.pop(histCtx);
                                                Navigator.pop(context);
                                                _showSalesmenManagementModal(editItem: item);
                                              },
                                            ),
                                            IconButton(
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                              onPressed: () {
                                                setState(() {
                                                  salesmenList.removeAt(idx);
                                                });
                                                setHistState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Show assigned route in history list
                                    if (item.assignedRoute.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _AdminPalette.primaryBrown.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: _AdminPalette.primaryBrown.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.route, size: 14, color: _AdminPalette.primaryBrown),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "Route: ${item.assignedRoute}",
                                                style: const TextStyle(fontSize: 10, color: _AdminPalette.inkDark),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final String currentEmpId = generateEmpId(selectedRole);

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
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  editItem == null ? "Register New Salesman" : "Edit Salesman Profile",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: "View Registered Members List",
                                icon: const Icon(Icons.history, color: _AdminPalette.primaryBrown),
                                onPressed: showHistoryDialog,
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                          const Text("Employee ID:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AdminPalette.inkDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _AdminPalette.primaryBrown, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              currentEmpId,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
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
                              labelText: "Role Hierarchy",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
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
                              labelText: "Assigned City/Zone",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Assigned Route Field
                    TextFormField(
                      controller: routeCtrl,
                      decoration: InputDecoration(
                        labelText: "Assigned Route (e.g., Press Quarter -> Nari Chawkdi -> Shihor -> Palitana)",
                        hintText: "Enter assigned route for this salesman",
                        prefixIcon: const Icon(Icons.route, color: _AdminPalette.primaryBrown),
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
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              if (editItem != null) {
                                editItem.id = currentEmpId;
                                editItem.name = nameCtrl.text.trim();
                                editItem.phone = phoneCtrl.text.trim();
                                editItem.email = emailCtrl.text.trim();
                                editItem.city = cityCtrl.text.trim();
                                editItem.role = selectedRole;
                                editItem.assignedRoute = routeCtrl.text.trim();
                              } else {
                                salesmenList.add(
                                  SalesmanModel(
                                    id: currentEmpId,
                                    name: nameCtrl.text.trim(),
                                    role: selectedRole,
                                    city: cityCtrl.text.trim(),
                                    phone: phoneCtrl.text.trim(),
                                    email: emailCtrl.text.trim(),
                                    lastUpdated: "Just Now",
                                    assignedRoute: routeCtrl.text.trim(),
                                  ),
                                );
                              }
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          editItem == null ? "Register Member" : "Update Profile",
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

  // --- DELIVERY STATUS MODAL ---
  void _showDeliveryModal() {
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
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.local_shipping, color: Colors.orange),
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text("Delivery Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.shade100)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order #101", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("13 Jun, 11:13 PM", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Packed", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.shade100)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order #102", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("13 Jun, 11:13 PM", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Delivered", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AdminPalette.bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Box (Contains live Date & Time)
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
                                  const Text("Bhadra Foods", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: _AdminPalette.accentBadge, borderRadius: BorderRadius.circular(10)),
                                        child: const Text("Supplier", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AdminPalette.inkDark)),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(child: Text("Bhavnagar, Gujarat", style: TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Option Menu Button
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: _showOptionsMenu,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Date & Time Display Box in Top Header Box
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Statistics Counters Row (Positioned directly above Quick Actions)
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
                              onTap: () => _showSuperStockistModal(),
                              child: _buildBodyStat("${stockistList.length}", "Stockists", Icons.storefront, Colors.indigo),
                            ),
                          ),
                          Container(height: 30, width: 1, color: Colors.black12),
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
                              onTap: () => _showDeliveryModal(),
                              child: _buildBodyStat("$deliveryCount", "Deliveries", Icons.local_shipping_outlined, Colors.orange),
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
                        _buildActionCard("Super Stockist", Icons.storefront_outlined, Colors.indigo, _showSuperStockistModal),
                        _buildActionCard("Catalog", Icons.inventory_2_outlined, Colors.blue, _showCatalogModal),
                        _buildActionCard("Delivery", Icons.local_shipping_outlined, Colors.orange, _showDeliveryModal),
                        _buildActionCard("Live Map", Icons.map_outlined, Colors.teal, _showLiveTrackingModal),
                        _buildActionCard("Manage Team", Icons.manage_accounts_outlined, Colors.purple, () => _showSalesmenManagementModal()),
                        _buildActionCard("Manage Leave", Icons.time_to_leave_outlined, Colors.amber.shade800, _showLeaveManagementModal),
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