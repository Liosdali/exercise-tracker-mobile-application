import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';
import '../models/team_member.dart';
import '../models/team_activity_log.dart';
import '../models/program_suggestion.dart';
import '../models/leaderboard_entry.dart';

/// Manages team/group operations for social features.
/// Handles creating, joining, and managing teams via Supabase.
class TeamProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Team> _myTeams = [];
  Map<String, List<TeamMember>> _teamMembers = {};
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Query groups where user is a member
      final response = await _supabase.from('group_members').select('''
        group_id,
        groups(id, name, description, owner_id, invite_token, created_at)
      ''').eq('user_id', userId);

      _myTeams = (response as List<dynamic>)
          .map((row) {
            final groupData = row['groups'];
            return Team.fromJson(groupData);
          })
          .toList();

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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate a unique invite token
      final inviteToken = _generateInviteToken();

      final response = await _supabase.from('groups').insert({
        'name': name,
        'description': description,
        'owner_id': userId,
        'invite_token': inviteToken,
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Find the team with this invite token
      final groupResponse = await _supabase
          .from('groups')
          .select()
          .eq('invite_token', inviteToken)
          .single();

      final team = Team.fromJson(groupResponse);

      // Check if user is already a member
      final existingMember = await _supabase.from('group_members').select().eq('group_id', team.id).eq('user_id', userId);

      if ((existingMember as List).isNotEmpty) {
        throw Exception('You are already a member of this team');
      }

      // Add user to the team
      await _supabase.from('group_members').insert({
        'group_id': team.id,
        'user_id': userId,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });

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
      final currentUserId = _supabase.auth.currentUser?.id;
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
      final userId = _supabase.auth.currentUser?.id;
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
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Verify current user is owner
      final team = _myTeams.firstWhere((t) => t.id == teamId);
      if (team.ownerId != currentUserId) {
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

  /// Generates a unique invite token.
  String _generateInviteToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final input = '$timestamp-$random';
    return md5.convert(input.codeUnits).toString().substring(0, 8).toUpperCase();
  }

  /// Gets the invite link for sharing a team.
  String getInviteLink(Team team) {
    return 'https://atlasworkout.app/join-team?token=${team.inviteToken}';
  }

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
      final currentUserId = _supabase.auth.currentUser?.id;
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('program_suggestions')
          .select('''
            *,
            social_users:from_user_id(id, display_name, avatar_url)
          ''')
          .eq('to_user_id', currentUserId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

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
