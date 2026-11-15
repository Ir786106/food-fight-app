const assert = require("node:assert/strict");
const { after, test } = require("node:test");
const { setTimeout: delay } = require("node:timers/promises");

const project = "demo-food-fight";
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const functionsHost = "127.0.0.1:5687";
if (process.env.GCLOUD_PROJECT !== project ||
    ![authHost, process.env.FIRESTORE_EMULATOR_HOST].every(
      (host) => /^127\.0\.0\.1:\d+$/.test(host ?? ""),
    )) {
  throw new Error("Run against the local Food Fight demo emulators.");
}

const admin = require("firebase-admin");
const app = admin.initializeApp({ projectId: project });
const db = app.firestore();
after(() => app.delete());

async function request(url, data, token) {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(token ? { authorization: "Bearer " + token } : {}),
    },
    body: JSON.stringify(data),
    signal: AbortSignal.timeout(90000),
  });
  return { status: response.status, body: await response.json() };
}

async function signInFixture(role) {
  const email = role + "@callable-fixture.test";
  const password = "local-emulator-fixture-only";
  const user = await app.auth().createUser({ email, password });
  await db.doc("users/" + user.uid).set({
    id: user.uid, uid: user.uid, role, isActive: true, status: "active",
  });
  const result = await request(
    "http://" + authHost + "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo",
    { email, password, returnSecureToken: true },
  );
  assert.equal(result.status, 200);
  return { uid: user.uid, token: result.body.idToken };
}

function call(name, data, token) {
  return request(
    "http://" + functionsHost + "/" + project + "/us-central1/" + name,
    { data },
    token,
  );
}

test("production client callable names and payloads work over local HTTP", async () => {
  const customer = await signInFixture("customer");
  const operator = await signInFixture("super_admin");
  // The local worker may outlive the CLI's cold-start request deadline.
  // Warm up with an unauthenticated read before asserting callable behavior.
  let anonymous;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      anonymous = await call("getPlatformMetrics", {});
      if (anonymous.status < 500) break;
    } catch (error) {
      if (attempt === 2) throw error;
    }
    await delay(5000);
  }
  assert.equal(anonymous?.body.error?.status, "UNAUTHENTICATED");
  assert.equal(
    (await call("getPlatformMetrics", {}, customer.token)).body.error?.status,
    "PERMISSION_DENIED",
  );
  const metrics = await call("getPlatformMetrics", {}, operator.token);
  assert.equal(metrics.status, 200);
  assert.equal(typeof metrics.body.result.totalOrders, "number");

  const mutation = { action: "setBranchStatus", branchId: "callable-test", status: "inactive" };
  const branch = db.doc("branches/callable-test");
  await branch.set({ name: "Local fixture", status: "active" });
  assert.equal(
    (await call("mutatePlatform", mutation, customer.token)).body.error?.status,
    "PERMISSION_DENIED",
  );
  assert.equal((await branch.get()).get("status"), "active");
  assert.equal((await call("mutatePlatform", mutation, operator.token)).status, 200);
  assert.equal((await branch.get()).get("status"), "inactive");

  const staff = await signInFixture("admin");
  const profile = db.doc("users/" + staff.uid);
  const edit = {
    action: "updateAccount",
    targetId: staff.uid,
    name: "Callable Test Admin",
    role: "admin",
    branchId: branch.id,
    permissions: ["menu", "orders"],
  };
  assert.equal(
    (await call("mutatePlatform", edit, customer.token)).body.error?.status,
    "PERMISSION_DENIED",
  );
  assert.equal((await profile.get()).get("branchId"), undefined);
  assert.equal((await call("mutatePlatform", edit, operator.token)).status, 200);
  const updatedStaff = await profile.get();
  assert.equal(updatedStaff.get("branchId"), branch.id);
  assert.deepEqual(updatedStaff.get("permissions"), edit.permissions);

  await db.doc("users/" + operator.uid).update({ status: "suspended" });
  assert.equal(
    (await call("getPlatformMetrics", {}, operator.token)).body.error?.status,
    "PERMISSION_DENIED",
  );
});
