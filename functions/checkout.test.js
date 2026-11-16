const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const test = require("node:test");
const { runInNewContext } = require("node:vm");
const { privateMetrics } = require("./migrate_branch_metrics");

function setup() {
  const documents = new Map([
    ["users/customer", { isActive: true }],
    ["branches/kitchen", { status: "active" }],
    ["deliveryAreas/zone", { branchId: "kitchen", deliveryCharge: 25 }],
    ["menuItems/item", { branchId: "kitchen", price: 100.25, stock: 4 }],
    ["coupons/offer", { branchId: "kitchen", type: "fixed", value: 10,
      validFrom: 0, validUntil: Date.now() + 60000 }],
  ]);
  const account = { phoneNumber: "+923001234567", providerData: [{ providerId: "phone" }] };
  const firestore = () => db;
  firestore.FieldValue = { serverTimestamp: () => 1 };
  let autoId = 0;
  const snapshot = (path) => ({
    id: path.split("/").at(-1),
    exists: documents.has(path),
    data: () => documents.get(path),
    get: (key) => documents.get(path)?.[key],
  });
  const ref = (path) => ({ path, get: async () => snapshot(path) });
  function collection(name, filters = [], max = Infinity) {
    const query = {
      doc: (id = `auto-${++autoId}`) => ref(`${name}/${id}`),
      where: (field, op, value) => collection(name, [...filters, [field, value]], max),
      limit: (size) => collection(name, filters, size),
      orderBy: () => query,
      select: () => query,
      async get() {
        const docs = [...documents.keys()]
          .filter((path) => path.startsWith(`${name}/`) &&
            !path.slice(name.length + 1).includes("/") &&
            filters.every(([field, value]) => documents.get(path)[field] === value))
          .slice(0, max).map(snapshot);
        return { docs, empty: docs.length === 0 };
      },
    };
    return query;
  }
  const db = {
    collection,
    doc: ref,
    getAll: async (...refs) => refs.map(({ path }) => snapshot(path)),
    async runTransaction(body) {
      const writes = [];
      const result = await body({
        get: async (ref) => {
          assert.equal(writes.length, 0, "Reads must precede writes");
          if (!ref.path) return ref.get();
          return { ref, ...snapshot(ref.path) };
        },
        set: (ref, data) => writes.push(() => documents.set(ref.path, data)),
        delete: (ref) => writes.push(() => documents.delete(ref.path)),
        create: (ref, data) => writes.push(() => {
          assert.equal(documents.has(ref.path), false);
          documents.set(ref.path, data);
        }),
        update: (ref, data) => writes.push(() => {
          documents.set(ref.path, { ...documents.get(ref.path), ...data });
        }),
      });
      for (const write of writes) write();
      return result;
    },
  };
  class HttpsError extends Error {
    constructor(code, message, details) {
      super(message);
      Object.assign(this, { code, details });
    }
  }
  const document = () => ({ onCreate() {}, onUpdate() {}, onWrite() {} });
  const functions = {
    https: { onCall: (handler) => handler, HttpsError },
    firestore: { document },
    pubsub: { schedule: () => ({ onRun() {} }) },
    runWith: () => ({ firestore: { document }, https: { onCall: (handler) => handler } }),
  };
  const exports = {};
  runInNewContext(readFileSync(require.resolve("./index.js"), "utf8"), {
    exports,
    process: { env: {} },
    require: (name) => {
      if (name === "firebase-functions") return functions;
      if (name === "firebase-admin/firestore") return { FieldValue: firestore.FieldValue };
      if (name === "firebase-admin") return { initializeApp() {}, firestore, auth: () => ({ getUser: async () => account }) };
      return require(name);
    },
  });
  return {
    ...exports,
    documents,
    account,
    context: { auth: { uid: "customer" } },
    payload: {
      branchId: "kitchen",
      deliveryAreaId: "zone",
      deliveryAddress: "123 Test Street",
      customerPhone: "03001234567",
      couponId: "offer",
      items: [{ id: "item", quantity: 2, price: 1 }],
    },
  };
}

test("quotes server prices without creating orders or consuming stock and coupons", async () => {
  const { quoteOrder, documents, context, payload } = setup();
  const size = documents.size;
  const quote = await quoteOrder(payload, context);
  assert.equal(quote.data.subtotal, 200.50);
  assert.equal(quote.data.deliveryFee, 25);
  assert.equal(quote.data.discount, 10);
  assert.equal(quote.data.total, 215.50);
  assert.equal(documents.size, size);
  assert.equal(documents.get("menuItems/item").stock, 4);
  assert.equal(documents.get("coupons/offer").usageCount, undefined);
});

test("branch customer management only lists and restricts linked customers", async () => {
  const { manageBranchCustomers, quoteOrder, documents, context, payload } = setup();
  documents.set("users/manager", { role: "admin", branchId: "kitchen" });
  documents.set("users/staff", { role: "staff", branchId: "kitchen" });
  documents.set("users/customer", { role: "customer", phone: "03001234567", privateField: "hidden" });
  documents.set("users/foreign", { role: "customer", branchId: "other" });
  documents.set("orders/linked", { branchId: "kitchen", customerId: "customer" });
  documents.set("orders/foreign", { branchId: "other", customerId: "foreign" });
  const manager = { auth: { uid: "manager" } };
  await assert.rejects(manageBranchCustomers({ action: "list" }, { auth: { uid: "staff" } }),
    { code: "permission-denied" });
  const directory = await manageBranchCustomers({ action: "list", branchId: "other" }, manager);
  assert.equal(directory.branchId, "kitchen");
  assert.equal(directory.customers.length, 1);
  assert.equal(directory.customers[0].id, "customer");
  assert.equal(directory.customers[0].privateField, undefined);
  const setStatus = (customerId, active) =>
    manageBranchCustomers({ action: "setStatus", customerId, active }, manager);
  await assert.rejects(setStatus("foreign", false), { code: "permission-denied" });
  await setStatus("customer", false);
  await assert.rejects(quoteOrder(payload, context), { code: "permission-denied" });
  documents.set("branches/other", { status: "active" });
  documents.set("deliveryAreas/other-zone", { branchId: "other", deliveryCharge: 25 });
  documents.set("menuItems/other-item", { branchId: "other", price: 100.25, stock: 4 });
  const otherOrder = {
    ...payload, branchId: "other", deliveryAreaId: "other-zone", couponId: null,
    items: [{ id: "other-item", quantity: 1 }],
  };
  await quoteOrder(otherOrder, context);
  assert.equal(documents.get("users/customer").isActive, undefined);
  await setStatus("customer", true);
  await quoteOrder(payload, context);
});

test("rejects changed prices, then places and replays the confirmed order once", async () => {
  const { quoteOrder, placeOrder, documents, context, payload } = setup();
  const { data } = await quoteOrder(payload, context);
  await assert.rejects(placeOrder({
    ...payload, requestId: "underpaid", clientTotal: data.total - 0.01,
  }, context), { code: "failed-precondition" });
  documents.get("menuItems/item").price += 0.01;
  const request = { ...payload, requestId: "unique", clientTotal: data.total };
  await assert.rejects(placeOrder(request, context), {
    code: "failed-precondition",
  });
  assert.equal(documents.get("menuItems/item").stock, 4);
  assert.equal(documents.get("coupons/offer").usageCount, undefined);
  request.clientTotal = (await quoteOrder(payload, context)).data.total;
  const order = await placeOrder(request, context);
  assert.equal(order.order.total, 215.52);
  documents.get("menuItems/item").price += 5;
  assert.equal((await placeOrder(request, context)).orderId, order.orderId);
  assert.equal(documents.get("menuItems/item").stock, 2);
  assert.equal(documents.get("coupons/offer").usageCount, 1);
  assert.equal(documents.get("branches/kitchen").totalRevenue, undefined);
  assert.equal(documents.get("branchMetrics/kitchen").totalOrders, 1);
  assert.equal(documents.get("branchMetrics/kitchen").totalRevenue, 215.52);
  const notice = documents.get(`notifications/order_${order.orderId}_placed`);
  assert.equal(notice.messageKey, "orderPlaced");
  assert.equal(notice.orderNumber, order.order.orderNumber);
});

test("branch metric migration preserves private totals and legacy inputs", () => {
  assert.equal(privateMetrics({name: "Kitchen"}), null);
  assert.deepEqual(privateMetrics({revenue: 200, expenses: 20, orderCount: 3}, {
    totalRevenue: 350, totalOrders: 4,
  }), {
    totalRevenue: 350, totalOrders: 4, expenses: 20,
    legacyPublic: {revenue: 200, expenses: 20, orderCount: 3},
  });
});

test("rejects unauthenticated, inactive, malformed and non-COD checkout", async () => {
  const { quoteOrder, placeOrder, documents, context, payload } = setup();
  await assert.rejects(quoteOrder(payload, {}), { code: "unauthenticated" });
  await assert.rejects(quoteOrder({ ...payload, items: [null] }, context), {
    code: "invalid-argument",
  });
  await assert.rejects(quoteOrder({ ...payload, paymentMethod: "JazzCash" }, context), {
    code: "invalid-argument",
  });
  documents.get("users/customer").isActive = "false";
  await assert.rejects(quoteOrder(payload, context), { code: "permission-denied" });
  await assert.rejects(placeOrder({ ...payload, requestId: "unique" }, context), {
    code: "permission-denied",
  });
});

test("rejects a legacy menu item owned by another branch", async () => {
  const { quoteOrder, documents, context, payload } = setup();
  documents.set("menuItems/item", { branch_id: "other", price: 100 });
  await assert.rejects(quoteOrder(payload, context), { code: "failed-precondition" });
});
test("phone profile creation is customer-only and preserves existing profiles", async () => {
  const { completePhoneProfile, documents, account } = setup();
  const token = { firebase: { sign_in_provider: "phone" }, phone_number: account.phoneNumber };
  const context = { auth: { uid: "new-phone", token } };
  await assert.rejects(completePhoneProfile({}, {}), { code: "permission-denied" });
  await assert.rejects(completePhoneProfile({}, { auth: { ...context.auth, token: {
    ...token, firebase: { sign_in_provider: "password" },
  } } }), { code: "permission-denied" });
  await assert.rejects(completePhoneProfile({}, { auth: { ...context.auth, token: {
    ...token, role: "admin",
  } } }), { code: "permission-denied" });
  account.customClaims = { role: "staff" };
  await assert.rejects(completePhoneProfile({}, context), { code: "permission-denied" });
  delete account.customClaims;
  await completePhoneProfile({ role: "super_admin", phone: "+923099999999" }, context);
  const profile = documents.get("users/new-phone");
  assert.equal(profile.role, "customer");
  assert.equal(profile.phone, account.phoneNumber);
  profile.name = "Existing Customer";
  await completePhoneProfile({}, context);
  assert.equal(documents.get("users/new-phone").name, "Existing Customer");
  profile.isActive = false;
  await assert.rejects(completePhoneProfile({}, context), { code: "permission-denied" });
  profile.isActive = true;
  profile.role = "admin";
  await assert.rejects(completePhoneProfile({}, context), { code: "permission-denied" });
  documents.delete("users/new-phone");
  account.providerData.push({ providerId: "password" });
  await assert.rejects(completePhoneProfile({}, context), { code: "failed-precondition" });
  assert.equal(documents.has("users/new-phone"), false);
});
