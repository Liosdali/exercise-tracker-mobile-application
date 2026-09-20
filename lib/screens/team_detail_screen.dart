import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../services/deep_link_service.dart';
import '../theme/atlas_colors.dart';
import '../theme/atlas_tokens.dart';
import '../theme/team_palette.dart';
import '../widgets/atlas/kit_picker.dart';
import '../widgets/atlas/team_header.dart';
import '../widgets/atlas/team_theme.dart';
import 'team_activity_screen.dart';
import 'team_leaderboard_screen.dart';

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

  Future<void> _copy(String value, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(confirmation)),
    );
  }

  Future<void> _shareInvite() async {
    final l10n = AppLocalizations.of(context)!;
    await DeepLinkService().shareGroupInviteLink(
      widget.team.name,
      widget.team.inviteToken,
      message: l10n.teamInviteMessage(widget.team.name),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
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
              style: TextStyle(color: context.atlas.danger),
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
          backgroundColor: context.atlas.danger,
        ),
      );
    }
  }

  Future<void> _editColor(BuildContext context, Team team) async {
    final provider = context.read<TeamProvider>();
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<KitColor>(
      context: context,
      builder: (sheetContext) {
        var selection = team.kit;
        return StatefulBuilder(
          builder: (builderContext, setSheetState) => Padding(
            padding: const EdgeInsets.all(AtlasSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitPicker(
                  selected: selection,
                  onChanged: (kit) => setSheetState(() => selection = kit),
                ),
                const SizedBox(height: AtlasSpace.xl),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(selection),
                  child: Text(l10n.teamColorChangeAction),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || picked == team.kit) return;
    await provider.setTeamColor(team.id, picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.teamColorUpdated)),
    );
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
              style: TextStyle(color: context.atlas.danger),
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
          backgroundColor: context.atlas.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();
    final members = teamProvider.getTeamMembers(widget.team.id);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner =
        widget.team.ownerId != null && widget.team.ownerId == currentUserId;
    // The RLS policy already restricts the write to admins and owners; this
    // only decides whether the control is worth showing.
    final isAdmin = isOwner ||
        members.any((m) => m.userId == currentUserId && m.isAdmin);

    return TeamTheme(
      kit: widget.team.kit,
      child: Scaffold(
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
              if (isOwner)
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(
                    l10n.commonDelete,
                    style: TextStyle(color: context.atlas.danger),
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
            // Team Info Header
            TeamHeader(
              teamName: widget.team.name,
              memberSummary: '${members.length} ${l10n.teamMembers}',
              description: widget.team.description,
            ),
            if (isAdmin)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _editColor(context, widget.team),
                  child: Text(l10n.teamColorChangeAction),
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
                                selectionColor: context.atlas.line,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: l10n.teamInviteCode,
                          onPressed: () => _copy(
                            widget.team.inviteToken,
                            l10n.teamCodeCopied,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.teamInviteLink,
                                style: Theme.of(context)
                                    .textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                teamProvider
                                    .getInviteLink(widget.team),
                                style: Theme.of(context)
                                    .textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: l10n.teamInviteLink,
                          onPressed: () => _copy(
                            teamProvider.getInviteLink(widget.team),
                            l10n.teamLinkCopied,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: _shareInvite,
                      icon: const Icon(Icons.ios_share),
                      label: Text(l10n.teamShareInvite),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      TeamLeaderboardScreen(teamId: widget.team.id),
                    ),
                    icon: const Icon(Icons.leaderboard_outlined),
                    label: Text(
                      l10n.teamLeaderboard,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      TeamActivityScreen(teamId: widget.team.id),
                    ),
                    icon: const Icon(Icons.insights_outlined),
                    label: Text(
                      l10n.teamActivity,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }
}
