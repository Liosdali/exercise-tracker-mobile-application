// Emails the moderator when a user files a report.
//
// App Store guideline 1.2 requires acting on reports of objectionable content
// within 24 hours, and the app tells users it does. Reports land in
// public.user_reports where nobody would otherwise see them, so the
// `notify_new_user_report` trigger (migration 202609300001) posts each new
// row here and this sends it on through Resend.
//
// Secrets (supabase secrets set ...):
//   REPORT_WEBHOOK_SECRET  shared with the trigger via Vault
//   RESEND_API_KEY         https://resend.com/api-keys
//   REPORT_EMAIL_TO        where reports go
//   REPORT_EMAIL_FROM      optional; defaults to Resend's test sender, which
//                          can only deliver to the Resend account's own email

const DEFAULT_FROM = "Atlas Workout <onboarding@resend.dev>";

class RequestError extends Error {
  constructor(readonly status: number, readonly code: string) {
    super(code);
  }
}

interface Report {
  id: string;
  reporter_id: string | null;
  reported_id: string | null;
  reason: string;
  created_at: string | null;
}

function secret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new RequestError(503, "report_notify_not_configured");
  return value;
}

function response(status: number, body: Record<string, unknown>): Response {
  return Response.json(body, {
    status,
    headers: { "Cache-Control": "no-store" },
  });
}

/** Compares without leaking, through timing, how much of the secret matched. */
function sameSecret(given: string, expected: string): boolean {
  const a = new TextEncoder().encode(given);
  const b = new TextEncoder().encode(expected);
  let diff = a.length ^ b.length;
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    diff |= (a[i] ?? 0) ^ (b[i] ?? 0);
  }
  return diff === 0;
}

function parseReport(body: unknown): Report {
  const record = (body as { record?: unknown } | null)?.record as
    | Record<string, unknown>
    | undefined;
  if (!record || typeof record.id !== "string") {
    throw new RequestError(400, "invalid_report");
  }
  const optionalString = (value: unknown) =>
    typeof value === "string" ? value : null;
  return {
    id: record.id,
    reporter_id: optionalString(record.reporter_id),
    reported_id: optionalString(record.reported_id),
    reason: optionalString(record.reason) ?? "",
    created_at: optionalString(record.created_at),
  };
}

/**
 * Best effort: a name makes the email actionable at a glance, but a failed
 * lookup must not cost the moderator the report itself.
 */
async function displayNames(ids: string[]): Promise<Map<string, string>> {
  const names = new Map<string, string>();
  if (ids.length === 0) return names;
  try {
    const url = new URL(`${secret("SUPABASE_URL")}/rest/v1/social_users`);
    url.searchParams.set("select", "id,display_name");
    url.searchParams.set("id", `in.(${ids.join(",")})`);
    const key = secret("SUPABASE_SERVICE_ROLE_KEY");
    const result = await fetch(url, {
      headers: { apikey: key, Authorization: `Bearer ${key}` },
      signal: AbortSignal.timeout(10000),
    });
    if (!result.ok) return names;
    for (const row of await result.json() as Array<Record<string, unknown>>) {
      if (typeof row.id === "string" && typeof row.display_name === "string") {
        names.set(row.id, row.display_name);
      }
    }
  } catch (error) {
    console.error("report-notify: name lookup failed", error);
  }
  return names;
}

export function composeEmail(
  report: Report,
  names: Map<string, string>,
  supabaseUrl: string,
): { subject: string; text: string } {
  const label = (id: string | null) =>
    id ? `${names.get(id) ?? "(adsız)"} — ${id}` : "(hesap silinmiş)";
  const filed = report.created_at ? new Date(report.created_at) : new Date();
  const deadline = new Date(filed.getTime() + 24 * 60 * 60 * 1000);
  const projectRef = new URL(supabaseUrl).hostname.split(".")[0];
  const dashboard = `https://supabase.com/dashboard/project/${projectRef}`;
  const reported = report.reported_id ? names.get(report.reported_id) : null;

  return {
    subject: `[Atlas Workout] Yeni şikayet: ${reported ?? "kullanıcı"}`,
    text: [
      "Yeni bir kullanıcı şikayeti var. Apple 1.2 gereği 24 saat içinde ele alınmalı.",
      "",
      `Şikayet edilen : ${label(report.reported_id)}`,
      `Şikayet eden   : ${label(report.reporter_id)}`,
      `Sebep          : ${report.reason || "(belirtilmemiş)"}`,
      `Zaman (UTC)    : ${filed.toISOString()}`,
      `Son tarih (UTC): ${deadline.toISOString()}`,
      `Şikayet ID     : ${report.id}`,
      "",
      "Ne yapmalı:",
      "1. Kullanıcının ekip içeriğini incele (ekip adları, akış kayıtları, öneriler):",
      `   ${dashboard}/editor`,
      "2. İhlal varsa içeriği sil ve gerekirse hesabı yasakla veya sil:",
      `   ${dashboard}/auth/users`,
      "3. İhlal yoksa bir şey yapman gerekmez; şikayet kaydı tabloda kalır.",
    ].join("\n"),
  };
}

export async function handleRequest(request: Request): Promise<Response> {
  if (request.method !== "POST") {
    return response(405, { error: "method_not_allowed" });
  }
  try {
    const given = request.headers.get("x-webhook-secret") ?? "";
    if (!given || !sameSecret(given, secret("REPORT_WEBHOOK_SECRET"))) {
      throw new RequestError(401, "unauthorized");
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      throw new RequestError(400, "invalid_report");
    }
    const report = parseReport(body);

    const ids = [report.reported_id, report.reporter_id].filter(
      (id): id is string => id !== null,
    );
    const email = composeEmail(
      report,
      await displayNames(ids),
      secret("SUPABASE_URL"),
    );

    const sent = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${secret("RESEND_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: Deno.env.get("REPORT_EMAIL_FROM") || DEFAULT_FROM,
        to: [secret("REPORT_EMAIL_TO")],
        subject: email.subject,
        text: email.text,
      }),
      signal: AbortSignal.timeout(15000),
    });
    if (!sent.ok) {
      console.error("report-notify: Resend rejected", sent.status, await sent.text());
      throw new RequestError(502, "email_failed");
    }
    return response(200, { notified: true });
  } catch (error) {
    if (error instanceof RequestError) {
      return response(error.status, { error: error.code });
    }
    console.error("report-notify: unexpected failure", error);
    return response(500, { error: "unexpected_failure" });
  }
}
