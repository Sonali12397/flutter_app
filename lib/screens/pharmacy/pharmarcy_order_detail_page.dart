import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cart_item_model.dart';

class PharmacyOrderDetailPage extends StatefulWidget {
  final OrderModel order;
  const PharmacyOrderDetailPage({super.key, required this.order});

  @override
  State<PharmacyOrderDetailPage> createState() => _PharmacyOrderDetailPageState();
}

class _PharmacyOrderDetailPageState extends State<PharmacyOrderDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedStatus;
  bool _isUpdating = false;
  late OrderModel _currentOrder; // Use a local copy that can be updated

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order; // Create a local copy
    _selectedStatus = _currentOrder.status;
  }

  Future<void> _updateOrderStatus() async {
    if (_selectedStatus == _currentOrder.status) return;

    setState(() => _isUpdating = true);

    try {
      // Fix: Pass all required arguments - check what your FirestoreService expects
      // If it only needs orderId and status, use this:
      // await _firestoreService.updateOrderStatus(_currentOrder.id!, _selectedStatus!);

      // If your FirestoreService needs pharmacyId as third parameter, use this instead:
      await _firestoreService.updateOrderStatus(_currentOrder.id!, _selectedStatus!, _currentOrder.pharmacyId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $_selectedStatus')),
      );

      // Update local order object - create a new instance instead of modifying final field
      setState(() {
        _currentOrder = OrderModel(
          id: _currentOrder.id,
          userId: _currentOrder.userId,
          pharmacyId: _currentOrder.pharmacyId,
          pharmacyName: _currentOrder.pharmacyName,
          items: _currentOrder.items,
          shippingAddress: _currentOrder.shippingAddress,
          subtotal: _currentOrder.subtotal,
          shipping: _currentOrder.shipping,
          total: _currentOrder.total,
          paymentMethod: _currentOrder.paymentMethod,
          status: _selectedStatus!, // Update the status here
          createdAt: _currentOrder.createdAt,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
      // Revert selection on error
      setState(() => _selectedStatus = _currentOrder.status);
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return 'FFA500'; // Orange
      case 'Confirmed': return '2196F3'; // Blue
      case 'Shipped': return 'FF9800'; // Deep Orange
      case 'Delivered': return '4CAF50'; // Green
      case 'Cancelled': return 'F44336'; // Red
      default: return '757575'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder; // Use the local copy
    String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toDate());
    String estimatedDelivery = DateFormat('dd MMM yyyy').format(
        order.createdAt.toDate().add(const Duration(days: 3))
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Header with order status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${_getStatusColor(order.status)}')).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Order #${order.id?.substring(0, 8) ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${_getStatusColor(order.status)}')),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Placed on $formattedDate',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Information
                  _buildSectionHeader('Customer Information'),
                  _buildInfoCard(
                    children: [
                      _buildInfoRow('Patient Name', order.shippingAddress.title),
                      _buildInfoRow('Contact', 'Not available'),
                      _buildInfoRow('Order Date', formattedDate),
                      _buildInfoRow('Estimated Delivery', estimatedDelivery),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Shipping Address
                  _buildSectionHeader('Shipping Address'),
                  _buildInfoCard(
                    children: [
                      Text(
                        '${order.shippingAddress.addressLine1}\n'
                            '${order.shippingAddress.addressLine2.isNotEmpty ? '${order.shippingAddress.addressLine2}\n' : ''}'
                            '${order.shippingAddress.city}, ${order.shippingAddress.stateRegion}\n'
                            '${order.shippingAddress.postalCode}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Order Items
                  _buildSectionHeader('Order Items (${order.items.length})'),
                  _buildInfoCard(
                    children: [
                      ...order.items.map((item) => _buildOrderItem(item)).toList(),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildSummaryRow('Subtotal', order.subtotal),
                      _buildSummaryRow('Shipping', order.shipping),
                      _buildSummaryRow('Total', order.total, isTotal: true),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Payment Information
                  _buildSectionHeader('Payment Information'),
                  _buildInfoCard(
                    children: [
                      _buildInfoRow('Payment Method', order.paymentMethod),
                      _buildInfoRow('Payment Status', 'Paid'),
                      _buildInfoRow('Total Amount', '₹${order.total.toStringAsFixed(2)}'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Update Status Section
                  _buildSectionHeader('Update Order Status'),
                  _buildInfoCard(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Order Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                          DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                          DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                          DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: _isUpdating ? null : (value) {
                          setState(() => _selectedStatus = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdating || _selectedStatus == order.status
                              ? null
                              : _updateOrderStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isUpdating
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Update Status',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicineName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}