const { initializeApp } = require("firebase-admin/app");
const { FieldPath, FieldValue, getFirestore } = require("firebase-admin/firestore");

const publicFields = [
  "revenue", "expenses", "orderCount", "ordersCount", "totalRevenue", "totalOrders",
];

function privateMetrics(branch, current = {}) {
  const legacyPublic = Object.fromEntries(publicFields
    .filter((field) => Object.hasOwn(branch, field))
    .map((field) => [field, branch[field]]));
  if (!Object.keys(legacyPublic).length) return null;

  return {
    totalRevenue: current.totalRevenue ?? branch.totalRevenue ?? branch.revenue ?? 0,
    totalOrders: current.totalOrders ?? branch.totalOrders ?? branch.orderCount ?? branch.ordersCount ?? 0,
    expenses: current.expenses ?? branch.expenses ?? 0,
    legacyPublic,
  };
}

async function run() {
  const args = process.argv.slice(2);
  const projectId = args.find((arg) => arg.startsWith("--project="))?.slice(10);
  const apply = args.includes("--apply");
  if (!projectId || !/^[a-z][a-z0-9-]+$/.test(projectId)) {
    throw new Error("Pass --project=<Firebase project ID>. Add --apply to move data.");
  }
  if (process.env.FIRESTORE_EMULATOR_HOST && !projectId.startsWith("demo-")) {
    throw new Error("Use a demo project ID when the Firestore emulator is configured.");
  }
  initializeApp({ projectId });
  const db = getFirestore();
  const branches = db.collection("branches").orderBy(FieldPath.documentId());
  let cursor;
  let affected = 0;
  for (;;) {
    const page = await (cursor ? branches.startAfter(cursor) : branches).limit(100).get();
    if (page.empty) break;
    for (const doc of page.docs) {
      if (!privateMetrics(doc.data())) continue;
      if (!apply) {
        affected++;
        continue;
      }
      const moved = await db.runTransaction(async (transaction) => {
        const metricsRef = db.collection("branchMetrics").doc(doc.id);
        const [latest, current] = await Promise.all([
          transaction.get(doc.ref),
          transaction.get(metricsRef),
        ]);
        const metrics = latest.exists && privateMetrics(latest.data(), current.data());
        if (!metrics) return false;
        const archived = current.get("legacyPublic") ?? {};
        if (Object.keys(metrics).every((key) => key === "legacyPublic" ||
            metrics[key] === current.get(key)) &&
            Object.entries(metrics.legacyPublic).every(([key, value]) => archived[key] === value)) {
          return false;
        }
        transaction.set(metricsRef, {
          ...metrics,
          migratedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        return true;
      });
      if (moved) affected++;
    }
    cursor = page.docs.at(-1);
  }
  console.log(`${projectId}: ${affected} branch(es) ${apply ? "copied" : "with legacy public fields"}.`);
}

module.exports = { privateMetrics };

if (require.main === module) {
  run().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
