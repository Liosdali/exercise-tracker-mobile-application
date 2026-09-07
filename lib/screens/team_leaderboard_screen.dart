import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/leaderboard_entry.dart';
import '../providers/team_provider.dart';

class TeamLeaderboardScreen extends StatefulWidget {
  final String teamId;

  const TeamLeaderboardScreen({
    Key? key,
    required this.teamId,
  }) : super(key: key);

  @override
  State<TeamLeaderboardScreen> createState() => _TeamLeaderboardScreenState();
}

class _TeamLeaderboardScreenState extends State<TeamLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMetric = 'workouts'; // workouts, weight, calories

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboards();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    final teamProvider = context.read<TeamProvider>();
    await Future.wait([
      teamProvider.fetchWeeklyLeaderboard(widget.teamId),
      teamProvider.fetchMonthlyLeaderboard(widget.teamId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamLeaderboard),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.leaderboardWeekly),
            Tab(text: l10n.leaderboardMonthly),
          ],
        ),
      ),
      body: Column(
        children: [
          // Metric selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _metricChip('workouts', l10n.leaderboardMetricWorkouts),
                  const SizedBox(width: 8),
                  _metricChip('weight', l10n.leaderboardMetricWeight),
                  const SizedBox(width: 8),
                  _metricChip('calories', l10n.leaderboardMetricCalories),
                ],
              ),
            ),
          ),
          // Leaderboard list
          Expanded(
            child: teamProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Weekly leaderboard
                      _buildLeaderboardList(
                        teamProvider.weeklyLeaderboard,
                        l10n,
                      ),
                      // Monthly leaderboard
                      _buildLeaderboardList(
                        teamProvider.monthlyLeaderboard,
                        l10n,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedMetric == value,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedMetric = value);
        }
      },
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries, AppLocalizations l10n) {
    if (entries.isEmpty) {
      return Center(
        child: Text(l10n.leaderboardEmpty),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final score = _getScoreForMetric(entry);
        final isMedal = entry.isTopThree;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isMedal ? 4 : 1,
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isMedal
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  entry.getRankDisplay(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            title: Text(
              entry.userName ?? l10n.teamMember,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _getMetricLabel(entry, _selectedMetric, l10n),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                _buildTrendIndicator(entry, _selectedMetric),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemberLeaderboardDetailScreen(
                    leaderboardEntry: entry,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getScoreForMetric(LeaderboardEntry entry) {
    switch (_selectedMetric) {
      case 'workouts':
        return entry.workoutCount.toString();
      case 'weight':
        return '${entry.totalWeightLifted.toStringAsFixed(1)} kg';
      case 'calories':
        return entry.totalCalories.toStringAsFixed(0);
      default:
        return '0';
    }
  }

  String _getMetricLabel(LeaderboardEntry entry, String metric, AppLocalizations l10n) {
    switch (metric) {
      case 'workouts':
        return '${entry.workoutCount} ${l10n.leaderboardWorkouts}';
      case 'weight':
        return '${entry.totalWeightLifted.toStringAsFixed(1)} kg';
      case 'calories':
        return '${entry.totalCalories.toStringAsFixed(0)} kcal';
      default:
        return '';
    }
  }

  Widget _buildTrendIndicator(LeaderboardEntry entry, String metric) {
    // Placeholder for trend (would compare with previous period)
    return const Icon(Icons.trending_up, size: 16, color: Colors.green);
  }
}

/// Screen showing individual member's leaderboard details and history
class MemberLeaderboardDetailScreen extends StatelessWidget {
  final LeaderboardEntry leaderboardEntry;

  const MemberLeaderboardDetailScreen({
    Key? key,
    required this.leaderboardEntry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(leaderboardEntry.userName ?? l10n.teamMember),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member card with rank
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (leaderboardEntry.userAvatarUrl != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(leaderboardEntry.userAvatarUrl!),
                        radius: 30,
                      )
                    else
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leaderboardEntry.userName ?? l10n.teamMember,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.leaderboardRank} ${leaderboardEntry.rank}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        leaderboardEntry.getRankDisplay(),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats breakdown
              Text(
                l10n.leaderboardStats,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _statCard(
                label: l10n.leaderboardMetricWorkouts,
                value: '${leaderboardEntry.workoutCount}',
                icon: Icons.fitness_center,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _statCard(
                label: l10n.leaderboardMetricWeight,
                value: '${leaderboardEntry.totalWeightLifted.toStringAsFixed(1)} kg',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _statCard(
                label: l10n.leaderboardMetricCalories,
                value: '${leaderboardEntry.totalCalories.toStringAsFixed(0)} kcal',
                icon: Icons.local_fire_department,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
