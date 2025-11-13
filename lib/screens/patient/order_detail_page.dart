import 'package:abc_app/models/order_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abc_app/screens/patient/medicine_detail_page.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _cancelReasonController = TextEditingController();

  @override
  void dispose() {
    _cancelReasonController.dispose();
    super.dispose();
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order? Please provide a reason.'),
            const SizedBox(height: 16),
            TextField(
              controller: _cancelReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
            onPressed: () {
              if (_cancelReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }
              _firestoreService.updateOrderStatus(
                widget.order.id!,
                'Cancelled',
                widget.order.userId, // User ID for notification
                cancellationReason: _cancelReasonController.text.trim(),
              );
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back from detail page
            },
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    double _rating = 3.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was your order from ${widget.order.pharmacyName}?'),
            StatefulBuilder(
                builder: (context, setDialogState) {
                  return Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.round().toString(),
                    onChanged: (double value) {
                      setDialogState(() {
                        _rating = value;
                      });
                    },
                  );
                }
            ),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Write a review (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Submit'),
            onPressed: () {
              // TODO: Implement actual rating logic
              print("Rating submitted: $_rating stars");
              // _firestoreService.submitRating(...)
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMMM yyyy').format(widget.order.createdAt.toDate());
    bool canCancel = widget.order.status == 'Pending';
    bool isDelivered = widget.order.status == 'Delivered';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: #${widget.order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Placed on: $formattedDate', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),

            Text('Items (${widget.order.items.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return ListTile(
                  leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(item.medicineName),
                  subtitle: Text('Qty: ${item.quantity}'),
                  trailing: Text('Rs. ${(item.price * item.quantity).toStringAsFixed(2)}'),
                  onTap: () {
                    // This makes the medicine clickable, as you asked
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicineDetailPage(medicineId: item.medicineId),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),

            _buildSummaryRow('Subtotal', widget.order.subtotal),
            _buildSummaryRow('Shipping', widget.order.shipping),
            _buildSummaryRow('Total', widget.order.total, isTotal: true),
            const SizedBox(height: 24),

            Text('Shipping Address', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                  '${widget.order.shippingAddress.title}\n'
                      '${widget.order.shippingAddress.addressLine1}\n'
                      '${widget.order.shippingAddress.city}, ${widget.order.shippingAddress.stateRegion} ${widget.order.shippingAddress.postalCode}\n'
                      '${widget.order.shippingAddress.country}',
                  style: const TextStyle(fontSize: 16, height: 1.5)
              ),
            ),
            const SizedBox(height: 32),

            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showCancelDialog,
                  child: const Text('Cancel Order', style: TextStyle(fontSize: 16)),
                ),
              ),

            if (isDelivered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showFeedbackDialog,
                  child: const Text('Submit Feedback', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
          ],
        ),
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
}