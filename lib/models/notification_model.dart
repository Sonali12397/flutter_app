import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String userId; // The user who receives this
  final String title;
  final String body;
  final Timestamp createdAt;
  final bool isRead;
  final String? orderId; // Optional: link to an order

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
  });

  // From Firestore
  factory NotificationModel.fromMap(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      body: data['body'],
      createdAt: data['createdAt'],
      isRead: data['isRead'],
      orderId: data['orderId'],
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': createdAt,
      'isRead': isRead,
      'orderId': orderId,
    };
  }
}