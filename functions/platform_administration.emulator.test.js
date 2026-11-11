const assert = require("node:assert/strict");
const { after, test } = require("node:test");

for (const key of ["FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST"]) {
  if (!/^127\.0\.0\.1:\d+$/.test(process.env[key] || "")) {
    throw new Error("This test requires local Firestore and Auth emulators.");
  }
}
if (process.env.GCLOUD_PROJECT !== "demo-food-fight") {
  throw new Error("This test runs only on the demo-food-fight project.");
}

const admin = require("firebase-admin");
const { mutatePlatform, getPlatformMetrics } = require("./index");

after(() => admin.app().delete());

test("platform operations persist across real local Auth and Firestore emulators", async () => {
  const db = admin.firestore();
  const auth = admin.auth();
  const operator = await auth.createUser({ email: "platform@example.test" });
  await db.doc("users/" + operator.uid).set({ role: "super_admin", isActive: 1 });
  const context = { auth: { uid: operator.uid } };
  const result = await mutatePlatform.run({
    action: "createAccount",
    email: "branch@example.test",
    role: "admin",
    name: "Branch Manager",
    branchId: "new-branch",
    newBranch: {
      id: "new-branch", name: "New Branch", city: "Lahore", address: "Main Street",
    },
  }, context);
  assert.equal((await auth.getUser(result.userId)).email, "branch@example.test");
  assert.equal((await db.doc("users/" + result.userId).get()).data().branchId, "new-branch");

  await mutatePlatform.run({
    action: "setAccountStatus", targetId: result.userId, status: "suspended",
  }, context);
  assert.equal((await auth.getUser(result.userId)).disabled, true);
  assert.equal((await db.doc("users/" + result.userId).get()).data().isActive, 0);

  await mutatePlatform.run({
    action: "setBranchStatus", branchId: "new-branch", status: "inactive",
  }, context);
  assert.equal((await db.doc("branches/new-branch").get()).data().status, "inactive");
  await db.doc("orders/delivered").set({ status: "delivered", total: 100, createdAt: Date.now() });
  await db.doc("orders/pending").set({ status: "pending", total: 60, createdAt: Date.now() });
  const metrics = await getPlatformMetrics.run({}, context);
  assert.equal(metrics.totalBranches, 1);
  assert.equal(metrics.totalRestaurants, 0);
  assert.equal(metrics.totalOrders, 2);
  assert.equal(metrics.deliveredGmv, 100);
  assert.equal(metrics.dailySales.at(-1).ordersCount, 1);
  const audit = await db.collection("auditLogs").where("actorId", "==", operator.uid).get();
  assert.equal(audit.size, 4);
});
