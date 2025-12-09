import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:eventide/models/app_models.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class FirebaseEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  static CollectionReference get _eventsCollection => _firestore.collection('events');
  static CollectionReference get _providersCollection => _firestore.collection('providers');

  // Create Event
  static Future<void> createEvent(EventModel event) async {
    try {
      await _eventsCollection.doc(event.eventId).set(event.toJson());
    } catch (e) {
      if (kDebugMode) print('Error creating event: $e');
      rethrow;
    }
  }

  // Get Event by ID
  static Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (!doc.exists) return null;
      
      return EventModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'eventId': doc.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching event: $e');
      return null;
    }
  }

  // Get All Events
  static Future<List<EventModel>> getAllEvents() async {
    try {
      final snapshot = await _eventsCollection.orderBy('date', descending: false).limit(100).get();
      
      return snapshot.docs.map((doc) {
        return EventModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'eventId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching events: $e');
      return [];
    }
  }

  // Get Events by Category
  static Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      if (category == 'All') return getAllEvents();
      
      final snapshot = await _eventsCollection
          .where('category', isEqualTo: category)
          .orderBy('date', descending: false)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) {
        return EventModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'eventId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching events by category: $e');
      return [];
    }
  }

  // Search Events
  static Future<List<EventModel>> searchEvents(String query) async {
    try {
      // Note: For better search, consider using Algolia or similar service
      // This is a basic implementation that fetches all and filters locally
      final allEvents = await getAllEvents();
      final lowerQuery = query.toLowerCase();
      
      return allEvents.where((event) =>
        event.title.toLowerCase().contains(lowerQuery) ||
        event.description.toLowerCase().contains(lowerQuery) ||
        event.venue.toLowerCase().contains(lowerQuery)
      ).toList();
    } catch (e) {
      if (kDebugMode) print('Error searching events: $e');
      return [];
    }
  }

  // Update Event
  static Future<void> updateEvent(EventModel event) async {
    try {
      await _eventsCollection.doc(event.eventId).update(
        event.copyWith(updatedAt: DateTime.now()).toJson()
      );
    } catch (e) {
      if (kDebugMode) print('Error updating event: $e');
      rethrow;
    }
  }

  // Delete Event
  static Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting event: $e');
      rethrow;
    }
  }

  // Get Sponsored Events
  static Future<List<EventModel>> getSponsoredEvents() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      
      final snapshot = await _eventsCollection
          .where('isSponsored', isEqualTo: true)
          .where('date', isGreaterThan: now)
          .orderBy('date', descending: false)
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) {
        return EventModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'eventId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching sponsored events: $e');
      return [];
    }
  }

  // Get Organizer Events
  static Future<List<EventModel>> getOrganizerEvents(String organizerId) async {
    try {
      final snapshot = await _eventsCollection
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('date', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) {
        return EventModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'eventId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching organizer events: $e');
      return [];
    }
  }

  // Get Event Recommendations based on user preferences
  static Future<List<EventModel>> getRecommendations(List<String> userCategories) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      
      if (userCategories.isEmpty) {
        // Return popular upcoming events
        final snapshot = await _eventsCollection
            .where('date', isGreaterThan: now)
            .orderBy('date', descending: false)
            .orderBy('soldTickets', descending: true)
            .limit(5)
            .get();
        
        return snapshot.docs.map((doc) {
          return EventModel.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'eventId': doc.id,
          });
        }).toList();
      }
      
      // Get events in user's preferred categories
      final allEvents = await getAllEvents();
      final upcomingEvents = allEvents.where((e) => e.date.isAfter(DateTime.now())).toList();
      final recommended = upcomingEvents.where((e) => userCategories.contains(e.category)).toList();
      
      recommended.sort((a, b) => b.soldTickets.compareTo(a.soldTickets));
      return recommended.take(5).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching recommendations: $e');
      return [];
    }
  }

  // ===== PROVIDERS =====

  // Create Provider
  static Future<void> createProvider(ProviderModel provider) async {
    try {
      await _providersCollection.doc(provider.providerId).set(provider.toJson());
    } catch (e) {
      if (kDebugMode) print('Error creating provider: $e');
      rethrow;
    }
  }

  // Get All Providers
  static Future<List<ProviderModel>> getAllProviders() async {
    try {
      final snapshot = await _providersCollection
          .orderBy('rating', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) {
        return ProviderModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'providerId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching providers: $e');
      return [];
    }
  }

  // Get Providers by Service Type
  static Future<List<ProviderModel>> getProvidersByService(String serviceType) async {
    try {
      final snapshot = await _providersCollection
          .where('serviceType', isEqualTo: serviceType)
          .orderBy('rating', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) {
        return ProviderModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'providerId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching providers by service: $e');
      return [];
    }
  }

  // Update Provider
  static Future<void> updateProvider(ProviderModel provider) async {
    try {
      await _providersCollection.doc(provider.providerId).update(
        provider.copyWith(updatedAt: DateTime.now()).toJson()
      );
    } catch (e) {
      if (kDebugMode) print('Error updating provider: $e');
      rethrow;
    }
  }

  // ===== STORAGE =====

  // Upload Event Main Image
  static Future<String?> uploadEventImage(String eventId, Uint8List imageData) async {
    try {
      final ref = _storage.ref().child('event_images/$eventId/main_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print('Error uploading event image: $e');
      return null;
    }
  }

  // Upload Event Media (photos/videos)
  static Future<String?> uploadEventMedia(String eventId, Uint8List mediaData, String fileName) async {
    try {
      final extension = fileName.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);
      
      final ref = _storage.ref().child('event_media/$eventId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = await ref.putData(
        mediaData,
        SettableMetadata(contentType: contentType),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print('Error uploading event media: $e');
      return null;
    }
  }

  // Helper method to determine content type
  static String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }
}
