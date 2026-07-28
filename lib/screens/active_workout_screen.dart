import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database_helper.dart';
import '../models/exercise.dart';
import '../models/workout_entry.dart';
import '../models/workout_session.dart';
import '../providers/program_progress_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';
import '../services/calorie_calculator_service.dart';
import '../widgets/category_style.dart';
import '../widgets/rest_timer_sheet.dart';

/// One exercise step within a guided workout session (built from either a
/// [WorkoutProgram] day or a [CustomRoutine]).
class ActiveWorkoutStep {
  final Exercise exercise;
  final int targetSets;
  final int targetReps;
  final int restSeconds;

  const ActiveWorkoutStep({
    required this.exercise,
    required this.targetSets,
    required this.targetReps,
    this.restSeconds = 60,
  });
}

class _SetLog {
  final int reps;
  final double weight;
  const _SetLog(this.reps, this.weight);
}

/// Guides the user through a sequence of exercises/sets, prompting rest
/// timers between sets, and saves the results as workout log entries for
/// today once finished.
class ActiveWorkoutScreen extends StatefulWidget {
  final String title;
  final List<ActiveWorkoutStep> steps;

  /// When this workout comes from a program (built-in or custom), these
  /// identify which program/day it is so sequential progress can advance
  /// once the session is finished.
  final String? programKey;
  final int? dayIndex;
  final int? totalDays;

  const ActiveWorkoutScreen({
    super.key,
    required this.title,
    required this.steps,
    this.programKey,
    this.dayIndex,
    this.totalDays,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _exerciseIndex = 0;
  int _setIndex = 0;
  final Map<int, List<_SetLog>> _logs = {};
  final Stopwatch _stopwatch = Stopwatch();

  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  ActiveWorkoutStep get _currentStep => widget.steps[_exerciseIndex];

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.steps.first.targetReps.toString());
    _weightController = TextEditingController(text: '0');
    // "Antrenmanı Başlat": start the elapsed-time timer as soon as the
    // guided workout screen opens.
    _stopwatch.start();
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _isLastSetOfExercise => _setIndex >= _currentStep.targetSets - 1;
  bool get _isLastExercise => _exerciseIndex >= widget.steps.length - 1;

  Future<void> _completeSet() async {
    final reps = int.tryParse(_repsController.text) ?? _currentStep.targetReps;
    final weight = double.tryParse(_weightController.text) ?? 0;
    _logs.putIfAbsent(_exerciseIndex, () => []).add(_SetLog(reps, weight));

    final wasLastSet = _isLastSetOfExercise;
    final wasLastExercise = _isLastExercise;

    if (wasLastSet && wasLastExercise) {
      await _finishWorkout();
      return;
    }

    await showRestTimerSheet(context, initialSeconds: _currentStep.restSeconds);
    if (!mounted) return;

    setState(() {
      if (wasLastSet) {
        _exerciseIndex++;
        _setIndex = 0;
        _repsController.text = _currentStep.targetReps.toString();
        _weightController.text = '0';
      } else {
        _setIndex++;
      }
    });
  }

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    final workoutProvider = context.read<WorkoutProvider>();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double totalVolume = 0;
    int totalSets = 0;

    for (final entry in _logs.entries) {
      final step = widget.steps[entry.key];
      final setLogs = entry.value;
      final avgReps = setLogs.isEmpty
          ? step.targetReps
          : (setLogs.map((s) => s.reps).reduce((a, b) => a + b) / setLogs.length).round();
      final avgWeight = setLogs.isEmpty
          ? 0.0
          : setLogs.map((s) => s.weight).reduce((a, b) => a + b) / setLogs.length;
      totalSets += setLogs.length;
      totalVolume += setLogs.length * avgReps * avgWeight;

      await workoutProvider.addEntry(
        WorkoutEntry(
          date: today,
          exerciseId: step.exercise.id,
          exerciseName: step.exercise.name,
          category: step.exercise.bodyPart,
          sets: setLogs.length,
          reps: avgReps,
          weight: avgWeight,
          notes: 'Antrenman: ${widget.title}',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    if (!mounted) return;

    // Duration tracked by the stopwatch started when this screen opened.
    final durationMinutes = (_stopwatch.elapsed.inSeconds / 60).ceil().clamp(1, 1000000);

    // Resolve the user's current weight for the MET calorie formula:
    // latest logged body measurement -> a safe default.
    double weightKg = CalorieCalculatorService.fallbackWeightKg;
    final measurements = await DatabaseHelper.instance.allMeasurements();
    for (final m in measurements) {
      if (m.weightKg != null && m.weightKg! > 0) {
        weightKg = m.weightKg!;
        break;
      }
    }

    final calories = CalorieCalculatorService.calculateCalories(
      weightKg: weightKg,
      durationMinutes: durationMinutes.toDouble(),
    );

    await DatabaseHelper.instance.insertWorkoutSession(
      WorkoutSession(
        date: today,
        durationMinutes: durationMinutes,
        calories: calories,
        exerciseCount: widget.steps.length,
        totalSets: totalSets,
        totalVolume: totalVolume,
        title: widget.title,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    if (!mounted) return;

    if (widget.programKey != null && widget.dayIndex != null && widget.totalDays != null) {
      await context.read<ProgramProgressProvider>().markCompleted(
            widget.programKey!,
            widget.dayIndex!,
            widget.totalDays!,
            today,
          );
    }

    if (!mounted) return;
    // Keep the streak/weekly-goal/achievements stats in sync immediately,
    // since StatsProvider is otherwise only loaded once at screen init.
    await context.read<StatsProvider>().load();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          title: widget.title,
          durationMinutes: durationMinutes,
          calories: calories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _currentStep;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_exerciseIndex + (_setIndex + 1) / step.targetSets) / widget.steps.length,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Egzersiz ${_exerciseIndex + 1}/${widget.steps.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(step.exercise.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(titleCase(step.exercise.bodyPart)),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                step.exercise.gifAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.fitness_center, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Set ${_setIndex + 1}/${step.targetSets} • Hedef: ${step.targetReps} tekrar'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tekrar', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Ağırlık (kg)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _completeSet,
            icon: const Icon(Icons.check),
            label: Text(
              _isLastSetOfExercise && _isLastExercise ? 'Antrenmanı Bitir' : 'Seti Tamamla',
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown after finishing a guided workout session: totals summary.
class WorkoutSummaryScreen extends StatelessWidget {
  final String title;
  final int durationMinutes;
  final double calories;

  const WorkoutSummaryScreen({
    super.key,
    required this.title,
    required this.durationMinutes,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrenman Tamamlandı')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _StatRow(label: 'Süre', value: '$durationMinutes dk'),
              _StatRow(label: 'Tahmini kalori', value: '${calories.toStringAsFixed(0)} kcal'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
