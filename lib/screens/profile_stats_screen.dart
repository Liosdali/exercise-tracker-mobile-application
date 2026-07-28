import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/achievement.dart';
import '../models/body_measurement.dart';
import '../providers/stats_provider.dart';
import 'body_measurement_form.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

IconData _achievementIcon(String iconName) {
  switch (iconName) {
    case 'flag':
      return Icons.flag;
    case 'military_tech':
      return Icons.military_tech;
    case 'workspace_premium':
      return Icons.workspace_premium;
    case 'emoji_events':
      return Icons.emoji_events;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'timer':
      return Icons.timer;
    case 'repeat':
      return Icons.repeat;
    default:
      return Icons.emoji_events;
  }
}

/// "Profil & İstatistikler" tab: charts, achievements, body measurements,
/// settings, and a link to the full workout calendar/history.
class ProfileStatsScreen extends StatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen> {
  List<BodyMeasurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().load();
      _loadMeasurements();
    });
  }

  Future<void> _loadMeasurements() async {
    final measurements = await DatabaseHelper.instance.allMeasurements();
    if (mounted) setState(() => _measurements = measurements);
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (!stats.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final weeklySeries = stats.weeklyDurationSeries;
    final maxMinutes = weeklySeries.fold<double>(1, (m, w) => w.minutes > m ? w.minutes.toDouble() : m);
    final achievements = stats.achievements;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(label: l10n.dashboardTotalWorkoutsLabel, value: '${stats.totalWorkouts}'),
              ),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(label: l10n.profileStreakLabel, value: '${stats.currentStreak}')),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: l10n.profileBadgesLabel,
                  value: '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.profileWeeklyVolumeChartTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxMinutes * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weeklySeries.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(weeklySeries[index].dayLabel, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  for (var i = 0; i < weeklySeries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklySeries[i].minutes.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu hafta toplam: ${stats.weeklyDurationSeries.fold<int>(0, (sum, w) => sum + w.minutes)} dk • ${stats.weeklyCalories.toStringAsFixed(0)} kcal',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(l10n.profileAchievementsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 116,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final achievement in achievements)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _AchievementCard(achievement: achievement),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: Text(l10n.profileCalendarLinkTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.profileBodyMeasurementsTitle, style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const BodyMeasurementForm()),
                  );
                  if (saved == true) _loadMeasurements();
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.commonAdd),
              ),
            ],
          ),
          if (_measurements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.profileNoMeasurements),
            )
          else
            for (final m in _measurements)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat.yMMMd().format(DateTime.parse(m.date))),
                subtitle: Text([
                  if (m.weightKg != null) '${m.weightKg} kg',
                  if (m.heightCm != null) '${m.heightCm} cm boy',
                  if (m.calculatedBodyFat != null) '%${m.calculatedBodyFat!.toStringAsFixed(1)} yağ',
                  if (m.chestCm != null) 'Göğüs ${m.chestCm} cm',
                  if (m.waistCm != null) 'Bel ${m.waistCm} cm',
                ].join(' • ')),
              ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Fixed-width, overflow-safe achievement badge card for the horizontally
/// scrollable achievements row. A fixed width (instead of a Grid with
/// `childAspectRatio`) avoids the classic Flutter grid-overflow pitfall and
/// scales cleanly to 50+ achievements without layout blowup.
class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Card(
        color: achievement.unlocked
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                achievement.unlocked ? _achievementIcon(achievement.iconName) : Icons.lock_outline,
                color: achievement.unlocked ? Colors.amber : null,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  achievement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Flexible(
                child: Text(
                  achievement.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

