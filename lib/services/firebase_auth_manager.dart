import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventide/auth/auth_manager.dart';
import 'package:eventide/models/app_models.dart';

class FirebaseAuthManager extends AuthManager
    with EmailSignInManager, GoogleSignInManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Convert Firebase User to AppUser
  Future<AppUser?> _getAppUserFromFirebase(User firebaseUser) async {
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return AppUser.fromJson({
        ...data,
        'userId': firebaseUser.uid,
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  // Email/Password Sign In
  @override
  Future<AppUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      return await _getAppUserFromFirebase(credential.user!);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return null;
    } catch (e) {
      _showError(context, 'Sign in failed: $e');
      return null;
    }
  }

  // Email/Password Account Creation
  @override
  Future<AppUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Create user profile in Firestore
      final now = DateTime.now();
      final newUser = AppUser(
        userId: credential.user!.uid,
        name: email.split('@').first,
        phoneNumber: '',
        username: 'user_${credential.user!.uid.substring(0, 8)}',
        email: email,
        passwordHash: '', // Firebase manages passwords
        role: UserRole.buyer,
        joinedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toJson());

      return newUser;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return null;
    } catch (e) {
      _showError(context, 'Account creation failed: $e');
      return null;
    }
  }

  // Google Sign In
  @override
  Future<AppUser?> signInWithGoogle(BuildContext context) async {
    try {
      // Use Google Sign-In with Firebase Auth directly
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes for better user info
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Sign in with popup (web) or redirect (mobile/web fallback)
      UserCredential? userCredential;
      
      try {
        userCredential = await _auth.signInWithPopup(googleProvider);
      } catch (popupError) {
        // Fallback to redirect if popup fails
        debugPrint('Popup failed, trying redirect: $popupError');
        await _auth.signInWithRedirect(googleProvider);
        return null; // Will handle on redirect back
      }
      
      if (userCredential?.user == null) return null;

      // Check if user exists in Firestore
      final doc = await _firestore.collection('users').doc(userCredential!.user!.uid).get();

      if (doc.exists) {
        // Existing user - return their data
        return await _getAppUserFromFirebase(userCredential!.user!);
      }

      // New user - create profile
      final now = DateTime.now();
      final newUser = AppUser(
        userId: userCredential!.user!.uid,
        name: userCredential!.user!.displayName ?? 'User',
        phoneNumber: '',
        username: 'user_${userCredential!.user!.uid.substring(0, 8)}',
        email: userCredential!.user!.email,
        passwordHash: '', // OAuth users don't have passwords
        role: UserRole.buyer,
        joinedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(userCredential!.user!.uid).set(newUser.toJson());

      return newUser;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return null;
    } catch (e) {
      _showError(context, 'Google Sign-In failed: $e');
      return null;
    }
  }

  // Sign Out
  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // Delete User
  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
    } catch (e) {
      _showError(context, 'Failed to delete account: $e');
    }
  }

  // Update Email
  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await user.verifyBeforeUpdateEmail(email);
      
      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'email': email,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
    } catch (e) {
      _showError(context, 'Failed to update email: $e');
    }
  }

  // Reset Password
  @override
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent. Please check your inbox.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
    } catch (e) {
      _showError(context, 'Failed to send reset email: $e');
    }
  }

  // Send Email Verification
  @override
  Future<void> sendEmailVerification({required AppUser user}) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && !firebaseUser.emailVerified) {
        await firebaseUser.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('Email verification error: $e');
    }
  }

  // Refresh User
  @override
  Future<void> refreshUser({required AppUser user}) async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('User refresh error: $e');
    }
  }

  // Error Handling
  void _handleAuthError(BuildContext context, FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        message = 'Invalid email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'requires-recent-login':
        message = 'Please log in again to continue.';
        break;
      default:
        message = 'Authentication error: ${e.message}';
    }
    _showError(context, message);
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
