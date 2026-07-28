import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_program.dart';
import '../models/exercise.dart';
import '../providers/custom_program_provider.dart';
import '../providers/exercise_provider.dart';
import '../services/exercise_localizer.dart';
import '../widgets/category_style.dart';
import '../widgets/exercise_thumbnail.dart';

/// One exercise selected for a specific program day, with editable target
/// sets/reps.
class _SelectedExercise {
  final Exercise exercise;
  int targetSets;
  int targetReps;

  _SelectedExercise({required this.exercise, this.targetSets = 3, this.targetReps = 10});
}

/// A single day being edited within the program builder (in-memory draft).
class _DayDraft {
  final TextEditingController nameController;
  final List<_SelectedExercise> exercises;
  final int? existingDayId;

  _DayDraft({required String name, List<_SelectedExercise>? exercises, this.existingDayId})
      : nameController = TextEditingController(text: name),
        exercises = exercises ?? [];
}

/// Lets the user create or edit a multi-day [CustomProgram]: add/remove
/// days, name each day, and pick exercises (with target sets/reps) per day.
class ProgramBuilderScreen extends StatefulWidget {
  final CustomProgram? existingProgram;

  const ProgramBuilderScreen({super.key, this.existingProgram});

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  late final TextEditingController _nameController;
  final List<_DayDraft> _days = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingProgram?.name ?? '');
    if (widget.existingProgram != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final exerciseProvider = context.read<ExerciseProvider>();
        setState(() {
          for (final day in widget.existingProgram!.days) {
            final draft = _DayDraft(name: day.name, existingDayId: day.id);
            for (final pe in day.exercises) {
              final exercise = exerciseProvider.byId(pe.exerciseId);
              if (exercise != null) {
                draft.exercises.add(
                  _SelectedExercise(
                    exercise: exercise,
                    targetSets: pe.targetSets,
                    targetReps: pe.targetReps,
                  ),
                );
              }
            }
            _days.add(draft);
          }
        });
      });
    } else {
      _days.add(_DayDraft(name: 'Gün 1'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final day in _days) {
      day.nameController.dispose();
    }
    super.dispose();
  }

  void _addDay() {
    setState(() => _days.add(_DayDraft(name: 'Gün ${_days.length + 1}')));
  }

  void _removeDay(int index) {
    setState(() {
      final removed = _days.removeAt(index);
      removed.nameController.dispose();
    });
  }

  Future<void> _editDayExercises(_DayDraft day) async {
    final result = await Navigator.of(context).push<List<_SelectedExercise>>(
      MaterialPageRoute(
        builder: (_) => _DayExercisePickerScreen(initialSelection: day.exercises),
      ),
    );
    if (result != null) {
      setState(() {
        day.exercises
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _days.isEmpty || _days.every((d) => d.exercises.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir program adı girin ve en az bir güne egzersiz ekleyin.'),
        ),
      );
      return;
    }

    final program = CustomProgram(
      id: widget.existingProgram?.id,
      name: name,
      createdAt: widget.existingProgram?.createdAt ?? DateTime.now().toIso8601String(),
      days: [
        for (var d = 0; d < _days.length; d++)
          CustomProgramDay(
            id: _days[d].existingDayId,
            name: _days[d].nameController.text.trim().isEmpty
                ? 'Gün ${d + 1}'
                : _days[d].nameController.text.trim(),
            position: d,
            exercises: [
              for (var i = 0; i < _days[d].exercises.length; i++)
                CustomProgramExercise(
                  exerciseId: _days[d].exercises[i].exercise.id,
                  exerciseName: _days[d].exercises[i].exercise.name,
                  category: _days[d].exercises[i].exercise.bodyPart,
                  targetSets: _days[d].exercises[i].targetSets,
                  targetReps: _days[d].exercises[i].targetReps,
                  position: i,
                ),
            ],
          ),
      ],
    );

    final provider = context.read<CustomProgramProvider>();
    if (widget.existingProgram == null) {
      await provider.addProgram(program);
    } else {
      await provider.updateProgram(program);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProgram == null ? 'Yeni Program' : 'Programı Düzenle'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDay,
        icon: const Icon(Icons.add),
        label: const Text('Gün Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Program adı', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _days.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _days[i].nameController,
                            decoration: const InputDecoration(
                              labelText: 'Gün adı',
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _days.length > 1 ? () => _removeDay(i) : null,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${_days[i].exercises.length} egzersiz seçildi'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _editDayExercises(_days[i]),
                      icon: const Icon(Icons.fitness_center),
                      label: const Text('Egzersizleri Düzenle'),
                    ),
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

/// Multi-select exercise picker (with per-exercise target sets/reps),
/// used to build the exercise list of a single [_DayDraft].
class _DayExercisePickerScreen extends StatefulWidget {
  final List<_SelectedExercise> initialSelection;

  const _DayExercisePickerScreen({required this.initialSelection});

  @override
  State<_DayExercisePickerScreen> createState() => _DayExercisePickerScreenState();
}

class _DayExercisePickerScreenState extends State<_DayExercisePickerScreen> {
  late final List<_SelectedExercise> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection
        .map((s) => _SelectedExercise(exercise: s.exercise, targetSets: s.targetSets, targetReps: s.targetReps))
        .toList();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();
    final l10n = AppLocalizations.of(context)!;
    final lang = l10n.localeName;
    final results = exerciseProvider.search(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egzersiz Seç'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selected.isNotEmpty)
            SizedBox(
              height: 172,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _selected.length,
                itemBuilder: (context, index) {
                  final item = _selected[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 130,
                        child: SingleChildScrollView(
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
                                  const Text('Set'),
                                  _Stepper(
                                    value: item.targetSets,
                                    onChanged: (v) => setState(() => item.targetSets = v),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tekrar'),
                                  _Stepper(
                                    value: item.targetReps,
                                    onChanged: (v) => setState(() => item.targetReps = v),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _toggle(item.exercise),
                                child: const Text('Kaldır'),
                              ),
                            ],
                          ),
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
              decoration: const InputDecoration(
                labelText: 'Egzersiz ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
                  subtitle: Text(titleCase(ExerciseLocalizer.localizedBodyPart(exercise.bodyPart, lang))),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 16,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 16,
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
