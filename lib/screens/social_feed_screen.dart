import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../providers/team_provider.dart';
import '../services/supabase_service.dart';
import '../theme/atlas_colors.dart';
import '../theme/team_palette.dart';
import '../widgets/atlas/feed_item.dart';
import '../widgets/atlas/team_theme.dart';
import 'create_team_screen.dart';
import 'join_team_screen.dart';
import 'pending_suggestions_screen.dart';
import 'team_activity_screen.dart';
import 'team_leaderboard_screen.dart';
import 'team_list_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  SocialFeedScreenState createState() => SocialFeedScreenState();
}

class SocialFeedScreenState extends State<SocialFeedScreen> {
  // Resolved lazily: in an unconfigured build `Supabase.initialize` never ran,
  // and touching `Supabase.instance` would throw while this State is built.
  SupabaseClient get _supabase => SupabaseService().client;
  bool _isLoading = true;
  /// fetchMyTeams patladi: ekip listesine hic ulasilamadi.
  bool _teamsFailed = false;
  /// Ekipler geldi ama aktivite akisi sorgusu patladi. Ayri tutuluyor cunku
  /// "ekiplerin yuklenemedi" demek, ekipleri duran bir kullaniciyi yanlis
  /// yere bakmaya gonderiyor.
  bool _feedFailed = false;
  List<dynamic> _friendsWorkouts = [];
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTeamsAndFeed();
    });
  }

  Future<void> _fetchTeamsAndFeed() async {
    final teamProvider = context.read<TeamProvider>();

    // Guest mode, or no Supabase credentials: there is nothing to load and
    // nothing has gone wrong. Resolve the spinner and let build() explain.
    if (!teamProvider.isReady) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _teamsFailed = false;
          _feedFailed = false;
        });
      }
      return;
    }

    try {
      await teamProvider.fetchMyTeams();
      // Primes the suggestions badge in the app bar.
      unawaited(teamProvider.fetchPendingSuggestions().catchError((Object e) {
        debugPrint('Error loading pending suggestions: $e');
      }));
      await _fetchFeed();
    } catch (e) {
      debugPrint('Error loading teams: $e');
      // Only fetchMyTeams can land here: _fetchFeed handles its own failure
      // and does not rethrow.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _teamsFailed = true;
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _teamsFailed = false;
      _feedFailed = false;
    });
    await _fetchTeamsAndFeed();
  }

  /// Pushes [screen], then reloads — the user may have created or joined a
  /// team while they were away.
  Future<void> _pushThenReload(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) await _retry();
  }

  Future<void> _fetchFeed() async {
    setState(() => _isLoading = true);
    try {
      // RLS already narrows this to users sharing a group with the caller and
      // drops blocked users. The team picker narrows it further, to the
      // members of one specific team.
      List<String>? memberIds;
      final teamId = _selectedTeamId;
      if (teamId != null) {
        final teamProvider = context.read<TeamProvider>();
        if (teamProvider.getTeamMembers(teamId).isEmpty) {
          await teamProvider.fetchTeamMembers(teamId);
        }
        memberIds =
            teamProvider.getTeamMembers(teamId).map((m) => m.userId).toList();
        if (memberIds.isEmpty) {
          if (!mounted) return;
          setState(() {
            _friendsWorkouts = const [];
            _feedFailed = false;
          });
          return;
        }
      }

      var query = _supabase.from('workout_sessions').select('''
            *,
            social_users!inner(id, display_name, avatar_url)
          ''');
      if (memberIds != null) {
        query = query.inFilter('user_id', memberIds);
      }

      final response = await query.order('date', ascending: false).limit(50);

      if (!mounted) return;
      setState(() {
        _friendsWorkouts = response as List<dynamic>;
        _feedFailed = false;
      });
    } catch (e) {
      debugPrint('Error fetching social feed: $e');
      if (mounted) setState(() => _feedFailed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// The team the team-scoped screens act on: whichever team the picker has
  /// selected, otherwise the user's first team.
  String? get _activeTeamId {
    if (_selectedTeamId != null) return _selectedTeamId;
    final teams = context.read<TeamProvider>().myTeams;
    return teams.isEmpty ? null : teams.first.id;
  }

  void _openTeamScoped(Widget Function(String teamId) builder) {
    final teamId = _activeTeamId;
    if (teamId == null) {
      // No team yet: send them where they can create or join one.
      _openTeams();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => builder(teamId)),
    );
  }

  Future<void> _openTeams() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TeamListScreen()),
    );
    if (!mounted) return;
    // Teams may have been created, joined or left while we were away.
    final teams = context.read<TeamProvider>().myTeams;
    if (_selectedTeamId != null &&
        !teams.any((t) => t.id == _selectedTeamId)) {
      setState(() => _selectedTeamId = null);
    }
    await _fetchFeed();
  }

  void _showReportBlockModal(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: context.atlas.warn),
                title: Text('Report $userName'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await SupabaseService().reportUser(userId, 'Inappropriate content');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User reported and under review.')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: context.atlas.danger),
                title: Text('Block $userName', style: TextStyle(color: context.atlas.danger)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await SupabaseService().blockUser(userId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked. You will no longer see their posts.')),
                  );
                  _fetchFeed(); // Refresh feed to apply block immediately
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();
    final ready = teamProvider.isReady;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTeam),
        elevation: 0,
        actions: ready ? [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: l10n.teamLeaderboard,
            onPressed: () => _openTeamScoped(
              (teamId) => TeamLeaderboardScreen(teamId: teamId),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.teamActivity,
            onPressed: () => _openTeamScoped(
              (teamId) => TeamActivityScreen(teamId: teamId),
            ),
          ),
          _SuggestionsButton(
            tooltip: l10n.suggestionInbox,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PendingSuggestionsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: l10n.teamMyTeams,
            onPressed: _openTeams,
          ),
        ] : const [],
      ),
      body: Column(
        children: [
          if (ready && teamProvider.myTeams.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButton<String?>(
                value: _selectedTeamId,
                hint: Text(l10n.teamSelectTeam),
                isExpanded: true,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.teamAllMembers),
                  ),
                  ...teamProvider.myTeams.map((team) {
                    return DropdownMenuItem<String?>(
                      value: team.id,
                      child: Text(team.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedTeamId = value);
                  _fetchFeed();
                },
              ),
            ),
          Expanded(
            child: _buildFeedContent(),
          ),
        ],
      ),
    );
  }

  /// A centred icon + message, with an optional action.
  Widget _message(
    IconData icon,
    String text, {
    String? title,
    List<Widget> actions = const [],
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: iconColor ?? Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(text, textAlign: TextAlign.center),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedContent() {
    final l10n = AppLocalizations.of(context)!;

    // Order matters: explain the reason teams are unusable before showing a
    // spinner or an empty feed, so the tab never looks broken.
    switch (context.watch<TeamProvider>().availability) {
      case TeamAvailability.notConfigured:
        return _message(Icons.cloud_off_outlined, l10n.accountConfigurationError);
      case TeamAvailability.signedOut:
        return _message(Icons.account_circle_outlined, l10n.teamSignInRequired);
      case TeamAvailability.ready:
        break;
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ekip listesine hic ulasilamadi: gercek bir hata, tekrar denenebilir.
    if (_teamsFailed) {
      return _message(
        Icons.error_outline,
        l10n.teamLoadError,
        actions: [
          FilledButton(onPressed: _retry, child: Text(l10n.accountRetry)),
        ],
        iconColor: Theme.of(context).colorScheme.error,
      );
    }

    // Ekipler yuklendi ve kullanicinin hic ekibi yok. Bu bir hata degil,
    // baslangic durumu -- dogru cevap kurma/katilma yoluna cikarmak.
    if (context.watch<TeamProvider>().myTeams.isEmpty) {
      return _message(
        Icons.groups_outlined,
        l10n.teamEmptyDescription,
        title: l10n.teamEmptyTitle,
        actions: [
          FilledButton.icon(
            onPressed: () => _pushThenReload(const CreateTeamScreen()),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.teamCreateTeam),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pushThenReload(const JoinTeamScreen()),
            icon: const Icon(Icons.person_add),
            label: Text(l10n.teamJoinTeam),
          ),
        ],
      );
    }

    // Ekipler var ama akis sorgusu patladi -- ayri mesaj, yoksa kullanici
    // duran ekiplerini aramaya gider.
    if (_feedFailed) {
      return _message(
        Icons.error_outline,
        l10n.teamFeedError,
        actions: [
          FilledButton(onPressed: _retry, child: Text(l10n.accountRetry)),
        ],
        iconColor: Theme.of(context).colorScheme.error,
      );
    }

    if (_friendsWorkouts.isEmpty) {
      return _message(
        Icons.group_outlined,
        l10n.teamNoActivity,
        actions: [
          FilledButton.icon(
            onPressed: _openTeams,
            icon: const Icon(Icons.groups_outlined),
            label: Text(l10n.teamMyTeams),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFeed,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _friendsWorkouts.length,
        itemBuilder: (context, index) {
          final session = _friendsWorkouts[index];
          final user = session['social_users'];
          final isMe = user['id'] == _supabase.auth.currentUser?.id;

          final dateValue = session['date'];
          final timestamp = dateValue is String
              ? DateFormat('yyyy-MM-dd')
                  .format(DateTime.tryParse(dateValue) ?? DateTime.now())
              : '';

          final durationMinutes = (session['duration_minutes'] as num?) ?? 0;
          final calories = (session['calories'] as num?) ?? 0;
          final metric = '${l10n.workoutSummaryDurationValue(durationMinutes.round())}, '
              '${l10n.feedCaloriesValue(calories.round())}';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // This query joins workout_sessions to social_users only; it
            // carries no team_id or color, so a row cannot know which team's
            // kit to wear. Falling back to the default kit rather than
            // inventing a per-row team lookup.
            child: TeamTheme(
              kit: kDefaultKit,
              child: FeedItem(
                actor: (user['display_name'] as String?) ?? '',
                action: (session['title'] as String?) ?? '',
                metric: metric,
                timestamp: timestamp,
                trailing: isMe
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showReportBlockModal(
                          user['id'] as String,
                          user['display_name'] as String,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Suggestions icon carrying a badge with the number of pending suggestions.
class _SuggestionsButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;

  const _SuggestionsButton({required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final count = context.select<TeamProvider, int>(
      (provider) => provider.pendingSuggestionCount,
    );

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: count == 0
          ? const Icon(Icons.mark_email_unread_outlined)
          : Badge(
              label: Text('$count'),
              child: const Icon(Icons.mark_email_unread_outlined),
            ),
    );
  }
}
