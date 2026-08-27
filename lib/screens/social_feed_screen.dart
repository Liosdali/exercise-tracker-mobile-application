import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchFeed();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendsWorkouts.isEmpty) {
      return const Center(
        child: Text(
          "No social activity yet.\nJoin a group or invite friends!",
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
            subtitle: Text('${session['title']}\n${session['duration_minutes']} min, ${session['calories']} kcal'),
            trailing: isMe 
              ? null 
              : IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showReportBlockModal(user['id'], user['display_name']),
                ),
          ),
        );
      },
    );
  }
}
