const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { verify } = require("./cleanup_public_branch_totals");

async function run() {
  const project = process.argv.find((arg) => arg.startsWith("--project="))?.slice(10);
  const clean = process.argv.includes("--require-clean");
  if (!project || !/^[a-z][a-z0-9-]+$/.test(project) ||
      (process.env.FIRESTORE_EMULATOR_HOST && !project.startsWith("demo-"))) {
    throw new Error("Specify --project=<id>. Use a demo project with the emulator.");
  }
  const app = initializeApp({ projectId: project });
  try {
    const branches = await verify(getFirestore(app));
    const rows = branches.map(({ branch, pass, reason, publicFields }) => ({
      branch,
      result: pass && (!clean || !publicFields.length) ? "PASS" : "FAIL",
      comparison: reason,
      publicFields: publicFields.join(", "),
    }));
    console.table(rows);
    if (!rows.length || rows.some((row) => row.result === "FAIL")) process.exitCode = 1;
  } finally {
    await deleteApp(app);
  }
}

run().catch((error) => { console.error(error.message); process.exitCode = 1; });
