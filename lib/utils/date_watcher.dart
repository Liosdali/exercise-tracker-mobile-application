import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/program_progress_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';

final DateFormat _dayFmt = DateFormat('yyyy-MM-dd');

/// Wraps [child] and keeps the app's date-dependent state (streak, weekly
/// goal, today's suggested workout) in sync with the device's local clock:
///  - Re-checks the current date whenever the app resumes from the
///    background (e.g. the user left it open overnight).
///  - Arms a [Timer] for the next local midnight so date-dependent widgets
///    refresh automatically even if the app stays in the foreground across
///    the day boundary.
///
/// On a detected day change it reloads [StatsProvider], [WorkoutProvider]
/// and [ProgramProgressProvider], whose `notifyListeners()` calls make any
/// `context.watch`-ing widgets (e.g. the Dashboard) rebuild with the new
/// day's data.
class AppDateWatcher extends StatefulWidget {
  final Widget child;

  const AppDateWatcher({super.key, required this.child});

  @override
  State<AppDateWatcher> createState() => _AppDateWatcherState();
}

class _AppDateWatcherState extends State<AppDateWatcher> with WidgetsBindingObserver {
  late String _lastKnownDate;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _lastKnownDate = _today();
    WidgetsBinding.instance.addObserver(this);
    _armMidnightTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  static String _today() => _dayFmt.format(DateTime.now());

  void _armMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // A small buffer avoids a race where the timer fires a moment early.
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(delay, () {
      _checkForDateChange();
      _armMidnightTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForDateChange();
      _armMidnightTimer();
    }
  }

  void _checkForDateChange() {
    final today = _today();
    if (today == _lastKnownDate) return;
    _lastKnownDate = today;
    if (!mounted) return;
    context.read<StatsProvider>().load();
    context.read<WorkoutProvider>().init();
    context.read<ProgramProgressProvider>().load();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
