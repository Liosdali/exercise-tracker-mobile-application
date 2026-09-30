import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether [error] is the server rejecting a request for an expired token.
///
/// PostgREST reports this as `PGRST303`, but older and proxied responses carry
/// only the message, so both are checked.
bool isExpiredTokenError(Object error) {
  if (error is! PostgrestException) return false;
  if (error.code == 'PGRST303') return true;
  final message = error.message.toLowerCase();
  return message.contains('jwt') && message.contains('expired');
}

/// Runs [action]; if the server rejects it because the access token has
/// expired, calls [refresh] once and runs [action] again.
///
/// This exists because `Session.isExpired` is evaluated against the DEVICE
/// clock. A device whose clock lags real time — an emulator that slept, a
/// phone with the wrong time, a laptop resuming from suspend — believes its
/// token is still fresh, so the client never auto-refreshes, while the server
/// correctly rejects it. The user then sees a failure whose Retry button
/// cannot help, because retrying re-sends the same stale token.
///
/// Exactly one retry: a second expiry after a successful refresh means
/// something other than staleness is wrong, and looping would hammer the
/// server. If [refresh] itself fails, the ORIGINAL expiry is rethrown — that
/// is the failure the caller's error handling is written against, and it
/// describes the user's situation better than a refresh error would.
Future<T> retryOnExpiredToken<T>({
  required Future<T> Function() action,
  required Future<void> Function() refresh,
}) async {
  try {
    return await action();
  } catch (error) {
    if (!isExpiredTokenError(error)) rethrow;
    try {
      await refresh();
    } catch (_) {
      // Deliberately `throw error`, not `rethrow`: inside this inner catch
      // `rethrow` would surface the refresh failure and hide the expiry.
      throw error;
    }
    return await action();
  }
}
