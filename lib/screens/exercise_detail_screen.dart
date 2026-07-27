import 'package:flutter/material.dart';

import '../models/exercise.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              exercise.gifAsset,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                exercise.imageAsset,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.fitness_center, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(titleCase(exercise.bodyPart)),
              _chip(exercise.equipment),
              _chip('Target: ${exercise.target}'),
              _chip(exercise.muscleGroup),
            ],
          ),
          if (exercise.secondaryMuscles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Secondary muscles', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.secondaryMuscles.map(_chip).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (exercise.stepsEn.isNotEmpty)
            ...exercise.stepsEn.asMap().entries.map(
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
            Text(exercise.instructionsEn),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add_task),
            label: const Text('Log this exercise'),
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
