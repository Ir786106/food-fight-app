const assert = require("node:assert/strict");
const { after, test } = require("node:test");
const admin = require("firebase-admin");

if (!/^127\.0\.0\.1:\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || "")) {
  throw new Error("Set FIRESTORE_EMULATOR_HOST to the local Firestore emulator.");
}
const { quoteOrder, placeOrder, mutateOrder, dispatchReadyOrder, expireRiderOffers } = require("./index");
const db = admin.firestore();
const functionsHost = process.env.FOODFIGHT_FUNCTIONS_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
if (functionsHost && (!/^127\.0\.0\.1:\d+$/.test(functionsHost) ||
    !/^127\.0\.0\.1:\d+$/.test(authHost || "") ||
    process.env.GCLOUD_PROJECT !== "demo-food-fight")) {
  throw new Error("HTTP verification requires local Auth and Functions emulators for demo-food-fight.");
}
const authUsers = [];

async function signIn(uid) {
  const email = uid + "@example.test";
  const password = "Emulator-only-password-123";
  await admin.auth().createUser({ uid, email, password });
  authUsers.push(uid);
  const response = await fetch(
    "http://" + authHost + "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-key",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
      signal: AbortSignal.timeout(30000),
    },
  );
  assert.equal(response.status, 200, "Auth emulator password sign-in");
  const body = await response.json();
  assert.equal(body.localId, uid);
  assert.ok(body.idToken);
  return body.idToken;
}

async function invokeHttp(name, data, token) {
  const response = await fetch("http://" + functionsHost + "/demo-food-fight/us-central1/" + name, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(token && { Authorization: "Bearer " + token }) },
    body: JSON.stringify({ data }),
    signal: AbortSignal.timeout(30000),
  });
  const body = await response.json();
  if (!response.ok) {
    throw Object.assign(new Error(body.error?.message || name + " failed"), {
      code: body.error?.status?.toLowerCase().replaceAll("_", "-"),
    });
  }
  return body.result;
}
const suffix = require("node:crypto").randomUUID();
const id = (name) => name + "_" + suffix;
const refs = [];
async function seed(collection, name, data) {
  const ref = db.collection(collection).doc(id(name));
  refs.push(ref);
  await ref.set(data);
}
async function call(actor, order, data) {
  return mutateOrder.run({ orderId: id(order), ...data }, { auth: { uid: id(actor) } });
}
after(async () => {
  await Promise.all(refs.map((ref) => ref.delete()));
  await Promise.all(authUsers.map((uid) => admin.auth().deleteUser(uid)));
  await admin.app().delete();
});

test("authorized kitchen, rider, and customer operations share one lifecycle", async () => {
  const branch = id("branch");
  for (const [user, profile] of [
    ["customer", { role: "customer" }],
    ["manager", { role: "admin", branchId: branch }],
    ["otherManager", { role: "admin", branchId: id("other") }],
    ["rider", { role: "delivery_rider", branchId: branch }],
    ["otherRider", { role: "delivery_rider", branchId: branch }],
  ]) {
    await seed("users", user, profile);
  }
  for (const rider of ["rider", "otherRider"]) {
    await seed("riders", rider, { userId: id(rider), isActive: 1, isOnline: 1, branchId: branch });
  }
  const order = { branchId: branch, customerId: id("customer"), status: "pending",
    createdAt: Date.now(), paymentMethod: "Cash on Delivery", total: 125.50, paymentStatus: "pending" };
  for (const name of ["first", "second", "cancel", "old"]) {
    await seed("orders", name, { ...order,
      ...(name === "second" && { status: "ready" }),
      ...(name === "old" && { createdAt: Date.now() - 360000 }) });
  }
  const transition = (actor, name, status, extra) => call(actor, name, { action: "transition", status, ...extra });
  await assert.rejects(transition("otherManager", "first", "accepted"), { code: "permission-denied" });
  await assert.rejects(transition("manager", "first", "ready"), { code: "failed-precondition" });
  await assert.rejects(transition("customer", "old", "cancelled", { reason: "Changed plans" }), { code: "failed-precondition" });
  await transition("customer", "cancel", "cancelled", { reason: "Changed plans" });

  for (const status of ["accepted", "preparing", "ready"]) await transition("manager", "first", status);
  const assign = (name, rider, expectedRiderId) => call("manager", name, {
    action: "assign", riderId: id(rider), expectedRiderId,
  });
  const results = await Promise.allSettled(["first", "second"].map((name) => assign(name, "rider")));
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  const assigned = results[0].status === "fulfilled" ? "first" : "second";
  assert.equal(results.find((result) => result.status === "rejected").reason.code, "failed-precondition");
  await assert.rejects(call("otherRider", assigned, { action: "accept" }), { code: "permission-denied" });
  await assert.rejects(transition("rider", assigned, "pickedUp"), { code: "failed-precondition" });
  await call("rider", assigned, { action: "decline" });
  assert.equal((await db.collection("orders").doc(id(assigned)).get()).data().status, "ready");
  await assign(assigned, "rider");
  await call("rider", assigned, { action: "accept" });
  await assert.rejects(assign(assigned, "otherRider", id("rider")), { code: "failed-precondition" });
  await transition("rider", assigned, "pickedUp");
  await transition("rider", assigned, "outForDelivery");
  await assert.rejects(transition("rider", assigned, "delivered"), { code: "failed-precondition" });
  await transition("rider", assigned, "delivered", { codCollected: true });
  await transition("rider", assigned, "delivered", { codCollected: true });

  const saved = (await db.collection("orders").doc(id(assigned)).get()).data();
  assert.equal(saved.paymentStatus, "paid");
  assert.equal(saved.statusHistory.filter((event) => event.status === "delivered").length, 1);
  const receipt = db.collection("codCollections").doc(id(assigned));
  refs.push(receipt, ...["first", "second"].map((name) => db.collection("riderAssignments").doc(id(name))));
  assert.equal((await receipt.get()).data().amountPaisa, 12550);
  await assert.rejects(call("otherManager", assigned, { action: "settle", amountPkr: 125.50 }), {
    code: "permission-denied",
  });
  await assert.rejects(call("manager", assigned, { action: "settle", amountPkr: 1 }), {
    code: "invalid-argument",
  });
  await call("manager", assigned, { action: "settle", amountPkr: 125.50 });
  const settled = (await receipt.get()).data();
  await call("manager", assigned, { action: "settle", amountPkr: 125.50 });
  assert.equal(settled.settledBy, id("manager"));
  assert.equal((await receipt.get()).data().settledAt.toMillis(), settled.settledAt.toMillis());
  assert.equal((await db.collection("orders").doc(id(assigned)).get()).data().codSettlementStatus, "settled");
  await assign(assigned === "first" ? "second" : "first", "rider");
});

test("expired offers release the order and branch dispatch tries another rider", async () => {
  const branch = id("dispatchBranch");
  await seed("branches", "dispatchBranch", { autoDispatchEnabled: true });
  for (const rider of ["firstOffer", "nextOffer"]) {
    await seed("users", rider, { role: "rider", branchId: branch });
    await seed("riders", rider, { userId: id(rider), isActive: 1, isOnline: 1, branchId: branch });
  }
  await seed("orders", "expired", {
    branchId: branch, status: "assigned", riderId: id("firstOffer"),
    offerExpiresAt: Date.now() - 1000, autoDispatchAttempts: 1,
  });
  const ref = db.collection("orders").doc(id("expired"));
  refs.push(db.collection("riderAssignments").doc(ref.id));
  await assert.rejects(call("firstOffer", "expired", { action: "accept" }), { code: "failed-precondition" });
  await assert.rejects(call("firstOffer", "expired", { action: "expire" }), { code: "invalid-argument" });
  await expireRiderOffers.run({});
  assert.equal((await ref.get()).data().status, "ready");
  await dispatchReadyOrder.run({
    before: { data: () => ({ status: "assigned" }) },
    after: { data: () => ({ status: "ready" }) },
  }, { params: { orderId: ref.id } });
  const reassigned = (await ref.get()).data();
  assert.equal(reassigned.riderId, id("nextOffer"));
  assert.equal(reassigned.autoDispatchAttempts, 2);
  assert.ok(reassigned.offerExpiresAt > Date.now());
  await call("nextOffer", "expired", { action: "accept" });
  await expireRiderOffers.run({});
  assert.equal((await ref.get()).data().offerExpiresAt, null);
});
test("customer quote and COD checkout reach delivery and kitchen settlement", async () => {
  const branchId = id("release-branch");
  await seed("branches", "release-branch", { status: "active" });
  await seed("deliveryAreas", "release-area", { branchId, deliveryCharge: 25 });
  await seed("menuItems", "release-item", { branchId, price: 100.50, stock: 3 });
  await seed("users", "release-customer", { role: "customer", isActive: true });
  await seed("users", "release-admin", { role: "admin", branchId });
  await seed("users", "release-rider", { role: "rider", branchId });
  await seed("riders", "release-rider", {
    userId: id("release-rider"), branchId, isActive: 1, isOnline: 1,
  });

  const tokens = new Map();
  if (functionsHost) {
    for (const actor of ["release-customer", "release-admin", "release-rider"]) {
      tokens.set(actor, await signIn(id(actor)));
    }
  }
  const invoke = (name, handler, actor, data) => functionsHost
    ? invokeHttp(name, data, tokens.get(actor))
    : handler.run(data, { auth: { uid: id(actor) } });
  const cart = {
    branchId, deliveryAreaId: id("release-area"),
    deliveryAddress: "123 Test Street", customerPhone: "03001234567",
    items: [{ id: id("release-item"), quantity: 1 }],
  };
  if (functionsHost) {
    await assert.rejects(invokeHttp("quoteOrder", cart), { code: "unauthenticated" });
  }
  const quote = await invoke("quoteOrder", quoteOrder, "release-customer", cart);
  assert.equal(quote.data.total, 125.50);
  const checkout = { ...cart, requestId: "release-verification", clientTotal: quote.data.total };
  const placed = await invoke("placeOrder", placeOrder, "release-customer", checkout);
  const orderId = placed.orderId;
  const order = db.collection("orders").doc(orderId);
  const receipt = db.collection("codCollections").doc(orderId);
  refs.push(order, receipt, db.collection("riderAssignments").doc(orderId));
  assert.equal((await invoke("placeOrder", placeOrder, "release-customer", checkout)).orderId, orderId);
  assert.equal((await db.collection("menuItems").doc(id("release-item")).get()).data().stock, 2);
  const mutate = (actor, data) => invoke("mutateOrder", mutateOrder, actor, { orderId, ...data });
  for (const status of ["accepted", "preparing", "ready"]) {
    await mutate("release-admin", { action: "transition", status });
  }
  await mutate("release-admin", { action: "assign", riderId: id("release-rider") });
  await mutate("release-rider", { action: "accept" });
  for (const status of ["pickedUp", "outForDelivery", "delivered"]) {
    await mutate("release-rider", { action: "transition", status, codCollected: status === "delivered" });
  }
  await assert.rejects(mutate("release-customer", { action: "settle", amountPkr: 125.50 }), {
    code: "permission-denied",
  });
  await mutate("release-admin", { action: "settle", amountPkr: 125.50 });
  if (functionsHost) console.log("Verified order lifecycle over authenticated callable HTTP.");
  assert.equal((await order.get()).data().codSettlementStatus, "settled");
  assert.equal((await receipt.get()).data().amountPaisa, 12550);
});