import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../providers/team_provider.dart';
import '../services/supabase_service.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({Key? key}) : super(key: key);

  @override
  SocialFeedScreenState createState() => SocialFeedScreenState();
}

class SocialFeedScreenState extends State<SocialFeedScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _friendsWorkouts = [];
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTeamsAndFeed();
    });
  }

  Future<void> _fetchTeamsAndFeed() async {
    try {
      await context.read<TeamProvider>().fetchMyTeams();
      await _fetchFeed();
    } catch (e) {
      debugPrint('Error loading teams and feed: $e');
    }
  }

  Future<void> _fetchFeed() async {
    setState(() => _isLoading = true);
    try {
      // With RLS, this will only return workouts of users in mutual groups
      // and filter out blocked users!
      final response = await _supabase
          .from('workout_sessions')
          .select('''
            *,
            social_users!inner(id, display_name, avatar_url)
          ''')
          .order('date', ascending: false)
          .limit(50);

      setState(() {
        _friendsWorkouts = response as List<dynamic>;
      });
    } catch (e) {
      debugPrint('Error fetching social feed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReportBlockModal(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                title: Text('Report $userName'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await SupabaseService().reportUser(userId, 'Inappropriate content');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User reported and under review.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text('Block $userName', style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await SupabaseService().blockUser(userId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked. You will no longer see their posts.')),
                  );
                  _fetchFeed(); // Refresh feed to apply block immediately
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTeam),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (teamProvider.myTeams.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButton<String?>(
                value: _selectedTeamId,
                hint: Text(l10n.teamSelectTeam),
                isExpanded: true,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.teamAllMembers),
                  ),
                  ...teamProvider.myTeams.map((team) {
                    return DropdownMenuItem<String?>(
                      value: team.id,
                      child: Text(team.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedTeamId = value);
                  _fetchFeed();
                },
              ),
            ),
          Expanded(
            child: _buildFeedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendsWorkouts.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.teamNoActivity,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _friendsWorkouts.length,
      itemBuilder: (context, index) {
        final session = _friendsWorkouts[index];
        final user = session['social_users'];
        final isMe = user['id'] == _supabase.auth.currentUser?.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user['avatar_url'] != null
                  ? NetworkImage(user['avatar_url'])
                  : null,
              child: user['avatar_url'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text('${user['display_name']} completed a workout!'),
            subtitle: Text(
              '${session['title']}\n${session['duration_minutes']} min, ${session['calories']} kcal',
            ),
            trailing: isMe
                ? null
                : IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () =>
                        _showReportBlockModal(user['id'], user['display_name']),
                  ),
          ),
        );
      },
    );
  }
}
