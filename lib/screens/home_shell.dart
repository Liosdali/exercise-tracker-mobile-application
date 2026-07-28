import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/date_watcher.dart';
import 'calendar_screen.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'profile_stats_screen.dart';
import 'workouts_screen.dart';

/// Root shell with bottom navigation across the 5 main sections: Dashboard,
/// Workouts, Calendar, Exercise library, Profile & Stats.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    WorkoutsScreen(),
    CalendarScreen(),
    CategoriesScreen(),
    ProfileStatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.navHome),
      _NavItem(icon: Icons.calendar_view_week_outlined, selectedIcon: Icons.calendar_view_week, label: l10n.navWorkouts),
      _NavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: l10n.navCalendar),
      _NavItem(icon: Icons.fitness_center_outlined, selectedIcon: Icons.fitness_center, label: l10n.navExercises),
      _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: l10n.navProfile),
    ];
    return AppDateWatcher(
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: _FixedWidthNavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          items: items,
        ),
      ),
    );
  }
}

/// Data for a single bottom-nav tab.
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// A bottom navigation bar where every tab is guaranteed the exact same
/// (equal) width and its label never wraps to a second line or overflows -
/// long labels (e.g. "Antrenmanlar") are truncated with an ellipsis
/// instead. This avoids the label-wrapping/clipping that Material's stock
/// [NavigationBar] can exhibit once there are enough tabs that a long label
/// no longer fits on one line at the default font size.
class _FixedWidthNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_NavItem> items;

  const _FixedWidthNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  flex: 1,
                  child: _NavTab(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? item.selectedIcon : item.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
