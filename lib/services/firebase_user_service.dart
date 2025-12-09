import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventide/models/app_models.dart';
import 'package:flutter/foundation.dart';

class FirebaseUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get _usersCollection => _firestore.collection('users');
  static CollectionReference get _securityStaffCollection => _firestore.collection('securityStaff');

  // ===== USERS =====

  // Create User
  static Future<void> createUser(AppUser user) async {
    try {
      await _usersCollection.doc(user.userId).set(user.toJson());
    } catch (e) {
      if (kDebugMode) print('Error creating user: $e');
      rethrow;
    }
  }

  // Get User by ID
  static Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;

      return AppUser.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'userId': doc.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching user: $e');
      return null;
    }
  }

  // Get User by Email
  static Future<AppUser?> getUserByEmail(String email) async {
    try {
      final snapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return AppUser.fromJson({
        ...snapshot.docs.first.data() as Map<String, dynamic>,
        'userId': snapshot.docs.first.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching user by email: $e');
      return null;
    }
  }

  // Get User by Phone Number
  static Future<AppUser?> getUserByPhone(String phoneNumber) async {
    try {
      final snapshot = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return AppUser.fromJson({
        ...snapshot.docs.first.data() as Map<String, dynamic>,
        'userId': snapshot.docs.first.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching user by phone: $e');
      return null;
    }
  }

  // Get User by Username
  static Future<AppUser?> getUserByUsername(String username) async {
    try {
      final snapshot = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return AppUser.fromJson({
        ...snapshot.docs.first.data() as Map<String, dynamic>,
        'userId': snapshot.docs.first.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching user by username: $e');
      return null;
    }
  }

  // Update User
  static Future<void> updateUser(AppUser user) async {
    try {
      await _usersCollection.doc(user.userId).update(
        user.copyWith(updatedAt: DateTime.now()).toJson()
      );
    } catch (e) {
      if (kDebugMode) print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete User
  static Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting user: $e');
      rethrow;
    }
  }

  // Get All Users (admin only - use with caution)
  static Future<List<AppUser>> getAllUsers({int limit = 100}) async {
    try {
      final snapshot = await _usersCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return AppUser.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'userId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching all users: $e');
      return [];
    }
  }

  // Get Users by Role
  static Future<List<AppUser>> getUsersByRole(UserRole role, {int limit = 50}) async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: role.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return AppUser.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'userId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching users by role: $e');
      return [];
    }
  }

  // Update User Profile
  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? email,
    DateTime? birthday,
    String? gender,
    String? neighborhood,
    List<String>? preferences,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (email != null) updates['email'] = email;
      if (birthday != null) updates['birthday'] = birthday.toIso8601String();
      if (gender != null) updates['gender'] = gender;
      if (neighborhood != null) updates['neighborhood'] = neighborhood;
      if (preferences != null) updates['preferences'] = preferences;

      await _usersCollection.doc(userId).update(updates);
    } catch (e) {
      if (kDebugMode) print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update User Role
  static Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _usersCollection.doc(userId).update({
        'role': role.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error updating user role: $e');
      rethrow;
    }
  }

  // Enable Premium Analytics
  static Future<void> enablePremiumAnalytics(String userId, int durationDays) async {
    try {
      final expiryDate = DateTime.now().add(Duration(days: durationDays));
      
      await _usersCollection.doc(userId).update({
        'hasPremiumAnalytics': true,
        'premiumExpiryDate': expiryDate.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error enabling premium analytics: $e');
      rethrow;
    }
  }

  // Check and Update Premium Status
  static Future<void> checkPremiumStatus(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return;

      if (user.hasPremiumAnalytics && 
          user.premiumExpiryDate != null &&
          user.premiumExpiryDate!.isBefore(DateTime.now())) {
        // Premium expired
        await _usersCollection.doc(userId).update({
          'hasPremiumAnalytics': false,
          'premiumExpiryDate': null,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error checking premium status: $e');
    }
  }

  // ===== SECURITY STAFF =====

  // Create Security Staff
  static Future<void> createSecurityStaff(SecurityStaff staff) async {
    try {
      await _securityStaffCollection.doc(staff.staffId).set(staff.toJson());
    } catch (e) {
      if (kDebugMode) print('Error creating security staff: $e');
      rethrow;
    }
  }

  // Get Security Staff by Event
  static Future<List<SecurityStaff>> getEventSecurityStaff(String eventId) async {
    try {
      final snapshot = await _securityStaffCollection
          .where('event_id', isEqualTo: eventId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return SecurityStaff.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching event security staff: $e');
      return [];
    }
  }

  // Get Security Staff by User ID
  static Future<SecurityStaff?> getSecurityStaffByUserId(String userId) async {
    try {
      final snapshot = await _securityStaffCollection
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SecurityStaff.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('Error fetching security staff by user ID: $e');
      return null;
    }
  }

  // Delete Security Staff
  static Future<void> deleteSecurityStaff(String staffId) async {
    try {
      await _securityStaffCollection.doc(staffId).delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting security staff: $e');
      rethrow;
    }
  }
}
