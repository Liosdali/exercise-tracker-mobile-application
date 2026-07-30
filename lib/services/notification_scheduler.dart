import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../providers/custom_program_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/program_resolver.dart';
import 'notification_service.dart';

/// Decides when the streak-loss warnings and the daily scheduled-workout
/// reminder should fire, and (re)schedules them via [NotificationService].
///
/// Fully offline / local-only: re-run this (e.g. every time the dashboard
/// is shown) so the schedule always reflects the latest stats/settings.
class NotificationScheduler {
  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static Future<void> reschedule({
    required AppLocalizations l10n,
    required StatsProvider stats,
    required SettingsProvider settings,
    required ProgramProgressProvider progress,
    required ProgramProvider builtinPrograms,
    required CustomProgramProvider customPrograms,
    required WorkoutProvider workoutProvider,
  }) async {
    final notifier = NotificationService.instance;

    if (!settings.notificationsEnabled) {
      await notifier.cancel(NotificationService.idStreakWarning2DaysLeft);
      await notifier.cancel(NotificationService.idStreakWarningLastDay);
      await notifier.cancel(NotificationService.idDailyWorkoutReminder);
      return;
    }

    await _rescheduleStreakWarnings(l10n: l10n, stats: stats, settings: settings, notifier: notifier);
    await _rescheduleDailyReminder(
      l10n: l10n,
      settings: settings,
      progress: progress,
      builtinPrograms: builtinPrograms,
      customPrograms: customPrograms,
      workoutProvider: workoutProvider,
      notifier: notifier,
    );
  }

  static Future<void> _rescheduleStreakWarnings({
    required AppLocalizations l10n,
    required StatsProvider stats,
    required SettingsProvider settings,
    required NotificationService notifier,
  }) async {
    if (!settings.streakWarningsEnabled || stats.currentStreak <= 0 || stats.lastWorkoutDate == null) {
      await notifier.cancel(NotificationService.idStreakWarning2DaysLeft);
      await notifier.cancel(NotificationService.idStreakWarningLastDay);
      return;
    }

    // The streak resets once 7 full days pass without a new workout, i.e.
    // on lastWorkoutDate + 7 days. Warn 2 days before that (day 5) and on
    // the very last day before the reset (day 6).
    final lastWorkoutDate = stats.lastWorkoutDate!;
    final twoDaysLeftAt = DateTime(lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day, 9)
        .add(const Duration(days: 5));
    final lastDayAt = DateTime(lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day, 9)
        .add(const Duration(days: 6));

    await notifier.scheduleAt(
      id: NotificationService.idStreakWarning2DaysLeft,
      title: l10n.notificationStreakWarning2DaysTitle,
      body: l10n.notificationStreakWarning2DaysBody(stats.currentStreak),
      dateTime: twoDaysLeftAt,
    );
    await notifier.scheduleAt(
      id: NotificationService.idStreakWarningLastDay,
      title: l10n.notificationStreakWarningLastDayTitle,
      body: l10n.notificationStreakWarningLastDayBody(stats.currentStreak),
      dateTime: lastDayAt,
    );
  }

  static Future<void> _rescheduleDailyReminder({
    required AppLocalizations l10n,
    required SettingsProvider settings,
    required ProgramProgressProvider progress,
    required ProgramProvider builtinPrograms,
    required CustomProgramProvider customPrograms,
    required WorkoutProvider workoutProvider,
    required NotificationService notifier,
  }) async {
    if (!settings.dailyReminderEnabled) {
      await notifier.cancel(NotificationService.idDailyWorkoutReminder);
      return;
    }

    final now = DateTime.now();
    final today = _fmt(now);
    final todayCompleted = workoutProvider.loggedDates.contains(today);
    if (todayCompleted) {
      await notifier.cancel(NotificationService.idDailyWorkoutReminder);
      return;
    }

    // Mirror dashboard_screen.dart's suggestion logic: a manually assigned
    // day for today takes priority, otherwise fall back to the active
    // program's next sequential day.
    ResolvedProgramDay? suggested;
    final planned = progress.plannedFor(today);
    if (planned != null) {
      suggested = resolveProgramDay(
        programKey: planned.programKey,
        dayIndex: planned.dayIndex,
        builtinPrograms: builtinPrograms,
        customPrograms: customPrograms,
        l10n: l10n,
      );
    } else {
      final activeKey = settings.activeProgramKey ??
          (builtinPrograms.programs.isNotEmpty ? 'builtin:${builtinPrograms.programs.first.id}' : null);
      if (activeKey != null) {
        final nextIndex = progress.cachedNextDayIndex(
          activeKey,
          dayNamesFor(activeKey, builtinPrograms, customPrograms).length,
        );
        suggested = resolveProgramDay(
          programKey: activeKey,
          dayIndex: nextIndex,
          builtinPrograms: builtinPrograms,
          customPrograms: customPrograms,
          l10n: l10n,
        );
      }
    }

    if (suggested == null) {
      await notifier.cancel(NotificationService.idDailyWorkoutReminder);
      return;
    }

    final reminderAt = DateTime(now.year, now.month, now.day, 7);
    await notifier.scheduleAt(
      id: NotificationService.idDailyWorkoutReminder,
      title: l10n.notificationDailyReminderTitle,
      body: l10n.notificationDailyReminderBody(suggested.programTitle, suggested.dayName),
      dateTime: reminderAt,
    );
  }
}
