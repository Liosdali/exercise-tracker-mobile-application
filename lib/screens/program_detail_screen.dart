import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/custom_program.dart';
import '../models/workout_program.dart';
import '../providers/exercise_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../services/program_share_service.dart';
import 'active_workout_screen.dart';

/// A single training day, normalized from either a built-in [WorkoutProgram]
/// day or a user-created [CustomProgram] day.
class _NormalizedDay {
  final String name;
  final List<ActiveWorkoutStep> Function(ExerciseProvider) buildSteps;
  final int exerciseCount;

  const _NormalizedDay({
    required this.name,
    required this.buildSteps,
    required this.exerciseCount,
  });
}

/// Shows the days within a workout program (built-in or user-created);
/// tapping a day starts a guided [ActiveWorkoutScreen] session and advances
/// that program's sequential day-tracking once finished.
class ProgramDetailScreen extends StatefulWidget {
  final String programKey;
  final String title;
  final String description;
  final String? levelLabel;
  final List<_NormalizedDay> days;

  /// Non-null only for user-created custom programs; used to enable the
  /// "Programı Paylaş" share action.
  final CustomProgram? sourceProgram;

  const ProgramDetailScreen._({
    required this.programKey,
    required this.title,
    required this.description,
    required this.levelLabel,
    required this.days,
    this.sourceProgram,
  });

  factory ProgramDetailScreen.builtin(WorkoutProgram program) {
    return ProgramDetailScreen._(
      programKey: 'builtin:${program.id}',
      title: program.name,
      description: program.description,
      levelLabel: program.level.label,
      days: [
        for (final day in program.days)
          _NormalizedDay(
            name: day.name,
            exerciseCount: day.exercises.length,
            buildSteps: (exerciseProvider) => day.exercises
                .map((pe) {
                  final exercise = exerciseProvider.byId(pe.exerciseId);
                  if (exercise == null) return null;
                  return ActiveWorkoutStep(
                    exercise: exercise,
                    targetSets: pe.targetSets,
                    targetReps: pe.targetReps,
                    restSeconds: pe.restSeconds,
                  );
                })
                .whereType<ActiveWorkoutStep>()
                .toList(),
          ),
      ],
    );
  }

  factory ProgramDetailScreen.custom(CustomProgram program) {
    return ProgramDetailScreen._(
      programKey: program.key,
      title: program.name,
      description: 'Kullanıcı tarafından oluşturulan ${program.days.length} günlük program.',
      levelLabel: null,
      sourceProgram: program,
      days: [
        for (final day in program.days)
          _NormalizedDay(
            name: day.name,
            exerciseCount: day.exercises.length,
            buildSteps: (exerciseProvider) => day.exercises
                .map((pe) {
                  final exercise = exerciseProvider.byId(pe.exerciseId);
                  if (exercise == null) return null;
                  return ActiveWorkoutStep(
                    exercise: exercise,
                    targetSets: pe.targetSets,
                    targetReps: pe.targetReps,
                  );
                })
                .whereType<ActiveWorkoutStep>()
                .toList(),
          ),
      ],
    );
  }

  String _dayTitle(String name, bool isSuggested) => isSuggested ? '$name (Sıradaki)' : name;

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context
          .read<ProgramProgressProvider>()
          .nextDayIndex(widget.programKey, widget.days.length);
      if (mounted) setState(() {});
    });
  }

  Future<void> _shareProgram() async {
    final program = widget.sourceProgram;
    if (program == null) return;
    final code = ProgramShareService.encodeProgram(program);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Atlas Workout antrenman programımı deneyin: "${program.name}"\n\n$code',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();
    final settings = context.watch<SettingsProvider>();
    final progress = context.watch<ProgramProgressProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isActive = settings.activeProgramKey == widget.programKey;
    final suggestedIndex = progress.cachedNextDayIndex(widget.programKey, widget.days.length);
    final todayAlreadyDone = workoutProvider.loggedDates.contains(today);
    final title = widget.title;
    final description = widget.description;
    final levelLabel = widget.levelLabel;
    final days = widget.days;
    final programKey = widget.programKey;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.sourceProgram != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Programı Paylaş',
              onPressed: _shareProgram,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(description),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (levelLabel != null) Chip(label: Text(levelLabel)),
              if (isActive)
                const Chip(
                  label: Text('Aktif Program'),
                  avatar: Icon(Icons.check_circle, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (days.length > 1)
            OutlinedButton.icon(
              onPressed: isActive ? null : () => settings.setActiveProgramKey(programKey),
              icon: const Icon(Icons.flag_outlined),
              label: Text(isActive ? 'Bu program aktif' : 'Aktif Program Yap'),
            ),
          const SizedBox(height: 16),
          for (var i = 0; i < days.length; i++) ...[
            Card(
              color: (i == suggestedIndex && days.length > 1)
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                title: Text(widget._dayTitle(days[i].name, i == suggestedIndex && days.length > 1)),
                subtitle: Text('${days[i].exerciseCount} egzersiz'),
                trailing: FilledButton(
                  onPressed: () async {
                    final steps = days[i].buildSteps(exerciseProvider);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActiveWorkoutScreen(
                          title: '$title - ${days[i].name}',
                          steps: steps,
                          programKey: programKey,
                          dayIndex: i,
                          totalDays: days.length,
                        ),
                      ),
                    );
                  },
                  child: const Text('Başla'),
                ),
              ),
            ),
            if (i == suggestedIndex && days.length > 1 && todayAlreadyDone)
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Bugün tamamlandı', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
