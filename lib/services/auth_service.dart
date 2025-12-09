// Firebase Auth Service Wrapper
// This provides backward compatibility for screens that used the old local auth service

import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/firebase_auth_manager.dart';
import 'package:eventide/services/firebase_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final _authManager = FirebaseAuthManager();

  // Get current user
  static Future<AppUser?> getCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return await FirebaseUserService.getUserById(firebaseUser.uid);
  }

  // Logout
  static Future<void> logout() async {
    await _authManager.signOut();
  }

  // Update user
  static Future<void> updateUser(AppUser user) async {
    await FirebaseUserService.updateUser(user);
  }

  // Get user by ID
  static Future<AppUser?> getUserById(String userId) async {
    return await FirebaseUserService.getUserById(userId);
  }

  // Get all users
  static Future<List<AppUser>> getAllUsers() async {
    return await FirebaseUserService.getAllUsers();
  }

  // Delete user
  static Future<void> deleteUser(String userId) async {
    await FirebaseUserService.deleteUser(userId);
  }

  // Update user role
  static Future<void> updateUserRole(AppUser user) async {
    await FirebaseUserService.updateUser(user);
  }

  // Update user profile
  static Future<void> updateUserProfile(AppUser user) async {
    await FirebaseUserService.updateUser(user);
  }

  // Google Sign-In
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    final context = _DummyContext();
    final user = await _authManager.signInWithGoogle(context);
    if (user == null) return null;
    
    return {
      'user': user,
      'isExistingUser': true,
    };
  }

  // Create account with email (Firebase)
  static Future<AppUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    return await _authManager.createAccountWithEmail(context, email, password);
  }

  // Sign in with email (Firebase)
  static Future<AppUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    return await _authManager.signInWithEmail(context, email, password);
  }

  // Login with credential (email or phone)
  static Future<AppUser?> login(String credential, String password) async {
    // Try to sign in with email
    try {
      final context = _DummyContext();
      return await _authManager.signInWithEmail(context, credential, password);
    } catch (e) {
      return null;
    }
  }

  // Signup (not used with Firebase - use createAccountWithEmail instead)
  static Future<AppUser?> signup(
    String name,
    String phoneNumber,
    String username,
    String password,
    UserRole role, {
    DateTime? birthday,
    String? gender,
    String? neighborhood,
    String? email,
  }) async {
    // Create account with email
    final context = _DummyContext();
    return await _authManager.createAccountWithEmail(
      context,
      email ?? '$username@ticketat.local',
      password,
    );
  }

  // Hash password (not needed with Firebase)
  static String hashPassword(String password) {
    return password; // Firebase handles password hashing
  }

  // Complete Google profile
  static Future<AppUser?> completeGoogleProfile(
    AppUser tempUser,
    String phoneNumber,
    DateTime birthday,
    String gender,
    String neighborhood,
  ) async {
    final updatedUser = tempUser.copyWith(
      phoneNumber: phoneNumber,
      birthday: birthday,
      gender: gender,
      neighborhood: neighborhood,
      updatedAt: DateTime.now(),
    );

    await FirebaseUserService.updateUser(updatedUser);
    return updatedUser;
  }

  // Password reset methods (not applicable with Firebase - Firebase handles this)
  static Future<String?> requestPasswordReset(String phoneNumber) async {
    return null; // Firebase uses email-based password reset
  }

  static Future<bool> resetPassword(String phoneNumber, String otp, String newPassword) async {
    return false; // Firebase uses email-based password reset
  }
}

// Dummy context for methods that don't have access to BuildContext
class _DummyContext implements BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  bool get mounted => false;

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, {Object? aspect}) {
    throw UnimplementedError();
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    throw UnimplementedError();
  }

  @override
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeElement(String name, {DiagnosticsTreeStyle? style}) {
    throw UnimplementedError();
  }

  @override
  List<DiagnosticsNode> describeMissingAncestor({required Type expectedAncestorType}) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeWidget(String name, {DiagnosticsTreeStyle? style}) {
    throw UnimplementedError();
  }

  @override
  void dispatchNotification(Notification notification) {}

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() {
    throw UnimplementedError();
  }

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() {
    throw UnimplementedError();
  }

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    throw UnimplementedError();
  }

  @override
  RenderObject? findRenderObject() {
    throw UnimplementedError();
  }

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() {
    throw UnimplementedError();
  }

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() {
    throw UnimplementedError();
  }

  @override
  BuildOwner? get owner => null;

  @override
  Size? get size => null;

  @override
  void visitAncestorElements(ConditionalElementVisitor visitor) {}

  @override
  void visitChildElements(ElementVisitor visitor) {}

  @override
  Widget get widget => Container();
}
