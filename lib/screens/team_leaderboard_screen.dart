import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/leaderboard_entry.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../theme/atlas_colors.dart';
import '../theme/team_palette.dart';
import '../widgets/atlas/leaderboard_row.dart' as atlas_leaderboard;
import '../widgets/atlas/team_theme.dart';

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

  /// Finds the team this leaderboard belongs to among the teams the viewer
  /// already has loaded, falling back to the default kit rather than
  /// fetching a team the caller has not made available.
  Team? _findTeam(List<Team> teams) {
    for (final team in teams) {
      if (team.id == widget.teamId) return team;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();
    final kit = _findTeam(teamProvider.myTeams)?.kit ?? kDefaultKit;

    return TeamTheme(
      kit: kit,
      child: Scaffold(
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

    final viewerId = Supabase.instance.client.auth.currentUser?.id;
    // AnimatedLeaderboard's callbacks hand back its own entry type, keyed by
    // userId; this maps back to the screen's own model to reuse its fields
    // for navigation and the trend indicator.
    final byUserId = {for (final entry in entries) entry.userId: entry};

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: atlas_leaderboard.AnimatedLeaderboard(
        entries: [
          for (final entry in entries)
            atlas_leaderboard.LeaderboardEntry(
              id: entry.userId,
              name: entry.userName ?? l10n.teamMember,
              metric: _getScoreForMetric(entry),
              detail: _getMetricLabel(entry, _selectedMetric, l10n),
            ),
        ],
        viewerId: viewerId,
        onEntryTap: (atlasEntry) {
          final entry = byUserId[atlasEntry.id];
          if (entry == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  MemberLeaderboardDetailScreen(leaderboardEntry: entry),
            ),
          );
        },
        trailingBuilder: (atlasEntry) {
          final entry = byUserId[atlasEntry.id];
          if (entry == null) return const SizedBox.shrink();
          return _buildTrendIndicator(entry, _selectedMetric);
        },
      ),
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
    return Icon(Icons.trending_up, size: 16, color: context.atlas.success);
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
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _statCard(
                label: l10n.leaderboardMetricCalories,
                value: '${leaderboardEntry.totalCalories.toStringAsFixed(0)} kcal',
                icon: Icons.local_fire_department,
                color: Theme.of(context).colorScheme.primary,
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
