// Storage Service - Language preference only
// All other data now stored in Firebase

import 'package:eventide/services/language_service.dart';

class StorageService {
  // Language methods
  static String getLanguage() {
    return LanguageService.getLanguage();
  }

  static Future<void> setLanguage(String language) async {
    await LanguageService.setLanguage(language);
  }

  // Legacy box names (not used - Firebase replaces these)
  static String get usersBox => 'users';
  static String get securityBox => 'security';

  // Get all data (Firebase implementation)
  static List<Map<String, dynamic>> getAllData(String boxName) {
    // Return empty list - use Firebase services directly
    return [];
  }

  // Save data (Firebase implementation)
  static Future<void> saveData(String boxName, String key, Map<String, dynamic> data) async {
    // This is handled by Firebase services directly
  }
}
