const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { isActiveProfile } = require("./account_status");

const knownRoles = new Set([
  "super_admin", "admin", "staff", "sub_admin", "customer", "delivery_rider",
]);

function timestampFormat(value) {
  if (value == null) return "missing";
  if (value instanceof Timestamp) return "firestore-timestamp";
  if (value === 0) return "zero-placeholder";
  if (Number.isSafeInteger(value)) return "integer-unit-unverified";
  return "unrecognized";
}

function summarizeAccount(uid, identity, profile) {
  const ids = [profile?.id, profile?.uid].filter((id) => id != null && id !== "");
  return {
    authFound: !!identity,
    authEnabled: identity ? !identity.disabled : null,
    profileFound: !!profile,
    identityMatches: !!identity && !!profile && identity.uid === uid &&
      ids.every((id) => id === uid),
    storedIdentityFields: ids.length,
    role: knownRoles.has(profile?.role) ? profile.role :
      ["super admin", "super-admin", "rider"].includes(profile?.role)
        ? "known-legacy" : profile ? "unrecognized" : null,
    activeProfile: isActiveProfile(profile, uid),
    canonicalSuperAdminClaim: identity?.customClaims?.role === "super_admin",
    hasBranchAssignment: typeof profile?.branchId === "string" &&
      profile.branchId.trim() !== "" && profile.branchId.trim() !== "all",
    createdAtFormat: timestampFormat(profile?.createdAt),
    updatedAtFormat: timestampFormat(profile?.updatedAt),
  };
}

async function run() {
  const args = process.argv.slice(2);
  const project = args.find((value) => value.startsWith("--project="))?.slice(10);
  const ids = args.filter((value) => value.startsWith("--uid=")).map((value) => value.slice(6));
  if (!/^[a-z][a-z0-9-]+$/.test(project ?? "") || ids.length < 1 || ids.length > 20 ||
      ids.some((uid) => !uid || uid.length > 128 || uid.includes("/"))) {
    throw new Error("Use --project=<id> and one to twenty --uid=<Auth UID> flags.");
  }
  const app = initializeApp({ projectId: project });
  try {
    const auth = getAuth(app);
    const db = getFirestore(app);
    const rows = [];
    for (const [index, uid] of ids.entries()) {
      const [identity, snapshot] = await Promise.all([
        auth.getUser(uid).catch((error) => {
          if (error.code === "auth/user-not-found") return null;
          throw error;
        }),
        db.collection("users").doc(uid).get(),
      ]);
      rows.push({ input: index + 1, ...summarizeAccount(uid, identity, snapshot.data()) });
    }
    console.log(JSON.stringify({ project, checked: rows.length, rows }, null, 2));
  } finally {
    await deleteApp(app);
  }
}

module.exports = { summarizeAccount };
if (require.main === module) {
  run().catch((error) => {
    console.error("Account audit failed: " + (error.code ?? error.name));
    process.exitCode = 1;
  });
}
