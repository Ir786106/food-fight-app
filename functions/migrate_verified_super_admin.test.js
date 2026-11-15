const test = require("node:test");
const assert = require("node:assert/strict");
const { planRoleCorrection } = require("./migrate_verified_super_admin");
const { isActiveProfile } = require("./account_status");

const uid = "test-platform-owner";
const identity = { uid, disabled: false };
const legacy = { uid, role: "super admin", isActive: 1, status: "active" };

test("plans a one-field correction and is idempotent after correction", () => {
  const patch = planRoleCorrection(uid, identity, legacy);
  assert.deepEqual(patch, { role: "super_admin" });
  assert.equal(legacy.role, "super admin");
  assert.equal(planRoleCorrection(uid, identity, { ...legacy, ...patch }), null);
});

test("rejects mismatched identities, missing profiles, and other roles", () => {
  assert.throws(() => planRoleCorrection(uid, { uid: "different" }, legacy));
  assert.throws(() => planRoleCorrection(uid, identity, null));
  assert.throws(() => planRoleCorrection(uid, identity, { ...legacy, id: "different" }));
  assert.throws(() => planRoleCorrection(uid, identity, { ...legacy, role: "admin" }));
  assert.throws(() => planRoleCorrection(uid, { ...identity, disabled: true }, legacy));
});

test("explicit inactive or suspended status overrides legacy active flags", () => {
  for (const status of ["blocked", "suspended", "deactivated", "inactive"]) {
    const profile = { ...legacy, status };
    assert.equal(isActiveProfile(profile), false);
    assert.throws(() => planRoleCorrection(uid, identity, profile));
  }
  assert.equal(isActiveProfile(legacy), true);
});

test("a conflicting stored identity prevents Super Admin authorization", () => {
  assert.equal(isActiveProfile({ ...legacy, role: "super_admin" }, uid), true);
  assert.equal(isActiveProfile({ ...legacy, role: "super_admin", id: "other" }, uid), false);
});
