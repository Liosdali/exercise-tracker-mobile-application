import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/team_provider.dart';
import '../theme/atlas_tokens.dart';
import '../theme/team_palette.dart';
import '../widgets/atlas/kit_picker.dart';
import '../widgets/atlas/status_mark.dart';

/// Screen for creating a new team.
class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isSubmitting = false;
  KitColor _kit = kDefaultKit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StatusMark(
            status: AtlasStatus.danger,
            label: AppLocalizations.of(context)!.teamNameRequired,
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final teamProvider = context.read<TeamProvider>();
      await teamProvider.createTeam(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        kit: _kit,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StatusMark(
            status: AtlasStatus.success,
            label: AppLocalizations.of(context)!.teamCreatedSuccess,
          ),
        ),
      );

      // Navigate back to team list
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: StatusMark(
            status: AtlasStatus.danger,
            label: 'Error: $e',
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
        title: Text(l10n.teamCreateTeam),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teamCreateDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.teamNameLabel,
                hintText: 'e.g., Morning Runners',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.teamDescriptionLabel,
                hintText: 'What is your team about? (Optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: AtlasSpace.xl),
            KitPicker(
              selected: _kit,
              onChanged: (kit) => setState(() => _kit = kit),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _createTeam,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add),
              label: Text(l10n.teamCreateTeam),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.teamCreateNote,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
