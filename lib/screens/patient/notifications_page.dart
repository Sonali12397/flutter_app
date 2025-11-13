import 'package:abc_app/models/notification_model.dart';
import 'package:abc_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no notifications.'));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              // Format the time (e.g., 10:30 AM)
              String formattedTime = DateFormat('h:mm a').format(notif.createdAt.toDate());

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  child: Icon(Icons.notifications_outlined, color: Colors.blue[800]),
                ),
                title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(notif.body),
                trailing: Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  if (notif.orderId != null) {
                    // TODO: Navigate to the order detail page for this order
                    print('Tapped notification for order: ${notif.orderId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}