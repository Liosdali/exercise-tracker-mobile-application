import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../l10n/app_localizations.dart';
import 'atlas/status_mark.dart';

const communityTermsAcceptedKey = 'community_terms_accepted_version';

/// Makes sure the user has agreed to the community terms before they create
/// or join a team - the point where they start seeing and producing other
/// people's content. App Store guideline 1.2 and Play's UGC policy both
/// require that agreement, including zero tolerance for objectionable content.
///
/// Returns true when the terms are (now) accepted. Asked once per device and
/// terms version; declining leaves nothing stored, so the next attempt asks
/// again.
Future<bool> ensureCommunityTermsAccepted(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final accepted = prefs.getInt(communityTermsAcceptedKey) ?? 0;
  if (accepted >= LegalLinks.communityTermsVersion) return true;
  if (!context.mounted) return false;

  final l10n = AppLocalizations.of(context)!;
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.communityTermsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communityTermsBody),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => openLegalPage(dialogContext, LegalLinks.termsOfUse),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.communityTermsRead),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.communityTermsDecline),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.communityTermsAccept),
        ),
      ],
    ),
  );
  if (agreed != true) return false;
  await prefs.setInt(
    communityTermsAcceptedKey,
    LegalLinks.communityTermsVersion,
  );
  return true;
}

/// Opens a legal page in the browser, telling the user if that fails
/// instead of doing nothing.
Future<void> openLegalPage(BuildContext context, Uri url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final errorLabel = AppLocalizations.of(context)!.legalLinkOpenError;
  var opened = false;
  try {
    opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[legal] launchUrl FAILED for $url: $e');
  }
  if (opened) return;
  messenger?.showSnackBar(
    SnackBar(
      content: StatusMark(status: AtlasStatus.danger, label: errorLabel),
    ),
  );
}
