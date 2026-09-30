import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/team_provider.dart';
import '../widgets/atlas/status_mark.dart';
import '../widgets/community_terms_gate.dart';

/// Screen for joining a team using an invite code/token.
class JoinTeamScreen extends StatefulWidget {
  final String? initialToken;

  const JoinTeamScreen({
    super.key,
    this.initialToken,
  });

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  late TextEditingController _tokenController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _joinTeam() async {
    final token = _tokenController.text.trim().toUpperCase();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StatusMark(
            status: AtlasStatus.danger,
            label: AppLocalizations.of(context)!.teamCodeRequired,
          ),
        ),
      );
      return;
    }

    if (!await ensureCommunityTermsAccepted(context)) return;
    if (!mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final teamProvider = context.read<TeamProvider>();
      final team = await teamProvider.joinTeamByInviteToken(token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StatusMark(
            status: AtlasStatus.success,
            label: AppLocalizations.of(context)!
                .teamJoinedSuccess(team.name),
          ),
        ),
      );

      // Navigate back to team list
      Navigator.of(context).pop();
      Navigator.of(context).pop(); // Pop join screen and return to list
    } catch (e) {
      if (!mounted) return;

      String errorMessage = AppLocalizations.of(context)!.teamJoinError;
      if (e.toString().contains('already a member')) {
        errorMessage = AppLocalizations.of(context)!.teamAlreadyMember;
      } else if (e.toString().contains('no rows')) {
        errorMessage = AppLocalizations.of(context)!.teamCodeInvalid;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StatusMark(
            status: AtlasStatus.danger,
            label: errorMessage,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamJoinTeam),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teamJoinDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tokenController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.teamInviteCodeLabel,
                hintText: 'Enter invite code (e.g., ABC12345)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              inputFormatters: [],
              onChanged: (value) {
                // Auto-format to uppercase
                _tokenController.value = TextEditingValue(
                  text: value.toUpperCase(),
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: value.length),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teamInviteCodeHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _joinTeam,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: Text(l10n.teamJoinTeam),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.teamInviteCodeTip,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ' + l10n.teamInviteCodeTip1,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ' + l10n.teamInviteCodeTip2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
