import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_routine.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../providers/routine_provider.dart';
import '../widgets/category_style.dart';
import '../widgets/exercise_thumbnail.dart';

/// Lets the user pick exercises from the library (multi-select), set
/// target sets/reps for each, and save the result as a [CustomRoutine].
class RoutineBuilderScreen extends StatefulWidget {
  final CustomRoutine? existingRoutine;

  const RoutineBuilderScreen({super.key, this.existingRoutine});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _SelectedExercise {
  final Exercise exercise;
  int targetSets;
  int targetReps;

  _SelectedExercise({required this.exercise, this.targetSets = 3, this.targetReps = 10});
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  late final TextEditingController _nameController;
  final List<_SelectedExercise> _selected = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingRoutine?.name ?? '');
    if (widget.existingRoutine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final exerciseProvider = context.read<ExerciseProvider>();
        setState(() {
          for (final re in widget.existingRoutine!.exercises) {
            final exercise = exerciseProvider.byId(re.exerciseId);
            if (exercise != null) {
              _selected.add(_SelectedExercise(
                exercise: exercise,
                targetSets: re.targetSets,
                targetReps: re.targetReps,
              ));
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(Exercise exercise) {
    setState(() {
      final index = _selected.indexWhere((s) => s.exercise.id == exercise.id);
      if (index >= 0) {
        _selected.removeAt(index);
      } else {
        _selected.add(_SelectedExercise(exercise: exercise));
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty || _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineBuilderValidationMessage)),
      );
      return;
    }
    final routineProvider = context.read<RoutineProvider>();
    final routine = CustomRoutine(
      id: widget.existingRoutine?.id,
      name: _nameController.text.trim(),
      createdAt: widget.existingRoutine?.createdAt ?? DateTime.now().toIso8601String(),
      exercises: [
        for (var i = 0; i < _selected.length; i++)
          CustomRoutineExercise(
            exerciseId: _selected[i].exercise.id,
            exerciseName: _selected[i].exercise.name,
            category: _selected[i].exercise.bodyPart,
            targetSets: _selected[i].targetSets,
            targetReps: _selected[i].targetReps,
            position: i,
          ),
      ],
    );

    if (widget.existingRoutine == null) {
      await routineProvider.addRoutine(routine);
    } else {
      await routineProvider.updateRoutine(routine);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exerciseProvider = context.watch<ExerciseProvider>();
    final results = exerciseProvider.search(_query);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRoutine == null ? l10n.routineBuilderNewRoutineTitle : l10n.routineBuilderEditRoutineTitle),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.routineBuilderNameLabel, border: const OutlineInputBorder()),
            ),
          ),
          if (_selected.isNotEmpty)
            SizedBox(
              height: 148,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _selected.length,
                itemBuilder: (context, index) {
                  final item = _selected[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: SizedBox(
                        width: 150,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    l10n.programBuilderSetsLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _Stepper(
                                  value: item.targetSets,
                                  onChanged: (v) => setState(() => item.targetSets = v),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    l10n.programBuilderRepsLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _Stepper(
                                  value: item.targetReps,
                                  onChanged: (v) => setState(() => item.targetReps = v),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _toggle(item.exercise),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.programBuilderRemoveButton),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.exerciseSearchLabel,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final exercise = results[index];
                final isSelected = _selected.any((s) => s.exercise.id == exercise.id);
                return CheckboxListTile(
                  secondary: ExerciseThumbnail(exercise: exercise),
                  title: Text(exercise.name),
                  subtitle: Text(titleCase(exercise.bodyPart)),
                  value: isSelected,
                  onChanged: (_) => _toggle(exercise),
                );
              },
            ),
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

  Widget _button(BuildContext context, {required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? Theme.of(context).disabledColor
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          context,
          icon: Icons.remove_circle_outline,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 18,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _button(context, icon: Icons.add_circle_outline, onTap: () => onChanged(value + 1)),
      ],
    );
  }
}
