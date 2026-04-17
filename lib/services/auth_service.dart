import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'analytics_service.dart';

/// Thrown when [blockNewAccounts] is set and the OAuth credential
/// did not match any existing Firebase user.
class AccountNotFoundAuthException implements Exception {
  const AccountNotFoundAuthException();
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

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

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
    );

    final result = await _auth.signInWithCredential(oauthCredential);
    await _enforceExistingAccount(result, blockNewAccounts);
    AnalyticsService.capture(AnalyticsService.signIn, {'method': 'apple'});
    return result;
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
