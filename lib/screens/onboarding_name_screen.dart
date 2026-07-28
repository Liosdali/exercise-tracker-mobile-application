import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

/// First-launch welcome screen: lets the user optionally enter their name,
/// which is then used for the Dashboard greeting. Skipping is allowed.
class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<SettingsProvider>().completeOnboarding(_nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fitness_center, size: 72, color: Colors.deepPurple),
              const SizedBox(height: 24),
              Text(
                'Hoş geldin!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Sana nasıl hitap edelim? (Opsiyonel)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'İsminiz',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _finish(),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _finish, child: const Text('Devam Et')),
              TextButton(
                onPressed: () {
                  _nameController.clear();
                  _finish();
                },
                child: const Text('Atla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
