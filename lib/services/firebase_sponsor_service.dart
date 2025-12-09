import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventide/models/app_models.dart';
import 'package:flutter/foundation.dart';
import 'package:eventide/services/firebase_user_service.dart';

class FirebaseSponsorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _sponsorsCollection => _firestore.collection('sponsors');
  static CollectionReference get _applicationsCollection => _firestore.collection('sponsorApplications');
  static CollectionReference get _promotionsCollection => _firestore.collection('eventPromotions');

  // ===== SPONSOR PROFILES =====

  // Create sponsor profile
  static Future<SponsorModel> createSponsorProfile({
    required String userId,
    required String companyName,
    required String category,
    required String budgetRange,
    required List<String> targetAudience,
  }) async {
    try {
      final now = DateTime.now();
      final sponsor = SponsorModel(
        sponsorId: 'sponsor_${now.millisecondsSinceEpoch}',
        userId: userId,
        companyName: companyName,
        category: category,
        budgetRange: budgetRange,
        targetAudience: targetAudience,
        createdAt: now,
        updatedAt: now,
      );

      await _sponsorsCollection.doc(sponsor.sponsorId).set(sponsor.toJson());
      return sponsor;
    } catch (e) {
      if (kDebugMode) print('Error creating sponsor profile: $e');
      rethrow;
    }
  }

  // Get sponsor by user ID
  static Future<SponsorModel?> getSponsorByUserId(String userId) async {
    try {
      final snapshot = await _sponsorsCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SponsorModel.fromJson({
        ...snapshot.docs.first.data() as Map<String, dynamic>,
        'sponsorId': snapshot.docs.first.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching sponsor by user ID: $e');
      return null;
    }
  }

  // Get sponsor by ID
  static Future<SponsorModel?> getSponsorById(String sponsorId) async {
    try {
      final doc = await _sponsorsCollection.doc(sponsorId).get();
      if (!doc.exists) return null;

      return SponsorModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'sponsorId': doc.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching sponsor: $e');
      return null;
    }
  }

  // Update sponsor profile
  static Future<void> updateSponsorProfile(SponsorModel sponsor) async {
    try {
      await _sponsorsCollection.doc(sponsor.sponsorId).update(
        sponsor.copyWith(updatedAt: DateTime.now()).toJson()
      );
    } catch (e) {
      if (kDebugMode) print('Error updating sponsor profile: $e');
      rethrow;
    }
  }

  // ===== SPONSORSHIP APPLICATIONS =====

  // Submit sponsorship application
  static Future<SponsorApplication> submitApplication({
    required String sponsorId,
    required String eventId,
    required String brandName,
    required double budgetOffered,
    required String message,
  }) async {
    try {
      final now = DateTime.now();
      final application = SponsorApplication(
        applicationId: 'app_${now.millisecondsSinceEpoch}',
        sponsorId: sponsorId,
        eventId: eventId,
        brandName: brandName,
        budgetOffered: budgetOffered,
        message: message,
        status: SponsorApplicationStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await _applicationsCollection.doc(application.applicationId).set(application.toJson());
      return application;
    } catch (e) {
      if (kDebugMode) print('Error submitting application: $e');
      rethrow;
    }
  }

  // Get applications by event
  static Future<List<SponsorApplication>> getApplicationsByEvent(String eventId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return SponsorApplication.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'applicationId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching applications by event: $e');
      return [];
    }
  }

  // Get applications by sponsor
  static Future<List<SponsorApplication>> getApplicationsBySponsor(String sponsorId) async {
    try {
      final snapshot = await _applicationsCollection
          .where('sponsorId', isEqualTo: sponsorId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return SponsorApplication.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'applicationId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching applications by sponsor: $e');
      return [];
    }
  }

  // Accept sponsorship application
  static Future<void> acceptApplication(String applicationId, String organizerContactInfo) async {
    try {
      await _applicationsCollection.doc(applicationId).update({
        'status': 'accepted',
        'organizerContactInfo': organizerContactInfo,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error accepting application: $e');
      rethrow;
    }
  }

  // Reject sponsorship application
  static Future<void> rejectApplication(String applicationId) async {
    try {
      await _applicationsCollection.doc(applicationId).update({
        'status': 'rejected',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error rejecting application: $e');
      rethrow;
    }
  }

  // Get application by ID
  static Future<SponsorApplication?> getApplicationById(String applicationId) async {
    try {
      final doc = await _applicationsCollection.doc(applicationId).get();
      if (!doc.exists) return null;

      return SponsorApplication.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'applicationId': doc.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching application: $e');
      return null;
    }
  }

  // ===== EVENT PROMOTIONS =====

  // Promote event
  static Future<EventPromotion> promoteEvent({
    required String eventId,
    required int daysPromoted,
    required double totalCost,
  }) async {
    try {
      final now = DateTime.now();
      final promotion = EventPromotion(
        promotionId: 'promo_${now.millisecondsSinceEpoch}',
        eventId: eventId,
        daysPromoted: daysPromoted,
        totalCost: totalCost,
        startDate: now,
        endDate: now.add(Duration(days: daysPromoted)),
        createdAt: now,
      );

      await _promotionsCollection.doc(promotion.promotionId).set(promotion.toJson());
      return promotion;
    } catch (e) {
      if (kDebugMode) print('Error promoting event: $e');
      rethrow;
    }
  }

  // Get promotions by event
  static Future<List<EventPromotion>> getEventPromotions(String eventId) async {
    try {
      final snapshot = await _promotionsCollection
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        return EventPromotion.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'promotionId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching event promotions: $e');
      return [];
    }
  }

  // Get active promotions
  static Future<List<EventPromotion>> getActivePromotions() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      
      final snapshot = await _promotionsCollection
          .where('endDate', isGreaterThan: now)
          .orderBy('endDate', descending: false)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return EventPromotion.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'promotionId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching active promotions: $e');
      return [];
    }
  }

  // Get all sponsors (admin only)
  static Future<List<SponsorModel>> getAllSponsors({int limit = 50}) async {
    try {
      final snapshot = await _sponsorsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return SponsorModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'sponsorId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching all sponsors: $e');
      return [];
    }
  }
}
