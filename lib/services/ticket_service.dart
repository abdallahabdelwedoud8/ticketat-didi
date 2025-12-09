// Firebase Ticket Service Wrapper
// This provides backward compatibility for screens that used the old local ticket service

import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/firebase_ticket_service.dart';

class TicketService {
  // Purchase ticket
  static Future<TicketModel?> purchaseTicket(
    String userId,
    String eventId, {
    String? tierName,
    int quantity = 1,
  }) async {
    return await FirebaseTicketService.purchaseTicket(
      userId: userId,
      eventId: eventId,
      tierName: tierName,
      quantity: quantity,
    );
  }

  // Get user tickets
  static Future<List<TicketModel>> getUserTickets(String userId) async {
    return await FirebaseTicketService.getUserTickets(userId);
  }

  // Get active tickets
  static Future<List<TicketModel>> getActiveTickets(String userId) async {
    return await FirebaseTicketService.getActiveTickets(userId);
  }

  // Get used tickets
  static Future<List<TicketModel>> getUsedTickets(String userId) async {
    return await FirebaseTicketService.getUsedTickets(userId);
  }

  // Get past tickets
  static Future<List<TicketModel>> getPastTickets(String userId) async {
    return await FirebaseTicketService.getPastTickets(userId);
  }

  // Validate ticket
  static Future<bool> validateTicket(String barcodeData, String eventId) async {
    return await FirebaseTicketService.validateTicket(barcodeData, eventId);
  }

  // Get ticket by ID
  static Future<TicketModel?> getTicketById(String ticketId) async {
    return await FirebaseTicketService.getTicketById(ticketId);
  }

  // Get event tickets
  static Future<List<TicketModel>> getEventTickets(String eventId) async {
    return await FirebaseTicketService.getEventTickets(eventId);
  }

  // Get event analytics
  static Future<Map<String, dynamic>> getEventAnalytics(String eventId) async {
    return await FirebaseTicketService.getEventAnalytics(eventId);
  }

  // Get ticket by barcode
  static Future<TicketModel?> getTicketByBarcode(String barcodeData) async {
    return await FirebaseTicketService.getTicketByBarcode(barcodeData);
  }

  // Legacy method for backwards compatibility
  static Future<TicketModel?> getTicketByQR(String qrData) async {
    return await FirebaseTicketService.getTicketByBarcode(qrData);
  }

  // Mark ticket as used
  static Future<void> markTicketAsUsed(String ticketId) async {
    await FirebaseTicketService.markTicketAsUsed(ticketId);
  }
}
