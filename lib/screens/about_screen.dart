import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// "Hakkında" screen shown from Settings: app status and developer contact.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAboutTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.aboutBodyText),
      ),
    );
  }
}
