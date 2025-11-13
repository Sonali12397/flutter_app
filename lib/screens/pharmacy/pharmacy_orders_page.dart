import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/screens/pharmacy/pharmarcy_order_detail_page.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

class PharmacyOrdersPage extends StatefulWidget {
  const PharmacyOrdersPage({super.key});

  @override
  State<PharmacyOrdersPage> createState() => _PharmacyOrdersPageState();
}

class _PharmacyOrdersPageState extends State<PharmacyOrdersPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _activeFilter = 'All Orders';
  bool _hasIndexError = false;

  @override
  void initState() {
    super.initState();
    _checkIndex();
  }

  Future<void> _checkIndex() async {
    final indexExists = await _firestoreService.checkAndCreateIndex();
    if (!indexExists) {
      setState(() {
        _hasIndexError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _hasIndexError
          ? _buildIndexErrorWidget()
          : StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getPharmacyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('index')) {
              return _buildIndexErrorWidget();
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyOrdersWidget();
          }

          return _buildOrdersList(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildIndexErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Database Setup Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature requires a database index to be set up. '
                  'Please contact support or try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _hasIndexError = false;
                _checkIndex();
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> allOrders) {
    final int totalOrders = allOrders.length;
    final int pendingOrders = allOrders.where((o) => o.status == 'Pending').length;
    final int deliveredOrders = allOrders.where((o) => o.status == 'Delivered').length;

    final List<OrderModel> filteredOrders = _activeFilter == 'All Orders'
        ? allOrders
        : allOrders.where((o) => o.status == _activeFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCards(totalOrders, pendingOrders, deliveredOrders),
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        _buildFilterDropdown(),
        Expanded(
          child: filteredOrders.isEmpty
              ? _buildNoFilteredOrdersWidget()
              : ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              return _buildOrderItem(context, filteredOrders[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoFilteredOrdersWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No $_activeFilter found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Keep your existing helper methods (_buildSummaryCards, _buildSummaryCard,
  // _buildFilterDropdown, _buildOrderItem) as they are
  Widget _buildSummaryCards(int total, int pending, int delivered) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildSummaryCard('Total Orders', total.toString(), Colors.blue),
          const SizedBox(width: 16),
          _buildSummaryCard('Pending Orders', pending.toString(), Colors.orange),
          const SizedBox(width: 16),
          _buildSummaryCard('Delivered Orders', delivered.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.cases_outlined, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _activeFilter,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: ['All Orders', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled']
            .map((status) => DropdownMenuItem(
          value: status,
          child: Text(status),
        ))
            .toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _activeFilter = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderModel order) {
    Color statusColor;
    switch(order.status) {
      case 'Pending': statusColor = Colors.orange; break;
      case 'Confirmed': statusColor = Colors.blue; break;
      case 'Shipped': statusColor = Colors.deepOrange; break;
      case 'Delivered': statusColor = Colors.green; break;
      case 'Cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacyOrderDetailPage(order: order),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue[50],
                child: const Icon(Icons.person_outline, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.shippingAddress.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${order.id?.substring(0, 8) ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${order.total.toStringAsFixed(2)} • ${order.items.length} items',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}