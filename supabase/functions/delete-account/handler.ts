import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from "npm:jose@6.1.0";

const appleKeys = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

class RequestError extends Error {
  constructor(readonly status: number, readonly code: string) {
    super(code);
  }
}

function secret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new RequestError(503, "account_deletion_not_configured");
  return value;
}

function response(status: number, body: Record<string, unknown>): Response {
  return Response.json(body, {
    status,
    headers: { "Cache-Control": "no-store" },
  });
}

async function appleRequest(
  path: "token" | "revoke",
  body: URLSearchParams,
): Promise<Response> {
  const result = await fetch(`https://appleid.apple.com/auth/${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
    signal: AbortSignal.timeout(15000),
  });
  if (!result.ok) {
    throw new RequestError(502, "apple_reauthentication_required");
  }
  return result;
}

async function revokeApple(
  body: Record<string, unknown>,
  subjects: Set<string>,
): Promise<void> {
  const native = body.appleClient === "native";
  if (!native && body.appleClient !== "web") {
    throw new RequestError(400, "apple_reauthentication_required");
  }
  const credential = native
    ? body.appleAuthorizationCode
    : body.appleRefreshToken;
  if (typeof credential !== "string" || !credential || credential.length > 16384) {
    throw new RequestError(400, "apple_reauthentication_required");
  }
  const clientId = secret(native ? "APPLE_NATIVE_CLIENT_ID" : "APPLE_WEB_CLIENT_ID");
  const privateKey = await importPKCS8(
    secret("APPLE_PRIVATE_KEY").replaceAll("\\n", "\n"),
    "ES256",
  );
  const clientSecret = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: secret("APPLE_KEY_ID") })
    .setIssuer(secret("APPLE_TEAM_ID"))
    .setSubject(clientId)
    .setAudience("https://appleid.apple.com")
    .setIssuedAt()
    .setExpirationTime("5m")
    .sign(privateKey);
  const parameters = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    grant_type: native ? "authorization_code" : "refresh_token",
    [native ? "code" : "refresh_token"]: credential,
  });
  const exchange = await appleRequest("token", parameters);
  const tokens = await exchange.json();
  if (typeof tokens.id_token !== "string") {
    throw new RequestError(502, "apple_identity_verification_failed");
  }
  const { payload } = await jwtVerify(tokens.id_token, appleKeys, {
    issuer: "https://appleid.apple.com",
    audience: clientId,
    algorithms: ["RS256"],
  });
  if (!payload.sub || !subjects.has(payload.sub)) {
    throw new RequestError(403, "apple_account_mismatch");
  }
  const refreshToken = typeof tokens.refresh_token === "string"
    ? tokens.refresh_token
    : native ? null : credential;
  if (!refreshToken) {
    throw new RequestError(502, "apple_reauthentication_required");
  }
  await appleRequest(
    "revoke",
    new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      token: refreshToken,
      token_type_hint: "refresh_token",
    }),
  );
}

export async function handleRequest(request: Request): Promise<Response> {
  if (request.method !== "POST") {
    return response(405, { error: "method_not_allowed" });
  }
  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) {
      return response(401, { error: "authentication_required" });
    }
    const projectUrl = secret("SUPABASE_URL");
    const serviceKey = secret("SUPABASE_SERVICE_ROLE_KEY");
    const identityResponse = await fetch(`${projectUrl}/auth/v1/user`, {
      headers: { Authorization: authorization, apikey: serviceKey },
      signal: AbortSignal.timeout(15000),
    });
    if (!identityResponse.ok) {
      return response(identityResponse.status >= 500 ? 503 : 401, {
        error: identityResponse.status >= 500
          ? "authentication_unavailable"
          : "authentication_required",
      });
    }
    const user = await identityResponse.json();
    if (typeof user.id !== "string" || !user.id) {
      throw new RequestError(502, "identity_verification_failed");
    }
    const rawBody = await request.text();
    if (rawBody.length > 20000) {
      return response(413, { error: "request_too_large" });
    }
    let body: unknown;
    try {
      body = JSON.parse(rawBody);
    } catch (error) {
      if (!(error instanceof SyntaxError)) throw error;
      return response(400, { error: "invalid_request" });
    }
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return response(400, { error: "invalid_request" });
    }
    const identities = Array.isArray(user.identities) ? user.identities : [];
    const appleIdentities = identities.filter(
      (identity: { provider?: string }) => identity.provider === "apple",
    );
    if (appleIdentities.length > 0 || user.app_metadata?.providers?.includes("apple")) {
      const subjects = new Set<string>();
      for (const identity of appleIdentities) {
        if (typeof identity.identity_data?.sub === "string") {
          subjects.add(identity.identity_data.sub);
        }
      }
      if (!subjects.size) {
        throw new RequestError(502, "apple_identity_verification_failed");
      }
      await revokeApple(body as Record<string, unknown>, subjects);
    }
    // The authenticated user's ID is authoritative; never accept a target ID
    // from the request body. Auth deletion cascades the private account tables.
    const deletion = await fetch(
      `${projectUrl}/auth/v1/admin/users/${encodeURIComponent(user.id)}`,
      {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${serviceKey}`,
          apikey: serviceKey,
        },
        signal: AbortSignal.timeout(15000),
      },
    );
    if (!deletion.ok) {
      throw new RequestError(502, "account_deletion_failed");
    }
    return response(200, { deleted: true });
  } catch (error) {
    if (error instanceof RequestError) {
      return response(error.status, { error: error.code });
    }
    // Do not expose/log Apple codes, tokens, identity payloads or signing keys.
    return response(500, { error: "account_deletion_failed" });
  }
}
