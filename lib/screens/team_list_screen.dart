import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import 'create_team_screen.dart';
import 'join_team_screen.dart';
import 'team_detail_screen.dart';

/// Main Team hub screen showing the user's teams and options to create or join.
class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchMyTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(l10n.navTeam),
            centerTitle: false,
            elevation: 0,
          ),
          if (teamProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (teamProvider.myTeams.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                onCreatePressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateTeamScreen(),
                    ),
                  );
                },
                onJoinPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const JoinTeamScreen(),
                    ),
                  );
                },
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final team = teamProvider.myTeams[index];
                  return _TeamCard(
                    team: team,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TeamDetailScreen(team: team),
                        ),
                      );
                    },
                  );
                },
                childCount: teamProvider.myTeams.length,
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const JoinTeamScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: Text(l10n.teamJoinTeam),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateTeamScreen(),
                ),
              );
            },
            icon: const Icon(Icons.group_add),
            label: Text(l10n.teamCreateTeam),
          ),
        ],
      ),
    );
  }
}

/// Card displaying a single team.
class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final memberCount = context
        .select<TeamProvider, int>((provider) =>
            provider.getTeamMembers(team.id).length);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.group,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(team.name),
        subtitle: Text('$memberCount members'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Empty state when user has no teams.
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;
  final VoidCallback onJoinPressed;

  const _EmptyState({
    required this.onCreatePressed,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.teamEmptyTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teamEmptyDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                FilledButton.icon(
                  onPressed: onCreatePressed,
                  icon: const Icon(Icons.group_add),
                  label: Text(l10n.teamCreateTeam),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onJoinPressed,
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.teamJoinTeam),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
