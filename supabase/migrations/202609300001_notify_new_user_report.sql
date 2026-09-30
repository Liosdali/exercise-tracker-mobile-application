-- ============================================================================
-- Email the moderator about every new user report
-- ============================================================================
-- App Store guideline 1.2 (and the app's own terms) promise that reports are
-- reviewed within 24 hours, but rows in public.user_reports were visible only
-- to someone who happened to open the table. This posts each new report to
-- the `report-notify` Edge Function, which emails it through Resend.
--
-- The function URL and shared secret come from Vault, so neither is committed.
-- One-time setup in the SQL editor (see docs/STORE_RELEASE.md):
--
--   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
--   select vault.create_secret('<random secret>', 'report_webhook_secret');
--
-- Filing a report must never fail because the notification could not be
-- sent: pg_net queues the request asynchronously, and any setup problem
-- (missing secret, missing extension) is downgraded to a WARNING.
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.notify_new_user_report()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  base_url text;
  hook_secret text;
BEGIN
  SELECT decrypted_secret INTO base_url
    FROM vault.decrypted_secrets WHERE name = 'project_url';
  SELECT decrypted_secret INTO hook_secret
    FROM vault.decrypted_secrets WHERE name = 'report_webhook_secret';

  IF base_url IS NULL OR hook_secret IS NULL THEN
    RAISE WARNING 'notify_new_user_report: Vault secrets project_url / report_webhook_secret are not set; report % was not emailed', NEW.id;
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := rtrim(base_url, '/') || '/functions/v1/report-notify',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', hook_secret
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(NEW)
    ),
    timeout_milliseconds := 10000
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_new_user_report: could not queue email for report %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

-- Only the trigger calls this; it must not be reachable through the API.
REVOKE ALL ON FUNCTION public.notify_new_user_report() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS notify_new_user_report ON public.user_reports;
CREATE TRIGGER notify_new_user_report
  AFTER INSERT ON public.user_reports
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_user_report();

COMMIT;
