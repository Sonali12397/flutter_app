import 'package:abc_app/models/address_model.dart';
import 'package:abc_app/models/cart_model.dart';
import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:abc_app/screens/patient/my_orders_page.dart';
import 'package:abc_app/screens/patient/saved_addresses_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double subtotal;
  final double shipping;
  final double total;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.shipping,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedAddressId;
  List<AddressModel> _availableAddresses = [];
  String _selectedPaymentMethod = 'Razorpay';
  bool _isLoading = false;

  Future<void> _placeOrder() async {
    final AddressModel? selectedAddress;
    try {
      selectedAddress = _availableAddresses.firstWhere((a) => a.id == _selectedAddressId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (widget.cartItems.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Get the user ID directly from FirebaseAuth.instance
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || currentUserId.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in. Please restart the app.')),
      );
      return;
    }

    // This is where the error was happening.
    // If your data is fixed, this will now work.
    final String pharmacyId = widget.cartItems.first.pharmacyId;
    final String pharmacyName = widget.cartItems.first.pharmacyName;

    if (pharmacyId.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not find pharmacy. Please re-add items to cart.')),
      );
      return;
    }

    final order = OrderModel(
      userId: currentUserId,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      items: widget.cartItems,
      shippingAddress: selectedAddress!,
      subtotal: widget.subtotal,
      shipping: widget.shipping,
      total: widget.total,
      paymentMethod: _selectedPaymentMethod,
      status: 'Pending',
      createdAt: Timestamp.now(),
    );

    try {
      await _firestoreService.placeOrder(order);

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyOrdersPage()),
            (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Shipping Address Section ---
                  const Text(
                    'Shipping Address',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAddressSelector(),
                  const SizedBox(height: 32),
                  // --- Payment Method Section ---
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethodOption('Razorpay'),
                  _buildPaymentMethodOption('Cash on Delivery'),
                  const SizedBox(height: 32),
                  // --- Order Summary Section ---
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Subtotal (${widget.cartItems.length} items)', widget.subtotal),
                  _buildSummaryRow('Shipping', widget.shipping),
                  const Divider(height: 24),
                  _buildSummaryRow('Total', widget.total, isTotal: true),
                ],
              ),
            ),
          ),
          // --- Bottom Button ---
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildAddressSelector() {
    return StreamBuilder<List<AddressModel>>(
      stream: _firestoreService.getAddresses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        _availableAddresses = snapshot.data ?? [];
        if (_availableAddresses.isEmpty) {
          return Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedAddressesPage()));
              },
              child: const Text('No addresses found. Add one now.'),
            ),
          );
        }
        if (_selectedAddressId == null || !_availableAddresses.any((a) => a.id == _selectedAddressId)) {
          _selectedAddressId = _availableAddresses
              .firstWhere((a) => a.isDefault, orElse: () => _availableAddresses.first)
              .id;
        }
        return DropdownButtonFormField<String>(
          value: _selectedAddressId,
          decoration: InputDecoration(
            labelText: 'Select Address',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: _availableAddresses.map((address) {
            return DropdownMenuItem<String>(
              value: address.id,
              child: Text('${address.title}: ${address.addressLine1}', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedAddressId = newValue;
            });
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodOption(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile<String>(
        title: Text(title),
        value: title,
        groupValue: _selectedPaymentMethod,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedPaymentMethod = value;
            });
          }
        },
        activeColor: Colors.blue[800],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              color: Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              color: Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isLoading ? null : _placeOrder,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            'Continue to Payment',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
