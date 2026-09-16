-- ============================================================================
-- Atlas Workout — SIFIRDAN KURULUM (tek dosya)
--
-- Bu dosya elle üretildi: kök dizindeki supabase_schema.sql ile
-- supabase/migrations/ altındaki üç migration'ı DOĞRU SIRADA birleştirir.
-- Sıra önemlidir; team_content_features public.groups tablosuna foreign key
-- verdiği için bootstrap'tan önce çalıştırılamaz.
--
-- NASIL ÇALIŞTIRILIR
--   Supabase Dashboard -> SQL Editor -> New query -> bu dosyanın tamamını
--   yapıştır -> Run. Tek seferde çalışır.
--
-- UYARI
--   Yalnızca BOŞ bir Supabase projesi içindir. Şeması kurulmuş mevcut bir
--   veritabanında bunu ÇALIŞTIRMA — orada yalnızca yeni migration'ları
--   uygula (supabase db push).
--
-- Kaynak dosyalar değişirse bu birleşik dosya elle güncellenmelidir.
-- Üretildiği tarih: 2026-09-16
-- ============================================================================


-- ==========================================================================
-- 1/4  Sosyal temel şema (social_users, groups, group_members, workout_sessions, bloklar, şikâyetler)
-- kaynak: supabase_schema.sql
-- ==========================================================================

-- Fresh-install psql entry point for Atlas Workout.
-- Run with ON_ERROR_STOP=1. Existing installations must apply only the
-- incremental files under supabase/migrations, not this social bootstrap.
-- The final \ir includes the authoritative private schema without maintaining
-- a second copy. In the Supabase SQL editor, run this social bootstrap without
-- the \ir line, followed by 202609070001_private_accounts.sql.

-- 1. ENUMS & EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS TABLE (Linked to auth.users)
CREATE TABLE public.social_users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger to create a user in social_users when they sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.social_users(id, display_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- 3. APP STORE GUIDES (Blocks & Reports)
CREATE TABLE public.user_blocks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  blocker_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

CREATE TABLE public.user_reports (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reported_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. GROUPS
CREATE TABLE public.groups (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  invite_token TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.group_members (
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'admin' or 'member'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

-- 5. WORKOUTS
CREATE TABLE public.workout_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  duration_minutes INTEGER,
  calories REAL,
  exercise_count INTEGER,
  total_sets INTEGER,
  total_volume REAL,
  title TEXT,
  created_at TEXT
);

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.social_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;

-- Users can only see profiles of people they haven't blocked and who haven't blocked them
CREATE POLICY "Users can view non-blocked profiles" ON public.social_users
  FOR SELECT USING (
    id NOT IN (
      SELECT blocked_id FROM public.user_blocks WHERE blocker_id = auth.uid()
    )
    AND
    id NOT IN (
      SELECT blocker_id FROM public.user_blocks WHERE blocked_id = auth.uid()
    )
  );

-- Users can manage their own profile
CREATE POLICY "Users can edit own profile" ON public.social_users
  FOR UPDATE USING (auth.uid() = id);

-- Groups RLS
CREATE POLICY "Users can view groups they belong to" ON public.groups
  FOR SELECT USING (
    id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Group Members RLS
CREATE POLICY "Users can view members of their groups" ON public.group_members
  FOR SELECT USING (
    group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Workout Sessions RLS (Only view friends in the same group, that are not blocked)
CREATE POLICY "Users can view mutual group members workouts" ON public.workout_sessions
  FOR SELECT USING (
    user_id = auth.uid() OR (
      user_id IN (
        SELECT user_id FROM public.group_members WHERE group_id IN (
          SELECT group_id FROM public.group_members WHERE user_id = auth.uid()
        )
      )
      AND user_id NOT IN (SELECT blocked_id FROM public.user_blocks WHERE blocker_id = auth.uid())
      AND user_id NOT IN (SELECT blocker_id FROM public.user_blocks WHERE blocked_id = auth.uid())
    )
  );

CREATE POLICY "Users can insert own workouts" ON public.workout_sessions
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own workouts" ON public.workout_sessions
  FOR UPDATE USING (user_id = auth.uid());

-- RPC FUNCTION: FOR DELETING USER ACCOUNT (Guideline 5.1.1)
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void AS $$
BEGIN
  -- Data in public tables will cascade automatically because of 'ON DELETE CASCADE'
  -- Deleting the user from auth.users triggers the cascades
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;
  IF EXISTS (
    SELECT 1 FROM auth.identities
    WHERE user_id = auth.uid() AND provider = 'apple'
  ) THEN
    RAISE EXCEPTION 'Apple accounts must use the delete-account endpoint'
      USING ERRCODE = '42501';
  END IF;
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- This authoritative migration also hardens the legacy function grants.


-- ==========================================================================
-- 2/4  Özel hesap şeması ve senkronizasyon (private_profiles, account_records, account_operations)
-- kaynak: supabase/migrations/202609070001_private_accounts.sql
-- ==========================================================================

-- Private account synchronization is deliberately separate from social feeds.
-- Safe to apply to the existing social schema; no legacy data is removed.
BEGIN;

CREATE TABLE IF NOT EXISTS public.private_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT '' CHECK (length(name) <= 200),
  age integer CHECK (age >= 0),
  weight_kg double precision CHECK (weight_kg > 0 AND weight_kg < 'Infinity'::float8),
  height_cm double precision CHECK (height_cm > 0 AND height_cm < 'Infinity'::float8),
  gender text CHECK (length(gender) <= 50),
  avatar_url text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS public.account_change_cursor;
CREATE TABLE IF NOT EXISTS public.account_records (
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity text NOT NULL CHECK (entity IN (
    'user_profile','account_preferences','custom_programs','custom_routines',
    'workout_sessions','workout_entries','body_measurements','planned_workouts',
    'program_progress','achievements_unlocked')),
  record_id text NOT NULL CHECK (length(record_id) BETWEEN 1 AND 200),
  payload jsonb, -- NULL is a permanent revisioned deletion tombstone.
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  change_cursor bigint NOT NULL DEFAULT nextval('public.account_change_cursor'),
  program_entity text CHECK (program_entity = 'custom_programs'),
  program_id text,
  session_entity text CHECK (session_entity = 'workout_sessions'),
  session_id text,
  PRIMARY KEY (owner_id,entity,record_id),
  FOREIGN KEY (owner_id,program_entity,program_id)
    REFERENCES public.account_records(owner_id,entity,record_id)
    DEFERRABLE INITIALLY DEFERRED,
  FOREIGN KEY (owner_id,session_entity,session_id)
    REFERENCES public.account_records(owner_id,entity,record_id)
    DEFERRABLE INITIALLY DEFERRED,
  CHECK ((program_entity IS NULL) = (program_id IS NULL)),
  CHECK ((session_entity IS NULL) = (session_id IS NULL))
);
CREATE INDEX IF NOT EXISTS account_records_download
  ON public.account_records(owner_id,change_cursor);
CREATE TABLE IF NOT EXISTS public.account_operations (
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operation_id uuid NOT NULL,
  request jsonb NOT NULL,
  result jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(owner_id,operation_id)
);

ALTER TABLE public.private_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_operations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS private_profile_owner ON public.private_profiles;
CREATE POLICY private_profile_owner ON public.private_profiles
  FOR SELECT TO authenticated USING (id = auth.uid());
DROP POLICY IF EXISTS account_record_owner ON public.account_records;
CREATE POLICY account_record_owner ON public.account_records
  FOR SELECT TO authenticated USING (owner_id = auth.uid());
DROP POLICY IF EXISTS account_operation_owner ON public.account_operations;
CREATE POLICY account_operation_owner ON public.account_operations
  FOR SELECT TO authenticated USING (owner_id = auth.uid());
REVOKE ALL ON public.private_profiles, public.account_records, public.account_operations
  FROM anon, authenticated;
GRANT SELECT ON public.private_profiles, public.account_records TO authenticated;
REVOKE ALL ON SEQUENCE public.account_change_cursor FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.validate_account_payload(e text, k text, p jsonb)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE n text; v numeric; d jsonb; x jsonb; allowed text[]; required_fields text[];
BEGIN
  IF p IS NULL OR p = 'null'::jsonb THEN RETURN; END IF;
  IF jsonb_typeof(p) <> 'object' THEN RAISE EXCEPTION 'Invalid record payload'; END IF;
  allowed := CASE e
    WHEN 'user_profile' THEN ARRAY['name','age','weight_kg','height_cm','gender','body_fat_percent','updated_at']
    WHEN 'account_preferences' THEN ARRAY['key','value']
    WHEN 'custom_programs' THEN ARRAY['name','created_at','days']
    WHEN 'custom_routines' THEN ARRAY['name','created_at','exercises']
    WHEN 'workout_sessions' THEN ARRAY['date','duration_minutes','calories','exercise_count','total_sets','total_volume','title','created_at']
    WHEN 'workout_entries' THEN ARRAY['date','exercise_id','exercise_name','category','sets','reps','weight','notes','created_at','session_id']
    WHEN 'body_measurements' THEN ARRAY['date','weight_kg','body_fat_percent','chest_cm','waist_cm','notes','created_at','height_cm','gender','neck_cm','hip_cm','calculated_body_fat']
    WHEN 'planned_workouts' THEN ARRAY['date','program_key','day_index','day_name','day_sync_id']
    WHEN 'program_progress' THEN ARRAY['program_key','next_day_index','last_completed_date']
    WHEN 'achievements_unlocked' THEN ARRAY['achievement_id','unlocked_at']
    ELSE NULL END;
  IF allowed IS NULL OR EXISTS (SELECT 1 FROM jsonb_object_keys(p) q WHERE NOT q = ANY(allowed)) THEN
    RAISE EXCEPTION 'Unknown record fields';
  END IF;
  required_fields := CASE e
    WHEN 'user_profile' THEN ARRAY['name','updated_at']
    WHEN 'account_preferences' THEN ARRAY['key']
    WHEN 'custom_programs' THEN ARRAY['name','created_at','days']
    WHEN 'custom_routines' THEN ARRAY['name','created_at','exercises']
    WHEN 'workout_sessions' THEN ARRAY['date','duration_minutes','calories','exercise_count','total_sets','total_volume','title','created_at']
    WHEN 'workout_entries' THEN ARRAY['date','exercise_id','exercise_name','category','created_at']
    WHEN 'body_measurements' THEN ARRAY['date','created_at']
    WHEN 'planned_workouts' THEN ARRAY['date','program_key','day_index','day_name']
    WHEN 'program_progress' THEN ARRAY['program_key','next_day_index']
    WHEN 'achievements_unlocked' THEN ARRAY['achievement_id','unlocked_at'] END;
  FOREACH n IN ARRAY required_fields LOOP
    IF p->>n IS NULL THEN RAISE EXCEPTION 'Required field missing: %',n; END IF;
  END LOOP;
  FOREACH n IN ARRAY ARRAY['name','gender','updated_at','key','created_at','date','title',
      'exercise_id','exercise_name','category','notes','session_id','program_key','day_name',
      'last_completed_date','achievement_id','unlocked_at','day_sync_id'] LOOP
    IF p->>n IS NOT NULL AND jsonb_typeof(p->n)<>'string' THEN RAISE EXCEPTION 'Text field required'; END IF;
  END LOOP;
  FOREACH n IN ARRAY ARRAY['created_at','updated_at','unlocked_at'] LOOP
    IF p->>n IS NOT NULL THEN PERFORM (p->>n)::timestamptz; END IF;
  END LOOP;
  IF e IN ('custom_programs','custom_routines','workout_sessions','workout_entries','body_measurements') THEN
    PERFORM k::uuid;
  END IF;
  IF e='user_profile' AND (k <> 'profile' OR length(p->>'name') > 200 OR p->>'name' IS NULL) THEN
    RAISE EXCEPTION 'Invalid profile';
  END IF;
  IF e='account_preferences' AND (k IS DISTINCT FROM p->>'key' OR NOT k = ANY(ARRAY[
    'weekly_goal','sound_enabled','vibration_enabled','active_program_key',
    'has_completed_onboarding','notifications_enabled','streak_warnings_enabled',
    'daily_reminder_enabled','has_seen_tutorial'])) THEN
    RAISE EXCEPTION 'Invalid preference';
  END IF;
  IF e='account_preferences' THEN
    IF k='weekly_goal' AND (jsonb_typeof(p->'value') IS DISTINCT FROM 'number' OR
        (p->>'value')::numeric NOT BETWEEN 1 AND 7 OR (p->>'value')::numeric<>trunc((p->>'value')::numeric)) THEN
      RAISE EXCEPTION 'Invalid weekly goal';
    ELSIF k='active_program_key' AND p->>'value' IS NOT NULL AND
        (jsonb_typeof(p->'value')<>'string' OR p->>'value' !~ '^(custom:|builtin:).+') THEN
      RAISE EXCEPTION 'Invalid active program';
    ELSIF k NOT IN ('weekly_goal','active_program_key') AND jsonb_typeof(p->'value') IS DISTINCT FROM 'boolean' THEN
      RAISE EXCEPTION 'Boolean preference required';
    END IF;
  END IF;
  IF e='planned_workouts' AND k IS DISTINCT FROM p->>'date' THEN RAISE EXCEPTION 'Calendar key mismatch'; END IF;
  IF e='program_progress' AND k IS DISTINCT FROM p->>'program_key' THEN RAISE EXCEPTION 'Program key mismatch'; END IF;
  IF e='achievements_unlocked' AND k IS DISTINCT FROM p->>'achievement_id' THEN RAISE EXCEPTION 'Achievement key mismatch'; END IF;
  IF e IN ('planned_workouts','program_progress') AND
      (p->>'program_key' IS NULL OR p->>'program_key' !~ '^(custom:|builtin:).+') THEN
    RAISE EXCEPTION 'Invalid program reference';
  END IF;
  FOREACH n IN ARRAY ARRAY['date','last_completed_date'] LOOP
    IF p->>n IS NOT NULL THEN
      IF p->>n !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN RAISE EXCEPTION 'Invalid calendar date'; END IF;
      PERFORM (p->>n)::date;
    END IF;
  END LOOP;
  IF e IN ('workout_sessions','workout_entries','body_measurements','planned_workouts')
      AND p->>'date' IS NULL THEN RAISE EXCEPTION 'Date required'; END IF;
  FOREACH n IN ARRAY ARRAY['age','sets','reps','duration_minutes','exercise_count','total_sets','day_index','next_day_index'] LOOP
    IF p->>n IS NOT NULL THEN
      IF jsonb_typeof(p->n)<>'number' THEN RAISE EXCEPTION 'Number required'; END IF;
      v := (p->>n)::numeric;
      IF v < 0 OR v <> trunc(v) OR v > 2147483647 THEN
        RAISE EXCEPTION 'Invalid integer measurement';
      END IF;
    END IF;
  END LOOP;
  FOREACH n IN ARRAY ARRAY['weight_kg','height_cm','chest_cm','waist_cm','neck_cm','hip_cm'] LOOP
    IF p->>n IS NOT NULL THEN
      IF jsonb_typeof(p->n)<>'number' THEN RAISE EXCEPTION 'Number required'; END IF;
      v := (p->>n)::numeric;
      IF v <= 0 OR v >= 'Infinity'::numeric OR v = 'NaN'::numeric THEN RAISE EXCEPTION 'Measurements must be positive'; END IF;
    END IF;
  END LOOP;
  FOREACH n IN ARRAY ARRAY['weight','calories','total_volume','body_fat_percent','calculated_body_fat'] LOOP
    IF p->>n IS NOT NULL THEN
      IF jsonb_typeof(p->n)<>'number' THEN RAISE EXCEPTION 'Number required'; END IF;
      v := (p->>n)::numeric;
      IF v < 0 OR v >= 'Infinity'::numeric OR v = 'NaN'::numeric THEN RAISE EXCEPTION 'Invalid measurement'; END IF;
    END IF;
  END LOOP;
  IF length(p->>'gender') > 50 THEN RAISE EXCEPTION 'Invalid gender'; END IF;
  IF e IN ('custom_programs','custom_routines') AND p->>'name' IS NULL THEN RAISE EXCEPTION 'Name required'; END IF;
  IF e='custom_programs' THEN
    IF jsonb_typeof(p->'days') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Program days required'; END IF;
    FOR d IN SELECT value FROM jsonb_array_elements(p->'days') LOOP
      PERFORM (d->>'sync_id')::uuid;
      IF d->>'name' IS NULL OR (d->>'position')::int < 0 OR jsonb_typeof(d->'exercises') IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'Invalid program day';
      END IF;
      FOR x IN SELECT value FROM jsonb_array_elements(d->'exercises') LOOP
        IF x->>'exercise_id' IS NULL OR (x->>'target_sets')::int < 0 OR (x->>'target_reps')::int < 0 THEN
          RAISE EXCEPTION 'Invalid program exercise';
        END IF;
      END LOOP;
    END LOOP;
  END IF;
  IF e='custom_routines' THEN
    IF jsonb_typeof(p->'exercises') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Routine exercises required'; END IF;
    FOR x IN SELECT value FROM jsonb_array_elements(p->'exercises') LOOP
      IF x->>'exercise_id' IS NULL OR (x->>'target_sets')::int < 0 OR (x->>'target_reps')::int < 0 THEN
        RAISE EXCEPTION 'Invalid routine exercise';
      END IF;
    END LOOP;
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.validate_account_payload(text,text,jsonb) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.provision_private_profile(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE p public.private_profiles; metadata jsonb;
BEGIN
  SELECT raw_user_meta_data INTO metadata FROM auth.users WHERE id=p_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Account not found'; END IF;
  INSERT INTO public.private_profiles(id,name,avatar_url)
    VALUES(p_user_id,left(coalesce(metadata->>'full_name',metadata->>'name',''),200),metadata->>'avatar_url')
    ON CONFLICT(id) DO NOTHING;
  SELECT * INTO p FROM public.private_profiles WHERE id=p_user_id;
  INSERT INTO public.account_records(owner_id,entity,record_id,payload)
    VALUES(p_user_id,'user_profile','profile',jsonb_build_object(
      'name',p.name,'age',p.age,'weight_kg',p.weight_kg,'height_cm',p.height_cm,
      'gender',p.gender,'updated_at',p.updated_at))
    ON CONFLICT(owner_id,entity,record_id) DO NOTHING;
END;
$$;
REVOKE ALL ON FUNCTION public.provision_private_profile(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.on_private_account_created()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  PERFORM public.provision_private_profile(NEW.id);
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.on_private_account_created() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS on_private_account_created ON auth.users;
CREATE TRIGGER on_private_account_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.on_private_account_created();
SELECT public.provision_private_profile(id) FROM auth.users;

-- Retain legacy social provisioning without granting it access to private data.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  INSERT INTO public.social_users(id,display_name)
    VALUES(NEW.id,NEW.raw_user_meta_data->>'full_name') ON CONFLICT(id) DO NOTHING;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.apply_account_changes(p_operation_id uuid, p_operations jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  uid uuid := auth.uid(); cached public.account_operations; op jsonb;
  current_row public.account_records; answer jsonb := '[]'::jsonb;
  e text; k text; p jsonb; pk text; sid text; rev bigint;
  root_op jsonb; child_op jsonb; other_op jsonb; new_day jsonb; child_payload jsonb;
  root_row public.account_records; child_row public.account_records;
  root_entity text; root_id text; root_payload jsonb;
  root_conflict boolean; affected boolean;
  blocked jsonb := '{}'::jsonb; group_identity jsonb;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  -- Serialize all writes for this owner, including first insert and cursor
  -- allocation. A committed higher cursor cannot hide an uncommitted lower one.
  PERFORM pg_advisory_xact_lock(hashtextextended(uid::text,0));
  SELECT * INTO cached FROM public.account_operations WHERE owner_id=uid AND operation_id=p_operation_id;
  IF FOUND THEN
    IF cached.request IS DISTINCT FROM p_operations THEN RAISE EXCEPTION 'Operation ID reused with different content'; END IF;
    RETURN cached.result;
  END IF;
  IF jsonb_typeof(p_operations) IS DISTINCT FROM 'array' OR jsonb_array_length(p_operations)>10000 THEN
    RAISE EXCEPTION 'Invalid operation batch';
  END IF;
  IF EXISTS(SELECT 1 FROM jsonb_array_elements(p_operations) item
    GROUP BY item->>'entity',item->>'record_id' HAVING count(*)>1) THEN
    RAISE EXCEPTION 'Duplicate entity in operation batch';
  END IF;
  PERFORM public.provision_private_profile(uid);
  -- Validate the complete request before changing any row.
  FOR op IN SELECT value FROM jsonb_array_elements(p_operations) LOOP
    IF op->>'expected_revision' IS NULL OR (op->>'expected_revision')::bigint < 0 THEN
      RAISE EXCEPTION 'Expected revision required';
    END IF;
    e := op->>'entity'; k := op->>'record_id';
    p := nullif(op->'payload','null'::jsonb);
    PERFORM public.validate_account_payload(e,k,p);
  END LOOP;

  -- A parent mutation must not turn a stale child deletion into a matching
  -- tombstone. Authorize every affected dependant against its actual revision
  -- BEFORE any writes; a conflict blocks the entire requested dependency group.
  FOR root_op IN SELECT value FROM jsonb_array_elements(p_operations)
      WHERE value->>'entity' IN ('custom_programs','workout_sessions') LOOP
    root_entity := root_op->>'entity'; root_id := root_op->>'record_id';
    root_payload := nullif(root_op->'payload','null'::jsonb);
    SELECT * INTO root_row FROM public.account_records
      WHERE owner_id=uid AND entity=root_entity AND record_id=root_id;
    rev := CASE WHEN FOUND THEN root_row.revision ELSE 0 END;
    root_conflict := rev<>(root_op->>'expected_revision')::bigint
      AND root_row.payload IS DISTINCT FROM root_payload;
    FOR child_row IN SELECT * FROM public.account_records
        WHERE owner_id=uid AND payload IS NOT NULL AND
          ((root_entity='workout_sessions' AND session_id=root_id)
            OR (root_entity='custom_programs' AND program_id=root_id)) LOOP
      affected := root_payload IS NULL;
      IF root_entity='custom_programs' AND root_payload IS NOT NULL
          AND child_row.entity='planned_workouts' AND child_row.payload->>'day_sync_id' IS NOT NULL THEN
        SELECT value INTO new_day FROM jsonb_array_elements(root_payload->'days')
          WHERE value->>'sync_id'=child_row.payload->>'day_sync_id' LIMIT 1;
        affected := NOT FOUND OR new_day->'position' IS DISTINCT FROM child_row.payload->'day_index'
          OR new_day->'name' IS DISTINCT FROM child_row.payload->'day_name';
      END IF;
      IF affected THEN
        SELECT value INTO child_op FROM jsonb_array_elements(p_operations)
          WHERE value->>'entity'=child_row.entity AND value->>'record_id'=child_row.record_id;
        IF NOT FOUND OR (child_op->>'expected_revision')::bigint<>child_row.revision THEN
          root_conflict := true;
        ELSIF root_payload IS NULL THEN
          child_payload := nullif(child_op->'payload','null'::jsonb);
          IF (root_entity='workout_sessions' AND child_payload->>'session_id'=root_id)
            OR (root_entity='custom_programs' AND
              (child_payload->>'program_key'='custom:' || root_id
                OR (child_row.entity='account_preferences'
                  AND child_payload->>'value'='custom:' || root_id))) THEN
            root_conflict := true;
          END IF;
        END IF;
      END IF;
    END LOOP;
    IF root_conflict THEN
      group_identity := jsonb_build_object('entity',root_entity,'record_id',root_id);
      blocked := blocked || jsonb_build_object(root_entity || ':' || root_id,group_identity);
      FOR other_op IN SELECT value FROM jsonb_array_elements(p_operations) LOOP
        IF EXISTS(SELECT 1 FROM public.account_records
            WHERE owner_id=uid AND entity=other_op->>'entity' AND record_id=other_op->>'record_id'
              AND ((root_entity='workout_sessions' AND session_id=root_id)
                OR (root_entity='custom_programs' AND program_id=root_id)))
          OR (root_entity='workout_sessions' AND other_op->'payload'->>'session_id'=root_id)
          OR (root_entity='custom_programs' AND
            (other_op->'payload'->>'program_key'='custom:' || root_id
              OR (other_op->>'entity'='account_preferences'
                AND other_op->'payload'->>'value'='custom:' || root_id))) THEN
          blocked := blocked || jsonb_build_object(
            (other_op->>'entity') || ':' || (other_op->>'record_id'),group_identity);
        END IF;
      END LOOP;
    END IF;
  END LOOP;

  FOR op IN SELECT value FROM jsonb_array_elements(p_operations) LOOP
    e := op->>'entity'; k := op->>'record_id';
    p := nullif(op->'payload','null'::jsonb);
    SELECT * INTO current_row FROM public.account_records
      WHERE owner_id=uid AND entity=e AND record_id=k FOR UPDATE;
    rev := CASE WHEN FOUND THEN current_row.revision ELSE 0 END;
    IF blocked ? (e || ':' || k) THEN
      group_identity := blocked->(e || ':' || k);
      answer := answer || jsonb_build_array(jsonb_build_object(
        'entity',e,'record_id',k,'revision',rev,'payload',current_row.payload,'conflict',true,
        'group_entity',group_identity->>'entity','group_record_id',group_identity->>'record_id'));
      CONTINUE;
    END IF;
    IF rev <> (op->>'expected_revision')::bigint THEN
      answer := answer || jsonb_build_array(jsonb_build_object(
        'entity',e,'record_id',k,'revision',rev,'payload',current_row.payload,
        'conflict',current_row.payload IS DISTINCT FROM p));
      CONTINUE;
    END IF;
    pk := CASE WHEN e IN ('planned_workouts','program_progress') THEN p->>'program_key'
      WHEN e='account_preferences' AND k='active_program_key' THEN p->>'value' ELSE NULL END;
    pk := CASE WHEN pk LIKE 'custom:%' THEN substr(pk,8) ELSE NULL END;
    sid := CASE WHEN e='workout_entries' THEN p->>'session_id' ELSE NULL END;
    IF (pk IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.account_records
      WHERE owner_id=uid AND entity='custom_programs' AND record_id=pk AND payload IS NOT NULL))
      OR (sid IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.account_records
      WHERE owner_id=uid AND entity='workout_sessions' AND record_id=sid AND payload IS NOT NULL))
      OR (e='planned_workouts' AND pk IS NOT NULL AND p->>'day_sync_id' IS NOT NULL AND NOT EXISTS(
        SELECT 1 FROM public.account_records parent,
          LATERAL jsonb_array_elements(parent.payload->'days') day
        WHERE parent.owner_id=uid AND parent.entity='custom_programs' AND parent.record_id=pk
          AND day->>'sync_id'=p->>'day_sync_id')) THEN
      answer := answer || jsonb_build_array(jsonb_build_object(
        'entity',e,'record_id',k,'revision',rev,'payload',current_row.payload,'conflict',true));
      CONTINUE;
    END IF;
    INSERT INTO public.account_records(owner_id,entity,record_id,payload,revision,
        program_entity,program_id,session_entity,session_id)
      VALUES(uid,e,k,p,rev+1,CASE WHEN pk IS NOT NULL THEN 'custom_programs' END,pk,
        CASE WHEN sid IS NOT NULL THEN 'workout_sessions' END,sid)
      ON CONFLICT(owner_id,entity,record_id) DO UPDATE SET
        payload=EXCLUDED.payload,revision=EXCLUDED.revision,
        change_cursor=nextval('public.account_change_cursor'),
        program_entity=EXCLUDED.program_entity,program_id=EXCLUDED.program_id,
        session_entity=EXCLUDED.session_entity,session_id=EXCLUDED.session_id;
    IF e='user_profile' THEN
      UPDATE public.private_profiles SET name=coalesce(p->>'name',''),
        age=(p->>'age')::int,weight_kg=(p->>'weight_kg')::float8,
        height_cm=(p->>'height_cm')::float8,gender=p->>'gender',updated_at=now()
        WHERE id=uid;
    END IF;
    -- Dependants are explicit operations, never unrevisioned cascade updates.
    answer := answer || jsonb_build_array(jsonb_build_object(
      'entity',e,'record_id',k,'revision',rev+1,'payload',p,'conflict',false));
  END LOOP;
  IF EXISTS(
    SELECT 1 FROM public.account_records child
    LEFT JOIN public.account_records program ON program.owner_id=child.owner_id
      AND program.entity=child.program_entity AND program.record_id=child.program_id
    LEFT JOIN public.account_records session ON session.owner_id=child.owner_id
      AND session.entity=child.session_entity AND session.record_id=child.session_id
    WHERE child.owner_id=uid AND child.payload IS NOT NULL AND
      ((child.program_id IS NOT NULL AND program.payload IS NULL)
        OR (child.session_id IS NOT NULL AND session.payload IS NULL)
        OR (child.entity='planned_workouts' AND child.program_id IS NOT NULL
          AND child.payload->>'day_sync_id' IS NOT NULL AND NOT EXISTS(
            SELECT 1 FROM jsonb_array_elements(program.payload->'days') d
            WHERE d->>'sync_id'=child.payload->>'day_sync_id')))
  ) THEN
    RAISE EXCEPTION 'Related writes must not leave an orphan record' USING ERRCODE='23503';
  END IF;
  INSERT INTO public.account_operations(owner_id,operation_id,request,result)
    VALUES(uid,p_operation_id,p_operations,answer);
  RETURN answer;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_account_changes(p_after bigint DEFAULT 0, p_limit integer DEFAULT 200)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE uid uuid := auth.uid(); changes jsonb; dependencies jsonb; last_cursor bigint; more boolean;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  IF p_after < 0 OR p_limit < 1 OR p_limit > 500 THEN RAISE EXCEPTION 'Invalid page'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(uid::text,0));
  PERFORM public.provision_private_profile(uid);
  SELECT coalesce(jsonb_agg(jsonb_build_object('entity',entity,'record_id',record_id,
      'payload',payload,'revision',revision) ORDER BY change_cursor),'[]'::jsonb),
      coalesce(max(change_cursor),p_after)
    INTO changes,last_cursor FROM (
      SELECT * FROM public.account_records WHERE owner_id=uid AND change_cursor>p_after
      ORDER BY change_cursor LIMIT p_limit) page;
  -- A parent might have been edited after its child. Include referenced
  -- parents ahead of the page so first-device restoration always has IDs.
  SELECT coalesce(jsonb_agg(jsonb_build_object('entity',r.entity,'record_id',r.record_id,
      'payload',r.payload,'revision',r.revision)),'[]'::jsonb)
    INTO dependencies FROM public.account_records r WHERE r.owner_id=uid AND EXISTS (
      SELECT 1 FROM public.account_records child
      WHERE child.owner_id=uid AND child.change_cursor>p_after AND child.change_cursor<=last_cursor
        AND ((r.entity=child.program_entity AND r.record_id=child.program_id)
          OR (r.entity=child.session_entity AND r.record_id=child.session_id)));
  SELECT EXISTS(SELECT 1 FROM public.account_records WHERE owner_id=uid AND change_cursor>last_cursor) INTO more;
  RETURN jsonb_build_object('changes',dependencies || changes,'cursor',last_cursor,'has_more',more);
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  IF EXISTS(SELECT 1 FROM auth.identities WHERE user_id=uid AND provider='apple') THEN
    RAISE EXCEPTION 'Apple accounts must use the delete-account endpoint to revoke Apple authorization'
      USING ERRCODE='42501';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(uid::text,0));
  DELETE FROM auth.users WHERE id=uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'Account not found'; END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.apply_account_changes(uuid,jsonb),
  public.get_account_changes(bigint,integer), public.delete_user_account()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.apply_account_changes(uuid,jsonb),
  public.get_account_changes(bigint,integer), public.delete_user_account() TO authenticated;
COMMIT;


-- ==========================================================================
-- 3/4  Ekip içeriği (aktivite kaydı, program önerileri, liderlik tabloları)
-- kaynak: supabase/migrations/202609071000_team_content_features.sql
-- ==========================================================================

-- Team Content Features Migration
-- Adds Activity Feed, Program Suggestions, and Leaderboard functionality

-- ============================================================================
-- 1. TEAM ACTIVITY LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.team_activity_log (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  workouts_count INTEGER NOT NULL DEFAULT 0,
  total_calories REAL DEFAULT 0,
  total_weight_lifted DECIMAL(10, 2) DEFAULT 0,
  total_duration_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, user_id, activity_date)
);

CREATE INDEX idx_team_activity_log_team_date ON public.team_activity_log(team_id, activity_date);
CREATE INDEX idx_team_activity_log_user_date ON public.team_activity_log(user_id, activity_date);

-- ============================================================================
-- 2. PROGRAM SUGGESTIONS TABLE
-- ============================================================================

CREATE TYPE suggestion_type AS ENUM ('exercise', 'program_change', 'feedback');
CREATE TYPE suggestion_status AS ENUM ('pending', 'accepted', 'rejected');

CREATE TABLE IF NOT EXISTS public.program_suggestions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  suggestion_type suggestion_type NOT NULL,
  related_exercise_id UUID,
  related_program_id UUID,
  message TEXT,
  response_message TEXT,
  status suggestion_status DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_program_suggestions_to_user ON public.program_suggestions(to_user_id, status);
CREATE INDEX idx_program_suggestions_team ON public.program_suggestions(team_id, created_at DESC);
CREATE INDEX idx_program_suggestions_from_user ON public.program_suggestions(from_user_id);

-- ============================================================================
-- 3. TEAM LEADERBOARD TABLES (Periodic Aggregation)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.team_leaderboard_weekly (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  workout_count INTEGER DEFAULT 0,
  total_weight_lifted DECIMAL(10, 2) DEFAULT 0,
  total_calories REAL DEFAULT 0,
  rank INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, user_id, week_start_date)
);

CREATE TABLE IF NOT EXISTS public.team_leaderboard_monthly (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month_start_date DATE NOT NULL,
  workout_count INTEGER DEFAULT 0,
  total_weight_lifted DECIMAL(10, 2) DEFAULT 0,
  total_calories REAL DEFAULT 0,
  rank INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, user_id, month_start_date)
);

CREATE INDEX idx_team_leaderboard_weekly_team ON public.team_leaderboard_weekly(team_id, week_start_date);
CREATE INDEX idx_team_leaderboard_monthly_team ON public.team_leaderboard_monthly(team_id, month_start_date);

-- ============================================================================
-- 4. ENABLE RLS
-- ============================================================================

ALTER TABLE public.team_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaderboard_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaderboard_monthly ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. RLS POLICIES - TEAM ACTIVITY LOG
-- ============================================================================

-- Users can see activity logs only for teams they belong to
CREATE POLICY "Users can view team activity for their teams" ON public.team_activity_log
  FOR SELECT USING (
    team_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Activity logs are managed by system (triggers), not direct inserts
CREATE POLICY "Only system can insert activity logs" ON public.team_activity_log
  FOR INSERT WITH CHECK (FALSE);

-- ============================================================================
-- 6. RLS POLICIES - PROGRAM SUGGESTIONS
-- ============================================================================

-- Users can see suggestions they received
CREATE POLICY "Users can view received suggestions" ON public.program_suggestions
  FOR SELECT USING (to_user_id = auth.uid());

-- Users can see suggestions they sent
CREATE POLICY "Users can view sent suggestions" ON public.program_suggestions
  FOR SELECT USING (from_user_id = auth.uid());

-- Users can create suggestions for team members
CREATE POLICY "Users can send suggestions to team members" ON public.program_suggestions
  FOR INSERT WITH CHECK (
    from_user_id = auth.uid()
    AND to_user_id IN (
      SELECT user_id FROM public.group_members 
      WHERE group_id = team_id 
      AND user_id != auth.uid()
    )
  );

-- Users can update their received suggestions (accept/reject with response)
CREATE POLICY "Users can update received suggestions" ON public.program_suggestions
  FOR UPDATE USING (to_user_id = auth.uid());

-- ============================================================================
-- 7. RLS POLICIES - LEADERBOARDS
-- ============================================================================

-- Users can view leaderboards only for teams they belong to
CREATE POLICY "Users can view team leaderboards" ON public.team_leaderboard_weekly
  FOR SELECT USING (
    team_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can view team leaderboards monthly" ON public.team_leaderboard_monthly
  FOR SELECT USING (
    team_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Leaderboards are managed by system (triggers/cron), not direct inserts
CREATE POLICY "Only system can insert leaderboard entries" ON public.team_leaderboard_weekly
  FOR INSERT WITH CHECK (FALSE);

CREATE POLICY "Only system can insert leaderboard entries monthly" ON public.team_leaderboard_monthly
  FOR INSERT WITH CHECK (FALSE);

-- ============================================================================
-- 8. TRIGGER FUNCTION: Auto-update activity log from workout_sessions
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_team_activity_log()
RETURNS TRIGGER AS $$
DECLARE
  v_team_id UUID;
  v_date DATE;
BEGIN
  -- Get all teams the user belongs to
  FOR v_team_id IN SELECT group_id FROM public.group_members WHERE user_id = NEW.user_id
  LOOP
    v_date := NEW.date::DATE;
    
    -- Insert or update activity log for each team
    INSERT INTO public.team_activity_log (
      team_id, user_id, activity_date, workouts_count, 
      total_calories, total_duration_minutes, updated_at
    )
    VALUES (
      v_team_id, 
      NEW.user_id, 
      v_date,
      1,
      COALESCE(NEW.calories, 0),
      COALESCE(NEW.duration_minutes, 0),
      NOW()
    )
    ON CONFLICT (team_id, user_id, activity_date) DO UPDATE SET
      workouts_count = team_activity_log.workouts_count + 1,
      total_calories = team_activity_log.total_calories + COALESCE(NEW.calories, 0),
      total_duration_minutes = team_activity_log.total_duration_minutes + COALESCE(NEW.duration_minutes, 0),
      updated_at = NOW();
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Trigger on workout_sessions insert
CREATE TRIGGER trigger_update_team_activity_log
  AFTER INSERT ON public.workout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_team_activity_log();

-- ============================================================================
-- 9. FUNCTION: Refresh leaderboards (called by cron job)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.refresh_team_leaderboards_weekly()
RETURNS void AS $$
DECLARE
  v_week_start_date DATE;
BEGIN
  v_week_start_date := DATE_TRUNC('week', NOW())::DATE;
  
  -- Insert or update weekly leaderboard
  INSERT INTO public.team_leaderboard_weekly (
    team_id, user_id, week_start_date, workout_count, 
    total_calories, rank
  )
  SELECT 
    tal.team_id,
    tal.user_id,
    v_week_start_date,
    SUM(COALESCE(tal.workouts_count, 0)),
    SUM(COALESCE(tal.total_calories, 0)),
    ROW_NUMBER() OVER (PARTITION BY tal.team_id ORDER BY SUM(COALESCE(tal.workouts_count, 0)) DESC, SUM(COALESCE(tal.total_calories, 0)) DESC)
  FROM public.team_activity_log tal
  WHERE tal.activity_date >= v_week_start_date
    AND tal.activity_date < v_week_start_date + INTERVAL '7 days'
  GROUP BY tal.team_id, tal.user_id
  ON CONFLICT (team_id, user_id, week_start_date) DO UPDATE SET
    workout_count = EXCLUDED.workout_count,
    total_calories = EXCLUDED.total_calories,
    rank = EXCLUDED.rank,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.refresh_team_leaderboards_monthly()
RETURNS void AS $$
DECLARE
  v_month_start_date DATE;
BEGIN
  v_month_start_date := DATE_TRUNC('month', NOW())::DATE;
  
  -- Insert or update monthly leaderboard
  INSERT INTO public.team_leaderboard_monthly (
    team_id, user_id, month_start_date, workout_count, 
    total_calories, rank
  )
  SELECT 
    tal.team_id,
    tal.user_id,
    v_month_start_date,
    SUM(COALESCE(tal.workouts_count, 0)),
    SUM(COALESCE(tal.total_calories, 0)),
    ROW_NUMBER() OVER (PARTITION BY tal.team_id ORDER BY SUM(COALESCE(tal.workouts_count, 0)) DESC, SUM(COALESCE(tal.total_calories, 0)) DESC)
  FROM public.team_activity_log tal
  WHERE tal.activity_date >= v_month_start_date
    AND tal.activity_date < v_month_start_date + INTERVAL '1 month'
  GROUP BY tal.team_id, tal.user_id
  ON CONFLICT (team_id, user_id, month_start_date) DO UPDATE SET
    workout_count = EXCLUDED.workout_count,
    total_calories = EXCLUDED.total_calories,
    rank = EXCLUDED.rank,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Note: To enable automatic refresh, run in Supabase dashboard:
-- SELECT cron.schedule('refresh_team_leaderboards_weekly', '0 1 * * 1', 'SELECT public.refresh_team_leaderboards_weekly()');
-- SELECT cron.schedule('refresh_team_leaderboards_monthly', '0 1 1 * *', 'SELECT public.refresh_team_leaderboards_monthly()');


-- ==========================================================================
-- 4/4  Ekip şema ve RLS düzeltmeleri (sütunlar, politikalar, davet fonksiyonu)
-- kaynak: supabase/migrations/202609160001_team_rls_and_schema_fixes.sql
-- ==========================================================================

-- ============================================================================
-- Team (group) layer fixes
-- ----------------------------------------------------------------------------
-- The Flutter client's TeamProvider reads and writes columns and performs
-- operations that the original social bootstrap (supabase_schema.sql) never
-- granted. Without this migration every team feature fails at runtime:
--
--   1. `groups` had no `description` / `owner_id` columns, but createTeam()
--      inserts both and Team.fromJson() reads both.
--   2. The `group_members` SELECT policy selected from `group_members`, so
--      evaluating it re-entered itself -> infinite recursion (42P17).
--   3. There were no INSERT/UPDATE/DELETE policies at all on `groups` or
--      `group_members`, so creating a team, joining, leaving, removing a
--      member and deleting a team were all rejected.
--   4. Joining by invite token needed to SELECT a group the user is not yet a
--      member of, which the SELECT policy forbids. Loosening that policy would
--      let anyone enumerate every group, so the join goes through a
--      SECURITY DEFINER RPC that validates the token instead.
--   5. `user_blocks` / `user_reports` had RLS enabled but no policies, so
--      blocking and reporting always failed.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Missing columns
-- ----------------------------------------------------------------------------

ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Existing groups predate owner_id; adopt the earliest admin as the owner.
UPDATE public.groups g
SET owner_id = m.user_id
FROM (
  SELECT DISTINCT ON (group_id) group_id, user_id
  FROM public.group_members
  WHERE role = 'admin'
  ORDER BY group_id, joined_at
) m
WHERE g.owner_id IS NULL
  AND m.group_id = g.id;

CREATE INDEX IF NOT EXISTS group_members_user_id_idx
  ON public.group_members (user_id);

-- ----------------------------------------------------------------------------
-- 2. Membership helpers
--
-- SECURITY DEFINER on purpose: a policy on `group_members` that queries
-- `group_members` directly would re-evaluate that same policy and recurse.
-- Running the lookup as the definer skips policy evaluation and terminates.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_team_member(p_group_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id = auth.uid()
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.is_team_admin(p_group_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id = auth.uid()
      AND role = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.is_group_owner(p_group_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id = p_group_id
      AND owner_id = auth.uid()
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '';

REVOKE ALL ON FUNCTION public.is_team_member(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_team_admin(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_group_owner(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_team_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_team_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_owner(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. `groups` policies
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view groups they belong to" ON public.groups;

-- The owner is included so that the INSERT ... RETURNING of createTeam() can
-- read back the row it just wrote, before the first membership row exists.
CREATE POLICY "Users can view groups they belong to" ON public.groups
  FOR SELECT TO authenticated
  USING (public.is_team_member(id) OR owner_id = auth.uid());

CREATE POLICY "Users can create groups" ON public.groups
  FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Admins can update their group" ON public.groups
  FOR UPDATE TO authenticated
  USING (public.is_team_admin(id) OR owner_id = auth.uid())
  WITH CHECK (public.is_team_admin(id) OR owner_id = auth.uid());

CREATE POLICY "Owners can delete their group" ON public.groups
  FOR DELETE TO authenticated
  USING (owner_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 4. `group_members` policies
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view members of their groups" ON public.group_members;

CREATE POLICY "Users can view members of their groups" ON public.group_members
  FOR SELECT TO authenticated
  USING (public.is_team_member(group_id));

-- Direct self-insert is limited to the group's own creator. Everyone else
-- joins through join_team_by_invite_token(), which proves they hold a valid
-- token; otherwise knowing a group's UUID would be enough to walk in.
CREATE POLICY "Owners can add themselves to their group" ON public.group_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND public.is_group_owner(group_id));

CREATE POLICY "Members can leave and admins can remove" ON public.group_members
  FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR public.is_team_admin(group_id));

CREATE POLICY "Admins can change member roles" ON public.group_members
  FOR UPDATE TO authenticated
  USING (public.is_team_admin(group_id))
  WITH CHECK (public.is_team_admin(group_id));

-- ----------------------------------------------------------------------------
-- 5. Join by invite token
--
-- Returns the joined group. Raises:
--   P0002 - no group carries that token
--   P0001 - the caller is already a member
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.join_team_by_invite_token(p_token TEXT)
RETURNS public.groups AS $$
DECLARE
  v_group public.groups;
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_group
  FROM public.groups
  WHERE invite_token = upper(btrim(p_token));

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid invite code' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = v_group.id
      AND user_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Already a member of this team' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.group_members (group_id, user_id, role, joined_at)
  VALUES (v_group.id, v_uid, 'member', NOW());

  RETURN v_group;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '';

REVOKE ALL ON FUNCTION public.join_team_by_invite_token(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_team_by_invite_token(TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. Blocks and reports
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users manage their own blocks" ON public.user_blocks;
CREATE POLICY "Users manage their own blocks" ON public.user_blocks
  FOR ALL TO authenticated
  USING (blocker_id = auth.uid())
  WITH CHECK (blocker_id = auth.uid());

DROP POLICY IF EXISTS "Users can file reports" ON public.user_reports;
CREATE POLICY "Users can file reports" ON public.user_reports
  FOR INSERT TO authenticated
  WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS "Users can read their own reports" ON public.user_reports;
CREATE POLICY "Users can read their own reports" ON public.user_reports
  FOR SELECT TO authenticated
  USING (reporter_id = auth.uid());

COMMIT;


-- ============================================================================
-- Kurulum tamam.
--
-- Sırada:
--   1. Project Settings -> API'den Project URL ve anon/public key'i .env'e yaz.
--   2. Authentication -> Providers altında Google (ve Apple) sağlayıcılarını aç.
--   3. Edge Function: supabase functions deploy delete-account
-- ============================================================================
