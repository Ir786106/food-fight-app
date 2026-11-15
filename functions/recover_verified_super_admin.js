const fs = require("node:fs/promises");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { isActiveProfile } = require("./account_status");
const { verifiedBackup } = require("./migrate_legacy_tenants");

function recoveryProfile(source, identity, sourceUid, targetUid) {
  if (sourceUid === targetUid || identity?.uid !== targetUid || identity.disabled) {
    throw new Error("Expected an enabled existing Auth account at a distinct target UID.");
  }
  if (source?.role !== "super admin" || ![sourceUid, targetUid].includes(source.id) ||
      source.uid !== targetUid || !isActiveProfile(source)) {
    throw new Error("The legacy profile does not explicitly link to this Auth UID.");
  }
  const email = identity.email?.trim();
  if (!email || typeof source.email !== "string" ||
      source.email.trim().toLowerCase() !== email.toLowerCase()) {
    throw new Error("The legacy and Auth emails do not match.");
  }
  return {
    id: targetUid,
    uid: targetUid,
    email,
    ...(typeof source.name === "string" && source.name.trim() ? { name: source.name } : {}),
    role: "super_admin",
    status: "active",
    isActive: true,
  };
}

async function prepareRecovery({ auth, db, sourceUid, targetUid, apply = false }) {
  const sourceRef = db.collection("users").doc(sourceUid);
  const targetRef = db.collection("users").doc(targetUid);
  const [identity, source, target] = await Promise.all([
    auth.getUser(targetUid), sourceRef.get(), targetRef.get(),
  ]);
  if (target.exists) throw new Error("Target profile already exists. No overwrite is allowed.");
  recoveryProfile(source.data(), identity, sourceUid, targetUid);

  if (apply) {
    await db.runTransaction(async (tx) => {
      const [currentSource, currentTarget] = await Promise.all([
        tx.get(sourceRef), tx.get(targetRef),
      ]);
      if (currentTarget.exists || !currentSource.updateTime?.isEqual(source.updateTime)) {
        throw new Error("A profile changed after the preflight read. Run the preview again.");
      }
      const profile = recoveryProfile(currentSource.data(), identity, sourceUid, targetUid);
      const now = FieldValue.serverTimestamp();
      tx.create(targetRef, { ...profile, createdAt: now, updatedAt: now });
    });
  }
  return { plannedProfiles: 1, createdProfiles: apply ? 1 : 0 };
}

async function requireApproval(file, project, sourceUid, targetUid) {
  if (!file) throw new Error("--apply requires --owner-approval=<reviewed approval JSON>");
  const approval = JSON.parse(await fs.readFile(file, "utf8"));
  if (approval.project !== project || approval.sourceUid !== sourceUid ||
      approval.targetUid !== targetUid || approval.action !== "create-super-admin-profile" ||
      typeof approval.authorizationReference !== "string" || !approval.authorizationReference.trim()) {
    throw new Error("The approval record must cover this project, both UIDs and this action.");
  }
}

async function run() {
  const args = process.argv.slice(2);
  const arg = (name) => args.find((value) => value.startsWith(`--${name}=`))?.slice(name.length + 3);
  const project = arg("project");
  const sourceUid = arg("source-uid");
  const targetUid = arg("target-uid");
  const apply = args.includes("--apply");
  const validUid = (uid) => typeof uid === "string" && uid === uid.trim() &&
    uid.length > 0 && uid.length <= 128 && !uid.includes("/");
  if (!/^[a-z][a-z0-9-]+$/.test(project ?? "") || !validUid(sourceUid) ||
      !validUid(targetUid) || sourceUid === targetUid) {
    throw new Error("Use --project=<id> --source-uid=<legacy UID> --target-uid=<existing Auth UID>.");
  }
  if (apply) {
    if (arg("confirm-target-uid") !== targetUid ||
        process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST) {
      throw new Error("Apply requires a live project and --confirm-target-uid matching the approved UID.");
    }
    await requireApproval(arg("owner-approval"), project, sourceUid, targetUid);
    await verifiedBackup(arg("backup-operation"), project);
  }
  const app = initializeApp({ projectId: project });
  try {
    const result = await prepareRecovery({
      auth: getAuth(app), db: getFirestore(app), sourceUid, targetUid, apply,
    });
    console.log(JSON.stringify({ project, mode: apply ? "apply" : "dry-run", ...result }));
  } finally {
    await deleteApp(app);
  }
}

module.exports = { prepareRecovery, recoveryProfile, requireApproval };
if (require.main === module) {
  run().catch((error) => {
    console.error(error.code ?? error.message);
    process.exitCode = 1;
  });
}
