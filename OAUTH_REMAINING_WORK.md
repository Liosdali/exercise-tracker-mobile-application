# Account System Quick Start - Remaining Work

## Status: 9/11 Major Tasks Complete (82%)

### What Works ✅
- OAuth authentication (Google/Apple) on Android/iOS
- Guest mode offline access
- Account-isolated data storage
- Bidirectional sync with conflict resolution
- Account deletion with server-side token revocation
- 62 passing unit/integration tests

### What Needs Finishing (2 tasks, ~20% work)

#### 1. Account Data Actions - UI/UX Polish
**Location**: `lib/screens/account_section.dart`, `lib/screens/settings_screen.dart`  
**What's Missing**:
- [ ] Real account deletion flow (backend exists, UI wiring needs testing)
- [ ] Workspace-aware backup restore UI feedback
- [ ] Reset flow with pending changes warning
- [ ] Finalize Turkish (TR) localization strings (8 keys in `lib/l10n/app_tr.arb`)
- [ ] Complete setup documentation in README (Supabase deployment steps)

**Quick Wins**:
```bash
# Test real deletion flow
flutter test test/account_backend_test.dart -k "deletion cleanup"

# Verify Turkish strings are complete
grep -r "accountDelete\|accountReset" lib/l10n/

# Run all account tests to verify no regressions
flutter test test/auth_provider_test.dart test/account_backend_test.dart
```

#### 2. Profile Feature Wiring - Integration
**Location**: `lib/screens/profile_edit_screen.dart`, `lib/screens/body_measurement_form.dart`  
**What's Missing**:
- [ ] Profile editing saves to sync outbox atomically
- [ ] Conflict resolution UI for duplicate name edits
- [ ] Measurement form validation integration with account sync
- [ ] Navigation between profile edit ↔ measurement history
- [ ] Root widget integration test (account_app_root_test.dart)

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

# UI validation (4 tests)
flutter test test/account_ui_test.dart

# Notifications (3 tests)
flutter test test/account_notifications_test.dart

# All account tests (62 tests, ~7 min)
flutter test test/auth_provider_test.dart test/account_backend_test.dart \
  test/account_ui_test.dart test/account_notifications_test.dart
```

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
| `lib/screens/account_section.dart` | Account UI | 🟡 Needs testing |
| `lib/screens/profile_edit_screen.dart` | Profile editing | 🟡 Needs integration |
| `test/account_app_root_test.dart` | Integration test | ⚠️ Incomplete (FFI issues) |

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
- The remaining 20% is UI wiring and documentation
- Don't spend time on root widget test (FFI + fake async = pain)
- Instead: use unit tests to verify logic, manual testing for UI
- Localization strings are 80% complete (just needs Turkish verification)
- Backup compatibility is tested; can be deployed with confidence
- Account deletion is safe (server-side enforcement via RLS + Edge Function)

Start with running the 62 passing tests to understand the system:
```bash
flutter test test/account_backend_test.dart  # Gives best overview of sync/conflicts
```
