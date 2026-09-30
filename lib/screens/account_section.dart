import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../services/user_account_service.dart';
import 'profile_edit_screen.dart';
import 'sync_conflicts_screen.dart';

String accountErrorText(AppLocalizations l10n, AccountAuthError error) {
  switch (error) {
    case AccountAuthError.configuration:
      return l10n.accountConfigurationError;
    case AccountAuthError.login:
      return l10n.accountLoginError;
    case AccountAuthError.cancelled:
      return l10n.accountLoginCancelled;
    case AccountAuthError.expired:
      return l10n.accountSessionExpired;
    case AccountAuthError.operation:
      return l10n.accountOperationError;
    case AccountAuthError.workspace:
      return l10n.accountWorkspaceError;
    case AccountAuthError.deletionCleanup:
      return l10n.accountDeletionCleanupError;
    case AccountAuthError.appleReauthentication:
      return l10n.accountAppleReauthentication;
    case AccountAuthError.deletionCancelled:
      return l10n.accountDeletionCancelled;
    case AccountAuthError.deletionUnavailable:
      return l10n.accountDeletionUnavailable;
    case AccountAuthError.appleAccountMismatch:
      return l10n.accountAppleMismatch;
  }
}

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  Future<void> _signOut(
    BuildContext context,
    AuthProvider auth,
    int pending,
    int conflicts,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountSignOut),
        content: Text(l10n.accountSignOutWarning(pending, conflicts)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.accountSignOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final account = context.watch<UserAccountService>();
    final profile = account.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              profile?.name.isNotEmpty == true
                  ? profile!.name
                  : (auth.signedIn ? l10n.accountSignedIn : l10n.accountGuest),
            ),
            Text(
              auth.signedIn
                  ? (auth.email ?? l10n.accountSignedIn)
                  : l10n.accountGuestDescription,
            ),
            TextButton.icon(
              onPressed: auth.busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen(),
                      ),
                    ),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.accountEditProfile),
            ),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  accountErrorText(l10n, auth.error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if ((auth.error == AccountAuthError.appleReauthentication ||
                    auth.error == AccountAuthError.appleAccountMismatch) &&
                auth.canSignIn)
              FilledButton.icon(
                onPressed: auth.busy
                    ? null
                    : () => auth.signIn(AccountLoginProvider.apple),
                icon: const Icon(Icons.apple),
                label: Text(l10n.accountAppleReauthenticateButton),
              ),
            if (!auth.signedIn || auth.error == AccountAuthError.expired) ...[
              if (!auth.gateway.configured &&
                  auth.error != AccountAuthError.configuration)
                Text(l10n.accountConfigurationError),
              if (!auth.gateway.mobileSupported) Text(l10n.accountMobileOnly),
              if (auth.gateway.mobileSupported) ...[
                FilledButton.icon(
                  onPressed: auth.canSignIn && !auth.busy
                      ? () => auth.signIn(AccountLoginProvider.google)
                      : null,
                  icon: const Icon(Icons.login),
                  label: Text(l10n.accountGoogle),
                ),
                OutlinedButton.icon(
                  onPressed: auth.canSignIn && !auth.busy
                      ? () => auth.signIn(AccountLoginProvider.apple)
                      : null,
                  icon: const Icon(Icons.apple),
                  label: Text(l10n.accountApple),
                ),
              ],
            ],
            if (auth.busy) const LinearProgressIndicator(),
            if (auth.waitingForBrowser) ...[
              Text(l10n.accountBrowserWaiting),
              TextButton(
                onPressed: auth.cancelSignIn,
                child: Text(l10n.commonCancel),
              ),
            ],
            if (auth.offerGuestImport) ...[
              const Divider(),
              Text(
                l10n.accountGuestImportTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(l10n.accountGuestImportMessage),
              FilledButton(
                onPressed: auth.busy
                    ? null
                    : () => auth.decideGuestImport(true),
                child: Text(l10n.accountGuestImportAccept),
              ),
              TextButton(
                onPressed: auth.busy
                    ? null
                    : () => auth.decideGuestImport(false),
                child: Text(l10n.accountGuestImportDecline),
              ),
            ],
            if (auth.signedIn) ...[
              const Divider(),
              Text(
                account.isSyncing
                    ? l10n.accountSyncing
                    : l10n.accountPending(account.pendingCount),
              ),
              if (account.syncError != null) Text(l10n.accountSyncError),
              TextButton.icon(
                onPressed: account.isSyncing || auth.busy ? null : auth.sync,
                icon: const Icon(Icons.sync),
                label: Text(l10n.accountSyncNow),
              ),
              if (account.conflictCount > 0)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SyncConflictsScreen(),
                    ),
                  ),
                  child: Text(l10n.accountConflicts(account.conflictCount)),
                ),
              OutlinedButton(
                onPressed: auth.busy
                    ? null
                    : () => _signOut(
                        context,
                        auth,
                        account.pendingCount,
                        account.conflictCount,
                      ),
                child: Text(l10n.accountSignOut),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
