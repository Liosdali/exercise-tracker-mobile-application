-- ============================================================================
-- PostgREST embed'leri için social_users ilişkileri
-- ----------------------------------------------------------------------------
-- İstemci, antrenman ve liderlik satırlarına yazarın adını/avatarını gömüyor:
--
--   from('workout_sessions').select('*, social_users!inner(...)')
--   from('group_members').select('..., social_users(...)')
--   from('team_leaderboard_weekly').select('*, social_users!user_id(...)')
--
-- PostgREST bu gömmeyi yalnızca iki tablo arasında gerçek bir FOREIGN KEY
-- varsa çözebiliyor. Bootstrap şemasında bu sütunların hepsi auth.users'a
-- bakıyordu; social_users da ayrıca auth.users'a bakıyor. İki tablo ortak bir
-- ebeveyni paylaşıyor ama aralarında doğrudan bir ilişki yok, üstelik auth
-- şeması PostgREST'e açık değil. Sonuç:
--
--   PGRST200: Could not find a relationship between 'workout_sessions'
--             and 'social_users' in the schema cache
--
-- Çözüm: gömülen her sütuna public.social_users(id)'ye ikinci bir FK ekle.
-- social_users.id zaten auth.users(id)'yi ON DELETE CASCADE ile takip ettiği
-- için silme davranışı değişmez; kullanıcı silindiğinde zincir yine temizler.
-- ============================================================================

BEGIN;

-- FK eklemeden önce her user_id'nin social_users'ta karşılığı olmalı.
-- handle_new_user tetikleyicisi bunu yeni kayıtlarda zaten yapıyor; bu
-- backfill, tetikleyici kurulmadan önce açılmış hesapları kurtarır.
INSERT INTO public.social_users (id, display_name)
SELECT u.id, u.raw_user_meta_data->>'full_name'
FROM auth.users u
LEFT JOIN public.social_users s ON s.id = u.id
WHERE s.id IS NULL;

-- Yalnızca istemcinin gerçekten gömdüğü sütunlar. Yeni bir embed eklenirse
-- ilgili (tablo, sütun) çiftini buraya eklemek yeterli.
DO $$
DECLARE
  r        record;
  fk_name  text;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('workout_sessions',         'user_id'),
      ('group_members',            'user_id'),
      ('team_leaderboard_weekly',  'user_id'),
      ('team_leaderboard_monthly', 'user_id')
    ) AS t(tbl, col)
  LOOP
    fk_name := format('%s_%s_social_users_fkey', r.tbl, r.col);

    IF NOT EXISTS (
      SELECT 1
      FROM pg_constraint c
      JOIN pg_namespace n ON n.oid = c.connamespace
      WHERE n.nspname = 'public' AND c.conname = fk_name
    ) THEN
      EXECUTE format(
        'ALTER TABLE public.%I '
        'ADD CONSTRAINT %I FOREIGN KEY (%I) '
        'REFERENCES public.social_users(id) ON DELETE CASCADE',
        r.tbl, fk_name, r.col
      );
    END IF;
  END LOOP;
END $$;

COMMIT;

-- PostgREST ilişkileri bir şema önbelleğinde tutuyor; DDL sonrası yenilenmezse
-- yukarıdaki FK'ler görünmez ve PGRST200 devam eder.
NOTIFY pgrst, 'reload schema';
