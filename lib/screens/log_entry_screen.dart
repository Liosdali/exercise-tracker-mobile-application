import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/workout_entry.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';

/// Form to log (or edit) a workout entry for a given exercise and date.
class LogEntryScreen extends StatefulWidget {
  final Exercise exercise;
  final DateTime initialDate;
  final WorkoutEntry? existingEntry;

  const LogEntryScreen({
    super.key,
    required this.exercise,
    required this.initialDate,
    this.existingEntry,
  });

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    final existing = widget.existingEntry;
    _setsController = TextEditingController(text: existing?.sets?.toString() ?? '');
    _repsController = TextEditingController(text: existing?.reps?.toString() ?? '');
    _weightController =
        TextEditingController(text: existing?.weight?.toString() ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final workoutProvider = context.read<WorkoutProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    final entry = WorkoutEntry(
      id: widget.existingEntry?.id,
      date: dateStr,
      exerciseId: widget.exercise.id,
      exerciseName: widget.exercise.name,
      category: widget.exercise.bodyPart,
      sets: int.tryParse(_setsController.text),
      reps: int.tryParse(_repsController.text),
      weight: double.tryParse(_weightController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.existingEntry?.createdAt ??
          DateTime.now().toIso8601String(),
    );

    if (widget.existingEntry == null) {
      await workoutProvider.addEntry(entry);
    } else {
      await workoutProvider.updateEntry(entry);
    }
    // Keep the streak/weekly-goal/achievements stats in sync immediately,
    // since StatsProvider is otherwise only loaded once at screen init.
    if (mounted) await context.read<StatsProvider>().load();

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit entry' : 'Log workout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(widget.exercise.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMMd().format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg, optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Text(isEditing ? 'Save changes' : 'Save entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
