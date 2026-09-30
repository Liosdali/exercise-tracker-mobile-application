import { composeEmail, handleRequest } from "./handler.ts";

function expectEqual(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function expect(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

const ENV = {
  SUPABASE_URL: "https://abcref.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
  REPORT_WEBHOOK_SECRET: "hook-secret",
  RESEND_API_KEY: "re_test",
  REPORT_EMAIL_TO: "moderator@example.invalid",
};

const REPORT = {
  type: "INSERT",
  table: "user_reports",
  record: {
    id: "report-1",
    reporter_id: "user-a",
    reported_id: "user-b",
    reason: "Inappropriate content",
    created_at: "2026-09-30T10:00:00+00:00",
  },
};

interface Sent {
  url: string;
  init?: RequestInit;
}

async function withEnv(
  run: (sent: Sent[]) => Promise<void>,
  options: { resendStatus?: number; namesFail?: boolean } = {},
): Promise<void> {
  const previousFetch = globalThis.fetch;
  const previous = Object.fromEntries(
    Object.keys(ENV).map((k) => [k, Deno.env.get(k)]),
  );
  for (const [k, v] of Object.entries(ENV)) Deno.env.set(k, v);
  const sent: Sent[] = [];
  globalThis.fetch = (input, init) => {
    const url = String(input);
    sent.push({ url, init });
    if (url.startsWith("https://abcref.supabase.co/rest/v1/social_users")) {
      if (options.namesFail) return Promise.reject(new Error("offline"));
      return Promise.resolve(Response.json([
        { id: "user-a", display_name: "Ayşe" },
        { id: "user-b", display_name: "Bora" },
      ]));
    }
    if (url === "https://api.resend.com/emails") {
      return Promise.resolve(
        Response.json({ id: "email-1" }, { status: options.resendStatus ?? 200 }),
      );
    }
    throw new Error(`Unexpected network request: ${url}`);
  };
  try {
    await run(sent);
  } finally {
    globalThis.fetch = previousFetch;
    for (const [k, v] of Object.entries(previous)) {
      if (v === undefined) Deno.env.delete(k);
      else Deno.env.set(k, v);
    }
  }
}

function request(body: unknown, secret: string | null = "hook-secret"): Request {
  return new Request("https://example.invalid/functions/v1/report-notify", {
    method: "POST",
    headers: secret === null ? {} : { "x-webhook-secret": secret },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

function resendPayload(sent: Sent[]): Record<string, unknown> {
  const call = sent.find((s) => s.url === "https://api.resend.com/emails");
  if (!call) throw new Error("No email was sent");
  return JSON.parse(String(call.init?.body));
}

Deno.test("accepts only POST", async () => {
  const result = await handleRequest(new Request("https://example.invalid"));
  expectEqual(result.status, 405);
});

Deno.test("rejects a missing or wrong secret without sending anything", async () => {
  await withEnv(async (sent) => {
    expectEqual((await handleRequest(request(REPORT, null))).status, 401);
    expectEqual((await handleRequest(request(REPORT, "hook-secreT"))).status, 401);
    expectEqual((await handleRequest(request(REPORT, "hook-secret-longer"))).status, 401);
    expectEqual(sent.length, 0);
  });
});

Deno.test("rejects a body that is not a report", async () => {
  await withEnv(async (sent) => {
    expectEqual((await handleRequest(request("not json"))).status, 400);
    expectEqual((await handleRequest(request({ record: {} }))).status, 400);
    expectEqual(sent.length, 0);
  });
});

Deno.test("emails the report with names to the moderator", async () => {
  await withEnv(async (sent) => {
    const result = await handleRequest(request(REPORT));
    expectEqual(result.status, 200);
    expectEqual(await result.json(), { notified: true });

    const email = resendPayload(sent);
    expectEqual(email.to, ["moderator@example.invalid"]);
    expectEqual(email.from, "Atlas Workout <onboarding@resend.dev>");
    expectEqual(email.subject, "[Atlas Workout] Yeni şikayet: Bora");
    const text = String(email.text);
    expect(text.includes("Bora — user-b"), "reported user missing");
    expect(text.includes("Ayşe — user-a"), "reporter missing");
    expect(text.includes("2026-10-01T10:00:00.000Z"), "24h deadline missing");
    expect(
      text.includes("https://supabase.com/dashboard/project/abcref/auth/users"),
      "dashboard link missing",
    );
  });
});

Deno.test("still emails when the name lookup fails", async () => {
  await withEnv(async (sent) => {
    const result = await handleRequest(request(REPORT));
    expectEqual(result.status, 200);
    const text = String(resendPayload(sent).text);
    expect(text.includes("(adsız) — user-b"), "fallback name missing");
  }, { namesFail: true });
});

Deno.test("reports a Resend failure instead of claiming success", async () => {
  await withEnv(async () => {
    const result = await handleRequest(request(REPORT));
    expectEqual(result.status, 502);
    expectEqual(await result.json(), { error: "email_failed" });
  }, { resendStatus: 403 });
});

Deno.test("an unconfigured function says so", async () => {
  await withEnv(async () => {
    Deno.env.delete("RESEND_API_KEY");
    const result = await handleRequest(request(REPORT));
    expectEqual(result.status, 503);
  });
});

Deno.test("a reporter whose account was deleted is labelled, not dropped", () => {
  const email = composeEmail(
    { id: "r", reporter_id: null, reported_id: "user-b", reason: "", created_at: null },
    new Map(),
    "https://abcref.supabase.co",
  );
  expect(email.text.includes("(hesap silinmiş)"), "deleted reporter label missing");
  expect(email.text.includes("(belirtilmemiş)"), "empty reason label missing");
});
