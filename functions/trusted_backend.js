const http = require("node:http");
const { readFileSync } = require("node:fs");
const { HttpsError } = require("firebase-functions/v1/https");

const operations = ["quoteOrder", "placeOrder", "mutateOrder", "mutatePlatform"];
const statuses = {
  "invalid-argument": 400, unauthenticated: 401, "permission-denied": 403,
  "not-found": 404, "failed-precondition": 400, aborted: 409,
  "already-exists": 409, "resource-exhausted": 429, unavailable: 503,
  "deadline-exceeded": 504,
};

function createServer({
  handlers, verifyToken, allowedOrigins = [], requestLimit = 120, now = Date.now,
}) {
  const paths = new Map(operations.map((name) => [`/v1/${name}`, handlers[name]]));
  const origins = new Set(allowedOrigins);
  let activeMinute = -1;
  const requestsByUser = new Map();
  return http.createServer({ requestTimeout: 30000 }, async (req, res) => {
    const reply = (status, data) => {
      res.writeHead(status, { "Content-Type": "application/json", "Cache-Control": "no-store" });
      res.end(JSON.stringify(data));
    };
    const handler = paths.get(req.url);
    if (req.url === "/health" && req.method === "GET") {
      return reply(200, { status: "ok" });
    }
    if (!handler) return reply(404, { error: { code: "not-found" } });

    const origin = req.headers.origin;
    if (origin) {
      res.setHeader("Vary", "Origin");
      if (!origins.has(origin)) return reply(403, { error: { code: "permission-denied" } });
      res.setHeader("Access-Control-Allow-Origin", origin);
    }
    if (req.method === "OPTIONS" && origin) {
      res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
      return res.writeHead(204).end();
    }
    if (req.method !== "POST") return reply(405, { error: { code: "invalid-argument" } });

    try {
      const bearer = /^Bearer ([^\s]+)$/.exec(req.headers.authorization ?? "");
      if (!bearer) throw new HttpsError("unauthenticated", "Sign in to continue.");
      let token;
      try {
        token = await verifyToken(bearer[1]);
      } catch {
        throw new HttpsError("unauthenticated", "Sign in again to continue.");
      }
      if (!token?.uid) throw new HttpsError("unauthenticated", "Sign in to continue.");
      const timestamp = now();
      const minute = Math.floor(timestamp / 60000);
      if (minute !== activeMinute) {
        requestsByUser.clear();
        activeMinute = minute;
      }
      const count = requestsByUser.get(token.uid) ?? 0;
      if (count >= requestLimit || (count === 0 && requestsByUser.size >= 10000)) {
        res.setHeader("Retry-After", Math.ceil((60000 - timestamp % 60000) / 1000));
        throw new HttpsError("resource-exhausted", "Too many requests. Wait and try again.");
      }
      requestsByUser.set(token.uid, count + 1);
      if (req.headers["content-type"]?.split(";")[0] !== "application/json") {
        throw new HttpsError("invalid-argument", "Expected JSON.");
      }
      const chunks = [];
      let size = 0;
      for await (const chunk of req) {
        size += chunk.length;
        if (size > 128 * 1024) throw new HttpsError("invalid-argument", "Request is too large.");
        chunks.push(chunk);
      }
      let data;
      try {
        data = JSON.parse(Buffer.concat(chunks).toString()).data;
      } catch {
        throw new HttpsError("invalid-argument", "Invalid JSON request.");
      }
      if (!data || typeof data !== "object" || Array.isArray(data)) {
        throw new HttpsError("invalid-argument", "Expected an operation payload.");
      }
      return reply(200, { result: await handler(data, { auth: { uid: token.uid, token } }) });
    } catch (error) {
      if (error instanceof HttpsError && Object.hasOwn(statuses, error.code)) {
        return reply(statuses[error.code], {
          error: { code: error.code, message: error.message, details: error.details },
        });
      }
      console.error("Trusted backend request failed", req.url, error?.code ?? "internal");
      return reply(500, { error: { code: "internal", message: "The service could not complete this request." } });
    }
  });
}

if (require.main === module) {
  const projectId = process.env.GCLOUD_PROJECT;
  if (!projectId) throw new Error("Set GCLOUD_PROJECT to the intended Firebase project ID.");
  const deployment = process.env.FOODFIGHT_BACKEND_ENV;
  if (deployment === "staging" || deployment === "production") {
    const isProductionProject = projectId === "food-fight-bd72e";
    if (deployment === "staging" && isProductionProject) {
      throw new Error("Staging cannot use the Food Fight production Firebase project.");
    }
    if (deployment === "production" && !isProductionProject) {
      throw new Error("Production must use the food-fight-bd72e Firebase project.");
    }
    let credential;
    try {
      credential = JSON.parse(readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, "utf8"));
    } catch {
      throw new Error("Mount the Firebase service account secret file before starting.");
    }
    if (credential?.type !== "service_account" || credential.project_id !== projectId) {
      throw new Error("The mounted Firebase service account must belong to the configured Firebase project.");
    }
  }
  const emulatorHosts = [process.env.FIREBASE_AUTH_EMULATOR_HOST, process.env.FIRESTORE_EMULATOR_HOST];
  const usingEmulators = emulatorHosts.some(Boolean);
  if (usingEmulators && (!projectId.startsWith("demo-") ||
      !emulatorHosts.every((host) => /^127\.0\.0\.1:\d+$/.test(host ?? "")))) {
    throw new Error("Local mode requires both loopback emulators and a demo project.");
  }
  const firebase = require("firebase-admin");
  const callables = require("./index");
  const handlers = Object.fromEntries(operations.map((name) => [name, callables[name].run]));
  const allowedOrigins = (process.env.FOODFIGHT_WEB_ORIGINS ?? "").split(",").map((value) => value.trim()).filter(Boolean);
  const port = Number(process.env.PORT ?? 8080);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("PORT must be an integer between 1 and 65535.");
  }
  const server = createServer({
    handlers, allowedOrigins,
    verifyToken: (token) => firebase.auth().verifyIdToken(token, true),
  });
  server.listen(port, usingEmulators ? "127.0.0.1" : "0.0.0.0");
  const shutdown = () => {
    const deadline = setTimeout(() => server.closeAllConnections(), 15000);
    deadline.unref();
    server.close(() => clearTimeout(deadline));
  };
  process.once("SIGTERM", shutdown);
  process.once("SIGINT", shutdown);
}

module.exports = { createServer };
