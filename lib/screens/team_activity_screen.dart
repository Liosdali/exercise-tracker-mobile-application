import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/team_activity_log.dart';
import '../providers/team_provider.dart';

class TeamActivityScreen extends StatefulWidget {
  final String teamId;

  const TeamActivityScreen({
    Key? key,
    required this.teamId,
  }) : super(key: key);

  @override
  State<TeamActivityScreen> createState() => _TeamActivityScreenState();
}

class _TeamActivityScreenState extends State<TeamActivityScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivityData();
    });
  }

  Future<void> _loadActivityData() async {
    final teamProvider = context.read<TeamProvider>();
    final sevenDaysAgo = _selectedDate.subtract(const Duration(days: 7));
    await teamProvider.fetchTeamActivityLogs(
      teamId: widget.teamId,
      startDate: sevenDaysAgo,
      endDate: _selectedDate,
    );
  }

  void _goToPreviousDate() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadActivityData();
  }

  void _goToNextDate() {
    if (_selectedDate.isBefore(DateTime.now())) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _loadActivityData();
    }
  }

  void _showMemberDetail(TeamActivityLog activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberActivityDetailScreen(
          teamId: widget.teamId,
          userId: activity.userId,
          date: activity.activityDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();
    final activities = teamProvider.teamActivityLogs;

    // Filter activities for selected date
    final selectedDayActivities = activities
        .where((log) =>
            log.activityDate.year == _selectedDate.year &&
            log.activityDate.month == _selectedDate.month &&
            log.activityDate.day == _selectedDate.day)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamActivity),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Navigator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _goToPreviousDate,
                    ),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _selectedDate.isBefore(DateTime.now())
                          ? _goToNextDate
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick stats for the day
                _buildDayStatsCard(selectedDayActivities, l10n),
              ],
            ),
          ),
          // Activity List
          Expanded(
            child: teamProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedDayActivities.isEmpty
                    ? Center(
                        child: Text(l10n.teamNoActivity),
                      )
                    : ListView.builder(
                        itemCount: selectedDayActivities.length,
                        itemBuilder: (context, index) {
                          final activity = selectedDayActivities[index];
                          return _buildActivityCard(activity, l10n);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStatsCard(List<TeamActivityLog> activities, AppLocalizations l10n) {
    final totalWorkouts = activities.fold<int>(0, (sum, a) => sum + a.workoutsCount);
    final totalCalories =
        activities.fold<double>(0, (sum, a) => sum + a.totalCalories);
    final totalDuration =
        activities.fold<int>(0, (sum, a) => sum + a.totalDurationMinutes);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            icon: Icons.fitness_center,
            label: l10n.teamActivityWorkouts,
            value: totalWorkouts.toString(),
          ),
          _statItem(
            icon: Icons.local_fire_department,
            label: l10n.teamActivityCalories,
            value: totalCalories.toStringAsFixed(0),
          ),
          _statItem(
            icon: Icons.timer,
            label: l10n.teamActivityMinutes,
            value: totalDuration.toString(),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActivityCard(TeamActivityLog activity, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(activity.workoutsCount.toString()),
        ),
        title: Text('${activity.workoutsCount} ${l10n.teamActivityWorkouts}'),
        subtitle: Text(
          '${activity.totalCalories.toStringAsFixed(0)} kcal • ${activity.totalDurationMinutes} min',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => _showMemberDetail(activity),
        ),
        onTap: () => _showMemberDetail(activity),
      ),
    );
  }
}

/// Screen showing detailed activity for a specific member on a specific date
class MemberActivityDetailScreen extends StatefulWidget {
  final String teamId;
  final String userId;
  final DateTime date;

  const MemberActivityDetailScreen({
    Key? key,
    required this.teamId,
    required this.userId,
    required this.date,
  }) : super(key: key);

  @override
  State<MemberActivityDetailScreen> createState() =>
      _MemberActivityDetailScreenState();
}

class _MemberActivityDetailScreenState extends State<MemberActivityDetailScreen> {
  List<dynamic> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemberWorkouts();
  }

  Future<void> _loadMemberWorkouts() async {
    try {
      // In a real implementation, you'd query workout_sessions
      // for this user on this date filtered by their teams
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading member workouts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSuggestionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.suggestionTitle),
        content: const Text('Suggest program changes or exercises to this member'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to suggestion screen
            },
            child: Text(AppLocalizations.of(context)!.actionSuggest),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memberActivityDetail),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with date and member info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(widget.date),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showSuggestionDialog,
                        icon: const Icon(Icons.lightbulb),
                        label: Text(l10n.actionSuggest),
                      ),
                    ],
                  ),
                ),
                // Workouts list
                Expanded(
                  child: _workouts.isEmpty
                      ? Center(
                          child: Text(l10n.teamNoActivity),
                        )
                      : ListView.builder(
                          itemCount: _workouts.length,
                          itemBuilder: (context, index) {
                            final workout = _workouts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(workout['title'] ?? 'Untitled'),
                                subtitle: Text(
                                  '${workout['duration_minutes']} min • ${workout['calories']} kcal',
                                ),
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
