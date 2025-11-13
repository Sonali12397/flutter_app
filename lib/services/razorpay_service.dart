import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  // --- Keys for your college project ---
  // Key ID is public and safe.
  final String keyId = 'rzp_test_kBoKUUZjcxQZ79';

  // WARNING: This is your secret key.
  // This is NOT safe for a real app, but will make it work
  // for your project without a backend server.
  final String keySecret = '4D2rXkBiNC3P2hMjJIgguhDW';
  // ---

  // Callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (onSuccess != null) {
      onSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (onFailure != null) {
      onFailure!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  /// --- THIS IS THE FIXED FUNCTION ---
  /// It creates a Razorpay Order by calling the Razorpay API directly
  /// from Flutter. This fixes the 404 error.
  Future<Map<String, dynamic>?> createRazorpayOrder(double amount) async {
    // This is the direct Razorpay API URL
    const String razorpayApiUrl = 'https://api.razorpay.com/v1/orders';

    try {
      final int amountInPaise = (amount * 100).toInt();

      // We use Basic Authentication, which is just 'username:password'
      // encoded in Base64. For Razorpay, it's 'key_id:key_secret'.
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';

      // This is the HTTP request to Razorpay's server
      final response = await http.post(
        Uri.parse(razorpayApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth, // Here is our key:secret
        },
        body: jsonEncode({
          'amount': amountInPaise,
          'currency': 'INR',
          'receipt': 'receipt_project_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success! Razorpay returns the order data.
        final orderData = jsonDecode(response.body);
        print('Razorpay order created directly: ${orderData['id']}');
        return orderData;
      } else {
        // If Razorpay gives an error (e.g., wrong keys)
        print('Failed to create order. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      print('Error calling createRazorpayOrder: $e');
      return null; // Return null on failure
    }
  }

  /// This function opens the checkout UI.
  /// Your code for this was already correct.
  void openCheckout({
    required double amount,
    required String orderId,
    required String name,
    required String email,
    required String contact,
  }) {
    final options = {
      'key': keyId, // Your public Key ID
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Urmedio', // Your app name
      'description': 'Order Payment',
      'order_id': orderId, // The ID from createRazorpayOrder
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'theme': {'color': '#007BFF'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}