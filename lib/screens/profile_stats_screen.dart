import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/body_measurement.dart';
import '../providers/stats_provider.dart';
import 'body_measurement_form.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

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

    final weeklySeries = stats.weeklyVolumeSeries;
    final maxVolume = weeklySeries.fold<double>(1, (m, w) => w.volume > m ? w.volume : m);
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
                maxY: maxVolume * 1.2,
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
                          child: Text(weeklySeries[index].weekLabel, style: const TextStyle(fontSize: 10)),
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
                          toY: weeklySeries[i].volume,
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
          const SizedBox(height: 24),
          Text(l10n.profileAchievementsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 92,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Card(
                color: achievement.unlocked
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        achievement.unlocked ? Icons.emoji_events : Icons.lock_outline,
                        color: achievement.unlocked ? Colors.amber : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  achievement.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  achievement.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                  if (m.bodyFatPercent != null) '%${m.bodyFatPercent} yağ',
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

