import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventide/models/app_models.dart';
import 'package:flutter/foundation.dart';

class FirebasePaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _paymentsCollection => _firestore.collection('payments');

  // Create payment proof
  static Future<PaymentProof> createPaymentProof({
    required String ticketId,
    required PaymentMethod method,
    String? screenshotUrl,
    String? senderNumber,
    String? transactionReference,
  }) async {
    try {
      final now = DateTime.now();
      final payment = PaymentProof(
        paymentId: 'pay_${now.millisecondsSinceEpoch}',
        ticketId: ticketId,
        method: method,
        screenshotUrl: screenshotUrl,
        senderNumber: senderNumber,
        transactionReference: transactionReference,
        status: PaymentStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await _paymentsCollection.doc(payment.paymentId).set(payment.toJson());
      return payment;
    } catch (e) {
      if (kDebugMode) print('Error creating payment proof: $e');
      rethrow;
    }
  }

  // Get pending payments
  static Future<List<PaymentProof>> getPendingPayments() async {
    try {
      final snapshot = await _paymentsCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        return PaymentProof.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'paymentId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching pending payments: $e');
      return [];
    }
  }

  // Verify payment
  static Future<void> verifyPayment(String paymentId) async {
    try {
      await _paymentsCollection.doc(paymentId).update({
        'status': 'verified',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error verifying payment: $e');
      rethrow;
    }
  }

  // Reject payment
  static Future<void> rejectPayment(String paymentId) async {
    try {
      await _paymentsCollection.doc(paymentId).update({
        'status': 'rejected',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error rejecting payment: $e');
      rethrow;
    }
  }

  // Get payment by ticket ID
  static Future<PaymentProof?> getPaymentByTicketId(String ticketId) async {
    try {
      final snapshot = await _paymentsCollection
          .where('ticketId', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PaymentProof.fromJson({
        ...snapshot.docs.first.data() as Map<String, dynamic>,
        'paymentId': snapshot.docs.first.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching payment by ticket ID: $e');
      return null;
    }
  }

  // Get payment by ID
  static Future<PaymentProof?> getPaymentById(String paymentId) async {
    try {
      final doc = await _paymentsCollection.doc(paymentId).get();
      if (!doc.exists) return null;

      return PaymentProof.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'paymentId': doc.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching payment: $e');
      return null;
    }
  }

  // Get all payments (admin/organizer)
  static Future<List<PaymentProof>> getAllPayments({int limit = 100}) async {
    try {
      final snapshot = await _paymentsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return PaymentProof.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'paymentId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching all payments: $e');
      return [];
    }
  }

  // Get verified payments
  static Future<List<PaymentProof>> getVerifiedPayments({int limit = 100}) async {
    try {
      final snapshot = await _paymentsCollection
          .where('status', isEqualTo: 'verified')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return PaymentProof.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'paymentId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching verified payments: $e');
      return [];
    }
  }

  // Get rejected payments
  static Future<List<PaymentProof>> getRejectedPayments({int limit = 50}) async {
    try {
      final snapshot = await _paymentsCollection
          .where('status', isEqualTo: 'rejected')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return PaymentProof.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'paymentId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching rejected payments: $e');
      return [];
    }
  }
}
