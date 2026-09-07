import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/date_watcher.dart';
import '../utils/tutorial_keys.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'social_feed_screen.dart';
import 'workouts_screen.dart';

/// Root shell with bottom navigation across the 5 main sections: Home,
/// Workouts (with integrated Exercises), Squad/Team, Calendar, and Profile.
///
/// The Squad tab is prominently featured as a floating action button-style tab
/// in the center of the bottom navigation bar, emphasizing it as the heart of
/// the application's social/community features.
///
/// Workouts and Exercises are now integrated into a single tab with sub-tabs,
/// and Profile is restored to the bottom navigation as the 5th tab.
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
    DashboardScreen(),      // 0: Home
    WorkoutsScreen(),       // 1: Workouts
    SocialFeedScreen(),     // 2: Squad/Team
    CalendarScreen(),       // 3: Calendar
    ProfileScreen(),        // 4: Profile
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
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
        label: l10n.navTeam,
        showcaseKey: TutorialKeys.navTeam,
        showcaseTitle: l10n.tutorialTeamTabTitle,
        showcaseDescription: l10n.tutorialTeamTabDescription,
        isFeatured: true,
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
        icon: Icons.person_outlined,
        selectedIcon: Icons.person,
        label: l10n.navProfile,
      ),
    ];
    return AppDateWatcher(
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: _EnhancedNavigationBar(
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
  final bool isFeatured;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.showcaseKey,
    this.showcaseTitle,
    this.showcaseDescription,
    this.isFeatured = false,
  });
}

/// Enhanced navigation bar with a featured floating action button-style center tab.
/// This layout positions regular tabs on the left and right, with a prominent
/// featured tab (Squad/Team) positioned above and at the center of the bar.
///
/// For 5 tabs: [0: Home, 1: Workouts] | [2: Squad (featured)] | [3: Calendar, 4: Profile]
///
/// The featured tab is circular, elevated, and uses contrasting styling to
/// emphasize its importance as the heart of the social/community features.
class _EnhancedNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_NavItem> items;

  const _EnhancedNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final featuredIndex = items.indexWhere((item) => item.isFeatured);
    
    return Material(
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 72,
              child: Row(
                children: [
                  // Left side tabs (before featured)
                  for (var i = 0; i < featuredIndex; i++)
                    Expanded(
                      flex: 1,
                      child: _NavTab(
                        item: items[i],
                        selected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                        isFeatured: false,
                      ),
                    ),
                  // Spacer for featured tab
                  if (featuredIndex >= 0)
                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),
                  // Right side tabs (after featured)
                  for (var i = featuredIndex + 1; i < items.length; i++)
                    Expanded(
                      flex: 1,
                      child: _NavTab(
                        item: items[i],
                        selected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                        isFeatured: false,
                      ),
                    ),
                ],
              ),
            ),
            // Featured FAB-style center tab
            if (featuredIndex >= 0)
              Positioned(
                left: 0,
                right: 0,
                top: -16,
                child: Center(
                  child: _FloatingTeamTab(
                    item: items[featuredIndex],
                    selected: featuredIndex == selectedIndex,
                    onTap: () => onDestinationSelected(featuredIndex),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Floating action button-style tab for the featured center position.
/// This tab is circular, raised above the navigation bar, and uses prominent
/// styling to draw attention.
class _FloatingTeamTab extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _FloatingTeamTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FloatingTeamTab> createState() => _FloatingTeamTabState();
}

class _FloatingTeamTabState extends State<_FloatingTeamTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        widget.selected ? colorScheme.primary : colorScheme.surfaceVariant;
    final foregroundColor =
        widget.selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    Widget tab = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              customBorder: const CircleBorder(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.selected
                        ? widget.item.selectedIcon
                        : widget.item.icon,
                    color: foregroundColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.item.showcaseKey != null) {
      tab = Showcase(
        key: widget.item.showcaseKey!,
        title: widget.item.showcaseTitle,
        description: widget.item.showcaseDescription,
        targetShapeBorder: const CircleBorder(),
        child: tab,
      );
    }
    return tab;
  }
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isFeatured;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
    this.isFeatured = false,
  });

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
