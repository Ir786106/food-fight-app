const assert = require("node:assert/strict");
const { test } = require("node:test");
const { platformAdministration } = require("./platform_administration");

function setup() {
  const documents = new Map([
    ["users/platform", { role: "super_admin", name: "Platform operator", isActive: 1 }],
    ["users/manager", { role: "admin", branchId: "branch-one", status: "active", isActive: 1 }],
    ["branches/branch-one", { name: "Branch one", status: "active", revenue: 125 }],
  ]);
  const accounts = new Map([
    ["platform", { uid: "platform", disabled: false }],
    ["manager", { uid: "manager", disabled: false }],
  ]);
  const revoked = [];
  let sequence = 0;
  const doc = (path) => ({
    path,
    async get() {
      return { exists: documents.has(path), data: () => documents.get(path) };
    },
  });
  const db = {
    collection: (name) => ({ doc: (id) => doc(name + "/" + (id ?? ++sequence)) }),
    async runTransaction(body) {
      const next = new Map(documents);
      const result = await body({
        get: (ref) => ref.get(),
        create(ref, data) {
          assert.equal(next.has(ref.path), false);
          next.set(ref.path, data);
        },
        update(ref, data) {
          next.set(ref.path, { ...next.get(ref.path), ...data });
        },
      });
      for (const [path, data] of next) documents.set(path, data);
      return result;
    },
  };
  const auth = {
    async getUser(id) {
      if (!accounts.has(id)) throw Object.assign(new Error("Missing user"), { code: "auth/user-not-found" });
      return accounts.get(id);
    },
    async createUser(fields) {
      assert.ok(fields.password.length >= 32);
      const uid = "new-user-" + (++sequence);
      const account = { uid, email: fields.email, disabled: false };
      accounts.set(uid, account);
      return account;
    },
    async deleteUser(id) { accounts.delete(id); },
    async updateUser(id, patch) { Object.assign(accounts.get(id), patch); },
    async revokeRefreshTokens(id) { revoked.push(id); },
  };
  const platform = platformAdministration({
    db, auth, timestamp: () => 1,
    fail: (code, message) => { throw Object.assign(new Error(message), { code }); },
  });
  return { ...platform, accounts, documents, revoked, context: { auth: { uid: "platform" } } };
}

const newAccount = {
  action: "createAccount", role: "admin", name: "Branch manager",
  email: " manager@example.test ", branchId: "branch-two", permissions: ["manage_orders"],
};

test("rejects a privileged token when the current profile is not an active Super Admin", async () => {
  const { mutate, documents, context } = setup();
  const stale = { auth: { uid: "manager", token: { role: "super_admin" } } };
  await assert.rejects(mutate(newAccount, stale), { code: "permission-denied" });
  documents.set("users/platform", { role: "super_admin", status: "suspended" });
  await assert.rejects(mutate(newAccount, context), { code: "permission-denied" });
});

test("provisions an Auth-backed admin and its new branch with server audit records", async () => {
  const { mutate, documents, accounts, context } = setup();
  const { userId } = await mutate({
    ...newAccount, newBranch: {
      id: "branch-two", name: "Branch two", city: "Lahore", address: "Main Street",
    },
  }, context);
  assert.equal(accounts.get(userId).email, "manager@example.test");
  assert.equal(documents.get("users/" + userId).branchId, "branch-two");
  assert.deepEqual(documents.get("users/" + userId).permissions, ["orders"]);
  assert.equal(documents.get("branches/branch-two").status, "active");
  const logs = [...documents].filter(([path]) => path.startsWith("auditLogs/")).map(([, data]) => data);
  assert.deepEqual(logs.map((log) => log.action), ["branch_created", "admin_created"]);
  assert.ok(logs.every((log) => log.actorId === "platform"));
});

test("rolls back the new Auth user when the selected branch is missing", async () => {
  const { mutate, documents, accounts, context } = setup();
  await assert.rejects(mutate(newAccount, context), { code: "not-found" });
  assert.equal(accounts.size, 2);
  assert.equal(documents.size, 3);
});

test("suspends Auth, revokes tokens, and can reactivate the same account", async () => {
  const { mutate, documents, accounts, revoked, context } = setup();
  await mutate({ action: "setAccountStatus", targetId: "manager", status: "suspended" }, context);
  assert.equal(documents.get("users/manager").isActive, 0);
  assert.equal(accounts.get("manager").disabled, true);
  assert.deepEqual(revoked, ["manager"]);
  await mutate({ action: "setAccountStatus", targetId: "manager", status: "active" }, context);
  assert.equal(documents.get("users/manager").isActive, 1);
  assert.equal(accounts.get("manager").disabled, false);
  await assert.rejects(
    mutate({ action: "setAccountStatus", targetId: "platform", status: "suspended" }, context),
    { code: "failed-precondition" },
  );
});

test("branch suspension preserves financial history and writes only one audit on retry", async () => {
  const { mutate, documents, context } = setup();
  const input = { action: "setBranchStatus", branchId: "branch-one", status: "inactive" };
  await mutate(input, context);
  await mutate(input, context);
  assert.equal(documents.get("branches/branch-one").revenue, 125);
  assert.equal(documents.get("branches/branch-one").status, "inactive");
  assert.equal([...documents.keys()].filter((path) => path.startsWith("auditLogs/")).length, 1);
});


test("branch managers can suspend their own branch staff only", async () => {
  const { mutate, documents, accounts, revoked } = setup();
  documents.set("users/team", { role: "staff", branchId: "branch-one", status: "active", isActive: 1 });
  documents.set("users/foreign-team", { role: "sub_admin", branchId: "branch-two", status: "active", isActive: 1 });
  accounts.set("team", { uid: "team", disabled: false });
  accounts.set("foreign-team", { uid: "foreign-team", disabled: false });
  const context = { auth: { uid: "manager" } };
  const suspend = (targetId, action = "setBranchStaffStatus") =>
    mutate({ action, targetId, status: "suspended" }, context);
  await assert.rejects(suspend("foreign-team"), { code: "permission-denied" });
  await assert.rejects(suspend("platform"), { code: "permission-denied" });
  await assert.rejects(suspend("team", "setAccountStatus"), { code: "permission-denied" });
  await suspend("team");
  assert.equal(documents.get("users/team").isActive, 0);
  assert.equal(accounts.get("team").disabled, true);
  assert.deepEqual(revoked, ["team"]);
  const audit = [...documents.values()].find((value) => value.action === "admin_status_changed");
  assert.equal(audit.actorRole, "admin");
  assert.equal(audit.branchId, "branch-one");
});
