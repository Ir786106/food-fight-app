const test = require("node:test");
const assert = require("node:assert/strict");
const { prepareRecovery, recoveryProfile, requireApproval } = require("./recover_verified_super_admin");

const sourceUid = "old";
const targetUid = "existing";
const identity = { uid: targetUid, email: "owner@example.test", disabled: false };
const source = {
  id: sourceUid, uid: targetUid, email: identity.email, role: "super admin",
  isActive: 1, status: "active", fcmToken: "old-device", permissions: ["old"], branchId: "old",
};

function fixture({ targetExists = false, concurrentTarget = false, concurrentSource = false } = {}) {
  const writes = [];
  const document = (uid, inTransaction = false) => uid === sourceUid
    ? { data: () => source, updateTime: { isEqual: () => !inTransaction || !concurrentSource } }
    : { exists: targetExists || (inTransaction && concurrentTarget) };
  const db = {
    collection: () => ({ doc: (uid) => ({ uid, get: async () => document(uid) }) }),
    runTransaction: (callback) => callback({
      get: async (ref) => document(ref.uid, true),
      create: (ref, value) => writes.push({ ref, value }),
    }),
  };
  return { writes, args: { auth: { getUser: async () => identity }, db, sourceUid, targetUid } };
}

test("dry run leaves both profiles untouched", async () => {
  const { writes, args } = fixture();
  assert.deepEqual(await prepareRecovery(args), { plannedProfiles: 1, createdProfiles: 0 });
  assert.equal(writes.length, 0);
});

test("approved write creates only the target with canonical identity and no legacy secrets or scope", async () => {
  const { writes, args } = fixture();
  await prepareRecovery({ ...args, apply: true });
  assert.equal(writes.length, 1);
  const { ref, value } = writes[0];
  assert.equal(ref.uid, targetUid);
  assert.equal(value.id, targetUid);
  assert.equal(value.uid, targetUid);
  assert.equal(value.role, "super_admin");
  assert.equal(value.isActive, true);
  assert.equal(value.status, "active");
  for (const field of ["fcmToken", "permissions", "branchId"]) assert.equal(field in value, false);
});

test("rejects existing targets, concurrent changes and missing approval", async () => {
  for (const flags of [{ targetExists: true }, { concurrentTarget: true }, { concurrentSource: true }]) {
    const { args, writes } = fixture(flags);
    await assert.rejects(prepareRecovery({ ...args, apply: true }));
    assert.equal(writes.length, 0);
  }
  await assert.rejects(requireApproval(null, "test-project", sourceUid, targetUid), /owner-approval/);
});

test("email agreement alone cannot pass identity and status checks", () => {
  assert.equal(recoveryProfile({ ...source, id: targetUid }, identity, sourceUid, targetUid).id, targetUid);
  assert.throws(() => recoveryProfile({ ...source, id: "other" }, identity, sourceUid, targetUid));
  assert.throws(() => recoveryProfile({ ...source, uid: "other" }, identity, sourceUid, targetUid));
  assert.throws(() => recoveryProfile(source, { ...identity, disabled: true }, sourceUid, targetUid));
  assert.throws(() => recoveryProfile({ ...source, status: "suspended" }, identity, sourceUid, targetUid));
});
