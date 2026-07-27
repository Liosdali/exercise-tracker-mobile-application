import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/app_localizations.dart';
import '../models/workout_entry.dart';
import '../providers/custom_program_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/program_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/program_resolver.dart';
import '../widgets/category_style.dart';
import 'exercise_picker_screen.dart';
import 'log_entry_screen.dart';

/// Calendar of working days: mark days with logged exercises, assign a
/// specific program day to a specific date (overriding sequential
/// auto-suggestion), browse a day's entries, and add/edit/delete workout
/// log entries for that day.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = context.read<WorkoutProvider>();
      workoutProvider.init();
      workoutProvider.loadEntriesFor(_fmt(_selectedDay));
      context.read<CustomProgramProvider>().load();
      context.read<ProgramProgressProvider>().load();
    });
  }

  Future<void> _addExercise() async {
    final exercise = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (exercise == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogEntryScreen(exercise: exercise, initialDate: _selectedDay),
      ),
    );
    if (mounted) {
      context.read<WorkoutProvider>().loadEntriesFor(_fmt(_selectedDay));
    }
  }

  Future<void> _editEntry(WorkoutEntry entry) async {
    final exerciseProvider = context.read<ExerciseProvider>();
    final exercise = exerciseProvider.byId(entry.exerciseId);
    if (exercise == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogEntryScreen(
          exercise: exercise,
          initialDate: _selectedDay,
          existingEntry: entry,
        ),
      ),
    );
    if (mounted) {
      context.read<WorkoutProvider>().loadEntriesFor(_fmt(_selectedDay));
    }
  }

  Future<void> _assignProgram() async {
    final builtinPrograms = context.read<ProgramProvider>();
    final customPrograms = context.read<CustomProgramProvider>();
    final options = allProgramOptions(builtinPrograms, customPrograms);
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce Antrenmanlar sekmesinden bir program oluşturun.')),
      );
      return;
    }

    final selectedOption = await showModalBottomSheet<({String key, String name, int totalDays})>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Bir program seçin', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final option in options)
            ListTile(
              title: Text(option.name),
              subtitle: Text('${option.totalDays} gün'),
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
    if (selectedOption == null || !mounted) return;

    final dayNames = dayNamesFor(selectedOption.key, builtinPrograms, customPrograms);
    if (dayNames.isEmpty) return;

    final selectedDayIndex = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Hangi gün?', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (var i = 0; i < dayNames.length; i++)
            ListTile(
              title: Text(dayNames[i]),
              onTap: () => Navigator.of(context).pop(i),
            ),
        ],
      ),
    );
    if (selectedDayIndex == null || !mounted) return;

    await context.read<ProgramProgressProvider>().setPlanned(
          _fmt(_selectedDay),
          selectedOption.key,
          selectedDayIndex,
          dayNames[selectedDayIndex],
        );
  }

  Future<void> _clearAssignment() async {
    await context.read<ProgramProgressProvider>().clearPlanned(_fmt(_selectedDay));
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final progress = context.watch<ProgramProgressProvider>();
    final selectedKey = _fmt(_selectedDay);
    final entries = workoutProvider.entriesFor(selectedKey);
    final planned = progress.plannedFor(selectedKey);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarScreenTitle)),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              context.read<WorkoutProvider>().loadEntriesFor(_fmt(selectedDay));
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final key = _fmt(day);
                final completed = workoutProvider.loggedDates.contains(key);
                final hasPlan = progress.plannedFor(key) != null;
                if (!completed && !hasPlan) return null;
                return Positioned(
                  bottom: 2,
                  child: Icon(
                    completed ? Icons.check_circle : Icons.event_note,
                    size: 14,
                    color: completed ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat.yMMMMd().format(_selectedDay),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (workoutProvider.loggedDates.contains(selectedKey))
                      const Chip(
                        avatar: Icon(Icons.check_circle, color: Colors.green, size: 18),
                        label: Text('Tamamlandı'),
                      ),
                  ],
                ),
                if (planned != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Atanmış: ${planned.dayName}')),
                        TextButton(
                          onPressed: _clearAssignment,
                          child: const Text('Kaldır'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _assignProgram,
                        icon: const Icon(Icons.event_note),
                        label: Text(planned == null ? 'Program Ata' : 'Atamayı Değiştir'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add),
                        label: const Text('Add exercise'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No exercises logged for this day.'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final details = [
                        if (entry.sets != null) '${entry.sets} sets',
                        if (entry.reps != null) '${entry.reps} reps',
                        if (entry.weight != null) '${entry.weight} kg',
                      ].join(' · ');
                      return ListTile(
                        title: Text(entry.exerciseName),
                        subtitle: Text(
                          [
                            titleCase(entry.category),
                            if (details.isNotEmpty) details,
                            if ((entry.notes ?? '').isNotEmpty) entry.notes!,
                          ].join('\n'),
                        ),
                        isThreeLine: (entry.notes ?? '').isNotEmpty,
                        onTap: () => _editEntry(entry),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await context.read<WorkoutProvider>().deleteEntry(entry);
                            if (context.mounted) {
                              await context.read<StatsProvider>().load();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

