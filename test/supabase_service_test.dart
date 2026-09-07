import 'package:exercise_app/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _LogoutAuth implements GoTrueClient {
  bool clearSession = true;
  SignOutScope? requestedScope;
  @override
  Session? currentSession = Session(
    accessToken: 'non-secret-test-token',
    tokenType: 'bearer',
    user: User(
      id: 'A',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '',
    ),
  );

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    requestedScope = scope;
    if (clearSession) currentSession = null;
    throw StateError('Remote logout unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements SupabaseClient {
  _Client(this.auth);
  @override
  final GoTrueClient auth;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SessionStorage extends EmptyLocalStorage {
  bool removed = false;
  bool fail = false;
  @override
  Future<void> removePersistedSession() async {
    if (fail) throw StateError('Storage unavailable');
    removed = true;
  }
}

void main() {
  test(
    'remote logout failure does not fail confirmed local session cleanup',
    () async {
      final auth = _LogoutAuth();
      final storage = _SessionStorage();
      final service = SupabaseService.forTesting(_Client(auth), storage);
      await service.signOut();
      expect(auth.requestedScope, SignOutScope.local);
      expect(auth.currentSession, isNull);
      expect(storage.removed, isTrue);
    },
  );

  test('logout failure that retains the local session is not masked', () async {
    final auth = _LogoutAuth()..clearSession = false;
    final storage = _SessionStorage();
    final service = SupabaseService.forTesting(_Client(auth), storage);
    await expectLater(service.signOut(), throwsStateError);
    expect(auth.currentSession, isNotNull);
    expect(storage.removed, isFalse);
  });

  test('persisted credential cleanup failure remains retryable', () async {
    final auth = _LogoutAuth();
    final storage = _SessionStorage()..fail = true;
    final service = SupabaseService.forTesting(_Client(auth), storage);
    await expectLater(service.signOut(), throwsStateError);
    storage.fail = false;
    await service.signOut();
    expect(storage.removed, isTrue);
  });
}
