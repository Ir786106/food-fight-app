const { initializeApp, deleteApp } = require("firebase-admin/app");
const { FieldPath, FieldValue, getFirestore } = require("firebase-admin/firestore");

const fields = {
  revenue: "totalRevenue",
  totalRevenue: "totalRevenue",
  orderCount: "totalOrders",
  ordersCount: "totalOrders",
  totalOrders: "totalOrders",
  expenses: "expenses",
};

function compare(branch, metrics) {
  const publicFields = Object.keys(fields).filter((key) => Object.hasOwn(branch, key));
  if (!metrics) return { pass: false, reason: "Missing private metrics", publicFields };
  const mismatches = publicFields.filter((key) =>
    !Number.isFinite(branch[key]) || branch[key] !== metrics[fields[key]]);
  return {
    pass: mismatches.length === 0,
    reason: mismatches.length ? `Mismatch: ${mismatches.join(", ")}` :
      publicFields.length ? "Matching values" : "No public totals",
    publicFields,
  };
}

async function verify(db) {
  const result = [];
  const query = db.collection("branches").orderBy(FieldPath.documentId());
  let cursor;
  for (;;) {
    const page = await (cursor ? query.startAfter(cursor) : query).limit(100).get();
    if (page.empty) return result;
    const metrics = await db.getAll(...page.docs.map((doc) => db.doc(`branchMetrics/${doc.id}`)));
    page.docs.forEach((doc, index) => {
      result.push({ branch: doc.id, ...compare(doc.data(), metrics[index].data()) });
    });
    cursor = page.docs.at(-1);
  }
}

async function run() {
  const args = process.argv.slice(2);
  const project = args.find((arg) => arg.startsWith("--project="))?.slice(10);
  const apply = args.includes("--apply");
  if (!project || !/^[a-z][a-z0-9-]+$/.test(project)) throw new Error("Use --project=<id>.");
  if (apply && !args.includes("--confirm-public-financial-cleanup")) {
    throw new Error("Cleanup requires --confirm-public-financial-cleanup after both verification runs.");
  }
  if (process.env.FIRESTORE_EMULATOR_HOST && (apply || !project.startsWith("demo-"))) {
    throw new Error("Emulator runs are verification-only and require a demo project ID.");
  }
  const app = initializeApp({ projectId: project });
  try {
    const db = getFirestore(app);
    const result = await verify(db);
    console.table(result.map(({ branch, pass, reason }) => ({ branch, result: pass ? "PASS" : "FAIL", reason })));
    if (result.some(({ pass }) => !pass)) throw new Error("Branch metrics parity failed.");
    if (!apply) return;
    for (const { branch, publicFields } of result) {
      if (!publicFields.length) continue;
      await db.runTransaction(async (tx) => {
        const ref = db.doc(`branches/${branch}`);
        const [current, metrics] = await tx.getAll(ref, db.doc(`branchMetrics/${branch}`));
        if (!current.exists) throw new Error(`Branch disappeared: ${branch}`);
        const parity = compare(current.data(), metrics.data());
        if (!parity.pass) throw new Error(`Branch changed after preflight: ${branch}`);
        if (parity.publicFields.length) {
          tx.update(ref, Object.fromEntries(parity.publicFields.map((field) => [field, FieldValue.delete()])));
        }
      });
    }
  } finally {
    await deleteApp(app);
  }
}

module.exports = { compare, verify };
if (require.main === module) {
  run().catch((error) => { console.error(error.message); process.exitCode = 1; });
}
