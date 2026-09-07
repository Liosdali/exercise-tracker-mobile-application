import 'dart:async';

import 'package:exercise_app/models/user_profile.dart';
import 'package:exercise_app/providers/auth_provider.dart';
import 'package:exercise_app/services/supabase_service.dart';
import 'package:exercise_app/services/user_account_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthGateway implements AuthGateway {
  final controller = StreamController<AccountAuthEvent>.broadcast(sync: true);
  @override
  bool configured = true;
  @override
  bool mobileSupported = true;
  @override
  String? userId;
  @override
  String? email;
  @override
  String? displayName;
  @override
  bool sessionValid = true;
  Object? loginFailure;
  bool deleteFails = false;
  Object? deletionFailure;
  final calls = <String>[];
  @override
  Stream<AccountAuthEvent> get events => controller.stream;
  void emit(String? id) {
    userId = id;
    controller.add(AccountAuthEvent.changed);
  }

  @override
  Future<bool> signIn(AccountLoginProvider provider) async {
    if (loginFailure != null) throw loginFailure!;
    return true;
  }

  @override
  Future<void> refreshSession() async {}
  @override
  Future<void> acknowledgeDisplayName() async {
    displayName = null;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    emit(null);
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('delete');
    if (deletionFailure != null) throw deletionFailure!;
    if (deleteFails) throw StateError('Server unavailable');
  }
}

class FakeAccounts extends ChangeNotifier implements UserAccountService {
  @override
  String? userId;
  @override
  UserProfile? profile = const UserProfile();
  final initializations = <String?>[];
  final gates = <String, Completer<void>>{};
  bool guestData = false;
  bool syncFails = false;
  bool importFails = false;
  bool cleanupFails = false;
  int imports = 0;
  int syncs = 0;
  final deleted = <String>[];
  @override
  Future<void> initialize(String? id) async {
    initializations.add(id);
    await gates[id]?.future;
    userId = id;
  }

  @override
  Future<void> updateProfile({
    required String name,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
  }) async {
    profile = UserProfile(
      id: userId,
      name: name,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      gender: gender,
    );
  }

  @override
  Future<bool> hasGuestData() async => guestData;
  @override
  Future<void> importGuestData() async {
    if (importFails) throw StateError('Import failed');
    imports++;
  }

  @override
  Future<void> sync() async {
    syncs++;
    if (syncFails) throw StateError('Offline');
  }

  @override
  Future<void> clearDeletedAccount(String id) async {
    if (cleanupFails) throw StateError('Device cleanup failed');
    deleted.add(id);
  }

  @override
  bool get isSyncing => false;
  @override
  int get pendingCount => 2;
  @override
  int conflictCount = 0;
  @override
  String? get syncError => syncFails ? 'offline' : null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> settleAuth() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAuthGateway gateway;
  late FakeAccounts accounts;
  late AuthProvider auth;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = FakeAuthGateway();
    accounts = FakeAccounts();
    auth = AuthProvider(gateway: gateway, accounts: accounts);
  });
  tearDown(() async {
    auth.dispose();
    accounts.dispose();
    await gateway.controller.close();
  });

  test(
    'confirmed deletion clears only its account-scoped auth metadata',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_apple_name:A', 'First name');
      await prefs.setString('pending_apple_name:B', 'Other name');
      await prefs.setBool('guest_import_decision:A', true);
      await prefs.setString(
        'apple_refresh_token_fingerprint:A',
        'non-secret-fingerprint',
      );
      gateway.userId = 'A';
      await auth.initialize();
      expect(await auth.deleteAccount(), isTrue);
      expect(prefs.containsKey('pending_apple_name:A'), isFalse);
      expect(prefs.getString('pending_apple_name:B'), 'Other name');
      expect(prefs.containsKey('guest_import_decision:A'), isFalse);
      expect(prefs.containsKey('apple_refresh_token_fingerprint:A'), isFalse);
      expect(prefs.containsKey('pending_account_cleanup'), isFalse);
    },
  );

  test(
    'Apple browser reauthentication rejects a different Supabase UUID before deletion',
    () async {
      gateway.userId = 'A';
      await auth.initialize();
      await auth.signIn(AccountLoginProvider.apple);
      gateway.emit('B');
      await settleAuth();
      expect(auth.error, AccountAuthError.appleAccountMismatch);
      expect(auth.userId, isNull);
      expect(accounts.initializations, ['A', null]);
      expect(accounts.deleted, isEmpty);
      expect(gateway.calls, ['signOut']);
    },
  );

  test(
    'delete refuses a gateway identity different from the active workspace',
    () async {
      gateway.userId = 'A';
      await auth.initialize();
      gateway.userId = 'B';
      expect(await auth.deleteAccount(), isFalse);
      expect(auth.error, AccountAuthError.appleAccountMismatch);
      expect(gateway.calls, isEmpty);
      expect(accounts.deleted, isEmpty);
    },
  );

  test(
    'workspace waits for provider teardown and notification cancellation barrier',
    () async {
      auth.dispose();
      final cancellation = Completer<void>();
      auth = AuthProvider(
        gateway: gateway,
        accounts: accounts,
        beforeWorkspaceSwitch: () => cancellation.future,
      );
      final initialization = auth.initialize();
      await settleAuth();
      expect(auth.accountGeneration, 1);
      expect(auth.workspaceReady, isFalse);
      expect(accounts.initializations, isEmpty);
      cancellation.complete();
      await initialization;
      expect(accounts.initializations, [null]);
      expect(auth.workspaceReady, isTrue);
    },
  );

  test(
    'missing configuration initializes guest before exposing workspace',
    () async {
      gateway.configured = false;
      expect(auth.workspaceReady, isFalse);
      await auth.initialize();
      expect(accounts.initializations, [null]);
      expect(auth.workspaceReady, isTrue);
      expect(auth.canSignIn, isFalse);
      expect(auth.error, AccountAuthError.configuration);
    },
  );

  test(
    'restored session opens account, never imports guest automatically',
    () async {
      gateway.userId = 'A';
      accounts.guestData = true;
      await auth.initialize();
      await settleAuth();
      expect(auth.userId, 'A');
      expect(accounts.initializations, ['A']);
      expect(auth.offerGuestImport, isTrue);
      expect(accounts.imports, 0);
    },
  );

  test(
    'late A initialization cannot expose A after B and guest transitions',
    () async {
      await auth.initialize();
      accounts.gates['A'] = Completer<void>();
      gateway.emit('A');
      await settleAuth();
      expect(auth.workspaceReady, isFalse);
      gateway.emit('B');
      accounts.gates['A']!.complete();
      await settleAuth();
      expect(auth.userId, 'B');
      expect(accounts.userId, 'B');
      expect(auth.workspaceReady, isTrue);
      await auth.signOut();
      expect(auth.userId, isNull);
      expect(accounts.userId, isNull);
      expect(accounts.initializations, [null, 'A', 'B', null]);
    },
  );

  test(
    'duplicate token callbacks do not recreate an account workspace',
    () async {
      gateway.userId = 'A';
      await auth.initialize();
      gateway.emit('A');
      gateway.emit('A');
      await settleAuth();
      expect(accounts.initializations, ['A']);
    },
  );

  test(
    'native cancellation and browser cancellation are recoverable',
    () async {
      await auth.initialize();
      gateway.loginFailure = LoginCancelled();
      await auth.signIn(AccountLoginProvider.apple);
      expect(auth.error, AccountAuthError.cancelled);
      expect(auth.busy, isFalse);
      gateway.loginFailure = null;
      await auth.signIn(AccountLoginProvider.google);
      expect(auth.waitingForBrowser, isTrue);
      auth.cancelSignIn();
      expect(auth.busy, isFalse);
      expect(auth.waitingForBrowser, isFalse);
      expect(auth.userId, isNull);
    },
  );

  test(
    'failed browser launch surfaces error without losing guest data',
    () async {
      await auth.initialize();
      gateway.loginFailure = StateError('Launch failed');
      await auth.signIn(AccountLoginProvider.google);
      expect(auth.error, AccountAuthError.login);
      expect(auth.workspaceReady, isTrue);
      expect(auth.userId, isNull);
    },
  );

  test(
    'offline restored account remains accessible and remote name is not overwritten',
    () async {
      gateway.userId = 'A';
      gateway.displayName = 'Provider name';
      accounts.syncFails = true;
      await auth.initialize();
      await settleAuth();
      expect(auth.workspaceReady, isTrue);
      expect(auth.userId, 'A');
      expect(accounts.profile!.name, isEmpty);
    },
  );

  test(
    'provider name never overwrites user edits or clears measurements',
    () async {
      gateway.userId = 'A';
      gateway.displayName = 'Provider name';
      accounts.profile = const UserProfile(
        name: 'Edited',
        age: 35,
        weightKg: 70,
      );
      await auth.initialize();
      await settleAuth();
      expect(accounts.profile!.name, 'Edited');
      expect(accounts.profile!.weightKg, 70);
    },
  );

  test('declining guest import is persisted once per account', () async {
    gateway.userId = 'A';
    accounts.guestData = true;
    await auth.initialize();
    await settleAuth();
    await auth.decideGuestImport(false);
    expect(auth.offerGuestImport, isFalse);
    expect(accounts.imports, 0);
    await auth.signOut();
    gateway.emit('A');
    await settleAuth();
    expect(auth.offerGuestImport, isFalse);
    gateway.emit('B');
    await settleAuth();
    expect(auth.offerGuestImport, isTrue);
  });

  test(
    'import requires consent, failure remains retryable, success reloads UI',
    () async {
      gateway.userId = 'A';
      accounts.guestData = true;
      await auth.initialize();
      await settleAuth();
      accounts.importFails = true;
      await auth.decideGuestImport(true);
      expect(auth.offerGuestImport, isTrue);
      expect(accounts.imports, 0);
      accounts.importFails = false;
      final revision = auth.workspaceRevision;
      await auth.decideGuestImport(true);
      expect(accounts.imports, 1);
      expect(auth.offerGuestImport, isFalse);
      expect(auth.workspaceRevision, greaterThan(revision));
    },
  );

  test(
    'failed remote deletion does not clear local account or sign out',
    () async {
      gateway.userId = 'A';
      gateway.deleteFails = true;
      await auth.initialize();
      expect(await auth.deleteAccount(), isFalse);
      expect(accounts.deleted, isEmpty);
      expect(gateway.calls, ['delete']);
      expect(auth.accountDeleted, isFalse);
      expect(auth.userId, 'A');
      expect(auth.workspaceReady, isTrue);
    },
  );

  test(
    'confirmed deletion clears only that account and returns to guest',
    () async {
      gateway.userId = 'A';
      await auth.initialize();
      expect(await auth.deleteAccount(), isTrue);
      expect(accounts.deleted, ['A']);
      expect(gateway.calls, ['delete', 'signOut']);
      expect(auth.accountDeleted, isTrue);
      expect(auth.userId, isNull);
      expect(auth.workspaceReady, isTrue);
    },
  );

  test(
    'confirmed remote deletion with local failure stays locked until cleanup retry',
    () async {
      gateway.userId = 'A';
      accounts.cleanupFails = true;
      await auth.initialize();
      expect(await auth.deleteAccount(), isFalse);
      expect(auth.workspaceReady, isFalse);
      expect(auth.error, AccountAuthError.deletionCleanup);
      gateway.emit('A');
      await settleAuth();
      expect(auth.workspaceReady, isFalse);
      accounts.cleanupFails = false;
      await auth.retryWorkspace();
      expect(accounts.deleted, ['A']);
      expect(gateway.calls.where((call) => call == 'delete').length, 1);
      expect(auth.workspaceReady, isTrue);
      expect(auth.userId, isNull);
      expect(auth.error, isNull);
    },
  );

  test(
    'expired restored session keeps cached account but pauses sync',
    () async {
      gateway.userId = 'A';
      gateway.sessionValid = false;
      await auth.initialize();
      await settleAuth();
      expect(auth.workspaceReady, isTrue);
      expect(auth.userId, 'A');
      expect(auth.error, AccountAuthError.expired);
      expect(accounts.syncs, 0);
      gateway.sessionValid = true;
      gateway.emit('A');
      await settleAuth();
      expect(auth.error, isNull);
      expect(accounts.syncs, greaterThan(0));
    },
  );

  test(
    'first Apple name survives failed sync and fills only after recovery',
    () async {
      gateway.userId = 'A';
      gateway.displayName = 'First Apple name';
      accounts.syncFails = true;
      accounts.profile = const UserProfile(age: 30, weightKg: 65);
      await auth.initialize();
      await settleAuth();
      expect(gateway.displayName, 'First Apple name');
      expect(accounts.profile!.name, isEmpty);
      accounts.syncFails = false;
      await auth.sync();
      expect(accounts.profile!.name, 'First Apple name');
      expect(accounts.profile!.age, 30);
      expect(accounts.profile!.weightKg, 65);
      expect(gateway.displayName, isNull);
    },
  );

  test(
    'browser denial reports cancellation rather than expired guest session',
    () async {
      await auth.initialize();
      await auth.signIn(AccountLoginProvider.google);
      gateway.controller.addError(LoginCancelled());
      expect(auth.error, AccountAuthError.cancelled);
      expect(auth.waitingForBrowser, isFalse);
      expect(auth.busy, isFalse);
    },
  );

  test(
    'missing Apple revocation credential never clears account and supports browser reauthentication',
    () async {
      gateway.userId = 'A';
      gateway.deletionFailure = AppleReauthenticationRequired();
      await auth.initialize();
      expect(await auth.deleteAccount(), isFalse);
      expect(auth.error, AccountAuthError.appleReauthentication);
      expect(accounts.deleted, isEmpty);
      await auth.signIn(AccountLoginProvider.apple);
      expect(auth.waitingForBrowser, isTrue);
      gateway.emit('A');
      await settleAuth();
      expect(auth.waitingForBrowser, isFalse);
      expect(accounts.initializations, ['A']);
    },
  );

  test(
    'cancelling native Apple deletion leaves the Supabase identity unchanged',
    () async {
      gateway.userId = 'A';
      gateway.deletionFailure = LoginCancelled();
      await auth.initialize();
      expect(await auth.deleteAccount(), isFalse);
      expect(auth.error, AccountAuthError.deletionCancelled);
      expect(auth.userId, 'A');
      expect(accounts.deleted, isEmpty);
      expect(gateway.calls, ['delete']);
    },
  );

  test(
    'server setup and Apple identity failures remain actionable without local deletion',
    () async {
      gateway.userId = 'A';
      await auth.initialize();
      gateway.deletionFailure = AccountDeletionUnavailable();
      expect(await auth.deleteAccount(), isFalse);
      expect(auth.error, AccountAuthError.deletionUnavailable);
      gateway.deletionFailure = AppleAccountMismatch();
      expect(await auth.deleteAccount(), isFalse);
      expect(auth.error, AccountAuthError.appleAccountMismatch);
      expect(accounts.deleted, isEmpty);
      expect(auth.userId, 'A');
    },
  );
}
