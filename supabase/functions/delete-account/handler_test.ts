import { handleRequest } from "./handler.ts";
import { exportJWK, exportPKCS8, generateKeyPair, SignJWT } from "npm:jose@6.1.0";

function expectEqual(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

async function withAuthMock(
  apple: boolean,
  deletionStatus: number,
  run: (deletedIds: string[]) => Promise<void>,
  appleFetch?: typeof fetch,
): Promise<void> {
  const previousFetch = globalThis.fetch;
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const deletedIds: string[] = [];
  Deno.env.set("SUPABASE_URL", "https://example.invalid");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-only-key");
  globalThis.fetch = (input, init) => {
    const address = String(input);
    if (address === "https://example.invalid/auth/v1/user") {
      return Promise.resolve(Response.json({
        id: "authenticated-user",
        identities: apple ? [{ provider: "apple", identity_data: { sub: "apple-user" } }] : [],
      }));
    }
    if (address.startsWith("https://example.invalid/auth/v1/admin/users/")) {
      expectEqual(init?.method, "DELETE");
      deletedIds.push(address.substring(address.lastIndexOf("/") + 1));
      return Promise.resolve(Response.json({}, { status: deletionStatus }));
    }
    if (appleFetch) return appleFetch(input, init);
    throw new Error("Unexpected network request");
  };
  try {
    await run(deletedIds);
  } finally {
    globalThis.fetch = previousFetch;
    if (url === undefined) Deno.env.delete("SUPABASE_URL");
    else Deno.env.set("SUPABASE_URL", url);
    if (key === undefined) Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
    else Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", key);
  }
}

function request(body = "{}", authenticated = true): Request {
  return new Request("https://example.invalid/functions/v1/delete-account", {
    method: "POST",
    headers: authenticated ? { Authorization: "Bearer test-user-token" } : {},
    body,
  });
}

Deno.test("deletion rejects missing authentication before accessing configuration", async () => {
  const result = await handleRequest(request("{}", false));
  expectEqual(result.status, 401);
  expectEqual(await result.json(), { error: "authentication_required" });
});

Deno.test("deletion accepts only POST", async () => {
  const result = await handleRequest(new Request("https://example.invalid"));
  expectEqual(result.status, 405);
});

Deno.test("deletion targets the authenticated user, never a supplied user ID", async () => {
  await withAuthMock(false, 200, async (deletedIds) => {
    const result = await handleRequest(request('{"userId":"someone-else"}'));
    expectEqual(result.status, 200);
    expectEqual(await result.json(), { deleted: true });
    expectEqual(deletedIds, ["authenticated-user"]);
  });
});

Deno.test("Apple users cannot bypass provider revocation", async () => {
  await withAuthMock(true, 200, async (deletedIds) => {
    const result = await handleRequest(request());
    expectEqual(result.status, 400);
    expectEqual(await result.json(), { error: "apple_reauthentication_required" });
    expectEqual(deletedIds, []);
  });
});

Deno.test("failed remote deletion is never reported as success", async () => {
  await withAuthMock(false, 500, async () => {
    const result = await handleRequest(request());
    expectEqual(result.status, 502);
    expectEqual(await result.json(), { error: "account_deletion_failed" });
  });
});

Deno.test("invalid JSON does not trigger account deletion", async () => {
  await withAuthMock(false, 200, async (deletedIds) => {
    const result = await handleRequest(request("{"));
    expectEqual(result.status, 400);
    expectEqual(deletedIds, []);
  });
});

Deno.test("Apple exchange verifies identity and revokes before deleting", async () => {
  const clientKeys = await generateKeyPair("ES256", { extractable: true });
  const appleKeys = await generateKeyPair("RS256");
  const jwk = await exportJWK(appleKeys.publicKey);
  const values: Record<string, string> = {
    APPLE_NATIVE_CLIENT_ID: "test.native",
    APPLE_WEB_CLIENT_ID: "test.web",
    APPLE_TEAM_ID: "test-team",
    APPLE_KEY_ID: "test-key",
    APPLE_PRIVATE_KEY: await exportPKCS8(clientKeys.privateKey),
  };
  const previous = Object.keys(values).map((key) => [key, Deno.env.get(key)] as const);
  for (const [key, value] of Object.entries(values)) Deno.env.set(key, value);
  let subject = "apple-user";
  let revoked = false;
  let audience = "test.native";
  const appleFetch: typeof fetch = async (input, init) => {
    const url = String(input);
    if (url.endsWith("/auth/keys")) {
      return Response.json({ keys: [{ ...jwk, kid: "test-apple-key", alg: "RS256" }] });
    }
    if (url.endsWith("/auth/token")) {
      const params = new URLSearchParams(String(init?.body));
      expectEqual(params.get("client_id"), audience);
      const token = await new SignJWT({})
        .setProtectedHeader({ alg: "RS256", kid: "test-apple-key" })
        .setIssuer("https://appleid.apple.com")
        .setAudience(audience)
        .setSubject(subject)
        .setIssuedAt()
        .setExpirationTime("5m")
        .sign(appleKeys.privateKey);
      return Response.json({ id_token: token, refresh_token: "test-refresh" });
    }
    if (url.endsWith("/auth/revoke")) {
      revoked = true;
      expectEqual(new URLSearchParams(String(init?.body)).get("token"), "test-refresh");
      return new Response(null, { status: 200 });
    }
    throw new Error("Unexpected network request");
  };
  try {
    await withAuthMock(true, 200, async (deletedIds) => {
      const result = await handleRequest(request(JSON.stringify({
        appleClient: "native",
        appleAuthorizationCode: "test-code",
      })));
      expectEqual(result.status, 200);
      expectEqual(revoked, true);
      expectEqual(deletedIds, ["authenticated-user"]);
    }, appleFetch);
    revoked = false;
    subject = "different-apple-user";
    await withAuthMock(true, 200, async (deletedIds) => {
      const result = await handleRequest(request(JSON.stringify({
        appleClient: "native",
        appleAuthorizationCode: "test-code",
      })));
      expectEqual(result.status, 403);
      expectEqual(revoked, false);
      expectEqual(deletedIds, []);
    }, appleFetch);
    subject = "apple-user";
    audience = "test.web";
    await withAuthMock(true, 200, async (deletedIds) => {
      const result = await handleRequest(request(JSON.stringify({
        appleClient: "web",
        appleRefreshToken: "test-refresh",
      })));
      expectEqual(result.status, 200);
      expectEqual(revoked, true);
      expectEqual(deletedIds, ["authenticated-user"]);
    }, appleFetch);
  } finally {
    for (const [key, value] of previous) {
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
  }
});
