import 'package:exercise_app/utils/expired_token_retry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

PostgrestException expired() => const PostgrestException(
      message: 'JWT expired',
      code: 'PGRST303',
      details: 'Unauthorized',
    );

void main() {
  group('isExpiredTokenError', () {
    test('recognises the PostgREST expiry code', () {
      expect(isExpiredTokenError(expired()), isTrue);
    });

    test('recognises an expiry reported without the code', () {
      expect(
        isExpiredTokenError(
          const PostgrestException(message: 'JWT expired'),
        ),
        isTrue,
      );
    });

    test('does not claim unrelated failures', () {
      expect(
        isExpiredTokenError(
          const PostgrestException(message: 'permission denied', code: '42501'),
        ),
        isFalse,
      );
      expect(isExpiredTokenError(Exception('network unreachable')), isFalse);
    });
  });

  group('retryOnExpiredToken', () {
    test('passes the result through when nothing fails', () async {
      var refreshes = 0;
      final result = await retryOnExpiredToken(
        action: () async => 'ok',
        refresh: () async => refreshes++,
      );
      expect(result, 'ok');
      expect(refreshes, 0, reason: 'must not refresh a working session');
    });

    test('refreshes once and retries when the token has expired', () async {
      var attempts = 0;
      var refreshes = 0;
      final result = await retryOnExpiredToken(
        action: () async {
          attempts++;
          if (attempts == 1) throw expired();
          return 'ok';
        },
        refresh: () async => refreshes++,
      );
      expect(result, 'ok');
      expect(attempts, 2);
      expect(refreshes, 1);
    });

    test('gives up after one retry rather than looping', () async {
      var attempts = 0;
      var refreshes = 0;
      await expectLater(
        retryOnExpiredToken(
          action: () async {
            attempts++;
            throw expired();
          },
          refresh: () async => refreshes++,
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(attempts, 2, reason: 'one original attempt plus one retry');
      expect(refreshes, 1);
    });

    test('rethrows the original error when the refresh itself fails', () async {
      var attempts = 0;
      await expectLater(
        retryOnExpiredToken(
          action: () async {
            attempts++;
            throw expired();
          },
          refresh: () async => throw Exception('offline'),
        ),
        // The caller needs to see the expiry, not the refresh failure: the
        // expiry is what its own error handling is written against.
        throwsA(
          isA<PostgrestException>().having((e) => e.code, 'code', 'PGRST303'),
        ),
      );
      expect(attempts, 1);
    });

    test('does not refresh for an unrelated failure', () async {
      var refreshes = 0;
      await expectLater(
        retryOnExpiredToken(
          action: () async => throw Exception('network unreachable'),
          refresh: () async => refreshes++,
        ),
        throwsA(isA<Exception>()),
      );
      expect(refreshes, 0);
    });
  });
}
