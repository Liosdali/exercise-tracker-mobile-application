-- ============================================================================
-- program_suggestions -> social_users ilişkisi
-- ----------------------------------------------------------------------------
-- 202609160002 numaralı migration, istemcinin gömdüğü her sütuna
-- public.social_users(id)'ye ikinci bir FK ekliyordu. O listede
-- program_suggestions atlanmış; oysa istemci öneri listesini çekerken
-- öneriyi gönderenin adını/avatarını gömüyor:
--
--   from('program_suggestions').select('..., social_users:from_user_id(...)')
--
-- from_user_id yalnızca auth.users'a bakıyor, social_users da ayrıca
-- auth.users'a bakıyor. İki tablo ortak ebeveyni paylaşıyor ama aralarında
-- doğrudan ilişki yok ve auth şeması PostgREST'e açık değil. Sonuç, cihaz
-- log'unda görülen hata:
--
--   PGRST200: Could not find a relationship between 'program_suggestions'
--             and 'from_user_id' in the schema cache
--
-- Bu, bekleyen öneri rozetini sessizce bozuyordu: istek her seferinde
-- başarısız oluyor, çağrı `catchError` ile yutulduğu için de ekranda hiçbir
-- belirti çıkmıyordu.
--
-- Yalnızca from_user_id ekleniyor, çünkü 202609160002'nin koyduğu kural bu:
-- sadece istemcinin gerçekten gömdüğü sütunlar. to_user_id hiçbir yerde
-- gömülmüyor; gömülürse çifti buraya eklemek yeterli.
--
-- Re-runnable: FK yalnızca yoksa ekleniyor.
-- ============================================================================

BEGIN;

-- FK eklemeden önce her from_user_id'nin social_users'ta karşılığı olmalı.
-- handle_new_user tetikleyicisi bunu yeni kayıtlarda zaten yapıyor; bu
-- backfill, tetikleyici kurulmadan önce açılmış hesapları kurtarır.
INSERT INTO public.social_users (id, display_name)
SELECT u.id, u.raw_user_meta_data->>'full_name'
FROM auth.users u
LEFT JOIN public.social_users s ON s.id = u.id
WHERE s.id IS NULL;

DO $$
DECLARE
  r        record;
  fk_name  text;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('program_suggestions', 'from_user_id')
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
-- yukarıdaki FK görünmez ve PGRST200 devam eder.
NOTIFY pgrst, 'reload schema';
