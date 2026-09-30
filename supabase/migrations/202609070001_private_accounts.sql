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
