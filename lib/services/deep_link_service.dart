import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/team_provider.dart';
import '../screens/team_detail_screen.dart';
import '../widgets/atlas/status_mark.dart';

/// Handles `https://atlasworkout.app/join?token=XYZ789` invite links.
///
/// Started once by the root shell with a [BuildContext] that sits *below* the
/// provider scope and *above* the navigator, so the confirmation dialog can
/// reach [TeamProvider] and push the team the user just joined.
class DeepLinkService {
  /// Custom domain used in iOS associated domains & Android App Links.
  static const String domain = 'https://atlasworkout.app';

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Guards against handling the same token twice: a cold start delivers the
  /// launch URI through `getInitialLink()` and, on some platforms, again
  /// through `uriLinkStream`.
  String? _lastHandledToken;
  bool _isDialogOpen = false;

  /// Builds the shareable invite URL for a team.
  static String inviteLinkFor(String inviteToken) =>
      '$domain/join?token=$inviteToken';

  void initDeepLinks(BuildContext context) {
    if (_appLinks != null) return;
    // `app_links` ships no web or desktop implementation. Where the plugin is
    // absent, activating its event channel raises a MissingPluginException
    // that surfaces through FlutterError.onError rather than the
    // subscription's `onError`, so it cannot be caught at the call site — it
    // just becomes an uncaught framework error. This project builds for
    // Windows as well as mobile, so the guard is not hypothetical.
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    final appLinks = AppLinks();
    _appLinks = appLinks;

    unawaited(
      appLinks.getInitialLink().then((Uri? uri) {
        if (uri != null && context.mounted) {
          _handleIncomingLink(uri, context);
        }
      }).catchError((Object err) {
        debugPrint('Deep link (initial) error: $err');
      }),
    );

    _linkSubscription = appLinks.uriLinkStream.listen(
      (Uri uri) {
        if (context.mounted) _handleIncomingLink(uri, context);
      },
      onError: (Object err) => debugPrint('Deep link error: $err'),
    );
  }

  void _handleIncomingLink(Uri uri, BuildContext context) {
    if (uri.path != '/join') return;

    final inviteToken = uri.queryParameters['token']?.trim();
    if (inviteToken == null || inviteToken.isEmpty) return;
    if (_isDialogOpen || inviteToken == _lastHandledToken) return;

    _lastHandledToken = inviteToken;
    unawaited(_showJoinGroupDialog(context, inviteToken));
  }

  /// Opens the platform share sheet with the team's invite link.
  Future<void> shareGroupInviteLink(
    String groupName,
    String inviteToken, {
    String? message,
  }) {
    final link = inviteLinkFor(inviteToken);
    return SharePlus.instance.share(
      ShareParams(
        text: message == null ? link : '$message\n$link',
        subject: groupName,
      ),
    );
  }

  Future<void> _showJoinGroupDialog(BuildContext context, String token) async {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.read<TeamProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    _isDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teamJoinTeam),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.teamJoinDescription),
            const SizedBox(height: 16),
            Text(l10n.teamInviteCode, style: Theme.of(ctx).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(token, style: Theme.of(ctx).textTheme.titleMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.teamJoinTeam),
          ),
        ],
      ),
    );
    _isDialogOpen = false;

    if (confirmed != true) {
      // Let the user open the same link again later.
      _lastHandledToken = null;
      return;
    }

    try {
      final team = await teamProvider.joinTeamByInviteToken(token);

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.teamJoinedSuccess(team.name))),
      );

      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => TeamDetailScreen(team: team),
        ),
      );
    } catch (e) {
      _lastHandledToken = null;
      final error = e.toString();
      final text = error.contains('Already a member')
          ? l10n.teamAlreadyMember
          : error.contains('Invalid invite code')
              ? l10n.teamCodeInvalid
              : l10n.teamJoinError;

      messenger.showSnackBar(
        SnackBar(
          content: StatusMark(status: AtlasStatus.danger, label: text),
        ),
      );
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _appLinks = null;
  }
}
