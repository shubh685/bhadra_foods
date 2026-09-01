import 'package:bhad_foods/Log_In.dart';
import 'package:flutter/material.dart';

class SuperStockistPortal extends StatefulWidget {
  const SuperStockistPortal({super.key});

  @override
  State<SuperStockistPortal> createState() => _SuperStockistPortalState();
}

class _SuperStockistPortalState extends State<SuperStockistPortal> {
  int _currentIndex = 0;

  // Exact Color Tokens Extracted from the Design Image
  static const Color primaryBrown = Color(0xFF5C3317);
  static const Color darkBrown = Color(0xFF4A2810);
  static const Color bgWarm = Color(0xFFFAF4E8);
  static const Color cardCream = Color(0xFFF5EBE0);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentRed = Color(0xFFC62828);
  static const Color textDark = Color(0xFF3E2723);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgWarm,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: primaryBrown,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Super Stockist Portal",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Bhad Foods • Depot West Zone",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.amber),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'catalog') {
                _showProductCatalogDialog(context);
              } else if (value == 'profile') {
                _showProfileDialog(context);
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'catalog',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: primaryBrown),
                    SizedBox(width: 10),
                    Text('View Product Catalog'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined, color: primaryBrown),
                    SizedBox(width: 10),
                    Text('Super Stockist Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: accentRed),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: accentRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildOverviewTab(),
          _buildInventoryTab(),
          _buildDistributorTab(),
          _buildDispatchTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBrown,
        unselectedItemColor: Colors.brown.shade300,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Overview",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse_outlined),
            activeIcon: Icon(Icons.warehouse),
            label: "Warehouse",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: "Distributors",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: "Dispatches",
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DEPOT OVERVIEW (KPIs + Alerts)
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Total Depot Valuation",
                value: "₹ 48.50 Lakh",
                subtitle: "+12.4% from last month",
                icon: Icons.account_balance_wallet_outlined,
                accentColor: accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Pending Dispatches",
                value: "14 Trucks",
                subtitle: "8 Distributors Waiting",
                icon: Icons.local_shipping_outlined,
                accentColor: primaryBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Primary Factory Order",
                value: "₹ 12.20 Lakh",
                subtitle: "ETA: Tomorrow 10 AM",
                icon: Icons.factory_outlined,
                accentColor: darkBrown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Credit Overdue Alert",
                value: "₹ 3.10 Lakh",
                subtitle: "3 Distributors Locked",
                icon: Icons.warning_amber_rounded,
                accentColor: accentRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Stock Replenishment & Expiry Warning",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 10),
        _buildAlertTile(
          skuName: "Premium Basmati Rice 5kg",
          batchNo: "BATCH-2026-X89",
          status: "Below Safety Buffer (12 Cases Left)",
          statusColor: accentRed,
          actionText: "Order Factory Stock",
        ),
        _buildAlertTile(
          skuName: "Sunflower Refined Oil 1L",
          batchNo: "BATCH-2026-A12",
          status: "Expires in 28 Days (45 Cases)",
          statusColor: Colors.orange.shade900,
          actionText: "Push Discount Scheme",
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: WAREHOUSE INVENTORY CONTROL
  // ---------------------------------------------------------------------------
  Widget _buildInventoryTab() {
    final List<Map<String, dynamic>> stockData = [
      {
        "sku": "Basmati Rice 5kg",
        "category": "Grains",
        "stock": "450 Cases",
        "valuation": "₹ 6,75,000",
        "buffer": 0.85
      },
      {
        "sku": "Sunflower Oil 1L",
        "category": "Edible Oils",
        "stock": "120 Cases",
        "valuation": "₹ 2,16,000",
        "buffer": 0.30
      },
      {
        "sku": "Spiced Masala Mix 100g",
        "category": "Spices",
        "stock": "800 Cases",
        "valuation": "₹ 4,80,000",
        "buffer": 0.92
      },
      {
        "sku": "Whole Wheat Flour 10kg",
        "category": "Atta",
        "stock": "50 Cases",
        "valuation": "₹ 1,10,000",
        "buffer": 0.15
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stockData.length,
      itemBuilder: (context, index) {
        final item = stockData[index];
        final double buffer = item["buffer"];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: cardCream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item["sku"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryBrown.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item["category"],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("In-Stock: ${item['stock']}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                  Text("Value: ${item['valuation']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBrown)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: buffer,
                  minHeight: 6,
                  backgroundColor: Colors.brown.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    buffer < 0.25
                        ? accentRed
                        : buffer < 0.5
                        ? Colors.orange.shade800
                        : accentGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: DISTRIBUTOR & CREDIT LEDGER
  // ---------------------------------------------------------------------------
  Widget _buildDistributorTab() {
    final List<Map<String, dynamic>> distributors = [
      {
        "name": "Mahavir Enterprises",
        "route": "North Zone - Beat A",
        "creditLimit": "₹ 5,00,000",
        "usedCredit": "₹ 4,20,000",
        "status": "Warning",
        "isLocked": false
      },
      {
        "name": "Shree Trades & Logistics",
        "route": "West Zone - Beat C",
        "creditLimit": "₹ 10,00,000",
        "usedCredit": "₹ 10,50,000",
        "status": "Locked",
        "isLocked": true
      },
      {
        "name": "Apex Food Agencies",
        "route": "Central City - Beat B",
        "creditLimit": "₹ 3,00,000",
        "usedCredit": "₹ 1,10,000",
        "status": "Active",
        "isLocked": false
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: distributors.length,
      itemBuilder: (context, index) {
        final dist = distributors[index];
        final bool isLocked = dist["isLocked"];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardCream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            shape: const Border(),
            title: Text(
              dist["name"],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
            ),
            subtitle: Text("${dist['route']} | Limit: ${dist['creditLimit']}",
                style: TextStyle(fontSize: 12, color: textDark.withOpacity(0.7))),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLocked
                    ? accentRed.withOpacity(0.15)
                    : dist["status"] == "Warning"
                    ? Colors.orange.withOpacity(0.15)
                    : accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dist["status"],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isLocked
                      ? accentRed
                      : dist["status"] == "Warning"
                      ? Colors.orange.shade900
                      : accentGreen,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Outstanding Balance:", style: TextStyle(fontSize: 13)),
                        Text(
                          dist["usedCredit"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isLocked ? accentRed : textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: primaryBrown),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.receipt_long, size: 16, color: primaryBrown),
                            label: const Text("View Ledger", style: TextStyle(color: primaryBrown)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLocked ? accentGreen : accentRed,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {},
                            icon: Icon(isLocked ? Icons.lock_open : Icons.block, size: 16, color: Colors.white),
                            label: Text(
                              isLocked ? "Unlock Limit" : "Freeze Dispatch",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: PRIMARY PURCHASE & DISPATCH OPERATIONS
  // ---------------------------------------------------------------------------
  Widget _buildDispatchTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            minimumSize: const Size(double.infinity, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {},
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: const Text(
            "Raise Primary PO to Factory Plant",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Outbound Delivery Challans (Secondary Sales)",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
        ),
        const SizedBox(height: 10),
        _buildDispatchCard(
          challanNo: "CHNL-2026-9041",
          distributor: "Mahavir Enterprises",
          itemsCount: "120 Cases (4 SKUs)",
          amount: "₹ 1,84,000",
          status: "Loading Vehicle",
          statusColor: Colors.orange.shade900,
        ),
        _buildDispatchCard(
          challanNo: "CHNL-2026-9038",
          distributor: "Apex Food Agencies",
          itemsCount: "45 Cases (2 SKUs)",
          amount: "₹ 62,500",
          status: "In-Transit",
          statusColor: primaryBrown,
        ),
        _buildDispatchCard(
          challanNo: "CHNL-2026-9022",
          distributor: "Kisan Provision Depot",
          itemsCount: "310 Cases (8 SKUs)",
          amount: "₹ 4,12,000",
          status: "Delivered & Signed",
          statusColor: accentGreen,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 11, color: textDark.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: textDark.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildAlertTile({
    required String skuName,
    required String batchNo,
    required String status,
    required Color statusColor,
    required String actionText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(skuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
        subtitle: Text("$batchNo\n$status", style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
        isThreeLine: true,
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBrown,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () {},
          child: Text(actionText, style: const TextStyle(fontSize: 11, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDispatchCard({
    required String challanNo,
    required String distributor,
    required String itemsCount,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(challanNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBrown)),
              Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor)),
            ],
          ),
          const Divider(height: 16, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(distributor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark)),
                  Text(itemsCount, style: TextStyle(fontSize: 11, color: textDark.withOpacity(0.6))),
                ],
              ),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
            ],
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OPTION MENU DIALOGS (Product Catalog, Personal Info, Logout)
  // ---------------------------------------------------------------------------
  void _showProductCatalogDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Product Master Catalog",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const Text("Master price list & wholesale stock rates", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildCatalogItem("Basmati Rice 5kg", "Grains", "₹ 1,500 / Case", "12 Units/Case"),
                        _buildCatalogItem("Sunflower Oil 1L", "Edible Oils", "₹ 1,800 / Case", "15 Units/Case"),
                        _buildCatalogItem("Spiced Masala 100g", "Spices", "₹ 600 / Case", "24 Units/Case"),
                        _buildCatalogItem("Wheat Flour 10kg", "Atta", "₹ 2,200 / Case", "5 Units/Case"),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogItem(String name, String category, String price, String packing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: const CircleAvatar(
          backgroundColor: primaryBrown,
          child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("$category • $packing"),
        trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBrown, fontSize: 13)),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgWarm,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.badge, color: primaryBrown),
              SizedBox(width: 10),
              Text("Super Stockist Profile", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardCream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryBrown,
                        child: Text("SS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 10),
                      Text("Bhad Foods Super Stockist", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                      Text("ID: SS-WEST-2026-09", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileDetailRow("Hub Location:", "Bhavnagar Depot"),
                _buildProfileDetailRow("Assigned Region:", "West Zone-1"),
                _buildProfileDetailRow("GSTIN Number:", "24AAACB1234F1Z2"),
                _buildProfileDetailRow("Contact Phone:", "+91 98765 43210"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgWarm,
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to exit the Super Stockist Portal?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentRed),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}