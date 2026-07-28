import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/custom_program.dart';
import '../models/custom_routine.dart';
import '../models/workout_program.dart';
import '../providers/custom_program_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/program_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/settings_provider.dart';
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
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kod ile Program Ekle'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'OLYMPOS-PROGRAM-CODE:v1:... kodunu buraya yapıştırın',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('İçe Aktar'),
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
        SnackBar(content: Text('"${program.name}" programı eklendi.')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Antrenmanlar')),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'newProgram',
            onPressed: _createProgram,
            icon: const Icon(Icons.calendar_view_month),
            label: const Text('Yeni Program'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'newRoutine',
            onPressed: _createRoutine,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Rutin'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Programlar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final program in programProvider.programs)
            Card(
              child: ListTile(
                title: Text(program.name),
                subtitle: Text(program.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Chip(label: Text(program.level.label)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProgramDetailScreen.builtin(program),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Programlarım', style: Theme.of(context).textTheme.titleLarge),
              TextButton.icon(
                onPressed: _importProgramWithCode,
                icon: const Icon(Icons.qr_code),
                label: const Text('Kod ile Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!customProgramProvider.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (customProgramProvider.programs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Henüz çok günlü bir program oluşturmadınız.'),
            )
          else
            for (final program in customProgramProvider.programs)
              Card(
                child: ListTile(
                  title: Text(program.name),
                  subtitle: Text('${program.days.length} günlük program'),
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
                          const PopupMenuItem(value: 'activate', child: Text('Aktif Program Yap')),
                          const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                          const PopupMenuItem(value: 'delete', child: Text('Sil')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProgramDetailScreen.custom(program),
                      ),
                    );
                  },
                ),
              ),
          const SizedBox(height: 24),
          Text('Rutinlerim', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (!routineProvider.isLoaded)
            const Center(child: CircularProgressIndicator())
          else if (routineProvider.routines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Henüz özel bir rutin oluşturmadınız.'),
            )
          else
            for (final routine in routineProvider.routines)
              Card(
                child: ListTile(
                  title: Text(routine.name),
                  subtitle: Text('${routine.exercises.length} egzersiz'),
                  onTap: () => _startRoutine(routine),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _editRoutine(routine);
                      } else if (value == 'delete') {
                        await context.read<RoutineProvider>().deleteRoutine(routine.id!);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      PopupMenuItem(value: 'delete', child: Text('Sil')),
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
