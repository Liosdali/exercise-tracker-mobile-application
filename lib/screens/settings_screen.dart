import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../providers/custom_program_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';
import '../services/backup_service.dart';
import '../services/supabase_service.dart';
import '../services/user_account_service.dart';
import '../theme/atlas_colors.dart';
import 'about_screen.dart';
import 'account_section.dart';

/// True when a destructive data action would discard work that has not yet
/// reached the cloud.
///
/// Guest workspaces return false: they have no cloud copy, so there is no
/// "lost on the way to your other devices" to warn about — the plain guest
/// reset warning already covers losing local data.
bool losesUnsyncedWork({
  required bool signedIn,
  required int pending,
  required int conflicts,
}) => signedIn && (pending > 0 || conflicts > 0);

/// Settings screen: manual language override, rest-timer/weekly-goal
/// preferences, and a "reset all data" factory-reset action.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// The amount of work that has not reached the cloud, phrased as a warning,
  /// or an empty string when there is nothing to lose. A reset destroys
  /// unsynced changes outright: unlike signing out, no workspace is left
  /// holding them afterwards, so the user is told what is at stake before
  /// confirming rather than discovering it later.
  String _unsyncedWarning(BuildContext context, AppLocalizations l10n) {
    final account = context.read<UserAccountService>();
    if (!losesUnsyncedWork(
      signedIn: context.read<AuthProvider>().signedIn,
      pending: account.pendingCount,
      conflicts: account.conflictCount,
    )) {
      return '';
    }
    return '\n\n'
        '${l10n.accountPendingLossWarning(account.pendingCount, account.conflictCount)}';
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final message =
        '${l10n.settingsResetDataConfirmMessage}\n\n'
        '${context.read<AuthProvider>().signedIn ? l10n.accountCloudResetWarning : l10n.accountGuestResetWarning}'
        '${_unsyncedWarning(context, l10n)}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsResetDataConfirmTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await DatabaseHelper.instance.resetAllData();
      if (!context.mounted) return;

      await Future.wait([
        context.read<StatsProvider>().load(),
        context.read<WorkoutProvider>().init(),
        context.read<CustomProgramProvider>().load(),
        context.read<RoutineProvider>().load(),
        context.read<ProgramProgressProvider>().load(),
        context.read<SettingsProvider>().resetToDefaults(),
        // The delete triggers have just rewritten sync_records; without this
        // the account card keeps showing the pre-reset pending count until
        // the periodic sync happens to run.
        context.read<UserAccountService>().refresh(),
      ]);
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsResetDataSuccess)));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountOperationError)));
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await BackupService.exportAndShare();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsBackupExportSuccess)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsBackupExportError)));
    }
  }

  Future<void> _importData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final file = await BackupService.pickBackupFile().catchError((Object _) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsBackupImportError)));
      }
      return null;
    });
    if (file == null || file.bytes == null) return;
    if (!context.mounted) return;

    late final String jsonString;
    Map<String, int> counts;
    try {
      jsonString = utf8.decode(file.bytes!);
      counts = BackupService.previewCounts(jsonString);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsBackupImportInvalidFile)),
      );
      return;
    }

    final totalRows = counts.values.fold<int>(0, (a, b) => a + b);
    if (!context.mounted) return;
    final importMessage =
        '${l10n.settingsBackupImportConfirmMessage('$totalRows')}\n\n'
        '${context.read<AuthProvider>().signedIn ? l10n.accountCloudImportWarning : l10n.accountGuestResetWarning}'
        '${_unsyncedWarning(context, l10n)}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsBackupImportConfirmTitle),
        content: Text(importMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await BackupService.restoreFromJson(jsonString);
      if (!context.mounted) return;

      await Future.wait([
        context.read<StatsProvider>().load(),
        context.read<WorkoutProvider>().init(),
        context.read<CustomProgramProvider>().load(),
        context.read<RoutineProvider>().load(),
        context.read<ProgramProgressProvider>().load(),
        context.read<SettingsProvider>().load(),
        context.read<UserAccountService>().refresh(),
      ]);
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsBackupImportSuccess)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsBackupImportError)));
    }
  }

  Future<void> _showDisclaimer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDisclaimerTitle),
        content: SingleChildScrollView(
          child: Text(l10n.settingsDisclaimerBody),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.settingsDisclaimerClose),
          ),
        ],
      ),
    );
  }

  Future<void> _replayTutorial(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    await settings.setHasSeenTutorial(false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountDelete),
        content: Text(l10n.accountDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.accountDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await auth.deleteAccount();
    // Successful deletion resets the entire account navigator to guest mode.
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error != null && auth.error != AccountAuthError.operation
                ? accountErrorText(l10n, auth.error!)
                : l10n.accountDeleteError,
          ),
          action:
              (auth.error == AccountAuthError.appleReauthentication ||
                      auth.error == AccountAuthError.appleAccountMismatch) &&
                  auth.canSignIn
              ? SnackBarAction(
                  label: l10n.accountAppleReauthenticateButton,
                  onPressed: () => auth.signIn(AccountLoginProvider.apple),
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const AccountSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settingsLanguageSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioListTile<String?>(
            title: Text(l10n.settingsLanguageSystem),
            value: null,
            // ignore: deprecated_member_use
            groupValue: settings.languageCode,
            // ignore: deprecated_member_use
            onChanged: (v) => settings.setLanguageCode(v),
          ),
          RadioListTile<String?>(
            title: Text(l10n.settingsLanguageTurkish),
            value: 'tr',
            // ignore: deprecated_member_use
            groupValue: settings.languageCode,
            // ignore: deprecated_member_use
            onChanged: (v) => settings.setLanguageCode(v),
          ),
          RadioListTile<String?>(
            title: Text(l10n.settingsLanguageEnglish),
            value: 'en',
            // ignore: deprecated_member_use
            groupValue: settings.languageCode,
            // ignore: deprecated_member_use
            onChanged: (v) => settings.setLanguageCode(v),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settingsThemeSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.settingsThemeSystem),
            value: ThemeMode.system,
            // ignore: deprecated_member_use
            groupValue: settings.themeMode,
            // ignore: deprecated_member_use
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.settingsThemeLight),
            value: ThemeMode.light,
            // ignore: deprecated_member_use
            groupValue: settings.themeMode,
            // ignore: deprecated_member_use
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.settingsThemeDark),
            value: ThemeMode.dark,
            // ignore: deprecated_member_use
            groupValue: settings.themeMode,
            // ignore: deprecated_member_use
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.settingsWeeklyGoalLabel),
            trailing: _Stepper(
              value: settings.weeklyGoal,
              onChanged: (v) => settings.setWeeklyGoal(v),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.settingsRestTimerSound),
            value: settings.soundEnabled,
            onChanged: (v) => settings.setSoundEnabled(v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsRestTimerVibration),
            value: settings.vibrationEnabled,
            onChanged: (v) => settings.setVibrationEnabled(v),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settingsNotificationsSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsMasterToggle),
            value: settings.notificationsEnabled,
            onChanged: (v) => settings.setNotificationsEnabled(v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsStreakToggle),
            subtitle: Text(l10n.settingsNotificationsStreakSubtitle),
            value: settings.streakWarningsEnabled,
            onChanged: settings.notificationsEnabled
                ? (v) => settings.setStreakWarningsEnabled(v)
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.settingsNotificationsDailyToggle),
            subtitle: Text(l10n.settingsNotificationsDailySubtitle),
            value: settings.dailyReminderEnabled,
            onChanged: settings.notificationsEnabled
                ? (v) => settings.setDailyReminderEnabled(v)
                : null,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settingsBackupSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.settingsBackupPrivacyNote}\n${l10n.accountBackupScope}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => _exportData(context),
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.settingsBackupExportButton),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => _importData(context),
              icon: const Icon(Icons.download_for_offline_outlined),
              label: Text(l10n.settingsBackupImportButton),
            ),
          ),
          const Divider(),
          if (auth.signedIn)
            ListTile(
              leading: Icon(Icons.delete_forever, color: context.atlas.danger),
              title: Text(
                l10n.accountDelete,
                style: TextStyle(color: context.atlas.danger),
              ),
              subtitle: Text(l10n.accountDeleteSummary),
              onTap: auth.busy ? null : () => _deleteAccount(context),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settingsResetDataSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.delete_forever),
              label: Text(l10n.settingsResetDataButton),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.settingsTutorialSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: Text(l10n.settingsReplayTutorialButton),
            onTap: () => _replayTutorial(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAboutTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: Text(l10n.settingsDisclaimerButton),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDisclaimer(context),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
