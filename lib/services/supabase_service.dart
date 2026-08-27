import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  // --- GUIDELINE 4.8: Add Sign in with Apple ---
  Future<AuthResponse> signInWithApple() async {
    final rawNonce = client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Could not find ID Token from Apple');
    }

    return client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- GUIDELINE 5.1.1: Delete Account ---
  Future<void> deleteAccount() async {
    final userId = currentUser?.id;
    if (userId == null) return;
    
    // Attempt RPC call to delete user account securely
    await client.rpc('delete_user_account');
    await signOut();
  }

  // --- GUIDELINE 1.2: Block & Report ---
  Future<void> blockUser(String blockedId) async {
    if (currentUser == null) return;
    await client.from('user_blocks').insert({
      'blocker_id': currentUser!.id,
      'blocked_id': blockedId,
    });
  }

  Future<void> reportUser(String reportedId, String reason) async {
    if (currentUser == null) return;
    await client.from('user_reports').insert({
      'reporter_id': currentUser!.id,
      'reported_id': reportedId,
      'reason': reason,
    });
  }
}
