const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { verifiedBackup } = require("./migrate_legacy_tenants");

function planRoleCorrection(uid, authUser, profile) {
  if (!authUser || authUser.uid !== uid || authUser.disabled) {
    throw new Error("Expected an enabled Auth identity matching the supplied UID.");
  }
  if (!profile || [profile.id, profile.uid].some((id) => id != null && id !== uid)) {
    throw new Error("The matching Firestore profile is missing or has conflicting IDs.");
  }
  if (profile.isBlocked === true ||
      ["blocked", "suspended", "deactivated", "inactive"].includes(profile.status) ||
      ![null, undefined, true, 1, "true", "1"].includes(profile.isActive)) {
    throw new Error("The profile is disabled.");
  }
  if (profile.role === "super_admin") return null;
  if (profile.role !== "super admin") {
    throw new Error("Unexpected current role. No role change is permitted.");
  }
  return { role: "super_admin" };
}

async function run() {
  const args = process.argv.slice(2);
  const arg = (name) => args.find((value) => value.startsWith(`--${name}=`))?.slice(name.length + 3);
  const project = arg("project");
  const uid = arg("uid");
  const apply = args.includes("--apply");
  if (!/^[a-z][a-z0-9-]+$/.test(project ?? "") || !uid || uid.length > 128 || uid.includes("/")) {
    throw new Error("Use --project=<id> --uid=<independently verified Auth UID>.");
  }
  if (apply && (arg("confirm-authorized-uid") !== uid || process.env.FIRESTORE_EMULATOR_HOST ||
      process.env.FIREBASE_AUTH_EMULATOR_HOST)) {
    throw new Error("Apply requires --confirm-authorized-uid matching the approved UID and a live project.");
  }
  if (apply) await verifiedBackup(arg("backup-operation"), project);
  const app = initializeApp({ projectId: project });
  try {
    const identity = await getAuth(app).getUser(uid);
    const db = getFirestore(app);
    const ref = db.collection("users").doc(uid);
    const snapshot = await ref.get();
    const patch = planRoleCorrection(uid, identity, snapshot.data());
    if (apply && patch) {
      await db.runTransaction(async (tx) => {
        const current = await tx.get(ref);
        if (!current.updateTime?.isEqual(snapshot.updateTime)) {
          throw new Error("Profile changed since preview. Run a fresh dry run.");
        }
        const verifiedPatch = planRoleCorrection(uid, identity, current.data());
        if (verifiedPatch) tx.update(ref, verifiedPatch);
      });
    }
    console.log(JSON.stringify({
      project, path: ref.path, mode: apply ? "apply" : "dry-run",
      scanned: 1, needsChange: patch ? 1 : 0, migrated: apply && patch ? 1 : 0,
      canonicalRoleClaim: identity.customClaims?.role === "super_admin",
    }));
  } finally {
    await deleteApp(app);
  }
}

module.exports = { planRoleCorrection };
if (require.main === module) {
  run().catch((error) => {
    console.error(error.code ?? error.message);
    process.exitCode = 1;
  });
}
