import 'package:flutter/material.dart';

/// Title-cases a raw category string like "lower arms" -> "Lower Arms".
String titleCase(String input) {
  return input
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Maps a body-part category to a representative icon.
IconData iconForCategory(String category) {
  switch (category) {
    case 'back':
      return Icons.accessibility_new;
    case 'cardio':
      return Icons.favorite;
    case 'chest':
      return Icons.fitness_center;
    case 'lower arms':
      return Icons.front_hand;
    case 'lower legs':
      return Icons.directions_walk;
    case 'neck':
      return Icons.face;
    case 'shoulders':
      return Icons.sports_gymnastics;
    case 'upper arms':
      return Icons.sports_martial_arts;
    case 'upper legs':
      return Icons.directions_run;
    case 'waist':
      return Icons.self_improvement;
    default:
      return Icons.fitness_center;
  }
}
