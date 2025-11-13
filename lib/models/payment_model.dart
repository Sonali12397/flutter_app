import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String? id;
  final String orderId;
  final String userId;
  final String paymentMethod; // 'Razorpay', 'Cash on Delivery'
  final String status; // 'Pending', 'Success', 'Failed', 'Cancelled'
  final double amount;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;
  final String? failureReason;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  PaymentModel({
    this.id,
    required this.orderId,
    required this.userId,
    required this.paymentMethod,
    required this.status,
    required this.amount,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
    this.failureReason,
    required this.createdAt,
    this.updatedAt,
  });

  // To Firestore document
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'paymentMethod': paymentMethod,
      'status': status,
      'amount': amount,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
      'failureReason': failureReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // From Firestore document
  factory PaymentModel.fromSnapshot(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      status: data['status'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      razorpayPaymentId: data['razorpayPaymentId'],
      razorpayOrderId: data['razorpayOrderId'],
      razorpaySignature: data['razorpaySignature'],
      failureReason: data['failureReason'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }
}