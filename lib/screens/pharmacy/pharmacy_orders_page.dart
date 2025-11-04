import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

class PharmacyOrdersPage extends StatefulWidget {
  const PharmacyOrdersPage({super.key});

  @override
  State<PharmacyOrdersPage> createState() => _PharmacyOrdersPageState();
}

class _PharmacyOrdersPageState extends State<PharmacyOrdersPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _activeFilter = 'All Orders'; // 'All Orders', 'Pending', 'Shipped', 'Delivered', 'Cancelled'

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
      body: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getPharmacyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no orders.'));
          }

          final allOrders = snapshot.data!;

          int totalOrders = allOrders.length;
          int pendingOrders = allOrders.where((o) => o.status == 'Pending').length;
          int deliveredOrders = allOrders.where((o) => o.status == 'Delivered').length;

          final List<OrderModel> filteredOrders;
          if (_activeFilter == 'All Orders') {
            filteredOrders = allOrders;
          } else {
            filteredOrders = allOrders.where((o) => o.status == _activeFilter).toList();
          }

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
                child: ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderItem(context, filteredOrders[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int total, int pending, int delivered) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildSummaryCard('Total Orders', total.toString()),
          const SizedBox(width: 16),
          _buildSummaryCard('Pending Orders', pending.toString()),
          const SizedBox(width: 16),
          _buildSummaryCard('Delivered Orders', delivered.toString()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF), // Light blue background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: const Icon(Icons.cases_outlined, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey[700])),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
        items: ['All Orders', 'Pending', 'Shipped', 'Delivered', 'Cancelled']
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
      case 'Shipped': statusColor = Colors.blue; break;
      case 'Delivered': statusColor = Colors.green; break;
      case 'Cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Pharmacy Order Detail Page
        },
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
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
                      'Patient: ${order.shippingAddress.title}', // Using address title as name
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Order ID: #${order.id!.substring(0, 6)}...', // Show partial ID
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
