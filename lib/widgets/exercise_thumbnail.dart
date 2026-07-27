import 'package:flutter/material.dart';

import '../models/exercise.dart';

/// A thumbnail image for an exercise, loaded from bundled assets.
/// Falls back to a placeholder icon if the asset can't be loaded.
class ExerciseThumbnail extends StatelessWidget {
  final Exercise exercise;
  final double size;

  const ExerciseThumbnail({super.key, required this.exercise, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        exercise.imageAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.fitness_center),
        ),
      ),
    );
  }
}
