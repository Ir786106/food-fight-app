const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const { test } = require("node:test");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { migrate, verifiedBackup } = require("./migrate_legacy_tenants");
const { compare, verify } = require("./cleanup_public_branch_totals");

test("backup gate rejects incomplete, partial, and foreign exports", async () => {
  const folder = await fs.mkdtemp(path.join(os.tmpdir(), "ff-backup-"));
  const receipt = path.join(folder, "export.json");
  const operation = {
    name: "projects/demo-food-fight/databases/(default)/operations/export",
    done: true,
    metadata: {
      "@type": "type.googleapis.com/google.firestore.admin.v1.ExportDocumentsMetadata",
      outputUriPrefix: "gs://backup/export",
    },
  };
  try {
    await assert.rejects(verifiedBackup(null, "demo-food-fight"));
    await fs.writeFile(receipt, JSON.stringify(operation));
    assert.equal(await verifiedBackup(receipt, "demo-food-fight"), operation.name);
    await assert.rejects(verifiedBackup(receipt, "other-project"));
    await fs.writeFile(receipt, JSON.stringify({ ...operation, done: false }));
    await assert.rejects(verifiedBackup(receipt, "demo-food-fight"));
    operation.metadata.collectionIds = ["orders"];
    await fs.writeFile(receipt, JSON.stringify(operation));
    await assert.rejects(verifiedBackup(receipt, "demo-food-fight"));
  } finally {
    await fs.rm(folder, { recursive: true });
  }
});

test("migration handles fresh, legacy, partial, orphaned, repeated and paginated records",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST, timeout: 180000 }, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST, /^(127\.0\.0\.1|localhost):\d+$/);
    const project = "demo-food-fight-tenants";
    const app = initializeApp({ projectId: project }, "tenant-migration-test");
    const db = getFirestore(app);
    const folder = await fs.mkdtemp(path.join(os.tmpdir(), "ff-migration-"));
    const now = Timestamp.fromMillis(1000);
    const complete = { tenantId: "tenant", status: "active", createdAt: now, updatedAt: now };
    const options = { project, delayMs: 0, batchSize: 100 };
    const reportPath = (name) => path.join(folder, `${name}.json`);
    try {
      await Promise.all(Object.entries({
        "tenants/tenant": complete,
        "restaurants/restaurant": { ...complete, restaurantId: "restaurant" },
        "branches/fresh": { ...complete, restaurantId: "restaurant" },
        "branches/legacy": { restaurant_id: "restaurant", isActive: 1, revenue: 42 },
        "branches/half": { tenantId: "tenant", restaurant_id: "restaurant", status: "suspended", createdAt: now },
        "branches/orphan": { restaurant_id: "missing", isActive: false },
        "orders/legacy": { branch_id: "legacy", status: "delivered" },
        "orderItems/legacy": { orderId: "legacy" },
        "users/unknown": { userRole: "super_admin", branch_id: "legacy" },
        "branchMetrics/legacy": { totalRevenue: 42 },
      }).map(([document, data]) => db.doc(document).set(data)));
      for (let start = 0; start < 503; start += 250) {
        const batch = db.batch();
        for (let index = start; index < Math.min(start + 250, 503); index++) {
          batch.set(db.doc(`categories/c${index.toString().padStart(4, "0")}`), {
            ...complete, branchId: "fresh", restaurantId: "restaurant",
          });
        }
        await batch.commit();
      }
      const dry = await migrate(db, { ...options, reportPath: reportPath("dry") });
      assert.equal(dry.counts.scanned, 513);
      assert.equal(dry.counts.migrated, 0);
      assert.deepEqual(dry.documents["branches/fresh"].fields, []);
      assert.equal((await db.doc("branches/legacy").get()).get("tenantId"), undefined);
      const applyOptions = { ...options, apply: true, reportPath: reportPath("apply") };
      const applied = await migrate(db, applyOptions);
      assert.ok(applied.counts.migrated >= 5);
      assert.equal((await db.doc("branches/legacy").get()).get("tenantId"), "tenant");
      assert.equal((await db.doc("branches/legacy").get()).get("revenue"), 42);
      assert.equal((await db.doc("branches/half").get()).get("status"), "suspended");
      assert.equal((await db.doc("branches/orphan").get()).get("tenantId"), undefined);
      assert.equal(typeof (await db.doc("orders/legacy").get()).get("createdAt"), "number");
      assert.equal((await db.doc("orderItems/legacy").get()).get("branchId"), "legacy");
      assert.equal((await db.doc("users/unknown").get()).get("role"), undefined);
      assert.equal((await db.doc("users/unknown").get()).get("branchId"), undefined);
      const resumed = await migrate(db, { ...applyOptions, resume: true });
      assert.deepEqual(resumed.counts, applied.counts);
      const repeat = await migrate(db, { ...options, apply: true, reportPath: reportPath("repeat") });
      assert.equal(repeat.counts.migrated, 0);
      const table = await verify(db);
      assert.equal(table.find(({ branch }) => branch === "legacy").pass, true);
      assert.equal(table.find(({ branch }) => branch === "fresh").pass, false);
      assert.equal(compare({ revenue: 42 }, { totalRevenue: 43 }).pass, false);
    } finally {
      await deleteApp(app);
      await fs.rm(folder, { recursive: true });
    }
  });
