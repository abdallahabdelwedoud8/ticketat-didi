// Firebase Payment Service Wrapper
// This provides backward compatibility for screens that used the old local payment service

import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/firebase_payment_service.dart';

class PaymentService {
  // Create payment proof
  static Future<PaymentProof> createPaymentProof({
    required String ticketId,
    required PaymentMethod method,
    String? screenshotUrl,
    String? senderNumber,
    String? transactionReference,
  }) async {
    return await FirebasePaymentService.createPaymentProof(
      ticketId: ticketId,
      method: method,
      screenshotUrl: screenshotUrl,
      senderNumber: senderNumber,
      transactionReference: transactionReference,
    );
  }

  // Get pending payments
  static Future<List<PaymentProof>> getPendingPayments() async {
    return await FirebasePaymentService.getPendingPayments();
  }

  // Verify payment
  static Future<void> verifyPayment(String paymentId) async {
    await FirebasePaymentService.verifyPayment(paymentId);
  }

  // Reject payment
  static Future<void> rejectPayment(String paymentId) async {
    await FirebasePaymentService.rejectPayment(paymentId);
  }

  // Get payment by ticket ID
  static Future<PaymentProof?> getPaymentByTicketId(String ticketId) async {
    return await FirebasePaymentService.getPaymentByTicketId(ticketId);
  }
}
