import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../services/exercise_localizer.dart';
import '../widgets/category_style.dart';
import 'log_entry_screen.dart';

/// Detail view for a single exercise: animation, instructions, and a
/// "Log workout" action to record it on the calendar.
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  Widget _chip(String label) => Chip(label: Text(label));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = l10n.localeName;
    // Exercise names always stay in English, regardless of app language.
    final name = exercise.name;
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                exercise.gifAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  exercise.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.fitness_center, size: 48),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(titleCase(ExerciseLocalizer.localizedBodyPart(exercise.bodyPart, lang))),
              _chip(ExerciseLocalizer.localizedEquipment(exercise.equipment, lang)),
              _chip(l10n.exerciseDetailTargetLabel(exercise.target)),
              _chip(exercise.muscleGroup),
            ],
          ),
          if (exercise.secondaryMuscles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.exerciseDetailSecondaryMusclesTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.secondaryMuscles.map(_chip).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Text(l10n.exerciseDetailInstructionsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (exercise.stepsFor(lang).isNotEmpty)
            ...exercise.stepsFor(lang).asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key + 1}. '),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            )
          else
            Text(exercise.instructionsFor(lang)),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add_task),
            label: Text(l10n.exerciseDetailLogButton),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LogEntryScreen(
                    exercise: exercise,
                    initialDate: DateTime.now(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
