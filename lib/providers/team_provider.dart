import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/leaderboard_entry.dart';
import '../models/program_suggestion.dart';
import '../models/team.dart';
import '../models/team_activity_log.dart';
import '../models/team_member.dart';
import '../services/deep_link_service.dart';
import '../services/supabase_service.dart';
import '../utils/expired_token_retry.dart';
import '../theme/team_palette.dart';

/// Why the team features can or cannot be used right now.
enum TeamAvailability {
  /// Supabase credentials are missing or still the `.env.example` placeholders.
  notConfigured,

  /// Supabase is configured but nobody is signed in (guest mode).
  signedOut,

  /// Teams are usable.
  ready,
}

/// Manages team/group operations for social features.
/// Handles creating, joining, and managing teams via Supabase.
class TeamProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  /// Resolved lazily: reading `Supabase.instance` before `Supabase.initialize`
  /// has run throws, and in an unconfigured build it never runs. Constructing
  /// this provider must stay safe so the Team tab can render an explanation
  /// instead of crashing.
  SupabaseClient get _supabase => _service.client;

  /// Whether team features can be used, and if not, why.
  TeamAvailability get availability {
    if (!_service.configured) return TeamAvailability.notConfigured;
    if (_service.currentUser == null) return TeamAvailability.signedOut;
    return TeamAvailability.ready;
  }

  bool get isReady => availability == TeamAvailability.ready;

  List<Team> _myTeams = [];
  final Map<String, List<TeamMember>> _teamMembers = {};
  List<TeamActivityLog> _teamActivityLogs = [];
  List<ProgramSuggestion> _pendingSuggestions = [];
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  List<LeaderboardEntry> _monthlyLeaderboard = [];
  bool _isLoading = false;
  String? _error;

  /// Gets all teams the current user belongs to.
  List<Team> get myTeams => _myTeams;

  /// Gets members of a specific team.
  List<TeamMember> getTeamMembers(String teamId) =>
      _teamMembers[teamId] ?? [];

  /// Gets activity logs for team members.
  List<TeamActivityLog> get teamActivityLogs => _teamActivityLogs;

  /// Gets pending suggestions received by current user.
  List<ProgramSuggestion> get pendingSuggestions => _pendingSuggestions;

  /// Gets weekly leaderboard for current team.
  List<LeaderboardEntry> get weeklyLeaderboard => _weeklyLeaderboard;

  /// Gets monthly leaderboard for current team.
  List<LeaderboardEntry> get monthlyLeaderboard => _monthlyLeaderboard;

  /// Count of unread/pending suggestions.
  int get pendingSuggestionCount =>
      _pendingSuggestions.where((s) => s.status == SuggestionStatus.pending).length;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads the current user's teams from Supabase.
  Future<void> fetchMyTeams() async {
    // Not an error condition: a guest, or an unconfigured build, simply has no
    // teams to load. Throwing here used to leave callers mid-flight with their
    // loading flag still set.
    if (!isReady) {
      _myTeams = [];
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _service.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Query groups where user is a member
      final response = await retryOnExpiredToken(
        action: () async => await _supabase.from('group_members').select('''
          group_id,
          groups(id, name, description, owner_id, invite_token, created_at, color)
        ''').eq('user_id', userId),
        refresh: _service.refreshSession,
      );

      final teams = <Team>[];
      var unreadable = 0;
      for (final row in response as List<dynamic>) {
        final groupData = row['groups'];
        // PostgREST embeds null when the membership row survives but the
        // group itself is not readable — hidden by RLS, or deleted between
        // the two reads. Passing that null to Team.fromJson threw and failed
        // the entire list, so one unreadable team took the whole tab down.
        if (groupData == null) {
          unreadable++;
          continue;
        }
        teams.add(Team.fromJson(Map<String, dynamic>.from(groupData as Map)));
      }
      if (unreadable > 0) {
        debugPrint(
          'fetchMyTeams: skipped $unreadable membership row(s) whose group '
          'was not readable',
        );
      }
      _myTeams = teams;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load teams: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Creates a new team.
  Future<Team> createTeam({
    required String name,
    String? description,
    KitColor kit = kDefaultKit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _service.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate a unique invite token
      final inviteToken = _generateInviteToken();

      final response = await _supabase.from('groups').insert({
        'name': name,
        'description': description,
        'owner_id': userId,
        'invite_token': inviteToken,
        'color': swatchOf(kit).slug,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final team = Team.fromJson(response);

      // Add creator as admin member
      await _supabase.from('group_members').insert({
        'group_id': team.id,
        'user_id': userId,
        'role': 'admin',
        'joined_at': DateTime.now().toIso8601String(),
      });

      _myTeams.add(team);
      _isLoading = false;
      notifyListeners();

      return team;
    } catch (e) {
      _error = 'Failed to create team: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Joins a team using an invite token.
  Future<Team> joinTeamByInviteToken(String inviteToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _service.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // The group cannot be looked up directly: the SELECT policy only exposes
      // groups the caller already belongs to. `join_team_by_invite_token` is a
      // SECURITY DEFINER function that validates the token, inserts the
      // membership row and returns the group in one round trip.
      final response = await _supabase.rpc(
        'join_team_by_invite_token',
        params: {'p_token': inviteToken.trim().toUpperCase()},
      );

      if (response == null) {
        throw Exception('Invalid invite code');
      }

      final team = Team.fromJson(Map<String, dynamic>.from(response as Map));

      _myTeams.removeWhere((t) => t.id == team.id);
      _myTeams.add(team);
      _isLoading = false;
      notifyListeners();

      return team;
    } catch (e) {
      _error = 'Failed to join team: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches members of a specific team.
  Future<void> fetchTeamMembers(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.from('group_members').select('''
        user_id,
        role,
        joined_at,
        social_users(id, display_name, avatar_url)
      ''').eq('group_id', teamId);

      _teamMembers[teamId] = (response as List<dynamic>)
          .map((row) => TeamMember.fromJson(row))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load team members: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Removes a member from a team (admin only).
  Future<void> removeMember(String teamId, String userId) async {
    try {
      final currentUserId = _service.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Verify current user is admin
      final isAdmin = await _isTeamAdmin(teamId, currentUserId);
      if (!isAdmin) throw Exception('You do not have permission to remove members');

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', teamId)
          .eq('user_id', userId);

      // Refresh members
      await fetchTeamMembers(teamId);
    } catch (e) {
      _error = 'Failed to remove member: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Leaves a team.
  Future<void> leaveTeam(String teamId) async {
    try {
      final userId = _service.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', teamId)
          .eq('user_id', userId);

      _myTeams.removeWhere((team) => team.id == teamId);
      _teamMembers.remove(teamId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to leave team: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a team (owner/admin only).
  Future<void> deleteTeam(String teamId) async {
    try {
      final currentUserId = _service.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Verify current user is owner. The team may be absent from the cache
      // entirely — after a sign-out `clear()`, or when this screen was reached
      // by deep link without a prior `fetchMyTeams` — and a bare `firstWhere`
      // would then throw `Bad state: No element`, which reads to the caller as
      // a permission failure rather than an unloaded list.
      final index = _myTeams.indexWhere((t) => t.id == teamId);
      if (index == -1) {
        throw Exception('Team is not loaded; refresh your teams and try again');
      }
      if (_myTeams[index].ownerId != currentUserId) {
        throw Exception('Only the team owner can delete this team');
      }

      await _supabase.from('groups').delete().eq('id', teamId);

      _myTeams.removeWhere((team) => team.id == teamId);
      _teamMembers.remove(teamId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete team: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Changes a team's kit colour.
  ///
  /// Only admins and the owner may do this. The `Admins can update their
  /// group` policy is a `FOR UPDATE ... USING (...)` rule, which does NOT
  /// raise for a caller who fails the check — the statement simply matches
  /// zero rows and PostgREST answers 204. Asking for the updated row back is
  /// therefore the only way to tell a real write from a silently discarded
  /// one; without it a member's attempt would report success.
  Future<void> setTeamColor(String teamId, KitColor kit) async {
    try {
      final updated = await _supabase
          .from('groups')
          .update({'color': swatchOf(kit).slug})
          .eq('id', teamId)
          .select();

      if ((updated as List).isEmpty) {
        throw Exception(
          'Not permitted to change this team\'s colour, or the team no longer exists',
        );
      }

      final index = _myTeams.indexWhere((t) => t.id == teamId);
      if (index != -1) {
        _myTeams[index] = _myTeams[index].copyWith(color: swatchOf(kit).slug);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update team colour: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Checks if current user is an admin of a team.
  Future<bool> _isTeamAdmin(String teamId, String userId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('role')
          .eq('group_id', teamId)
          .eq('user_id', userId)
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Generates an invite token: 8 characters, uppercase, no look-alike
  /// glyphs (0/O, 1/I) so it survives being read aloud or retyped.
  ///
  /// A time-derived token is both guessable and collision-prone against the
  /// UNIQUE constraint on `groups.invite_token`, so this draws from a secure
  /// random source instead.
  String _generateInviteToken() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  /// Gets the invite link for sharing a team.
  ///
  /// Must stay in step with the path [DeepLinkService] listens on, otherwise
  /// shared links open the app without joining anything.
  String getInviteLink(Team team) =>
      DeepLinkService.inviteLinkFor(team.inviteToken);

  /// Clears all cached data.
  void clear() {
    _myTeams.clear();
    _teamMembers.clear();
    _teamActivityLogs.clear();
    _pendingSuggestions.clear();
    _weeklyLeaderboard.clear();
    _monthlyLeaderboard.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ==================== TEAM ACTIVITY METHODS ====================

  /// Fetches team activity logs for a specific date range.
  Future<void> fetchTeamActivityLogs({
    required String teamId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.from('team_activity_log').select().eq('team_id', teamId).gte('activity_date', startDate.toString().split(' ')[0]).lte('activity_date', endDate.toString().split(' ')[0]);

      _teamActivityLogs = (response as List<dynamic>).map((row) => TeamActivityLog.fromJson(row)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch team activity: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Gets activity logs for a specific team member on a specific date.
  Future<List<TeamActivityLog>> getMemberActivityByDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toString().split(' ')[0];
      final response = await _supabase
          .from('team_activity_log')
          .select()
          .eq('user_id', userId)
          .eq('activity_date', dateStr);

      return (response as List<dynamic>).map((row) => TeamActivityLog.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error fetching member activity: $e');
      return [];
    }
  }

  // ==================== PROGRAM SUGGESTION METHODS ====================

  /// Sends a program suggestion to a team member.
  Future<ProgramSuggestion> sendProgramSuggestion({
    required String toUserId,
    required String teamId,
    required SuggestionType type,
    String? exerciseId,
    String? programId,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUserId = _service.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('program_suggestions')
          .insert({
            'from_user_id': currentUserId,
            'to_user_id': toUserId,
            'team_id': teamId,
            'suggestion_type': type.value,
            'related_exercise_id': exerciseId,
            'related_program_id': programId,
            'message': message,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final suggestion = ProgramSuggestion.fromJson(response);

      _isLoading = false;
      notifyListeners();

      return suggestion;
    } catch (e) {
      _error = 'Failed to send suggestion: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches pending suggestions for the current user.
  Future<void> fetchPendingSuggestions() async {
    if (!isReady) {
      _pendingSuggestions = [];
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUserId = _service.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await retryOnExpiredToken(
        action: () async => await _supabase
            .from('program_suggestions')
            .select('''
              *,
              social_users:from_user_id(id, display_name, avatar_url)
            ''')
            .eq('to_user_id', currentUserId)
            .eq('status', 'pending')
            .order('created_at', ascending: false),
        refresh: _service.refreshSession,
      );

      _pendingSuggestions = (response as List<dynamic>).map((row) => ProgramSuggestion.fromJson(row)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch suggestions: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Responds to a program suggestion (accept/reject with optional message).
  Future<void> respondToSuggestion({
    required String suggestionId,
    required SuggestionStatus status,
    String? responseMessage,
  }) async {
    try {
      await _supabase
          .from('program_suggestions')
          .update({
            'status': status.value,
            'response_message': responseMessage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', suggestionId);

      // Refresh suggestions
      await fetchPendingSuggestions();
    } catch (e) {
      _error = 'Failed to respond to suggestion: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ==================== LEADERBOARD METHODS ====================

  /// Fetches weekly leaderboard for a team.
  Future<void> fetchWeeklyLeaderboard(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calculate week start date (Monday)
      final now = DateTime.now();
      final weekStartDate = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = weekStartDate.toString().split(' ')[0];

      final response = await _supabase
          .from('team_leaderboard_weekly')
          .select('''
            *,
            social_users:user_id(id, display_name, avatar_url)
          ''')
          .eq('team_id', teamId)
          .eq('week_start_date', weekStart)
          .order('rank', ascending: true);

      _weeklyLeaderboard = (response as List<dynamic>).map((row) => LeaderboardEntry.fromJson(row)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch weekly leaderboard: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches monthly leaderboard for a team.
  Future<void> fetchMonthlyLeaderboard(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calculate month start date
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toString().split(' ')[0];

      final response = await _supabase
          .from('team_leaderboard_monthly')
          .select('''
            *,
            social_users:user_id(id, display_name, avatar_url)
          ''')
          .eq('team_id', teamId)
          .eq('month_start_date', monthStart)
          .order('rank', ascending: true);

      _monthlyLeaderboard = (response as List<dynamic>).map((row) => LeaderboardEntry.fromJson(row)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch monthly leaderboard: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Manually refresh leaderboards (calls Supabase functions).
  Future<void> refreshLeaderboards() async {
    try {
      // Call Supabase functions to refresh
      await _supabase.rpc('refresh_team_leaderboards_weekly');
      await _supabase.rpc('refresh_team_leaderboards_monthly');
    } catch (e) {
      debugPrint('Error refreshing leaderboards: $e');
      // Don't throw - leaderboards will be stale but app continues
    }
  }
}
