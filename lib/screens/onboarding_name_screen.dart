import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/atlas_colors.dart';

/// First-launch welcome screen: lets the user optionally enter their name,
/// which is then used for the Dashboard greeting. Skipping is allowed.
class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await context.read<SettingsProvider>().completeOnboarding(
        _nameController.text,
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.fitness_center,
                size: 72,
                color: context.atlas.teamMark,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.accountWelcome,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountOnboardingName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                maxLength: 200,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: l10n.accountName,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _finish(),
              ),
              const SizedBox(height: 24),
              if (_failed) Text(l10n.accountOperationError),
              FilledButton(
                onPressed: _saving ? null : _finish,
                child: Text(l10n.accountContinue),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () {
                        _nameController.clear();
                        _finish();
                      },
                child: Text(l10n.accountSkip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
