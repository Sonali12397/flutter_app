import 'package:abc_app/models/user_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPharmacyEarnings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return _buildEarningsContent(snapshot.data!.docs, firestoreService);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading earnings...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading earnings',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No earnings yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your earnings will appear here once you complete orders',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsContent(List<QueryDocumentSnapshot> earningsDocs, FirestoreService firestoreService) {
    // Calculate totals
    final earningsData = _calculateEarningsData(earningsDocs);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(firestoreService),
            const SizedBox(height: 24),
            _buildOverallStats(earningsData['totalEarnings']!, earningsData['ordersDelivered']!),
            const SizedBox(height: 24),
            const Text(
              'This Week',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildThisWeekStats(earningsData['thisWeekEarnings']!, earningsData['thisWeekOrders']!),
            const SizedBox(height: 24),
            const Text(
              'Recent Earnings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRecentEarningsList(earningsDocs),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateEarningsData(List<QueryDocumentSnapshot> earningsDocs) {
    double totalEarnings = 0;
    double thisWeekEarnings = 0;
    int ordersDelivered = 0;
    int thisWeekOrders = 0;

    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);

    for (var doc in earningsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'Completed') {
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalEarnings += amount;
        ordersDelivered++;

        final createdAt = (data['createdAt'] as Timestamp).toDate();
        if (createdAt.isAfter(startOfWeek)) {
          thisWeekEarnings += amount;
          thisWeekOrders++;
        }
      }
    }

    return {
      'totalEarnings': totalEarnings,
      'thisWeekEarnings': thisWeekEarnings,
      'ordersDelivered': ordersDelivered.toDouble(),
      'thisWeekOrders': thisWeekOrders.toDouble(),
    };
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Handle Sunday (weekday == 7)
    final daysToSubtract = date.weekday == 7 ? 0 : date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  Widget _buildProfileHeader(FirestoreService firestoreService) {
    return StreamBuilder<UserModel>(
      stream: firestoreService.getCurrentUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) return const SizedBox();

        final user = snapshot.data!;
        final displayName = user.pharmacyName ?? user.name;
        final profileImageUrl = user.profileImageUrl;
        bool hasImage = profileImageUrl.isNotEmpty;

        return Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: hasImage ? NetworkImage(profileImageUrl) : null,
                child: !hasImage
                    ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'ID: ${user.uid.substring(0, 8)}...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallStats(double totalEarnings, double ordersDelivered) {
    return Column(
      children: [
        Row(
          children: [
            // ***** FIX HERE *****
            Expanded(
              child: _buildStatCard(
                'Total Earnings',
                'Rs ${totalEarnings.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green[50]!,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            // ***** FIX HERE *****
            Expanded(
              child: _buildStatCard(
                'Orders Delivered',
                ordersDelivered.toInt().toString(),
                Icons.shopping_bag,
                Colors.blue[50]!,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Average per Order',
          // Add check for division by zero
          (ordersDelivered > 0) ? 'Rs ${(totalEarnings / ordersDelivered).toStringAsFixed(0)}' : 'Rs 0',
          Icons.trending_up,
          Colors.orange[50]!,
          Colors.orange,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildThisWeekStats(double thisWeekEarnings, double thisWeekOrders) {
    return Column(
      children: [
        Row(
          children: [
            // ***** FIX HERE *****
            Expanded(
              child: _buildStatCard(
                'Weekly Earnings',
                'Rs ${thisWeekEarnings.toStringAsFixed(0)}',
                Icons.weekend,
                Colors.purple[50]!,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            // ***** FIX HERE *****
            Expanded(
              child: _buildStatCard(
                'Weekly Orders',
                thisWeekOrders.toInt().toString(),
                Icons.local_shipping,
                Colors.teal[50]!,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color backgroundColor, Color iconColor, {bool isFullWidth = false}) {
    return Container(
      // The width: null (when isFullWidth is false) is fine *because*
      // we wrapped this widget in an Expanded in the functions above.
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEarningsList(List<QueryDocumentSnapshot> docs) {
    final completedEarnings = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'Completed';
    }).toList();

    if (completedEarnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No completed orders yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final recentEarnings = completedEarnings.length > 5
        ? completedEarnings.sublist(0, 5)
        : completedEarnings;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...recentEarnings.map((doc) => _buildEarningListItem(doc)),
          if (completedEarnings.length > 5)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Showing 5 of ${completedEarnings.length} earnings',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEarningListItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final orderId = (data['orderId'] as String?) ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final formattedDate = DateFormat('MMM dd, yyyy - HH:mm').format(createdAt);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        ),
        title: const Text(
          'Order Completed',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: #${orderId.length > 6 ? orderId.substring(0, 6) : orderId}'),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                fontSize: 16,
              ),
            ),
            Text(
              'Completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}