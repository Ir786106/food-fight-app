const test = require("node:test");
const assert = require("node:assert/strict");
const { Timestamp } = require("firebase-admin/firestore");
const { summarizeAccount } = require("./audit_account_profiles");

test("reports legacy formats without exporting identity or contact fields", () => {
  const row = summarizeAccount("owner", {
    uid: "owner", email: "fixture@example.test", customClaims: { role: "super_admin" },
  }, {
    uid: "owner", role: "super admin", isActive: 1, createdAt: 0,
    updatedAt: Timestamp.fromMillis(1000),
  });
  assert.equal(row.identityMatches, true);
  assert.equal(row.role, "known-legacy");
  assert.equal(row.createdAtFormat, "zero-placeholder");
  assert.equal(row.updatedAtFormat, "firestore-timestamp");
  assert.equal(row.canonicalSuperAdminClaim, true);
  assert.doesNotMatch(JSON.stringify(row), /owner|example\.test/);
});

test("distinguishes missing Auth and conflicting profile identity", () => {
  const profile = { id: "other", role: "super_admin", updatedAt: 1711111111 };
  const row = summarizeAccount("owner", { uid: "owner" }, profile);
  assert.equal(row.identityMatches, false);
  assert.equal(row.activeProfile, false);
  assert.equal(row.updatedAtFormat, "integer-unit-unverified");
  const orphan = summarizeAccount("owner", null, profile);
  assert.equal(orphan.authFound, false);
  assert.equal(orphan.profileFound, true);
});
