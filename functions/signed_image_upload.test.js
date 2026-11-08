const assert = require("node:assert/strict");
const test = require("node:test");
const { signedImageUpload } = require("./signed_image_upload");

function setup(profile) {
  const documents = new Map([["users/u1", profile]]);
  const calls = [];
  const db = {
    collection: (collection) => ({ doc: (id) => collection + "/" + id }),
    runTransaction: (body) => body({
      get: async (path) => ({ data: () => documents.get(path) }),
      set: (path, data) => documents.set(path, data),
    }),
  };
  const sign = signedImageUpload({
    db,
    fail: (code, message) => { throw Object.assign(new Error(message), { code }); },
    validId: (id) => id,
    config: () => ({ url: "https://example.supabase.co", key: "server-only" }),
    request: async (url, options) => {
      calls.push({ url, options });
      return { ok: true, json: async () => ({ url: "/object/upload/sign/file?token=signed" }) };
    },
  });
  return { sign, calls, documents, context: { auth: { uid: "u1" } } };
}

test("signs unique image paths scoped to the server-verified branch and user", async () => {
  const { sign, calls, context } = setup({ role: "admin", branchId: "branch-1" });
  const input = { purpose: "product", sizeBytes: 500, branchId: "other", path: "elsewhere" };
  const grant = await sign(input, context);
  assert.match(grant.path, /^products\/branch-1\/[a-f0-9-]+\.jpg$/);
  assert.equal(grant.token, "signed");
  assert.notEqual((await sign(input, context)).path, grant.path);
  assert.match((await sign({ purpose: "profile", sizeBytes: 500, uid: "other" }, context)).path, /^profiles\/u1\//);
  assert.equal(calls[0].options.method, "POST");
  assert.equal(calls[0].options.headers.Authorization, "Bearer server-only");
  assert.ok(calls[0].url.endsWith("/food-images/" + grant.path));
  assert.equal(JSON.stringify(grant).includes("server-only"), false);
});

test("rejects unauthenticated, oversized, blocked and out-of-role signing", async () => {
  const profile = { role: "staff", branchId: "branch-1", permissions: { categories: true } };
  const { sign, calls, context } = setup(profile);
  const upload = (purpose) => sign({ purpose, sizeBytes: 500 }, context);
  await assert.rejects(sign({ purpose: "profile", sizeBytes: 500 }, {}), { code: "unauthenticated" });
  await assert.rejects(sign({ purpose: "profile", sizeBytes: 2097153 }, context), { code: "invalid-argument" });
  await assert.rejects(upload("product"), { code: "permission-denied" });
  await assert.rejects(upload("banner"), { code: "permission-denied" });
  await assert.rejects(upload("chat_attachments"), { code: "invalid-argument" });
  assert.equal(calls.length, 0);
  assert.match((await upload("category")).path, /^categories\/branch-1\//);
  profile.isBlocked = true;
  await assert.rejects(upload("profile"), { code: "permission-denied" });
  assert.equal(calls.length, 1);
});

test("stops issuing credentials after the hourly account quota", async () => {
  const { sign, calls, documents, context } = setup({ role: "customer" });
  documents.set("imageUploadQuotas/u1", { hour: Math.floor(Date.now() / 3600000), count: 60 });
  await assert.rejects(sign({ purpose: "profile", sizeBytes: 500 }, context), { code: "resource-exhausted" });
  assert.equal(calls.length, 0);
});
