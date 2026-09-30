-- Run as the database owner against a disposable migrated Supabase project.
-- All fixtures and mutations are rolled back.
BEGIN;
INSERT INTO auth.users(id,raw_user_meta_data,aud,role)
VALUES
 ('10000000-0000-4000-a000-000000000001','{"full_name":"Account A"}','authenticated','authenticated'),
 ('10000000-0000-4000-a000-000000000002','{"full_name":"Account B"}','authenticated','authenticated'),
 ('10000000-0000-4000-a000-000000000003','{"full_name":"Apple account"}','authenticated','authenticated');
INSERT INTO auth.identities(id,user_id,provider,provider_id,identity_data)
VALUES('50000000-0000-4000-a000-000000000003','10000000-0000-4000-a000-000000000003',
  'apple','account-sync-test-apple','{"sub":"account-sync-test-apple"}');

DO $$
BEGIN
  PERFORM public.provision_private_profile('10000000-0000-4000-a000-000000000001');
  IF (SELECT count(*) FROM public.private_profiles WHERE id='10000000-0000-4000-a000-000000000001') <> 1 THEN
    RAISE EXCEPTION 'Provisioning is not idempotent';
  END IF;
END;
$$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000003',true);
DO $$
DECLARE denied boolean := false;
BEGIN
  BEGIN
    PERFORM public.delete_user_account();
  EXCEPTION WHEN insufficient_privilege THEN denied := true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Apple revocation was bypassed through direct RPC'; END IF;
END;
$$;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000001',true);
DO $$
DECLARE ops jsonb; first_result jsonb; retry_result jsonb; result jsonb;
BEGIN
  IF EXISTS(SELECT 1 FROM public.private_profiles WHERE id='10000000-0000-4000-a000-000000000002') THEN
    RAISE EXCEPTION 'Owner-only profile policy failed';
  END IF;
  ops := '[{"entity":"workout_sessions","record_id":"20000000-0000-4000-a000-000000000001","expected_revision":0,"version":1,
    "payload":{"date":"2026-09-07","duration_minutes":30,"calories":180,"exercise_count":1,"total_sets":3,"total_volume":1440,"title":"Private","created_at":"2026-09-07T10:00:00Z"}},
    {"entity":"workout_entries","record_id":"30000000-0000-4000-a000-000000000001","expected_revision":0,"version":1,
    "payload":{"date":"2026-09-07","exercise_id":"squat","exercise_name":"Squat","category":"legs","sets":3,"reps":8,"weight":60,
    "created_at":"2026-09-07T10:00:00Z","session_id":"20000000-0000-4000-a000-000000000001"}}]';
  first_result := public.apply_account_changes('40000000-0000-4000-a000-000000000001',ops);
  retry_result := public.apply_account_changes('40000000-0000-4000-a000-000000000001',ops);
  IF first_result IS DISTINCT FROM retry_result OR jsonb_array_length(first_result)<>2 THEN
    RAISE EXCEPTION 'Operation retry is not idempotent';
  END IF;
  ops := jsonb_set(ops,'{0,payload,title}','"Concurrent edit"');
  result := public.apply_account_changes('40000000-0000-4000-a000-000000000002',ops);
  IF (result->0->>'conflict')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Revision conflict was overwritten';
  END IF;
  result := public.get_account_changes(0,1);
  IF jsonb_array_length(result->'changes')<1 OR (result->>'cursor')::bigint<=0 THEN
    RAISE EXCEPTION 'Download checkpoint failed';
  END IF;
  PERFORM public.apply_account_changes('40000000-0000-4000-a000-000000000003',
    '[{"entity":"workout_sessions","record_id":"20000000-0000-4000-a000-000000000001","expected_revision":1,"version":2,"payload":null}]');
  IF EXISTS(SELECT 1 FROM public.account_records WHERE entity IN ('workout_sessions','workout_entries') AND payload IS NOT NULL) THEN
    RAISE EXCEPTION 'Session deletion did not tombstone its entries';
  END IF;
END;
$$;

SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-a000-000000000002',true);
DO $$
DECLARE denied boolean := false; result jsonb;
BEGIN
  IF EXISTS(SELECT 1 FROM public.account_records WHERE owner_id='10000000-0000-4000-a000-000000000001') THEN
    RAISE EXCEPTION 'Private history was visible across accounts';
  END IF;
  BEGIN
    result := public.apply_account_changes('40000000-0000-4000-a000-000000000004',
      '[{"entity":"workout_entries","record_id":"30000000-0000-4000-a000-000000000002","expected_revision":0,"version":1,
       "payload":{"date":"2026-09-07","exercise_id":"squat","exercise_name":"Squat","category":"legs","created_at":"2026-09-07T10:00:00Z",
       "session_id":"20000000-0000-4000-a000-000000000001"}}]');
    denied := (result->0->>'conflict')::boolean;
  EXCEPTION WHEN OTHERS THEN denied := true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Cross-account foreign key accepted'; END IF;
  PERFORM public.delete_user_account();
END;
$$;

RESET ROLE;
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM auth.users WHERE id='10000000-0000-4000-a000-000000000002') OR
     EXISTS(SELECT 1 FROM public.private_profiles WHERE id='10000000-0000-4000-a000-000000000002') THEN
    RAISE EXCEPTION 'Account deletion failed';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM auth.users WHERE id='10000000-0000-4000-a000-000000000001') THEN
    RAISE EXCEPTION 'Account deletion affected another owner';
  END IF;
END;
$$;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub','',true);
DO $$
DECLARE denied boolean := false;
BEGIN
  BEGIN
    PERFORM 1 FROM public.private_profiles;
  EXCEPTION WHEN insufficient_privilege THEN denied := true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Anonymous private profile access allowed'; END IF;
  denied := false;
  BEGIN
    PERFORM public.delete_user_account();
  EXCEPTION WHEN insufficient_privilege THEN denied := true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'Anonymous account deletion allowed'; END IF;
END;
$$;
ROLLBACK;
