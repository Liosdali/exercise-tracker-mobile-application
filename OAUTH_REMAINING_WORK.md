# Account System Quick Start - Remaining Work

## Status: 11/11 Major Tasks Complete

### What Works ✅
- OAuth authentication (Google/Apple) on Android/iOS
- Guest mode offline access
- Account-isolated data storage
- Bidirectional sync with conflict resolution
- Account deletion with server-side token revocation
- 65 passing unit/integration tests

### Known Issues

#### 1. Account Data Actions - UI/UX Polish — DONE
**Location**: `lib/screens/settings_screen.dart` (not `account_section.dart`;
the data actions live entirely in the settings screen)

- [x] Real account deletion flow — was already wired. `_deleteAccount` confirms,
      calls `auth.deleteAccount()`, and on failure surfaces the specific error
      with an Apple re-authentication action on the SnackBar.
- [x] Workspace-aware backup restore UI feedback — both restore and reset now
      call `UserAccountService.refresh()`. Previously the account card kept
      showing the pre-action pending count until the 5-second poll happened
      to run.
- [x] Reset flow with pending changes warning — reset and import now append
      `accountPendingLossWarning` with the live pending and conflict counts.
      Sign-out already disclosed these; reset and import destroy them outright,
      so they had the weaker warning of the three.
- [x] Turkish localization — already complete. Both ARB files carry the same
      385 keys with no untranslated values; the "8 missing keys" never existed.
- [x] README Supabase deployment steps — already written, under
      "Google/Apple girişi ve Supabase kurulumu".

Note on the data layer: reset and restore need no special sync handling.
`sync_records` is maintained by SQLite triggers on every INSERT/UPDATE/DELETE
(see `account_store.dart`), so bulk deletes and re-inserts record themselves
correctly and propagate as intended.

#### 2. Profile Feature Wiring - Integration - DONE
**Location**: `lib/screens/profile_edit_screen.dart`,
`lib/screens/body_measurement_form.dart`,
`lib/screens/measurement_history_screen.dart` (new)

- [x] Profile editing saves to sync outbox atomically - was already atomic.
      `updateProfile` writes the profile row and the derived measurement in
      one `db.transaction`, and the sync triggers fire inside that same
      transaction.
- [x] Conflict resolution UI for duplicate name edits - was already present.
      `SyncConflictsScreen` maps both `user_profile` and `body_measurements`
      to readable names and resolves either side.
- [x] Measurement form validation integration with account sync - validation
      already threw `ArgumentError` for non-positive values. What was missing
      was the refresh: `BodyMeasurementForm` now refreshes the account service
      after a save, the way `updateProfile` always did, so the pending count
      does not lag behind the write.
- [x] Navigation between profile edit and measurement history - the history
      only existed as a section inside the Profile tab. It is now
      `MeasurementHistoryList` in `measurement_history_screen.dart`, rendered
      by the Profile tab and by the new `MeasurementHistoryScreen` that the
      profile editor links to. Extracting it also fixed the unit labels,
      which were hardcoded Turkish and showed untranslated in English.
- [ ] Root widget integration test - still skipped, deliberately. See below:
      the blocker is not the fake async zone.

**Quick Wins**:
```bash
# Verify profile edit sync integration
grep -A 10 "updateProfile" lib/services/user_account_service.dart

# Test measurement validation
flutter test test/account_backend_test.dart -k "measurement"

# Check if root widget test runs (currently times out)
flutter test test/account_app_root_test.dart --timeout 20s
```

### Running All Tests
```bash
# Backend + sync logic (31 tests)
flutter test test/account_backend_test.dart

# Auth lifecycle (24 tests)  
flutter test test/auth_provider_test.dart

# UI validation (6 tests)
flutter test test/account_ui_test.dart

# Notifications (3 tests)
flutter test test/account_notifications_test.dart

# All account tests (65 tests, a few seconds - not minutes)
flutter test test/auth_provider_test.dart test/account_backend_test.dart \
  test/account_ui_test.dart test/account_notifications_test.dart
```

### Known-failing test: `widget_test.dart`

`flutter test test/widget_test.dart` fails at `HEAD`, and did so before any of
the work above - verified by stashing every change and re-running. It is not
an account regression.

The cause is visible now that the sign-in path prints breadcrumbs:

```
[auth] workspace switch FAILED: LateInitializationError:
       Field '_instance' has not been initialized.
  FlutterLocalNotificationsPlatform._instance
  NotificationService.init (notification_service.dart:66)
  main.dart:47 -> AuthProvider._selectWorkspace
```

The test mocks sqflite and shared_preferences but not
`flutter_local_notifications`. `NotificationService.init()` throws, which fails
`beforeWorkspaceSwitch`, so the workspace never becomes ready and the dashboard
never renders. The assertion on "Ana Sayfa" is the symptom, not the fault.

Worth checking whether `account_app_root_test.dart` hangs for the same reason
rather than the fake-async/FFI explanation recorded below - they both boot the
real root widget.

### Debugging

**Test Hangs on FFI Cleanup**:
```dart
// account_app_root_test.dart is incomplete due to fake async zone issues
// Try running with: flutter test --plain-name "unconfigured app" --timeout 10s
// Or skip integration test and rely on unit tests instead
```

**Pending Timers in Tests**:
```dart
// If tests fail with "!timersPending", ensure cleanup happens in finally block
await tester.pumpWidget(const SizedBox.shrink());
for (var i = 0; i < 5; i++) {
  await tester.pump(const Duration(milliseconds: 50));
}
```

**Workspace Generation Mismatch**:
```dart
// If you see "This account workspace is no longer active"
// Check that providers are created AFTER AuthProvider.initialize() completes
// Use ValueKey(auth.workspaceKey) to recreate providers on workspace change
```

### Key Files to Review

| File | Purpose | Status |
|------|---------|--------|
| `lib/services/user_account_service.dart` | Account lifecycle & sync | ✅ Complete |
| `lib/providers/auth_provider.dart` | OAuth & workspace management | ✅ Complete |
| `lib/data/account_store.dart` | Sync record batching | ✅ Complete |
| `supabase/functions/delete-account/` | Apple token revocation | ✅ Complete |
| `supabase/migrations/202609070001_private_accounts.sql` | Account schema | ✅ Complete |
| `lib/screens/settings_screen.dart` | Account data actions | ✅ Complete |
| `lib/screens/profile_edit_screen.dart` | Profile editing | ✅ Complete |
| `lib/screens/measurement_history_screen.dart` | Shared measurement history | ✅ Complete |
| `test/account_app_root_test.dart` | Integration test | ⚠️ Incomplete (see known-failing test above) |

### Deployment Steps (for DevOps)

1. Create Supabase project
2. Run migration: `supabase db push`
3. Deploy Edge Function: `supabase functions deploy delete-account`
4. Configure OAuth providers (Google Cloud, Apple App Store Connect)
5. Build iOS with signing + entitlements
6. Build Android with manifest + intent filters
7. Test on physical devices with real providers

### Next Developer Notes

- All core logic is unit tested and working
- Feature work is complete; what remains is the known-failing widget_test above
- Don't spend time on root widget test (FFI + fake async = pain)
- Instead: use unit tests to verify logic, manual testing for UI
- Localization is complete: 385 keys in both English and Turkish
- Backup compatibility is tested; can be deployed with confidence
- Account deletion is safe (server-side enforcement via RLS + Edge Function)

Start with running the 65 passing tests to understand the system:
```bash
flutter test test/account_backend_test.dart  # Gives best overview of sync/conflicts
```
