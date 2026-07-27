import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/custom_program_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/program_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/program_resolver.dart';
import 'active_workout_screen.dart';

/// "Ana Sayfa" tab: greeting, streak, weekly goal progress, suggested
/// workout of the day (manual calendar assignment first, otherwise the
/// active program's sequential next day), and quick stat tiles.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    final stats = context.read<StatsProvider>();
    final settings = context.read<SettingsProvider>();
    final progress = context.read<ProgramProgressProvider>();
    final workoutProvider = context.read<WorkoutProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stats.load();
      settings.load();
      progress.load();
      workoutProvider.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final settings = context.watch<SettingsProvider>();
    final builtinPrograms = context.watch<ProgramProvider>();
    final customPrograms = context.watch<CustomProgramProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final progress = context.watch<ProgramProgressProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();

    if (!stats.isLoaded || !settings.isLoaded || !progress.isLoaded || !customPrograms.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final today = _fmt(DateTime.now());
    final planned = progress.plannedFor(today);
    final isManualAssignment = planned != null;

    ResolvedProgramDay? suggested;
    if (planned != null) {
      suggested = resolveProgramDay(
        programKey: planned.programKey,
        dayIndex: planned.dayIndex,
        builtinPrograms: builtinPrograms,
        customPrograms: customPrograms,
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
        );
      }
    }
    // Prime the async-loaded next-day-index cache for the active program.
    if (planned == null && settings.activeProgramKey != null) {
      final totalDays = dayNamesFor(settings.activeProgramKey!, builtinPrograms, customPrograms).length;
      progress.nextDayIndex(settings.activeProgramKey!, totalDays);
    }

    final todayCompleted = workoutProvider.loggedDates.contains(today);
    final weeklyProgress = settings.weeklyGoal == 0
        ? 0.0
        : (stats.thisWeekCount / settings.weeklyGoal).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHome)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.dashboardGreeting, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, size: 36, color: Colors.deepOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stats.currentStreak > 0
                          ? l10n.dashboardStreakActive(stats.currentStreak)
                          : l10n.dashboardStreakStart,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dashboardWeeklyGoalTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: weeklyProgress, minHeight: 8),
                  const SizedBox(height: 8),
                  Text(l10n.dashboardWeeklyGoalCount(stats.thisWeekCount, settings.weeklyGoal)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(l10n.dashboardTodaysWorkoutTitle, style: Theme.of(context).textTheme.titleLarge),
              if (todayCompleted) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 4),
                Text(l10n.dashboardCompletedLabel, style: const TextStyle(color: Colors.green)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (suggested == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.dashboardNoProgramSelected),
              ),
            )
          else
            Card(
              child: ListTile(
                title: Text('${suggested.programTitle} - ${suggested.dayName}'),
                subtitle: Text(
                  isManualAssignment
                      ? l10n.dashboardManualAssignmentSubtitle
                      : l10n.dashboardNextWorkoutSubtitle,
                ),
                trailing: FilledButton(
                  onPressed: todayCompleted
                      ? null
                      : () {
                          final steps = suggested!.buildSteps(exerciseProvider);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ActiveWorkoutScreen(
                                title: '${suggested!.programTitle} - ${suggested.dayName}',
                                steps: steps,
                                programKey: isManualAssignment ? null : suggested.programKey,
                                dayIndex: isManualAssignment ? null : suggested.dayIndex,
                                totalDays: isManualAssignment ? null : suggested.totalDays,
                              ),
                            ),
                          );
                        },
                  child: Text(l10n.dashboardStartButton),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  icon: Icons.check_circle_outline,
                  label: l10n.dashboardTotalWorkoutsLabel,
                  value: '${stats.totalWorkouts}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStat(
                  icon: Icons.fitness_center,
                  label: l10n.dashboardTotalVolumeLabel,
                  value: '${stats.totalVolume.toStringAsFixed(0)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
