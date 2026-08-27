import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/database_helper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  Future<void> syncUp() async {
    if (_supabase.auth.currentUser == null) return;
    
    final db = await _dbHelper.database;
    final userId = _supabase.auth.currentUser!.id;

    // We fetch sessions that are not synced yet
    final unsyncedSessions = await db.query(
      'workout_sessions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (final session in unsyncedSessions) {
      String syncId = session['sync_id'] as String? ?? '';
      
      final dbData = {
        'user_id': userId,
        'date': session['date'],
        'duration_minutes': session['duration_minutes'],
        'calories': session['calories'],
        'exercise_count': session['exercise_count'],
        'total_sets': session['total_sets'],
        'total_volume': session['total_volume'],
        'title': session['title'],
        'created_at': session['created_at'],
      };

      try {
        if (syncId.isEmpty) {
          // INSERT
          final response = await _supabase.from('workout_sessions').insert(dbData).select().single();
          syncId = response['id'].toString();
        } else {
          // UPDATE
          await _supabase.from('workout_sessions').update(dbData).eq('id', syncId);
        }

        // Mark as synced locally
        await db.update(
          'workout_sessions',
          {'is_synced': 1, 'sync_id': syncId},
          where: 'id = ?',
          whereArgs: [session['id']],
        );
      } catch (e) {
        print('Error syncing up session ${session['id']}: $e');
      }
    }
  }

  Future<void> syncDown() async {
    if (_supabase.auth.currentUser == null) return;
    
    final db = await _dbHelper.database;
    final userId = _supabase.auth.currentUser!.id;

    // Fetch friend workouts via group memberships (assumed handled heavily by RLS/Postgres Functions)
    try {
      final response = await _supabase.rpc('get_friend_workouts');
      final List<dynamic> remoteWorkouts = response;

      for (final rw in remoteWorkouts) {
        // Save to local social_users and workout_sessions
        // Example logic for processing remote friend workouts to local SQLite
      }
    } catch (e) {
      print('Error syncing down: $e');
    }
  }

  Future<void> performFullSync() async {
    await syncUp();
    await syncDown();
  }
}
