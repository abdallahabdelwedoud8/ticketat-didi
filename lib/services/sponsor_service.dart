// Firebase Sponsor Service Wrapper
// This provides backward compatibility for screens that used the old local sponsor service

import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/firebase_sponsor_service.dart';

class SponsorService {
  // Submit application
  static Future<SponsorApplication> submitApplication({
    required String sponsorId,
    required String eventId,
    required String brandName,
    required double budgetOffered,
    required String message,
  }) async {
    return await FirebaseSponsorService.submitApplication(
      sponsorId: sponsorId,
      eventId: eventId,
      brandName: brandName,
      budgetOffered: budgetOffered,
      message: message,
    );
  }

  // Get applications by event
  static Future<List<SponsorApplication>> getApplicationsByEvent(String eventId) async {
    return await FirebaseSponsorService.getApplicationsByEvent(eventId);
  }

  // Get applications by sponsor
  static Future<List<SponsorApplication>> getApplicationsBySponsor(String sponsorId) async {
    return await FirebaseSponsorService.getApplicationsBySponsor(sponsorId);
  }

  // Accept application
  static Future<void> acceptApplication(String applicationId) async {
    final app = await FirebaseSponsorService.getApplicationById(applicationId);
    if (app == null) return;
    await FirebaseSponsorService.acceptApplication(applicationId, 'contact@ticketat.mr');
  }

  // Reject application
  static Future<void> rejectApplication(String applicationId) async {
    await FirebaseSponsorService.rejectApplication(applicationId);
  }

  // Promote event
  static Future<EventPromotion> promoteEvent({
    required String eventId,
    required int daysPromoted,
    required double totalCost,
  }) async {
    return await FirebaseSponsorService.promoteEvent(
      eventId: eventId,
      daysPromoted: daysPromoted,
      totalCost: totalCost,
    );
  }

  // Create sponsor profile
  static Future<SponsorModel> createSponsorProfile({
    required String userId,
    required String companyName,
    required String category,
    required String budgetRange,
    required List<String> targetAudience,
  }) async {
    return await FirebaseSponsorService.createSponsorProfile(
      userId: userId,
      companyName: companyName,
      category: category,
      budgetRange: budgetRange,
      targetAudience: targetAudience,
    );
  }

  // Get sponsor by user ID
  static Future<SponsorModel?> getSponsorByUserId(String userId) async {
    return await FirebaseSponsorService.getSponsorByUserId(userId);
  }
}
