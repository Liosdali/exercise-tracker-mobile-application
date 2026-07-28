/// Formats a total duration in minutes into a compact, human-readable
/// Turkish string that automatically scales from minutes up through hours,
/// days, and weeks as the value grows:
///   - under 60 minutes: "45 dk"
///   - 60+ minutes: "1 saat 0 dk", "1 saat 2 dk"
///   - 1+ days: "3 gün 5 saat 12 dk"
///   - 7+ days: "1 hafta 2 gün 3 saat 4 dk"
String formatWorkoutDuration(int totalMinutes) {
  if (totalMinutes < 60) return '$totalMinutes dk';

  const minutesPerHour = 60;
  const minutesPerDay = 24 * minutesPerHour;
  const minutesPerWeek = 7 * minutesPerDay;

  final weeks = totalMinutes ~/ minutesPerWeek;
  var remaining = totalMinutes % minutesPerWeek;
  final days = remaining ~/ minutesPerDay;
  remaining %= minutesPerDay;
  final hours = remaining ~/ minutesPerHour;
  final mins = remaining % minutesPerHour;

  final parts = <String>[];
  if (weeks > 0) parts.add('$weeks hafta');
  if (weeks > 0 || days > 0) parts.add('$days gün');
  parts.add('$hours saat');
  parts.add('$mins dk');
  return parts.join(' ');
}
