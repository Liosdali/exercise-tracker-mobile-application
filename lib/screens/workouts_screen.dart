import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_program.dart';
import '../models/custom_routine.dart';
import '../providers/custom_program_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/program_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/settings_provider.dart';
import '../services/program_localizer.dart';
import '../services/program_share_service.dart';
import 'active_workout_screen.dart';
import 'program_builder_screen.dart';
import 'program_detail_screen.dart';
import 'routine_builder_screen.dart';

/// "Antrenmanlar" tab: built-in programs + the user's custom routines.
class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().load();
      context.read<CustomProgramProvider>().load();
    });
  }

  Future<void> _startRoutine(CustomRoutine routine) async {
    final exerciseProvider = context.read<ExerciseProvider>();
    final steps = routine.exercises
        .map((re) {
          final exercise = exerciseProvider.byId(re.exerciseId);
          if (exercise == null) return null;
          return ActiveWorkoutStep(
            exercise: exercise,
            targetSets: re.targetSets,
            targetReps: re.targetReps,
          );
        })
        .whereType<ActiveWorkoutStep>()
        .toList();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(title: routine.name, steps: steps),
      ),
    );
  }

  Future<void> _createRoutine() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoutineBuilderScreen()),
    );
    if (!mounted) return;
    context.read<RoutineProvider>().load();
  }

  Future<void> _editRoutine(CustomRoutine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineBuilderScreen(existingRoutine: routine),
      ),
    );
    if (!mounted) return;
    context.read<RoutineProvider>().load();
  }

  Future<void> _createProgram() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgramBuilderScreen()),
    );
    if (!mounted) return;
    context.read<CustomProgramProvider>().load();
  }

  Future<void> _editProgram(CustomProgram program) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProgramBuilderScreen(existingProgram: program)),
    );
    if (!mounted) return;
    context.read<CustomProgramProvider>().load();
  }

  Future<void> _importProgramWithCode() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.workoutsImportDialogTitle),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: l10n.workoutsImportDialogHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.workoutsImportConfirmButton),
          ),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;

    try {
      final program = ProgramShareService.decodeProgram(code);
      await context.read<CustomProgramProvider>().addProgram(program);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workoutsAddedSnackbar(program.name))),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final programProvider = context.watch<ProgramProvider>();
    final routineProvider = context.watch<RoutineProvider>();
    final customProgramProvider = context.watch<CustomProgramProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navWorkouts)),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'newProgram',
            onPressed: _createProgram,
            icon: const Icon(Icons.calendar_view_month),
            label: Text(l10n.workoutsNewProgramButton),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'newRoutine',
            onPressed: _createRoutine,
            icon: const Icon(Icons.add),
            label: Text(l10n.workoutsNewRoutineButton),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.workoutsProgramsSectionTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final program in programProvider.programs)
            Card(
              child: ListTile(
                title: Text(ProgramLocalizer.name(l10n, program.id, program.name)),
                subtitle: Text(
                  ProgramLocalizer.description(l10n, program.id, program.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Chip(label: Text(ProgramLocalizer.levelLabel(l10n, program.level))),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProgramDetailScreen.builtin(program, l10n: l10n),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.workoutsMyProgramsSectionTitle, style: Theme.of(context).textTheme.titleLarge),
              TextButton.icon(
                onPressed: _importProgramWithCode,
                icon: const Icon(Icons.qr_code),
                label: Text(l10n.workoutsImportCodeButton),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!customProgramProvider.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (customProgramProvider.programs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.workoutsNoCustomProgramsMessage),
            )
          else
            for (final program in customProgramProvider.programs)
              Card(
                child: ListTile(
                  title: Text(program.name),
                  subtitle: Text(l10n.workoutsDaysCountLabel(program.days.length)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (settings.activeProgramKey == program.key)
                        const Icon(Icons.check_circle, color: Colors.green),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _editProgram(program);
                          } else if (value == 'delete') {
                            await context.read<CustomProgramProvider>().deleteProgram(program.id!);
                          } else if (value == 'activate') {
                            await settings.setActiveProgramKey(program.key);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'activate', child: Text(l10n.workoutsActivateProgramMenuItem)),
                          PopupMenuItem(value: 'edit', child: Text(l10n.workoutsEditMenuItem)),
                          PopupMenuItem(value: 'delete', child: Text(l10n.workoutsDeleteMenuItem)),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProgramDetailScreen.custom(program, l10n: l10n),
                      ),
                    );
                  },
                ),
              ),
          const SizedBox(height: 24),
          Text(l10n.workoutsMyRoutinesSectionTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (!routineProvider.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (routineProvider.routines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.workoutsNoCustomRoutinesMessage),
            )
          else
            for (final routine in routineProvider.routines)
              Card(
                child: ListTile(
                  title: Text(routine.name),
                  subtitle: Text(l10n.workoutsExerciseCountLabel(routine.exercises.length)),
                  onTap: () => _startRoutine(routine),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _editRoutine(routine);
                      } else if (value == 'delete') {
                        await context.read<RoutineProvider>().deleteRoutine(routine.id!);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(l10n.workoutsEditMenuItem)),
                      PopupMenuItem(value: 'delete', child: Text(l10n.workoutsDeleteMenuItem)),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
