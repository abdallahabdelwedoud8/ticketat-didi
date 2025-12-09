// Firebase Event Service Wrapper
// This provides backward compatibility for screens that used the old local event service

import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/firebase_event_service.dart';

class EventService {
  // Get all events
  static Future<List<EventModel>> getAllEvents() async {
    return await FirebaseEventService.getAllEvents();
  }

  // Get event by ID
  static Future<EventModel?> getEventById(String eventId) async {
    return await FirebaseEventService.getEventById(eventId);
  }

  // Get events by category
  static Future<List<EventModel>> getEventsByCategory(String category) async {
    return await FirebaseEventService.getEventsByCategory(category);
  }

  // Search events
  static Future<List<EventModel>> searchEvents(String query) async {
    return await FirebaseEventService.searchEvents(query);
  }

  // Create event
  static Future<void> createEvent(EventModel event) async {
    await FirebaseEventService.createEvent(event);
  }

  // Update event
  static Future<void> updateEvent(EventModel event) async {
    await FirebaseEventService.updateEvent(event);
  }

  // Delete event
  static Future<void> deleteEvent(String eventId) async {
    await FirebaseEventService.deleteEvent(eventId);
  }

  // Get recommendations
  static Future<List<EventModel>> getRecommendations(List<String> userCategories) async {
    return await FirebaseEventService.getRecommendations(userCategories);
  }

  // Get sponsored events
  static Future<List<EventModel>> getSponsoredEvents() async {
    return await FirebaseEventService.getSponsoredEvents();
  }

  // Get all providers
  static Future<List<ProviderModel>> getAllProviders() async {
    return await FirebaseEventService.getAllProviders();
  }

  // Get providers by service
  static Future<List<ProviderModel>> getProvidersByService(String serviceType) async {
    return await FirebaseEventService.getProvidersByService(serviceType);
  }

  // Generate private event code
  static String generatePrivateEventCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var seed = random;

    for (var i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      code += chars[seed % chars.length];
    }

    return code;
  }

  // Get event by private code
  static Future<EventModel?> getEventByPrivateCode(String code) async {
    final allEvents = await getAllEvents();
    try {
      return allEvents.firstWhere((e) => e.privateEventCode == code);
    } catch (e) {
      return null;
    }
  }

  // Track private event view
  static Future<void> trackPrivateEventView(String eventId, bool fromQRScan) async {
    final event = await getEventById(eventId);
    if (event == null) return;

    final updatedEvent = event.copyWith(
      qrScans: fromQRScan ? event.qrScans + 1 : event.qrScans,
      linkClicks: !fromQRScan ? event.linkClicks + 1 : event.linkClicks,
    );

    await updateEvent(updatedEvent);
  }

  // Get public events
  static Future<List<EventModel>> getPublicEvents() async {
    final allEvents = await getAllEvents();
    return allEvents.where((e) => !e.isPrivate).toList();
  }
}
