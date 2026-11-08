const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const test = require("node:test");
const { runInNewContext } = require("node:vm");

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
  const db = {
    collection: (name) => ({ doc: (id) => ({ path: name + "/" + id }) }),
    async runTransaction(body) {
      const writes = [];
      const result = await body({
        get: async (ref) => {
          assert.equal(writes.length, 0, "Reads must precede writes");
          return { ref, exists: documents.has(ref.path), data: () => documents.get(ref.path) };
        },
        set: (ref, data) => writes.push(() => documents.set(ref.path, data)),
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