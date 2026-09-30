-- ============================================================================
-- Atlas Workout — Supabase şema denetimi
--
-- SQL Editor'da çalıştırılan komutlar veritabanında saklanmaz; geriye yalnızca
-- sonuçları kalır. "Hangi dosyayı uygulamıştım?" sorusunun cevabı editördeki
-- geçmişte değil, şemanın kendisindedir. Bu sorgu her dosyanın yaratması
-- gereken nesneleri arar ve dosya başına tek satır verir.
--
-- Her zaman güvenle çalıştırılabilir: hiçbir şeyi değiştirmez, yalnızca okur.
-- ============================================================================

WITH beklenen(sira, dosya, tur, nesne) AS (
  VALUES
    -- supabase_schema.sql (sıfırdan kurulum temeli)
    (1, 'supabase_schema.sql',        'tablo',     'social_users'),
    (1, 'supabase_schema.sql',        'tablo',     'user_blocks'),
    (1, 'supabase_schema.sql',        'tablo',     'user_reports'),
    (1, 'supabase_schema.sql',        'tablo',     'groups'),
    (1, 'supabase_schema.sql',        'tablo',     'group_members'),
    (1, 'supabase_schema.sql',        'tablo',     'workout_sessions'),
    (1, 'supabase_schema.sql',        'fonksiyon', 'handle_new_user'),
    (1, 'supabase_schema.sql',        'trigger',   'on_auth_user_created'),

    -- 202609070001_private_accounts.sql
    (2, '202609070001_private_accounts',  'tablo',     'private_profiles'),
    (2, '202609070001_private_accounts',  'tablo',     'account_records'),
    (2, '202609070001_private_accounts',  'tablo',     'account_operations'),
    (2, '202609070001_private_accounts',  'fonksiyon', 'apply_account_changes'),
    (2, '202609070001_private_accounts',  'fonksiyon', 'get_account_changes'),
    (2, '202609070001_private_accounts',  'fonksiyon', 'delete_user_account'),
    (2, '202609070001_private_accounts',  'fonksiyon', 'provision_private_profile'),

    -- 202609071000_team_content_features.sql
    (3, '202609071000_team_content',  'tablo',     'team_activity_log'),
    (3, '202609071000_team_content',  'tablo',     'program_suggestions'),
    (3, '202609071000_team_content',  'tablo',     'team_leaderboard_weekly'),
    (3, '202609071000_team_content',  'tablo',     'team_leaderboard_monthly'),
    (3, '202609071000_team_content',  'fonksiyon', 'update_team_activity_log'),
    (3, '202609071000_team_content',  'fonksiyon', 'refresh_team_leaderboards_weekly'),
    (3, '202609071000_team_content',  'fonksiyon', 'refresh_team_leaderboards_monthly'),

    -- 202609160001_team_rls_and_schema_fixes.sql
    (4, '202609160001_team_rls_fixes', 'sutun',     'groups.description'),
    (4, '202609160001_team_rls_fixes', 'sutun',     'groups.owner_id'),
    (4, '202609160001_team_rls_fixes', 'fonksiyon', 'is_team_member'),
    (4, '202609160001_team_rls_fixes', 'fonksiyon', 'is_team_admin'),
    (4, '202609160001_team_rls_fixes', 'fonksiyon', 'is_group_owner'),
    (4, '202609160001_team_rls_fixes', 'fonksiyon', 'join_team_by_invite_token'),

    -- 202609160002_postgrest_social_user_relationships.sql
    (5, '202609160002_postgrest_fk',  'fk', 'workout_sessions_user_id_social_users_fkey'),
    (5, '202609160002_postgrest_fk',  'fk', 'group_members_user_id_social_users_fkey'),
    (5, '202609160002_postgrest_fk',  'fk', 'team_leaderboard_weekly_user_id_social_users_fkey'),
    (5, '202609160002_postgrest_fk',  'fk', 'team_leaderboard_monthly_user_id_social_users_fkey')
),
bulunan(tur, nesne) AS (
  SELECT 'tablo', table_name::text
    FROM information_schema.tables
   WHERE table_schema = 'public'
  UNION ALL
  SELECT 'sutun', (table_name || '.' || column_name)::text
    FROM information_schema.columns
   WHERE table_schema = 'public'
  UNION ALL
  SELECT 'fonksiyon', p.proname::text
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
  UNION ALL
  SELECT 'fk', c.conname::text
    FROM pg_constraint c
    JOIN pg_namespace n ON n.oid = c.connamespace
   WHERE n.nspname = 'public' AND c.contype = 'f'
  UNION ALL
  SELECT 'trigger', t.tgname::text
    FROM pg_trigger t
   WHERE NOT t.tgisinternal
)
SELECT
  b.dosya                                                   AS "dosya",
  count(*)                                                  AS "beklenen",
  count(f.nesne)                                            AS "bulunan",
  CASE WHEN count(*) = count(f.nesne)
       THEN 'UYGULANMIS'
       ELSE 'EKSIK'
  END                                                       AS "durum",
  coalesce(
    string_agg(b.tur || ' ' || b.nesne, ', ' ORDER BY b.nesne)
      FILTER (WHERE f.nesne IS NULL),
    '-'
  )                                                         AS "eksik olanlar"
FROM beklenen b
LEFT JOIN bulunan f
       ON f.tur = b.tur AND f.nesne = b.nesne
GROUP BY b.sira, b.dosya
ORDER BY b.sira;
