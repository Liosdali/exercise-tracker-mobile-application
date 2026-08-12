import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/date_watcher.dart';
import '../utils/tutorial_keys.dart';
import 'calendar_screen.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'profile_stats_screen.dart';
import 'workouts_screen.dart';

/// Root shell with bottom navigation across the 5 main sections: Dashboard,
/// Workouts, Calendar, Exercise library, Profile & Stats.
///
/// Also owns the first-launch interactive feature tour (see [TutorialKeys]):
/// a [ShowcaseView] is registered here and started once, right after
/// onboarding, highlighting the Dashboard's "start workout" card and the
/// bottom nav tabs. Users can skip it at any point, and replay it later from
/// Settings (which flips [SettingsProvider.hasSeenTutorial] back to false).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Tracks the last `hasSeenTutorial` value we've reacted to, so the tour
  // is (re-)started exactly once per false->true transition instead of on
  // every rebuild (e.g. while providers are still asynchronously loading).
  bool? _lastHandledHasSeenTutorial;
  late final ShowcaseView _showcaseView;

  static const _screens = [
    DashboardScreen(),
    WorkoutsScreen(),
    CalendarScreen(),
    CategoriesScreen(),
    ProfileStatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      autoPlay: false,
      disableBarrierInteraction: false,
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
      ),
      onFinish: _markTutorialSeen,
      onDismiss: (_) => _markTutorialSeen(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tooltip action labels need localized strings, which aren't available
    // yet in initState, so they're (re-)applied here instead.
    final l10n = AppLocalizations.of(context)!;
    _showcaseView.globalTooltipActions = [
      TooltipActionButton(
        type: TooltipDefaultActionType.skip,
        backgroundColor: Colors.transparent,
        textStyle: const TextStyle(decoration: TextDecoration.underline),
        name: l10n.tutorialSkipButton,
      ),
      const TooltipActionButton(type: TooltipDefaultActionType.previous),
      const TooltipActionButton(type: TooltipDefaultActionType.next),
    ];
  }

  void _markTutorialSeen() {
    if (!mounted) return;
    context.read<SettingsProvider>().setHasSeenTutorial(true);
  }

  void _maybeStartTour(SettingsProvider settings) {
    // Wait for SharedPreferences to finish loading before reacting: until
    // then `hasSeenTutorial` defaults to false, which would otherwise look
    // like a false->true (or null->false) transition and start the tour
    // spuriously on every fresh launch, even for returning users.
    if (!settings.isLoaded) return;
    if (_lastHandledHasSeenTutorial == settings.hasSeenTutorial) return;
    _lastHandledHasSeenTutorial = settings.hasSeenTutorial;
    if (settings.hasSeenTutorial) return;
    if (_index != 0) {
      setState(() => _index = 0);
    }
    _waitForDashboardThenStartTour();
  }

  /// The Dashboard tab briefly shows a loading spinner while its providers
  /// finish loading, during which the "start workout" showcase target isn't
  /// mounted yet. Starting the tour before it's ready would make the
  /// package treat the first step as "not found" and silently finish the
  /// whole tour instantly. So poll (bounded) until the target is rendered.
  void _waitForDashboardThenStartTour([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ready = _showcaseView.isTargetRendered(TutorialKeys.dashboardStartWorkout);
      if (ready || attempt >= 20) {
        _showcaseView.startShowCase(TutorialKeys.tourOrder);
        return;
      }
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _waitForDashboardThenStartTour(attempt + 1);
      });
    });
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    _maybeStartTour(settings);
    final items = [
      _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.navHome),
      _NavItem(
        icon: Icons.calendar_view_week_outlined,
        selectedIcon: Icons.calendar_view_week,
        label: l10n.navWorkouts,
        showcaseKey: TutorialKeys.navWorkouts,
        showcaseTitle: l10n.tutorialWorkoutsTabTitle,
        showcaseDescription: l10n.tutorialWorkoutsTabDescription,
      ),
      _NavItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: l10n.navCalendar,
        showcaseKey: TutorialKeys.navCalendar,
        showcaseTitle: l10n.tutorialCalendarTabTitle,
        showcaseDescription: l10n.tutorialCalendarTabDescription,
      ),
      _NavItem(
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        label: l10n.navExercises,
        showcaseKey: TutorialKeys.navExercises,
        showcaseTitle: l10n.tutorialExercisesTabTitle,
        showcaseDescription: l10n.tutorialExercisesTabDescription,
      ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.navProfile,
        showcaseKey: TutorialKeys.navProfile,
        showcaseTitle: l10n.tutorialProfileTabTitle,
        showcaseDescription: l10n.tutorialProfileTabDescription,
      ),
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
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final String? showcaseDescription;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.showcaseKey,
    this.showcaseTitle,
    this.showcaseDescription,
  });
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
    Widget tab = InkWell(
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
    if (item.showcaseKey != null) {
      tab = Showcase(
        key: item.showcaseKey!,
        title: item.showcaseTitle,
        description: item.showcaseDescription,
        targetShapeBorder: const CircleBorder(),
        child: tab,
      );
    }
    return tab;
  }
}
