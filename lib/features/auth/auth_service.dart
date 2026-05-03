import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../subscription/services/analytics_service.dart';

/// Thrown when [blockNewAccounts] is set and the OAuth credential
/// did not match any existing Firebase user.
class AccountNotFoundAuthException implements Exception {
  const AccountNotFoundAuthException();
}

/// Thrown when an email/password sign-in or sign-up fails with a known
/// Firebase auth code. [message] is a user-facing string that callers can
/// surface directly without inspecting [code].
class EmailAuthException implements Exception {
  final String code;
  final String message;
  const EmailAuthException(this.code, this.message);
}

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;

  static bool get isLoggedIn => _auth.currentUser != null;

  static Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
    AnalyticsService.capture(AnalyticsService.signIn, {'method': 'anonymous'});
  }

  static String get uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    return user.uid;
  }

  static String? get uidOrNull => _auth.currentUser?.uid;

  static final Stream<User?> authStateChanges = _auth.authStateChanges();

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  static Future<UserCredential> signInWithGoogle({
    bool blockNewAccounts = false,
  }) async {
    await _ensureGoogleInitialized();

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    await _enforceExistingAccount(result, blockNewAccounts);
    AnalyticsService.capture(AnalyticsService.signIn, {'method': 'google'});
    return result;
  }

  static Future<UserCredential> signInWithApple({
    bool blockNewAccounts = false,
  }) async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode, 
    );

    final result = await _auth.signInWithCredential(oauthCredential);
    await _enforceExistingAccount(result, blockNewAccounts);
    AnalyticsService.capture(AnalyticsService.signIn, {'method': 'apple'});
    return result;
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      AnalyticsService.capture(AnalyticsService.signIn, {'method': 'email'});
      return result;
    } on FirebaseAuthException catch (e) {
      throw EmailAuthException(e.code, _emailErrorMessage(e.code));
    }
  }

  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      AnalyticsService.capture(AnalyticsService.signIn, {'method': 'email'});
      return result;
    } on FirebaseAuthException catch (e) {
      throw EmailAuthException(e.code, _emailErrorMessage(e.code));
    }
  }

  static String _emailErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  /// If [block] is true and Firebase just provisioned a new account, undo it
  /// (delete the user, then sign out as a fallback) and throw
  /// [AccountNotFoundAuthException] so the UI can surface a "no account" error.
  static Future<void> _enforceExistingAccount(
    UserCredential result,
    bool block,
  ) async {
    if (!block) return;
    if (result.additionalUserInfo?.isNewUser != true) return;
    try {
      await result.user?.delete();
    } catch (e) {
      debugPrint('[AuthService] Failed to delete orphan user: $e');
      await _auth.signOut();
    }
    throw const AccountNotFoundAuthException();
  }

  static Future<void> signOut() async {
    await AnalyticsService.capture(AnalyticsService.signOut);
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  /// Deletes the Firestore user document (with all known subcollections) and
  /// the Firebase Auth account. The auth state change then triggers the
  /// AuthWrapper cleanup (local settings, native alarms).
  ///
  /// May throw [FirebaseAuthException] with code `requires-recent-login` if
  /// the user has not signed in recently — the UI should surface a re-auth
  /// prompt in that case.
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await AnalyticsService.capture(AnalyticsService.accountDeleted);

    await _deleteUserFirestoreData(uid);

    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('[AuthService] Google signOut during delete failed: $e');
      }
    }

    await user.delete();
    await _auth.signOut();
  }

  static Future<void> _deleteUserFirestoreData(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    const subcollections = ['alarms', 'sessions', 'meta'];
    for (final name in subcollections) {
      final snap = await userRef.collection(name).get();
      for (final doc in snap.docs) {
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('[AuthService] Failed to delete $name/${doc.id}: $e');
        }
      }
    }
    try {
      await userRef.delete();
    } catch (e) {
      debugPrint('[AuthService] Failed to delete user doc: $e');
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
