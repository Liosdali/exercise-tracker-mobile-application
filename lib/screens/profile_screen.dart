import 'package:flutter/material.dart';
import 'profile_stats_screen.dart';

/// Wrapper for the Profile tab in bottom navigation.
/// Currently displays the ProfileStatsScreen which shows user stats and metrics.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileStatsScreen();
  }
}
