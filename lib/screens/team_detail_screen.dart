import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';

/// Screen showing team details, members, and management options.
class TeamDetailScreen extends StatefulWidget {
  final Team team;

  const TeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchTeamMembers(widget.team.id);
    });
  }

  Future<void> _leaveTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.teamLeaveConfirmTitle),
        content: Text(l10n.teamLeaveConfirmMessage(widget.team.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.teamLeave,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<TeamProvider>().leaveTeam(widget.team.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teamLeftSuccess)),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.teamLeaveError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.teamDeleteConfirmTitle),
        content: Text(l10n.teamDeleteConfirmMessage(widget.team.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.commonDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<TeamProvider>().deleteTeam(widget.team.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teamDeletedSuccess)),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.teamDeleteError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();
    final members = teamProvider.getTeamMembers(widget.team.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _leaveTeam();
              } else if (value == 'delete') {
                _deleteTeam();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'leave',
                child: Text(l10n.teamLeave),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                  l10n.commonDelete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.team.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (widget.team.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.team.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Invite Section
            Text(
              l10n.teamInviteMembers,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.teamInviteCode,
                                style: Theme.of(context)
                                    .textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.team.inviteToken,
                                style: Theme.of(context)
                                    .textTheme.headlineSmall,
                                selectionColor: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            // Copy to clipboard implementation
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                    l10n.teamCodeCopied),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.teamInviteLink + ': ' +
                          teamProvider.getInviteLink(
                              widget.team),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Members Section
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.teamMembers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Badge(
                  label: Text('${members.length}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (teamProvider.isLoading)
              const SizedBox(
                height: 100,
                child: Center(
                    child: CircularProgressIndicator()),
              )
            else if (members.isEmpty)
              Center(
                child: Text(l10n.teamNoMembers),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.avatarUrl !=
                              null
                          ? NetworkImage(
                              member.avatarUrl!)
                          : null,
                      child: member.avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(member.displayName),
                    trailing: member.isAdmin
                        ? Chip(
                            label: Text(l10n.teamAdmin),
                            visualDensity:
                                VisualDensity.compact,
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
