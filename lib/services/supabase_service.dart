import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AccountLoginProvider { google, apple }

enum AccountAuthEvent { changed, expired }

class LoginCancelled implements Exception {}

class AppleReauthenticationRequired implements Exception {}

class SessionReauthenticationRequired implements Exception {}

class AccountDeletionUnavailable implements Exception {}

class AppleAccountMismatch implements Exception {}

abstract class AuthGateway {
  bool get configured;
  bool get mobileSupported;
  String? get userId;
  String? get email;
  String? get displayName;
  bool get sessionValid;
  Stream<AccountAuthEvent> get events;
  Future<bool> signIn(AccountLoginProvider provider);
  Future<void> signOut();
  Future<void> refreshSession();
  Future<void> deleteAccount();
  Future<void> acknowledgeDisplayName();
}

class SupabaseService implements AuthGateway {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  @visibleForTesting
  SupabaseService.forTesting(SupabaseClient client, LocalStorage storage) {
    _clientOverride = client;
    _sessionStorage = storage;
    _configured = true;
  }

  static const redirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'com.mythosforgelabs.atlasworkout://login-callback',
  );
  bool _configured = false;
  String? _appleName;
  String? _appleNameUserId;
  bool _expectedSignOut = false;
  LocalStorage? _sessionStorage;
  SupabaseClient? _clientOverride;

  Future<void> initialize() async {
    // Try to load from .env file first, fall back to environment variables
    final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');
    
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        key.isEmpty) {
      return;
    }
    try {
      _sessionStorage = SharedPreferencesLocalStorage(
        persistSessionKey: 'sb-${uri.host.split('.').first}-auth-token',
      );
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: _sessionStorage,
        ),
        debug: false,
      );
      _configured = true;
      await _restoreAppleName();
    } catch (_) {
      // Account configuration must never prevent access to the guest workspace.
      _configured = false;
    }
  }

  SupabaseClient get client => _clientOverride ?? Supabase.instance.client;
  User? get currentUser => configured ? client.auth.currentUser : null;
  @override
  bool get configured => _configured;
  @override
  bool get mobileSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  @override
  String? get userId => currentUser?.id;
  @override
  String? get email => currentUser?.email;
  @override
  String? get displayName => _appleNameUserId == userId ? _appleName : null;
  @override
  bool get sessionValid =>
      configured &&
      client.auth.currentSession != null &&
      !client.auth.currentSession!.isExpired;
  @override
  Stream<AccountAuthEvent> get events => configured
      ? client.auth.onAuthStateChange
            .map((state) {
              final expired =
                  state.event == AuthChangeEvent.signedOut && !_expectedSignOut;
              if (state.event == AuthChangeEvent.signedOut) {
                _expectedSignOut = false;
              }
              return (
                expired ? AccountAuthEvent.expired : AccountAuthEvent.changed,
                state,
              );
            })
            .asyncMap((record) async {
              await _recordOAuthProvenance(record.$2);
              await _restoreAppleName();
              return record.$1;
            })
            .handleError((Object error) {
              if (error is AuthException && error.code == 'access_denied') {
                throw LoginCancelled();
              }
              throw error;
            })
      : const Stream.empty();

  /// Returns true when a browser callback is still outstanding.
  @override
  Future<bool> signIn(AccountLoginProvider provider) async {
    if (!configured || !mobileSupported) {
      throw StateError('Authentication unavailable');
    }
    if (provider == AccountLoginProvider.apple &&
        defaultTargetPlatform == TargetPlatform.iOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_oauth_provider');
      await signInWithApple();
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_oauth_provider', provider.name);
    if (provider == AccountLoginProvider.apple && userId != null) {
      await prefs.setString('pending_oauth_expected_user', userId!);
    } else {
      await prefs.remove('pending_oauth_expected_user');
    }
    await prefs.setInt(
      'pending_oauth_started_at',
      DateTime.now().millisecondsSinceEpoch,
    );
    try {
      final launched = await client.auth.signInWithOAuth(
        provider == AccountLoginProvider.apple
            ? OAuthProvider.apple
            : OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('OAuth launch failed');
    } catch (_) {
      await prefs.remove('pending_oauth_provider');
      rethrow;
    }
    return true;
  }

  Future<AuthResponse> signInWithApple() async {
    final nonce = client.auth.generateRawNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
      if (credential.identityToken == null) {
        throw const AuthException('Missing Apple identity token');
      }
      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .where((part) => part.trim().isNotEmpty)
          .join(' ')
          .trim();
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: nonce,
      );
      if (name.isNotEmpty && response.user != null) {
        _appleName = name;
        _appleNameUserId = response.user!.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_apple_name:${response.user!.id}', name);
      }
      // Apple supplies this only once. Profile initialization also reads the
      // in-memory value if the metadata request fails while offline.
      if (name.isNotEmpty &&
          (response.user?.userMetadata?['full_name'] as String? ?? '')
              .isEmpty) {
        try {
          await client.auth.updateUser(
            UserAttributes(data: {'full_name': name}),
          );
        } catch (_) {
          // The account coordinator persists the first-authorization name locally.
        }
      }
      return response;
    } on SignInWithAppleAuthorizationException catch (error) {
      _appleName = null;
      _appleNameUserId = null;
      if (error.code == AuthorizationErrorCode.canceled) throw LoginCancelled();
      rethrow;
    }
  }

  Future<void> _restoreAppleName() async {
    final id = userId;
    final prefs = await SharedPreferences.getInstance();
    if (id != userId) return;
    _appleNameUserId = id;
    _appleName = id == null ? null : prefs.getString('pending_apple_name:$id');
  }

  Future<void> _recordOAuthProvenance(AuthState state) async {
    if (state.event != AuthChangeEvent.signedIn || state.session == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('pending_oauth_provider');
    final expectedUser = prefs.getString('pending_oauth_expected_user');
    final started = prefs.getInt('pending_oauth_started_at') ?? 0;
    if (provider == null) return;
    await prefs.remove('pending_oauth_provider');
    await prefs.remove('pending_oauth_expected_user');
    await prefs.remove('pending_oauth_started_at');
    if (expectedUser != null && expectedUser != state.session!.user.id) {
      await signOut();
      throw AppleAccountMismatch();
    }
    final key = 'apple_refresh_token_fingerprint:${state.session!.user.id}';
    final token = state.session!.providerRefreshToken;
    final elapsed = DateTime.now().millisecondsSinceEpoch - started;
    if (provider == AccountLoginProvider.apple.name &&
        token != null &&
        token.isNotEmpty &&
        elapsed >= 0 &&
        elapsed < const Duration(minutes: 10).inMilliseconds) {
      // Record provenance, not the token. A linked Google's refresh token must
      // never be submitted to Apple's revocation endpoint after session restore.
      await prefs.setString(key, sha256.convert(utf8.encode(token)).toString());
    } else {
      await prefs.remove(key);
    }
  }

  @override
  Future<void> acknowledgeDisplayName() async {
    final id = userId;
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_apple_name:$id');
    if (id == userId) {
      _appleName = null;
      _appleNameUserId = null;
    }
  }

  @override
  Future<void> signOut() async {
    _expectedSignOut = true;
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      _expectedSignOut = false;
      // GoTrue removes its local session before attempting the remote logout.
      // A removed user or offline logout must not undo successful local cleanup.
      if (client.auth.currentSession != null) rethrow;
    }
    await _sessionStorage?.removePersistedSession();
  }

  @override
  Future<void> refreshSession() async {
    if (configured && client.auth.currentSession != null) {
      await client.auth.refreshSession();
    }
  }

  @override
  Future<void> deleteAccount() async {
    if (userId == null || !sessionValid) {
      throw SessionReauthenticationRequired();
    }
    final user = currentUser!;
    final providers = user.appMetadata['providers'];
    final appleLinked =
        user.identities?.any((identity) => identity.provider == 'apple') ==
            true ||
        (providers is List && providers.contains('apple'));
    final body = <String, dynamic>{};
    if (appleLinked) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          // Reauthorize Apple only; do not replace the current Supabase session.
          final credential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.fullName,
              AppleIDAuthorizationScopes.email,
            ],
          );
          if (credential.authorizationCode.isEmpty) {
            throw AppleReauthenticationRequired();
          }
          body.addAll({
            'appleAuthorizationCode': credential.authorizationCode,
            'appleClient': 'native',
          });
        } on SignInWithAppleAuthorizationException catch (error) {
          if (error.code == AuthorizationErrorCode.canceled) {
            throw LoginCancelled();
          }
          rethrow;
        }
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final token = client.auth.currentSession?.providerRefreshToken;
        final prefs = await SharedPreferences.getInstance();
        final fingerprint = prefs.getString(
          'apple_refresh_token_fingerprint:${user.id}',
        );
        if (token == null ||
            token.isEmpty ||
            fingerprint != sha256.convert(utf8.encode(token)).toString()) {
          throw AppleReauthenticationRequired();
        }
        body.addAll({'appleRefreshToken': token, 'appleClient': 'web'});
      } else {
        throw AppleReauthenticationRequired();
      }
    }
    if (currentUser?.id != user.id) {
      throw const AuthException('Account changed');
    }
    try {
      final response = await client.functions.invoke(
        'delete-account',
        body: body,
      );
      if (response.status < 200 ||
          response.status >= 300 ||
          response.data is! Map ||
          response.data['deleted'] != true) {
        throw StateError('Account deletion was not confirmed');
      }
    } on FunctionException catch (error) {
      final details = error.details;
      final code = details is Map ? details['error'] : null;
      if (error.status == 401 || code == 'authentication_required') {
        throw SessionReauthenticationRequired();
      }
      if (code == 'account_deletion_not_configured' || error.status == 404) {
        throw AccountDeletionUnavailable();
      }
      if (code == 'apple_account_mismatch') throw AppleAccountMismatch();
      if (appleLinked && code == 'apple_reauthentication_required') {
        throw AppleReauthenticationRequired();
      }
      rethrow;
    }
  }

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
