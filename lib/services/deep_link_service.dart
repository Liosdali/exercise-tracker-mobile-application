import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // Custom domain used in iOS associated domains & Android App Links
  final String _domain = "https://atlasworkout.app";

  void initDeepLinks(BuildContext context) {
    _appLinks = AppLinks();

    _appLinks.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        _handleIncomingLink(uri, context);
      }
    });

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleIncomingLink(uri, context);
      }
    }, onError: (err) {
      debugPrint("Deep Link Error: $err");
    });
  }

  void _handleIncomingLink(Uri uri, BuildContext context) {
    // Example: https://atlasworkout.app/join?token=XYZ789
    if (uri.path == '/join') {
      final inviteToken = uri.queryParameters['token'];

      if (inviteToken != null && inviteToken.isNotEmpty) {
        debugPrint("Invite link caught! Token: $inviteToken");
        
        // Show join group confirmation modal
        _showJoinGroupDialog(context, inviteToken);
      }
    }
  }

  void shareGroupInviteLink(String groupName, String inviteToken) {
    final String deepLink = "$_domain/join?token=$inviteToken";
    final String message = "Join my workout group '$groupName' on Atlas Workout! Click here:\n$deepLink";
    
    Share.share(message, subject: "Atlas Workout Invite");
  }

  void _showJoinGroupDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group'),
        content: const Text('Do you want to join this workout group? \n\nBy joining, you agree to our EULA and Privacy Policy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Handle Supabase/SQLite joining logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Joined group successfully!')),
              );
            },
            child: const Text('I Agree & Join'),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
