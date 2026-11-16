const fs = require("node:fs/promises");
const { setTimeout: delay } = require("node:timers/promises");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { FieldPath, Timestamp, getFirestore } = require("firebase-admin/firestore");

const collections = [
  "tenants", "restaurants", "branches", "users", "riders", "categories",
  "menuItems", "menu_items", "optionTemplates", "option_templates", "deals",
  "deliveryAreas", "delivery_areas", "coupons", "orders", "orderItems",
  "riderAssignments", "menuReports", "reviews", "chats", "auditLogs",
  "codCollections", "branchMetrics",
];
const orderChildren = new Set(["orderItems", "riderAssignments", "codCollections"]);
const privilegedProfiles = new Set(["users", "riders"]);
const lifecycleRoots = new Set(["tenants", "restaurants", "branches"]);
const roles = new Set(["customer", "admin", "staff", "sub_admin", "super_admin", "rider", "delivery_rider"]);
const isId = (value) => typeof value === "string" && value.trim() === value &&
  value !== "" && value !== "all" && !value.includes("/");
const missing = (value) => value == null || value === "";

function dateMillis(value) {
  if (value instanceof Timestamp) return value.toMillis();
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}/.test(value)) {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

async function planDocument(db, snapshot, hasTenants) {
  const data = snapshot.data();
  const collection = snapshot.ref.parent.id;
  const patch = {};
  const issues = [];
  const dependencies = new Map();
  async function read(path) {
    const document = await db.doc(path).get();
    dependencies.set(path, document.updateTime);
    return document.data();
  }
  function add(field, value) {
    if (missing(data[field]) && value != null && value !== "") patch[field] = value;
  }
  function resolve(label, ...values) {
    const ids = [...new Set(values.filter((value) => !missing(value)))];
    if (ids.length > 1 || ids.some((value) => !isId(value))) {
      issues.push(`Invalid or conflicting ${label}`);
      return null;
    }
    return ids[0] ?? null;
  }

  let order;
  if (orderChildren.has(collection)) {
    const orderId = data.orderId ?? (collection === "codCollections" ? snapshot.id : null);
    if (isId(orderId)) order = await read(`orders/${orderId}`);
    if (!order) issues.push("Order parent missing or invalid");
  }
  const branchId = resolve("branch reference", data.branchId, data.branch_id,
    order?.branchId, order?.branch_id,
    ["branches", "branchMetrics"].includes(collection) ? snapshot.id : null);
  const branch = collection === "branches" ? data :
    branchId ? await read(`branches/${branchId}`) : null;
  if (branchId && !branch) issues.push("Branch parent missing");
  const restaurantId = resolve("restaurant reference", data.restaurantId, data.restaurant_id,
    branch?.restaurantId, branch?.restaurant_id, order?.restaurantId, order?.restaurant_id,
    collection === "restaurants" ? snapshot.id : null);
  const restaurant = collection === "restaurants" ? data :
    restaurantId ? await read(`restaurants/${restaurantId}`) : null;
  if (restaurantId && !restaurant) issues.push("Restaurant parent missing");

  let tenantId = resolve("tenant reference", data.tenantId, data.tenant_id,
    branch?.tenantId, branch?.tenant_id, restaurant?.tenantId, restaurant?.tenant_id,
    order?.tenantId, order?.tenant_id, collection === "tenants" ? snapshot.id : null);
  if (!tenantId && restaurant && restaurantId && !issues.length) {
    if (!hasTenants || await read(`tenants/${restaurantId}`)) tenantId = restaurantId;
  }
  if (tenantId && hasTenants && collection !== "tenants" && !await read(`tenants/${tenantId}`)) {
    issues.push("Tenant parent missing");
  }
  if (privilegedProfiles.has(collection)) {
    if (collection === "users" && !roles.has(data.role)) {
      issues.push("Missing or invalid user role. Verify against Auth before changing it.");
    }
    if (missing(data.branchId) && branchId) {
      issues.push("Legacy profile branch requires manual authorization review");
    }
  } else if (!issues.length) {
    if (branch && !lifecycleRoots.has(collection)) add("branchId", branchId);
    if (restaurant && collection !== "tenants") add("restaurantId", restaurantId);
  }
  if (!issues.length) add("tenantId", tenantId);
  if (!tenantId && !privilegedProfiles.has(collection)) issues.push("Tenant ownership unresolved");

  const legacyCreated = dateMillis(data.created_at);
  const legacyUpdated = dateMillis(data.updated_at);
  add("createdAt", collection === "orders"
    ? legacyCreated ?? snapshot.createTime.toMillis()
    : legacyCreated == null ? snapshot.createTime : data.created_at);
  add("updatedAt", legacyUpdated == null ? snapshot.updateTime : data.updated_at);
  if (lifecycleRoots.has(collection) && missing(data.status)) {
    if (typeof data.isActive === "boolean" || data.isActive === 0 || data.isActive === 1) {
      add("status", data.isActive ? "active" : "inactive");
    } else {
      issues.push("Lifecycle status unresolved");
    }
  }
  if (["users", "riders", "orders", "chats", "riderAssignments"].includes(collection) &&
      missing(data.status)) issues.push("Status requires manual verification");
  return { patch, issues, dependencies };
}

function counts(entries) {
  const results = { scanned: 0, "needs-change": 0, migrated: 0, skipped: 0, failed: 0 };
  for (const entry of Object.values(entries)) {
    results.scanned++;
    if (entry.fields?.length) results["needs-change"]++;
    if (["migrated", "skipped", "failed"].includes(entry.status)) results[entry.status]++;
  }
  return results;
}

async function saveReport(path, report) {
  report.counts = counts(report.documents);
  const temporary = `${path}.${process.pid}.tmp`;
  await fs.writeFile(temporary, JSON.stringify(report, null, 2), { mode: 0o600 });
  await fs.rename(temporary, path);
}

function serializable(patch) {
  return Object.fromEntries(Object.entries(patch).map(([field, value]) => [
    field, value instanceof Timestamp
      ? { type: "timestamp", seconds: value.seconds, nanoseconds: value.nanoseconds }
      : value,
  ]));
}

async function migrate(db, { project, apply = false, reportPath, resume = false,
  batchSize = 100, delayMs = 200, backup = null }) {
  let report;
  if (resume) {
    report = JSON.parse(await fs.readFile(reportPath, "utf8"));
    if (report.project !== project || report.apply !== apply || report.backup !== backup || report.schemaVersion !== 1) {
      throw new Error("Report project, mode, backup or schema version does not match.");
    }
  } else {
    report = { schemaVersion: 1, project, apply, backup, checkpoints: {}, documents: {} };
    await fs.writeFile(reportPath, JSON.stringify(report), { flag: "wx", mode: 0o600 });
  }
  const hasTenants = !(await db.collection("tenants").limit(1).get()).empty;
  for (const collection of collections) {
    if (report.checkpoints[collection]?.done) continue;
    let cursor = report.checkpoints[collection]?.after;
    const query = db.collection(collection).orderBy(FieldPath.documentId());
    for (;;) {
      const page = await (cursor ? query.startAfter(cursor) : query).limit(batchSize).get();
      if (page.empty) {
        report.checkpoints[collection] = { done: true };
        await saveReport(reportPath, report);
        break;
      }
      const plans = new Map();
      for (const doc of page.docs) {
        const path = doc.ref.path;
        const previous = report.documents[path];
        try {
          const plan = await planDocument(db, doc, hasTenants);
          const fields = Object.keys(plan.patch);
          const priorIntent = previous?.intent ?? previous?.priorIntent;
          report.documents[path] = fields.length
            ? { status: "needs-change", fields, issues: plan.issues,
                intent: apply ? serializable(plan.patch) : undefined,
                priorIntent }
            : previous?.status === "migrated"
              ? previous
              : { status: "skipped", fields, issues: plan.issues, priorIntent };
          if (apply && fields.length) plans.set(doc, plan);
        } catch (error) {
          report.documents[path] = { ...previous, status: "failed", error: String(error.code ?? error.name) };
        }
      }
      await saveReport(reportPath, report);
      for (const [doc, plan] of plans) {
        const entry = report.documents[doc.ref.path];
        try {
          await db.runTransaction(async (tx) => {
            const latest = await tx.get(doc.ref);
            if (!latest.updateTime?.isEqual(doc.updateTime)) throw new Error("Document changed");
            for (const [path, version] of plan.dependencies) {
              const parent = await tx.get(db.doc(path));
              if (version ? !parent.updateTime?.isEqual(version) : parent.exists) {
                throw new Error("Ownership evidence changed");
              }
            }
            tx.update(doc.ref, plan.patch);
          });
          entry.status = "migrated";
        } catch (error) {
          entry.status = "failed";
          entry.error = String(error.code ?? error.message);
        }
      }
      if (page.docs.some((doc) => report.documents[doc.ref.path].status === "failed")) {
        await saveReport(reportPath, report);
        throw new Error("Page has failures. Review the JSON report and rerun with --resume.");
      }
      cursor = page.docs.at(-1).id;
      report.checkpoints[collection] = { after: cursor };
      await saveReport(reportPath, report);
      if (delayMs) await delay(delayMs);
    }
  }
  return report;
}

async function verifiedBackup(path, project) {
  if (!path) throw new Error("--apply requires --backup-operation=<gcloud export JSON file>");
  const operation = JSON.parse(await fs.readFile(path, "utf8"));
  const metadata = operation.metadata ?? {};
  const output = metadata.outputUriPrefix ?? operation.response?.outputUriPrefix;
  if (operation.done !== true || operation.error ||
      !operation.name?.startsWith(`projects/${project}/databases/(default)/operations/`) ||
      !metadata["@type"]?.endsWith(".ExportDocumentsMetadata") ||
      metadata.collectionIds?.length || metadata.namespaceIds?.length || !output?.startsWith("gs://")) {
    throw new Error("Expected a completed, full default-database export for the specified project.");
  }
  return operation.name;
}

async function run() {
  const args = process.argv.slice(2);
  const arg = (name) => args.find((value) => value.startsWith(`--${name}=`))?.slice(name.length + 3);
  const project = arg("project");
  const reportPath = arg("report");
  const apply = args.includes("--apply");
  const batchSize = Number(arg("batch-size") ?? 100);
  const delayMs = Number(arg("delay-ms") ?? 200);
  if (!project || !/^[a-z][a-z0-9-]+$/.test(project) || !reportPath ||
      !Number.isInteger(batchSize) || batchSize < 1 || batchSize > 500 ||
      !Number.isInteger(delayMs) || delayMs < 0 || delayMs > 60000) {
    throw new Error("Use --project=<id> --report=<path> [--batch-size=1..500] [--delay-ms=0..60000].");
  }
  if (process.env.FIRESTORE_EMULATOR_HOST && (!project.startsWith("demo-") || apply)) {
    throw new Error("CLI emulator runs are read-only and require a demo project ID.");
  }
  const backup = apply ? await verifiedBackup(arg("backup-operation"), project) : null;
  const app = initializeApp({ projectId: project });
  try {
    const report = await migrate(getFirestore(app), {
      project, apply, reportPath, batchSize, delayMs, backup, resume: args.includes("--resume"),
    });
    console.log(JSON.stringify(report.counts));
  } finally {
    await deleteApp(app);
  }
}

module.exports = { migrate, verifiedBackup };
if (require.main === module) {
  run().catch((error) => { console.error(error.message); process.exitCode = 1; });
}
