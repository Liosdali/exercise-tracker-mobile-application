import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/supabase_service.dart';
import '../services/user_account_service.dart';

enum AccountAuthError {
  configuration,
  login,
  cancelled,
  expired,
  operation,
  workspace,
  deletionCleanup,
  appleReauthentication,
  deletionCancelled,
  deletionUnavailable,
  appleAccountMismatch,
}

/// Serializes account transitions before any account-bound UI is exposed.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.gateway,
    required this.accounts,
    this.beforeWorkspaceSwitch,
  });

  final AuthGateway gateway;
  final UserAccountService accounts;
  final Future<void> Function()? beforeWorkspaceSwitch;
  StreamSubscription<AccountAuthEvent>? _subscription;
  Future<void> _transition = Future.value();
  Timer? _loginTimeout;
  int _generation = 0;
  int _loginGeneration = 0;
  bool _disposed = false;
  bool _initialized = false;
  bool _deleting = false;
  String? _deletedAccountToClear;
  String? _expectedReauthenticationUser;
  bool _reauthenticationCleanupPending = false;
  bool workspaceReady = false;
  bool busy = false;
  bool waitingForBrowser = false;
  bool offerGuestImport = false;
  bool accountDeleted = false;
  String? userId;
  AccountAuthError? error;
  int workspaceRevision = 0;
  int get accountGeneration => _generation;
  String get workspaceKey => '${userId ?? 'guest'}:$workspaceRevision';
  bool get signedIn => userId != null;
  bool get canSignIn => gateway.configured && gateway.mobileSupported;
  String? get email => signedIn ? gateway.email : null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    _deletedAccountToClear = prefs.getString('pending_account_cleanup');
    if (!gateway.configured) error = AccountAuthError.configuration;
    _subscription = gateway.events.listen(
      (event) {
        if (_deleting || _deletedAccountToClear != null) return;
        if (_expectedReauthenticationUser != null &&
            gateway.userId != null &&
            gateway.userId != _expectedReauthenticationUser) {
          unawaited(_rejectReauthentication());
          return;
        }
        if (event == AccountAuthEvent.expired) error = AccountAuthError.expired;
        if (gateway.sessionValid && error == AccountAuthError.expired) {
          error = null;
        }
        _loginTimeout?.cancel();
        waitingForBrowser = false;
        busy = false;
        unawaited(_selectWorkspace(gateway.userId));
      },
      onError: (Object failure) {
        _loginTimeout?.cancel();
        error = failure is AppleAccountMismatch
            ? AccountAuthError.appleAccountMismatch
            : failure is LoginCancelled
            ? AccountAuthError.cancelled
            : (gateway.userId == null || gateway.sessionValid
                  ? AccountAuthError.login
                  : AccountAuthError.expired);
        busy = false;
        waitingForBrowser = false;
        _notify();
        if (failure is AppleAccountMismatch && gateway.userId != userId) {
          unawaited(_selectWorkspace(gateway.userId));
        }
      },
    );
    if (_deletedAccountToClear != null) {
      await retryWorkspace();
    } else {
      await _selectWorkspace(gateway.userId);
    }
  }

  Future<void> _selectWorkspace(String? nextUser) {
    if (workspaceReady && userId == nextUser) {
      _notify();
      if (nextUser != null && gateway.sessionValid) unawaited(sync());
      return Future.value();
    }
    final generation = ++_generation;
    workspaceReady = false;
    offerGuestImport = false;
    _notify();
    _transition = _transition.then((_) async {
      if (_disposed || generation != _generation) return;
      try {
        await beforeWorkspaceSwitch?.call();
        if (_disposed || generation != _generation) return;
        await accounts.initialize(nextUser);
        if (_disposed || generation != _generation) return;
        userId = nextUser;
        workspaceReady = true;
        workspaceRevision++;
        busy = false;
        _notify();
        if (nextUser != null) {
          // Never delay offline access while waiting for the network.
          unawaited(_finishAccountInitialization(generation, nextUser));
        }
      } catch (_) {
        if (generation != _generation || _disposed) return;
        error = AccountAuthError.workspace;
        busy = false;
        _notify();
      }
    });
    return _transition;
  }

  Future<void> _finishAccountInitialization(int generation, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = await accounts.hasGuestData();
      if (_disposed || generation != _generation) return;
      offerGuestImport =
          hasData && !(prefs.getBool('guest_import_decision:$id') ?? false);
      _notify();
      if (!gateway.sessionValid) {
        error = AccountAuthError.expired;
        _notify();
        return;
      }
      // Download first: an empty local profile may have an edited remote name.
      try {
        await accounts.sync();
      } catch (_) {
        return;
      }
      await _applyPendingName(generation);
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error = AccountAuthError.operation;
      _notify();
    }
  }

  Future<void> _applyPendingName(int generation) async {
    if (_disposed || generation != _generation) return;
    final name = gateway.displayName?.trim();
    final profile = accounts.profile;
    if (name != null && name.isNotEmpty && (profile?.name ?? '').isEmpty) {
      await accounts.updateProfile(
        name: name,
        age: profile?.age,
        weightKg: profile?.weightKg,
        heightCm: profile?.heightCm,
        gender: profile?.gender,
      );
    }
    if (!_disposed && generation == _generation && name != null) {
      await gateway.acknowledgeDisplayName();
    }
  }

  Future<void> signIn(AccountLoginProvider provider) async {
    if (busy || !canSignIn) return;
    final attempt = ++_loginGeneration;
    _expectedReauthenticationUser =
        provider == AccountLoginProvider.apple && signedIn ? userId : null;
    error = null;
    busy = true;
    _notify();
    try {
      final browser = await gateway.signIn(provider);
      if (_disposed || attempt != _loginGeneration) return;
      if (browser) {
        waitingForBrowser = true;
        _loginTimeout = Timer(const Duration(minutes: 2), cancelSignIn);
      } else if (gateway.userId != null) {
        await _selectWorkspace(gateway.userId);
      }
    } on LoginCancelled {
      if (attempt == _loginGeneration) error = AccountAuthError.cancelled;
    } catch (_) {
      if (attempt == _loginGeneration) error = AccountAuthError.login;
    } finally {
      if (attempt == _loginGeneration) {
        busy = waitingForBrowser;
        _notify();
      }
    }
  }

  void cancelSignIn() {
    ++_loginGeneration;
    _loginTimeout?.cancel();
    busy = false;
    waitingForBrowser = false;
    error = AccountAuthError.cancelled;
    _notify();
  }

  Future<void> decideGuestImport(bool import) async {
    final id = userId;
    final generation = _generation;
    if (id == null || busy || !offerGuestImport) return;
    busy = true;
    _notify();
    try {
      if (import) await accounts.importGuestData();
      if (_disposed || generation != _generation) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guest_import_decision:$id', true);
      if (_disposed || generation != _generation) return;
      offerGuestImport = false;
      if (import) {
        // Reload in-memory calendars, programs and statistics after consented import.
        workspaceRevision++;
      }
    } catch (_) {
      if (generation == _generation) error = AccountAuthError.operation;
    } finally {
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> sync() async {
    if (!signedIn || !workspaceReady || !gateway.sessionValid) {
      if (signedIn && !gateway.sessionValid) {
        error = AccountAuthError.expired;
        _notify();
      }
      return;
    }
    final generation = _generation;
    try {
      await accounts.sync();
      await _applyPendingName(generation);
    } catch (_) {
      // The coordinator exposes pending changes and a retryable sync error.
    }
  }

  Future<void> resume() async {
    if (!signedIn) return;
    final generation = _generation;
    try {
      await gateway.refreshSession();
    } catch (_) {
      if (generation == _generation && !gateway.sessionValid) {
        error = AccountAuthError.expired;
        _notify();
      }
    }
    if (generation == _generation) await sync();
  }

  Future<bool> signOut() async {
    if (busy) return false;
    busy = true;
    _expectedReauthenticationUser = null;
    error = null;
    _notify();
    try {
      await gateway.signOut();
      await _selectWorkspace(null);
      return true;
    } catch (_) {
      error = AccountAuthError.operation;
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> deleteAccount() async {
    final id = userId;
    if (id == null || busy) return false;
    if (gateway.userId != id) {
      error = gateway.userId == null
          ? AccountAuthError.expired
          : AccountAuthError.appleAccountMismatch;
      _notify();
      return false;
    }
    busy = true;
    error = null;
    _deleting = true;
    _notify();
    try {
      await gateway.deleteAccount();
      _deletedAccountToClear = id;
      // Only a confirmed server deletion authorizes local destruction.
      workspaceReady = false;
      ++_generation;
      _notify();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_account_cleanup', id);
      await beforeWorkspaceSwitch?.call();
      await _finishDeletion();
      return true;
    } catch (failure) {
      error = _deletedAccountToClear != null
          ? AccountAuthError.deletionCleanup
          : (failure is AppleReauthenticationRequired
                ? AccountAuthError.appleReauthentication
                : failure is SessionReauthenticationRequired
                ? AccountAuthError.expired
                : failure is LoginCancelled
                ? AccountAuthError.deletionCancelled
                : failure is AccountDeletionUnavailable
                ? AccountAuthError.deletionUnavailable
                : failure is AppleAccountMismatch
                ? AccountAuthError.appleAccountMismatch
                : AccountAuthError.operation);
      return false;
    } finally {
      _deleting = false;
      busy = false;
      _notify();
    }
  }

  Future<void> _rejectReauthentication() async {
    _reauthenticationCleanupPending = true;
    _expectedReauthenticationUser = null;
    waitingForBrowser = false;
    _loginTimeout?.cancel();
    busy = true;
    workspaceReady = false;
    ++_generation;
    _notify();
    try {
      await Future<void>.value();
      await gateway.signOut();
      await _selectWorkspace(null);
      _reauthenticationCleanupPending = false;
    } catch (_) {
      // No deletion is attempted; the session/workspace identity guard remains.
    } finally {
      error = AccountAuthError.appleAccountMismatch;
      busy = false;
      _notify();
    }
  }

  Future<void> _finishDeletion() async {
    final id = _deletedAccountToClear!;
    await accounts.clearDeletedAccount(id);
    await gateway.acknowledgeDisplayName();
    await gateway.signOut();
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'guest_import_decision:$id',
      'pending_apple_name:$id',
      'apple_refresh_token_fingerprint:$id',
    ]) {
      await prefs.remove(key);
    }
    if (prefs.getString('pending_oauth_expected_user') == id) {
      await prefs.remove('pending_oauth_expected_user');
      await prefs.remove('pending_oauth_provider');
      await prefs.remove('pending_oauth_started_at');
    }
    await prefs.remove('pending_account_cleanup');
    error = null;
    await _selectWorkspace(null);
    _deletedAccountToClear = null;
    accountDeleted = true;
    _notify();
  }

  void acknowledgeDeletion() {
    accountDeleted = false;
    _notify();
  }

  Future<void> retryWorkspace() async {
    if (_reauthenticationCleanupPending) {
      await _rejectReauthentication();
      return;
    }
    if (_deletedAccountToClear == null) {
      await _selectWorkspace(gateway.userId);
      return;
    }
    try {
      await _finishDeletion();
    } catch (_) {
      error = AccountAuthError.deletionCleanup;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _subscription?.cancel();
    _loginTimeout?.cancel();
    super.dispose();
  }
}
