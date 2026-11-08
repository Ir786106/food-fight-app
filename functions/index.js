const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

admin.initializeApp();
const db = admin.firestore();

// Provider credentials must be injected into the server-side runtime environment.
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || null;
const TWILIO_SID = process.env.TWILIO_SID || null;
const TWILIO_TOKEN = process.env.TWILIO_TOKEN || null;
const TWILIO_FROM = process.env.TWILIO_FROM || "";

let sgMail = null;
if (SENDGRID_API_KEY) {
  try {
    sgMail = require("@sendgrid/mail");
    sgMail.setApiKey(SENDGRID_API_KEY);
  } catch (err) {
    console.warn("SendGrid initialization warning:", err.message);
  }
}

let twilioClient = null;
if (TWILIO_SID && TWILIO_TOKEN && TWILIO_FROM) {
  try {
    twilioClient = require("twilio")(TWILIO_SID, TWILIO_TOKEN);
  } catch (err) {
    console.warn("Twilio initialization warning:", err.message);
  }
}

/**
 * Fetch platform system settings to inspect notification master switches
 */
async function getSystemSettings() {
  try {
    const doc = await db.collection("settings").doc("global_settings").get();
    if (doc.exists) {
      return doc.data();
    }
  } catch (err) {
    console.error("Error reading global settings:", err);
  }
  return {
    emailNotificationsEnabled: true,
    smsNotificationsEnabled: true,
    pushNotificationsEnabled: true,
    orderCancellationWindowMinutes: 10,
    loyaltyEarnRate: 100,
    defaultDeliveryFee: 150,
  };
}

/**
 * Send SMS notification via Twilio or Pakistani SMS Gateway
 */
async function sendSmsNotification(phone, message) {
  if (!phone || !phone.trim()) {
    console.log("No valid phone number provided for SMS.");
    return false;
  }

  // Format Pakistani mobile number e.g. 03001234567 -> +923001234567
  let formattedPhone = phone.trim().replace(/\s+/g, "").replace(/-/g, "");
  if (formattedPhone.startsWith("0")) {
    formattedPhone = "+92" + formattedPhone.substring(1);
  } else if (!formattedPhone.startsWith("+")) {
    formattedPhone = "+92" + formattedPhone;
  }

  if (twilioClient) {
    try {
      await twilioClient.messages.create({
        body: message,
        from: TWILIO_FROM,
        to: formattedPhone,
      });
      console.log('SMS dispatched.');
      return true;
    } catch (err) {
      console.error('SMS dispatch failed:', err.code);
      return false;
    }
  } else {
    console.warn("SMS provider is not configured; notification was not sent.");
    return false;
  }
}

/**
 * Send Email confirmation/invoice via SendGrid / SMTP
 */
async function sendEmailNotification(toEmail, subject, htmlContent) {
  if (!toEmail || !toEmail.includes("@")) {
    console.log("No valid email provided for receipt.");
    return false;
  }

  if (sgMail) {
    try {
      await sgMail.send({
        to: toEmail,
        from: "orders@foodfight.pk",
        subject: subject,
        html: htmlContent,
      });
      console.log(`Email dispatched to ${toEmail}`);
      return true;
    } catch (err) {
      console.error(`SendGrid email error to ${toEmail}:`, err);
      return false;
    }
  } else {
    console.warn("Email provider is not configured; notification was not sent.");
    return false;
  }
}

/**
 * Send FCM Push Notification to Customer
 */
async function sendPushNotification(customerId, title, body, orderId) {
  try {
    const userDoc = await db.collection("users").doc(customerId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        orderId: orderId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    await admin.messaging().send(message);
    console.log(`Push notification sent to customer ${customerId}`);
  } catch (err) {
    console.error(`Error sending push to customer ${customerId}:`, err);
  }
}

/** Monetary values are calculated in integer paisa, never from client prices. */
function fail(code, message, details) {
  throw new functions.https.HttpsError(code, message, details);
}
function cents(value, label = "price") {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0 || parsed > 100000000) {
    fail("failed-precondition", `Invalid ${label}. Please contact the restaurant.`);
  }
  return Math.round(parsed * 100);
}
function enabled(value) { return value !== false && value !== 0; }
function millis(value) {
  if (value == null) return null;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (typeof value === "number") return value;
  return Date.parse(value);
}
function validId(value, label) {
  if (typeof value !== "string" || !value.trim() || value.length > 160 || value.includes("/")) {
    fail("invalid-argument", `A valid ${label} is required.`);
  }
  return value.trim();
}
function activeInBranch(data, branchId, label) {
  if (!enabled(data.isActive) || !enabled(data.isAvailable) ||
      (data.branchId && data.branchId !== branchId) ||
      (data.branch_id && data.branch_id !== branchId)) {
    fail("failed-precondition", `${label} is unavailable at this branch.`);
  }
}
function discountPrice(data) {
  const base = cents(data.price ?? 0);
  const discount = Number(data.discount ?? 0);
  if (!Number.isFinite(discount) || discount < 0 || discount > 100) {
    fail("failed-precondition", "Invalid menu discount.");
  }
  return Math.round(base * (1 - discount / 100));
}
function distanceKm(aLat, aLng, bLat, bLng) {
  const radians = (degrees) => degrees * Math.PI / 180;
  const dLat = radians(bLat - aLat);
  const dLng = radians(bLng - aLng);
  const a = Math.sin(dLat / 2) ** 2 +
      Math.cos(radians(aLat)) * Math.cos(radians(bLat)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Authoritative order placement. Every dependent document is read inside the
 * transaction before any write. A durable request ID makes network retries safe.
 */
async function checkout(input, context, quoteOnly) {
  if (!context.auth) fail("unauthenticated", "Sign in to place your order.");
  const data = input || {};
  const customerId = context.auth.uid;
  const requestId = quoteOnly ? null : validId(data.requestId, "checkout request");
  const branchId = validId(data.branchId, "branch");
  if (!Array.isArray(data.items) || !data.items.length || data.items.length > 100) {
    fail("invalid-argument", "Your cart must contain between 1 and 100 lines.");
  }
  const deliveryAddress = String(data.deliveryAddress || "").trim();
  if (deliveryAddress.length < 8 || deliveryAddress.length > 1000) {
    fail("invalid-argument", "Enter a complete delivery address.");
  }
  const customerPhone = String(data.customerPhone || "").replace(/[\s()-]/g, "");
  if (!/^(03\d{9}|\+923\d{9})$/.test(customerPhone)) {
    fail("invalid-argument", "Enter a valid Pakistani mobile number.");
  }
  const paymentMethod = String(data.paymentMethod || "Cash on Delivery");
  if (paymentMethod !== "Cash on Delivery") {
    fail("invalid-argument", "Choose cash on delivery.");
  }
  const tokens = data.tokensRedeemed ?? data.tokensUsed ?? 0;
  if (!Number.isSafeInteger(tokens) || tokens < 0) {
    fail("invalid-argument", "Invalid loyalty token amount.");
  }
  if (tokens > 0 && data.couponId) {
    fail("invalid-argument", "Choose either loyalty tokens or a coupon.");
  }
  const hash = (value) => require("node:crypto").createHash("sha256").update(value).digest("hex");
  const orderId = quoteOnly ? null : hash(customerId + ":" + requestId);
  const fingerprint = hash(JSON.stringify({
    items: data.items, branchId, deliveryAddress, customerPhone, paymentMethod,
    tokens, couponId: data.couponId || null, areaId: data.deliveryAreaId || null,
    addressId: data.addressId || null, clientTotal: data.clientTotal,
  }));
  const orderRef = quoteOnly ? null : db.collection("orders").doc(orderId);
  return db.runTransaction(async (transaction) => {
    const profile = (await transaction.get(db.collection("users").doc(customerId))).data();
    if (profile && ((profile.isActive != null && ![true, 1, "true", "1"].includes(profile.isActive)) ||
        profile.status === "blocked" || profile.isBlocked === true)) {
      fail("permission-denied", "This account cannot place orders.");
    }
    const existing = orderRef && await transaction.get(orderRef);
    if (existing?.exists) {
      if (existing.data().requestFingerprint !== fingerprint) {
        fail("failed-precondition", "This checkout request was already used. Refresh your cart.");
      }
      return { success: true, orderId, order: existing.data() };
    }
    const now = Date.now();
    const settingsSnap = await transaction.get(db.collection("settings").doc("global_settings"));
    const settings = settingsSnap.exists ? settingsSnap.data() : {};
    if (!enabled(settings.isStoreOpen) || settings.maintenanceMode === true) {
      fail("failed-precondition", "The restaurant is not accepting orders right now.");
    }
    if (paymentMethod === "Cash on Delivery" && settings.allowCashOnDelivery === false) {
      fail("failed-precondition", "Cash on delivery is currently unavailable.");
    }
    const branchRef = db.collection("branches").doc(branchId);
    const branchSnap = await transaction.get(branchRef);
    if (!branchSnap.exists || (branchSnap.data().status || "active") !== "active") {
      fail("failed-precondition", "Choose an active kitchen.");
    }
    const branch = branchSnap.data();
    let area = null;
    if (data.deliveryAreaId) {
      const areaSnap = await transaction.get(db.collection("deliveryAreas").doc(validId(data.deliveryAreaId, "delivery area")));
      if (!areaSnap.exists) fail("failed-precondition", "Choose a valid delivery area.");
      area = areaSnap.data();
      activeInBranch(area, branchId, "Delivery area");
    } else {
      fail("failed-precondition", "Select your delivery area before placing an order.");
    }
    if (data.addressId) {
      const addressSnap = await transaction.get(db.collection("addresses").doc(validId(data.addressId, "address")));
      if (!addressSnap.exists || addressSnap.data().userId !== customerId) {
        fail("permission-denied", "This saved address is unavailable.");
      }
      const address = addressSnap.data();
      const coordinates = [branch.latitude, branch.longitude, address.latitude, address.longitude];
      if (coordinates.every((v) => typeof v === "number" && Number.isFinite(v)) &&
          distanceKm(...coordinates) > Number(branch.deliveryRadiusKm ?? 10)) {
        fail("failed-precondition", "Your address is outside this kitchen's delivery coverage.");
      }
    }
    const documents = new Map();
    const stockDemand = new Map();
    async function menuDocument(id) {
      if (documents.has(id)) return documents.get(id);
      let snapshot = await transaction.get(db.collection("menuItems").doc(id));
      if (!snapshot.exists) snapshot = await transaction.get(db.collection("menu_items").doc(id));
      if (!snapshot.exists) fail("not-found", "A menu item is no longer available. Refresh your cart.");
      const result = { ref: snapshot.ref, data: snapshot.data() };
      activeInBranch(result.data, branchId, result.data.name || "Menu item");
      documents.set(id, result);
      return result;
    }
    function reserveStock(document, quantity) {
      const field = ["stockQuantity", "stock"].find((key) => typeof document.data[key] === "number");
      if (!field) return; // Existing menus without stock tracking remain supported.
      const key = document.ref.path;
      const entry = stockDemand.get(key) || { ...document, field, quantity: 0 };
      entry.quantity += quantity;
      if (!Number.isSafeInteger(document.data[field]) || document.data[field] < entry.quantity) {
        fail("failed-precondition", `${document.data.name || document.data.title || "An item"} is out of stock.`);
      }
      stockDemand.set(key, entry);
    }
    const verifiedItems = [];
    let subtotal = 0;
    for (const requested of data.items) {
      if (!requested || typeof requested !== "object" || Array.isArray(requested) ||
          (requested.selectedAddons != null &&
            (!Array.isArray(requested.selectedAddons) || requested.selectedAddons.some(
              (addon) => typeof addon !== "string" && typeof addon?.name !== "string")))) {
        fail("invalid-argument", "Invalid checkout item or extra.");
      }
      const id = validId(requested.id || requested.foodId, "menu item");
      const quantity = requested.quantity;
      if (!Number.isSafeInteger(quantity) || quantity < 1 || quantity > 99) {
        fail("invalid-argument", "Item quantities must be between 1 and 99.");
      }
      let itemData;
      let unitPrice;
      let selectedVariant = null;
      let selectedSize = requested.selectedSize || null;
      let selectedAddons = [];
      if (id.startsWith("deal_")) {
        const dealSnap = await transaction.get(db.collection("deals").doc(id.substring(5)));
        if (!dealSnap.exists) fail("not-found", "This deal is no longer available.");
        itemData = dealSnap.data();
        activeInBranch(itemData, branchId, itemData.title || "Deal");
        // Business calendar uses Pakistan time, independent of the server timezone.
        const weekday = new Date(now + 5 * 60 * 60 * 1000).getUTCDay() || 7;
        if ((millis(itemData.startDate) != null && now < millis(itemData.startDate)) ||
            (millis(itemData.endDate) != null && now > millis(itemData.endDate)) ||
            (itemData.activeDays?.length && !itemData.activeDays.includes(weekday))) {
          fail("failed-precondition", "This deal has expired or is unavailable today.");
        }
        if (requested.selectedAddons?.length) fail("invalid-argument", "Deal extras are not available.");
        unitPrice = cents(itemData.dealPrice ?? itemData.price);
        selectedSize = "Bundle Deal";
        reserveStock({ ref: dealSnap.ref, data: itemData }, quantity);
        for (const bundle of itemData.bundleItems || []) {
          const bundleId = validId(bundle.menuItemId || bundle.itemId, "bundle item");
          const bundleQuantity = bundle.quantity ?? 1;
          if (!Number.isSafeInteger(bundleQuantity) || bundleQuantity < 1) {
            fail("failed-precondition", "This deal needs to be updated by the restaurant.");
          }
          reserveStock(await menuDocument(bundleId), quantity * bundleQuantity);
        }
      } else {
        const document = await menuDocument(id);
        itemData = document.data;
        reserveStock(document, quantity);
        const variants = Array.isArray(itemData.variants) ? itemData.variants : [];
        if (variants.length) {
          selectedVariant = variants.find((v) => String(v.label).toLowerCase() === String(selectedSize).toLowerCase());
          if (!selectedVariant) fail("failed-precondition", `Choose an available size for ${itemData.name}.`);
          unitPrice = discountPrice(selectedVariant);
          selectedSize = selectedVariant.label;
        } else if (itemData.sizePrices && Object.keys(itemData.sizePrices).length) {
          const size = Object.keys(itemData.sizePrices).find((label) => label.toLowerCase() === String(selectedSize).toLowerCase());
          if (!size) fail("failed-precondition", `Choose an available size for ${itemData.name}.`);
          unitPrice = cents(itemData.sizePrices[size]);
          selectedSize = size;
        } else {
          if (selectedSize) fail("failed-precondition", "An item's options changed. Remove it and add it again.");
          unitPrice = discountPrice(itemData);
        }
        const addons = Array.isArray(itemData.addons) ? itemData.addons : [];
        const selectedNames = new Set();
        for (const requestedAddon of requested.selectedAddons || []) {
          const name = String(requestedAddon.name || requestedAddon).toLowerCase();
          const addon = addons.find((candidate) => String(candidate.name).toLowerCase() === name);
          if (!addon || selectedNames.has(name)) fail("failed-precondition", "An extra is unavailable or duplicated.");
          selectedNames.add(name);
          const price = cents(addon.price);
          unitPrice += price;
          selectedAddons.push({ name: addon.name, price: price / 100 });
        }
      }
      const lineTotal = unitPrice * quantity;
      subtotal += lineTotal;
      const food = {
        id, name: itemData.name || itemData.title || "Food item",
        description: itemData.description || "", price: unitPrice / 100,
        imageUrl: itemData.imageUrl || null, imageEmoji: "",
        category: itemData.categoryId || itemData.category || "Deals",
        branchId, restaurantId: itemData.restaurantId || branchId,
        rating: Number(itemData.rating || 0), reviewCount: Number(itemData.reviewCount || 0),
        isAvailable: true, prepTimeMinutes: Number(itemData.prepTimeMinutes || 0),
      };
      verifiedItems.push({
        food, quantity, note: String(requested.note || "").trim().slice(0, 500),
        selectedSize, selectedVariant, selectedAddons,
        unitPrice: unitPrice / 100, totalPrice: lineTotal / 100,
      });
    }
    let deliveryFee = cents(area?.deliveryCharge ?? area?.deliveryFee ??
      branch.deliveryFee ?? settings.defaultDeliveryCharge ?? settings.defaultDeliveryFee ?? 150);
    if (Number(settings.freeDeliveryThreshold) > 0 && subtotal >= cents(settings.freeDeliveryThreshold)) deliveryFee = 0;
    let couponDiscount = 0;
    let couponRef = null;
    let coupon = null;
    if (data.couponId) {
      couponRef = db.collection("coupons").doc(validId(data.couponId, "coupon"));
      const couponSnap = await transaction.get(couponRef);
      if (!couponSnap.exists) fail("failed-precondition", "This coupon no longer exists.");
      coupon = couponSnap.data();
      activeInBranch(coupon, branchId, "Coupon");
      if (now < millis(coupon.validFrom) || now > millis(coupon.validUntil) ||
          (coupon.usageLimit > 0 && Number(coupon.usageCount || 0) >= coupon.usageLimit) ||
          subtotal < cents(coupon.minimumOrder || 0)) {
        fail("failed-precondition", "This coupon has expired or its requirements are not met.");
      }
      if (coupon.type === "free_delivery") deliveryFee = 0;
      else if (coupon.type === "percentage") {
        const percentage = Number(coupon.value);
        if (!Number.isFinite(percentage) || percentage < 0 || percentage > 100) fail("failed-precondition", "Invalid coupon discount.");
        couponDiscount = Math.round(subtotal * percentage / 100);
        if (Number(coupon.maximumDiscount) > 0) couponDiscount = Math.min(couponDiscount, cents(coupon.maximumDiscount));
      } else if (coupon.type === "fixed") couponDiscount = cents(coupon.value);
      else fail("failed-precondition", "This coupon type is unavailable.");
      couponDiscount = Math.min(couponDiscount, subtotal);
    }
    const tokenValue = cents(settings.loyaltyRedeemRate ?? 1, "loyalty redemption rate");
    const accountRef = db.collection("loyaltyAccounts").doc(customerId);
    let account = null;
    let loyaltyDiscount = 0;
    if (tokens > 0) {
      if (tokenValue <= 0 || tokens < Number(settings.minTokensToRedeem ?? 1) || tokens * tokenValue > subtotal) {
        fail("failed-precondition", "Adjust your loyalty tokens to match the available discount.");
      }
      const accountSnap = await transaction.get(accountRef);
      account = accountSnap.exists ? accountSnap.data() : {};
      if (Number(account.balance || 0) < tokens) fail("failed-precondition", "Your token balance changed. Reduce the tokens and retry.");
      loyaltyDiscount = tokens * tokenValue;
    }
    const total = subtotal + deliveryFee - couponDiscount - loyaltyDiscount;
    if (quoteOnly) {
      return { ok: true, data: {
        subtotal: subtotal / 100,
        deliveryFee: deliveryFee / 100,
        discount: (couponDiscount + loyaltyDiscount) / 100,
        total: total / 100,
      } };
    }
    const orderNumber = `FF-${orderId.substring(0, 10).toUpperCase()}`;
    const order = {
      id: orderId, requestFingerprint: fingerprint, orderNumber, customerId,
      customerName: String(data.customerName || "Customer").trim().slice(0, 100),
      customerPhone, branchId, restaurantName: branch.name || "Food Fight",
      deliveryAddress, deliveryAreaId: data.deliveryAreaId, addressId: data.addressId || null,
      items: verifiedItems, subtotal: subtotal / 100,
      deliveryCharge: deliveryFee / 100, deliveryFee: deliveryFee / 100,
      couponId: data.couponId || null, couponDiscount: couponDiscount / 100,
      discount: (couponDiscount + loyaltyDiscount) / 100,
      tokensDiscount: loyaltyDiscount / 100, loyaltyDiscount: loyaltyDiscount / 100,
      tokensUsed: tokens, tokensRedeemed: tokens, total: total / 100,
      paymentMethod, paymentStatus: "pending", status: "pending",
      statusHistory: [{ status: "pending", timestamp: now, actorId: customerId }],
      inventoryReservations: [...stockDemand.values()].map(entry => ({path:entry.ref.path, field:entry.field, quantity:entry.quantity})),
      verifiedByServer: true, createdAt: now, updatedAt: now,
    };
    if (data.clientTotal == null || cents(data.clientTotal) !== total) {
      fail("failed-precondition", "Prices or delivery fees changed. Review the updated total and place your order again.",
        { reason: "price-changed", order, tokenValue: tokenValue / 100 });
    }
    // All reads are complete. The following writes commit or fail together.
    if (tokens > 0) {
      const balanceAfter = Number(account.balance) - tokens;
      transaction.update(accountRef, {
        balance: balanceAfter, totalRedeemed: Number(account.totalRedeemed || 0) + tokens, updatedAt: now,
      });
      transaction.set(db.collection("loyaltyTransactions").doc(`redeem_${orderId}`), {
        userId: customerId, type: "redeem", amount: -tokens, balanceAfter, orderId,
        description: `Redeemed on order #${orderNumber}`, createdAt: now,
      });
    }
    for (const entry of stockDemand.values()) {
      transaction.update(entry.ref, { [entry.field]: entry.data[entry.field] - entry.quantity, updatedAt: now });
    }
    if (couponRef) transaction.update(couponRef, { usageCount: Number(coupon.usageCount || 0) + 1, updatedAt: now });
    transaction.set(orderRef, order);
    transaction.update(branchRef, {
      totalOrders: Number(branch.totalOrders || 0) + 1,
      totalRevenue: (cents(branch.totalRevenue || 0) + total) / 100,
      updatedAt: now,
    });
    transaction.set(db.collection("notifications").doc(`order_${orderId}_placed`), {
      userId: customerId, type: "order", referenceId: orderId, isRead: false,
      title: "Order placed", message: `Order #${orderNumber} has been sent to the kitchen.`, createdAt: now,
    });
    transaction.set(db.collection("notifications").doc(`admin_${orderId}_placed`), {
      userId: `branch_${branchId}`, branchId, type: "order", referenceId: orderId, isRead: false,
      title: "New order", message: `Order #${orderNumber} is waiting for acceptance.`, createdAt: now,
    });
    transaction.set(db.collection("auditLogs").doc(`placed_${orderId}`), {
      action: "order_placed_secure", targetEntity: "orders", targetId: orderId,
      branchId, actorId: customerId, timestamp: now,
    });
    return { success: true, orderId, order };
  });
}

exports.createSignedImageUpload = functions.runWith({ secrets: ["SUPABASE_SERVICE_ROLE_KEY"] }).https.onCall(
  require("./signed_image_upload").signedImageUpload({
    db, fail, validId,
    config: () => ({ url: process.env.SUPABASE_URL, key: process.env.SUPABASE_SERVICE_ROLE_KEY }),
  }),
);

exports.completePhoneProfile = functions.https.onCall(async (_, context) => {
  const token = context.auth?.token;
  const phone = token?.phone_number;
  if (token?.firebase?.sign_in_provider !== "phone" || !/^\+923\d{9}$/.test(phone || "")) {
    fail("permission-denied", "Verify a Pakistani mobile number first.");
  }
  if (token.role && token.role !== "customer") {
    fail("permission-denied", "Use your staff sign-in method.");
  }
  const uid = context.auth.uid;
  const account = await admin.auth().getUser(uid);
  if (account.disabled || account.phoneNumber !== phone ||
      (account.customClaims?.role && account.customClaims.role !== "customer")) {
    fail("permission-denied", "This account cannot sign in.");
  }
  const ref = db.collection("users").doc(uid);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (snapshot.exists) {
      const profile = snapshot.data();
      if (profile.role !== "customer" || profile.isBlocked === true ||
          profile.status === "blocked" ||
          (profile.isActive != null && ![true, 1, "true", "1"].includes(profile.isActive))) {
        fail("permission-denied", "This account cannot use customer phone sign-in.");
      }
      return;
    }
    if (account.providerData.some((provider) => provider.providerId !== "phone")) {
      fail("failed-precondition", "Account profile not found. Contact support.");
    }
    const timestamp = FieldValue.serverTimestamp();
    transaction.create(ref, {
      id: uid, name: "Customer", email: "", phone, role: "customer",
      isActive: true, createdAt: timestamp, updatedAt: timestamp,
    });
  });
  return { success: true };
});

exports.quoteOrder = functions.https.onCall((input, context) => checkout(input, context, true));
exports.placeOrder = functions.https.onCall((input, context) => checkout(input, context, false));

const mutateOrder = require("./order_lifecycle").orderLifecycle({
  db, fieldValue: FieldValue, fail, validId, cents, millis,
});
exports.mutateOrder = functions.https.onCall((data, context) => mutateOrder(data, context));

exports.dispatchReadyOrder = functions.firestore.document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    if (change.before.data().status === "ready" || change.after.data().status !== "ready") return;
    await mutateOrder({ action: "dispatch", orderId: context.params.orderId }, {}, true);
  });

exports.expireRiderOffers = functions.pubsub.schedule("every 1 minutes").onRun(async () => {
  const due = await db.collection("orders").where("offerExpiresAt", ">", 0)
    .where("offerExpiresAt", "<=", Date.now()).limit(100).get();
  for (const order of due.docs) {
    await mutateOrder({ action: "expire", orderId: order.id }, {}, true);
  }
});

/** Welcome rewards are configured and credited only by the trusted server. */
exports.claimWelcomeBonus = functions.https.onCall(async (_, context) => {
  if (!context.auth) fail("unauthenticated", "Sign in to collect your welcome tokens.");
  const userId = context.auth.uid;
  return db.runTransaction(async (transaction) => {
    const accountRef = db.collection("loyaltyAccounts").doc(userId);
    const ledgerRef = db.collection("loyaltyTransactions").doc(`welcome_${userId}`);
    const settingsSnap = await transaction.get(db.collection("settings").doc("global_settings"));
    const accountSnap = await transaction.get(accountRef);
    const ledgerSnap = await transaction.get(ledgerRef);
    const account = accountSnap.exists ? accountSnap.data() : {};
    if (ledgerSnap.exists || account.hasWelcomeBonus === true) return { success: true };
    const amount = Math.max(0, Math.floor(Number(settingsSnap.data()?.welcomeTokens ?? 50)));
    if (!Number.isFinite(amount)) fail("failed-precondition", "Welcome rewards are not configured correctly.");
    const now = Date.now();
    const balanceAfter = Number(account.balance || 0) + amount;
    transaction.set(accountRef, {
      userId, balance: balanceAfter, totalEarned: Number(account.totalEarned || 0) + amount,
      totalRedeemed: Number(account.totalRedeemed || 0), hasWelcomeBonus: true,
      createdAt: account.createdAt || now, updatedAt: now,
    }, { merge: true });
    transaction.set(ledgerRef, {
      userId, type: "bonus", amount, balanceAfter,
      description: "Welcome to Food Fight", createdAt: now,
    });
    return { success: true };
  });
});

/**
 * Trigger: On Order Created
 * Dispatches Push + Email Receipt + SMS Confirmation
 */
exports.onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const orderId = context.params.orderId;
    const order = snap.data();
    const settings = await getSystemSettings();

    console.log(`Processing new order trigger: ${orderId}`);

    // Second line of defense: Check if price tampering occurred on direct write
    if (!order.verifiedByServer && order.items && Array.isArray(order.items)) {
      try {
        let expectedSubtotal = 0;
        for (const it of order.items) {
          const itId = it.id || it.foodId;
          if (itId) {
            let doc = await db.collection("menu_items").doc(itId).get();
            if (!doc.exists) doc = await db.collection("menuItems").doc(itId).get();
            if (doc.exists) {
              const p = Number(doc.data().price || doc.data().startingPrice || 0);
              expectedSubtotal += p * (it.quantity || 1);
            }
          }
        }
        if (expectedSubtotal > 0 && Math.abs(expectedSubtotal - Number(order.subtotal || 0)) > 2) {
          console.error(`[Security Alert] Order ${orderId} subtotal tampering detected: submitted ${order.subtotal}, expected ${expectedSubtotal}. Cancelling.`);
          await snap.ref.update({
            status: "cancelled",
            cancellationReason: "Security: Order price mismatch detected",
            updatedAt: FieldValue.serverTimestamp(),
          });
          return;
        }
      } catch (checkErr) {
        console.warn(`Price check warning on order ${orderId}:`, checkErr);
      }
    }

    // 1. FCM Push Notification (Clean title, no glove emoji)
    if (settings.pushNotificationsEnabled !== false) {
      await sendPushNotification(
        order.customerId,
        "Order Confirmed!",
        `Your order #${order.orderNumber} (Rs. ${order.total}) has been received and sent to the kitchen.`,
        orderId
      );
    }

    // 2. Email Order Receipt
    if (settings.emailNotificationsEnabled !== false) {
      const userDoc = await db.collection("users").doc(order.customerId).get();
      const customerEmail = userDoc.exists ? userDoc.data().email : null;

      if (customerEmail) {
        const emailHtml = `
          <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
            <h2 style="color: #FFD504; background-color: #5C1318; padding: 12px; border-radius: 8px;">Food Fight Order Confirmed</h2>
            <p>Hi <strong>${order.customerName || "Valued Customer"}</strong>,</p>
            <p>Thank you for choosing Food Fight! We've received your order <strong>#${order.orderNumber}</strong>.</p>
            <hr style="border: 0; border-top: 1px solid #eee;" />
            <h3>Order Details:</h3>
            <p><strong>Total Amount:</strong> Rs. ${order.total}</p>
            <p><strong>Payment Method:</strong> ${order.paymentMethod}</p>
            <p><strong>Delivery Destination:</strong> ${order.deliveryAddress}</p>
            <hr style="border: 0; border-top: 1px solid #eee;" />
            <p style="font-size: 12px; color: #777;">You can track your order live anytime in the Food Fight app.</p>
          </div>
        `;
        await sendEmailNotification(customerEmail, `Food Fight Order Receipt #${order.orderNumber}`, emailHtml);
      }
    }

    // 3. SMS Alert (Pakistan Gateway / Twilio)
    if (settings.smsNotificationsEnabled !== false) {
      const phone = order.customerPhone;
      if (phone) {
        const smsMessage = `Food Fight: Order #${order.orderNumber} of Rs. ${order.total} confirmed! Kitchen is preparing your meal. Track live in app.`;
        await sendSmsNotification(phone, smsMessage);
      }
    }
  });

/**
 * Trigger: On Order Status Updated
 * Dispatches Push + Email + SMS on progress (Cooking, Out for Delivery, Delivered, Cancelled)
 */
exports.onOrderStatusUpdated = functions.runWith({failurePolicy: true}).firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const orderId = context.params.orderId;
    const before = change.before.data();
    const after = change.after.data();

    // Only fire if the status has changed
    if (before.status === after.status) return;

    const settings = await getSystemSettings();
    const newStatus = after.status;
    console.log(`Order ${orderId} status changed: ${before.status} -> ${newStatus}`);

    let statusTitle = "Order Update";
    let statusBody = `Your order #${after.orderNumber} is now ${newStatus}.`;

    switch (newStatus) {
      case "preparing":
        statusTitle = "Chefs Cooking Fresh Food";
        statusBody = `Your order #${after.orderNumber} is being cooked fresh in our kitchen!`;
        break;
      case "ready":
        statusTitle = "Food is Packed & Ready";
        statusBody = `Your order #${after.orderNumber} is packed and awaiting rider dispatch.`;
        break;
      case "outForDelivery":
        statusTitle = "Out for Delivery!";
        statusBody = `Rider has picked up your food and is on the way to your location.`;
        break;
      case "delivered":
        statusTitle = "Order Delivered! Enjoy your meal";
        statusBody = `Your meal has been delivered. Thank you for choosing Food Fight!`;
        break;
      case "cancelled":
        statusTitle = "Order Cancelled";
        statusBody = `Order #${after.orderNumber} was cancelled. ${after.cancellationReason ? `Reason: ${after.cancellationReason}` : ""}`;
        break;
    }

    // Status inbox trigger dispatches FCM once for this update.

    // 2. SMS (Critical alerts: outForDelivery, delivered, cancelled)
    if (settings.smsNotificationsEnabled !== false && ["outForDelivery", "delivered", "cancelled"].includes(newStatus)) {
      const phone = after.customerPhone;
      if (phone) {
        const smsMessage = `Food Fight: ${statusTitle} - ${statusBody}`;
        await sendSmsNotification(phone, smsMessage);
      }
    }

    // 3. Email (Delivered & Cancelled receipts)
    if (settings.emailNotificationsEnabled !== false && ["delivered", "cancelled"].includes(newStatus)) {
      const userDoc = await db.collection("users").doc(after.customerId).get();
      const customerEmail = userDoc.exists ? userDoc.data().email : null;

      if (customerEmail) {
        const emailHtml = `
          <div style="font-family: Arial, sans-serif; padding: 20px;">
            <h2 style="color: ${newStatus === "cancelled" ? "#D32F2F" : "#2E7D32"};">${statusTitle}</h2>
            <p>Hi <strong>${after.customerName || "Customer"}</strong>,</p>
            <p>${statusBody}</p>
            <p>Order Total: Rs. ${after.total}</p>
          </div>
        `;
        await sendEmailNotification(customerEmail, `Food Fight: ${statusTitle}`, emailHtml);
      }
    }

    // 4. Server-Side Automated Loyalty Management (Transaction-Safe & Idempotent)
    if (newStatus === "delivered" && after.customerId) {
      try {
        const earnRate = Number(settings.loyaltyEarnRate || 100);
        const totalAmount = Number(after.total || 0);
        const tokensToEarn = Math.floor(totalAmount / earnRate);

        if (tokensToEarn > 0) {
          const accountRef = db.collection("loyaltyAccounts").doc(after.customerId);
          // Idempotent document key prevents double-credit on retries
          const earnTxRef = db.collection("loyaltyTransactions").doc(`earn_${orderId}`);

          await db.runTransaction(async (t) => {
            const existingTx = await t.get(earnTxRef);
            if (existingTx.exists) {
              console.log(`Loyalty tokens already credited for order ${orderId}, skipping duplicate.`);
              return;
            }

            const accDoc = await t.get(accountRef);
            if (!accDoc.exists) {
              t.set(accountRef, {
                userId: after.customerId,
                balance: tokensToEarn,
                totalEarned: tokensToEarn,
                totalRedeemed: 0,
                createdAt: FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp(),
              });
            } else {
              t.update(accountRef, {
                balance: FieldValue.increment(tokensToEarn),
                totalEarned: FieldValue.increment(tokensToEarn),
                updatedAt: FieldValue.serverTimestamp(),
              });
            }

            t.set(earnTxRef, {
              id: earnTxRef.id,
              userId: after.customerId,
              amount: tokensToEarn,
              type: "earn",
              orderId: orderId,
              description: `Earned ${tokensToEarn} tokens for delivered order #${after.orderNumber}`,
              createdAt: FieldValue.serverTimestamp(),
            });
          });
          console.log(`Credited ${tokensToEarn} loyalty tokens to customer ${after.customerId} for order ${orderId}`);
        }
      } catch (loyaltyErr) {
        console.error(`Error processing loyalty rewards for delivered order ${orderId}:`, loyaltyErr);
        throw loyaltyErr;
      }
    } else if (newStatus === "cancelled" && after.customerId) {
      try {
        const tokensRedeemed = Number(after.tokensRedeemed ?? after.tokensUsed ?? 0);
        if (tokensRedeemed > 0) {
          const accountRef = db.collection("loyaltyAccounts").doc(after.customerId);
          // Idempotent document key prevents double-refund on retries
          const refundTxRef = db.collection("loyaltyTransactions").doc(`refund_${orderId}`);

          await db.runTransaction(async (t) => {
            const existingRefund = await t.get(refundTxRef);
            if (existingRefund.exists) {
              console.log(`Loyalty tokens already refunded for order ${orderId}, skipping duplicate.`);
              return;
            }

            t.update(accountRef, {
              balance: FieldValue.increment(tokensRedeemed),
              totalRedeemed: FieldValue.increment(-tokensRedeemed),
              updatedAt: FieldValue.serverTimestamp(),
            });

            t.set(refundTxRef, {
              id: refundTxRef.id,
              userId: after.customerId,
              amount: tokensRedeemed,
              type: "refund",
              orderId: orderId,
              description: `Refunded ${tokensRedeemed} redeemed tokens for cancelled order #${after.orderNumber}`,
              createdAt: FieldValue.serverTimestamp(),
            });
          });
          console.log(`Refunded ${tokensRedeemed} tokens to customer ${after.customerId} for cancelled order ${orderId}`);
        }

        // Write cancellation audit log entry
        await db.collection("auditLogs").add({
          action: "order_cancelled",
          targetEntity: "orders",
          targetId: orderId,
          branchId: after.branchId || "",
          actorId: after.customerId || "system",
          details: `Order #${after.orderNumber} cancelled. Reason: ${after.cancellationReason || "No reason specified"}`,
          timestamp: FieldValue.serverTimestamp(),
        });
      } catch (refundErr) {
        console.error(`Error refunding loyalty tokens for cancelled order ${orderId}:`, refundErr);
        throw refundErr;
      }
    }
  });

/**
 * Callable Function: Server-Side Custom Claims & Role Management (Super Admin Only)
 * Enforces server-side privilege control; clients cannot escalate privileges.
 */
exports.setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required to modify user roles."
    );
  }

  // Verify caller is super_admin (token claim or Firestore record)
  const callerClaims = context.auth.token || {};
  let isSuperAdmin = callerClaims.role === "super_admin";
  if (!isSuperAdmin) {
    const callerDoc = await db.collection("users").doc(context.auth.uid).get();
    if (callerDoc.exists && callerDoc.data().role === "super_admin") {
      isSuperAdmin = true;
    }
  }

  if (!isSuperAdmin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only Super Administrators can assign user roles and permissions."
    );
  }

  const { targetUid, role, branchId = null, permissions = [] } = data || {};
  if (!targetUid || typeof targetUid !== "string" || !targetUid.trim()) {
    throw new functions.https.HttpsError("invalid-argument", "Valid targetUid is required.");
  }

  const validRoles = ["super_admin", "admin", "sub_admin", "delivery_rider", "customer", "staff"];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid role '${role}'. Must be one of: ${validRoles.join(", ")}`
    );
  }

  // Set Firebase Custom Claims
  const newClaims = {
    role: role,
    branchId: branchId,
    permissions: Array.isArray(permissions) ? permissions : [],
  };
  await admin.auth().setCustomUserClaims(targetUid, newClaims);

  // Synchronize Firestore user record
  await db.collection("users").doc(targetUid).set(
    {
      role: role,
      branchId: branchId,
      permissions: newClaims.permissions,
      isAdmin: ["super_admin", "admin", "sub_admin", "staff"].includes(role),
      isSuperAdmin: role === "super_admin",
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // Server-side audit log
  await db.collection("auditLogs").add({
    action: "user_role_changed",
    targetEntity: "users",
    targetId: targetUid,
    branchId: branchId || "",
    actorId: context.auth.uid,
    details: `Role updated to '${role}' with branchId='${branchId}' by Super Admin`,
    timestamp: FieldValue.serverTimestamp(),
  });

  console.log(`[Audit] Role '${role}' set for user ${targetUid} by super_admin ${context.auth.uid}`);
  return { success: true, message: `Role '${role}' assigned successfully.` };
});

/**
 * Callable Function: Sensitive Action Audit Logger
 */
exports.recordServerAuditLog = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const { action, targetEntity, targetId, details, branchId = "" } = data || {};
  if (!action || !targetEntity) {
    throw new functions.https.HttpsError("invalid-argument", "action and targetEntity are required.");
  }

  const logRef = await db.collection("auditLogs").add({
    action: action,
    targetEntity: targetEntity,
    targetId: targetId || "",
    branchId: branchId,
    actorId: context.auth.uid,
    details: details || "",
    timestamp: FieldValue.serverTimestamp(),
  });

  return { success: true, logId: logRef.id };
});

/** Provision staff through Admin Auth; never create an unloginable random user ID. */
exports.provisionTeamMember = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
  const actorSnap = await db.collection('users').doc(context.auth.uid).get();
  const actor = actorSnap.data() || {};
  const superAdmin = actor.role === 'super_admin';
  const manager = actor.role === 'admin' && !actor.parentAdminId;
  if (!superAdmin && !manager) throw new functions.https.HttpsError('permission-denied', 'Only branch managers can manage team logins.');
  const role = data.role === 'rider' ? 'rider' : data.role === 'staff' ? 'staff' : null;
  if (!role) throw new functions.https.HttpsError('invalid-argument', 'Invalid team role.');
  const branchId = superAdmin ? (data.branchId || actor.branchId) : actor.branchId;
  if (!branchId) throw new functions.https.HttpsError('failed-precondition', 'Select a branch before creating staff.');
  const name = String(data.name || '').trim();
  const email = String(data.email || '').trim().toLowerCase();
  const phone = String(data.phone || '').replace(/[\s()-]/g, '');
  if (name.length < 2 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !/^(03\d{9}|\+923\d{9})$/.test(phone)) {
    throw new functions.https.HttpsError('invalid-argument', 'Enter a name, valid email and Pakistani mobile number.');
  }
  const allowed = ['orders','menu','categories','coupons','customers','delivery_areas','riders','reports','chats','reviews'];
  const permissions = Object.fromEntries(allowed.map(key => [key, data.permissions?.[key] === true]));
  let account;
  let created = false;
  if (data.userId) {
    account = await admin.auth().getUser(String(data.userId));
  } else {
    try { account = await admin.auth().getUserByEmail(email); }
    catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
    if (account && data.linkExisting !== true) throw new functions.https.HttpsError('already-exists', 'Email already exists. Choose link existing account.');
  }
  if (account) {
    const previous = (await db.collection('users').doc(account.uid).get()).data() || {};
    const existingRole = previous.role || 'customer';
    if ((!superAdmin && previous.branchId && previous.branchId !== branchId) ||
        !['customer', role, ...(role === 'rider' ? ['delivery_rider'] : ['sub_admin'])].includes(existingRole)) {
      throw new functions.https.HttpsError('permission-denied', 'This account cannot be linked to this team.');
    }
  } else {
    if (String(data.password || '').length < 8) throw new functions.https.HttpsError('invalid-argument', 'Use a password of at least 8 characters.');
    account = await admin.auth().createUser({email, password: data.password, displayName: name});
    created = true;
  }
  try {
    const userRef = db.collection('users').doc(account.uid);
    await db.runTransaction(async t => {
      const old = await t.get(userRef);
      const previous = old.data() || {};
      if ((!superAdmin && previous.branchId && previous.branchId !== branchId) ||
          (previous.role && !['customer',role,...(role === 'rider' ? ['delivery_rider'] : ['sub_admin'])].includes(previous.role))) {
        throw new functions.https.HttpsError('permission-denied', 'Account role changed. Reload and retry.');
      }
      t.set(userRef, {id: account.uid, uid: account.uid, name, email: account.email, phone,
        role, branchId, parentAdminId: context.auth.uid, permissions: role === 'staff' ? permissions : {},
        status: 'active', isActive: 1, ...(old.exists ? {} : {createdAt: Date.now()}), updatedAt: Date.now()}, {merge:true});
      if (role === 'rider') t.set(db.collection('riders').doc(account.uid), {
        id: account.uid, userId: account.uid, name, email: account.email, phone, branchId,
        vehicleType: String(data.vehicleType || 'Motorcycle'), vehicleNumber: String(data.vehicleNumber || ''),
        isActive: 1, ...(data.userId ? {} : {isOnline: 0}), updatedAt: Date.now(),
        ...(old.exists ? {} : {createdAt: Date.now(), totalDeliveries: 0, rating: 0}),
      }, {merge: true});
    });
    return {userId: account.uid};
  } catch (error) {
    if (created) await admin.auth().deleteUser(account.uid);
    throw error;
  }
});

// Deterministic inbox IDs make Firestore trigger retries safe.
async function inbox(id, userId, title, message, type, referenceId) {
  try {
    await db.collection('notifications').doc(id).create({id, userId, title, message, type, referenceId,
      isRead: 0, createdAt: FieldValue.serverTimestamp()});
  } catch (error) { if (error.code !== 6 && error.code !== 'already-exists') throw error; }
}
exports.notifyRiderAssignment = functions.runWith({failurePolicy:true}).firestore.document('orders/{orderId}').onUpdate(async (change, context) => {
  const before = change.before.data(), after = change.after.data();
  const id = context.params.orderId;
  if (before.riderId !== after.riderId) {
    if (after.riderId) await inbox(`assign_${context.eventId}`, after.riderId, 'New delivery assignment',
      `Order #${after.orderNumber || id} is ready for your acceptance.`, 'order', id);
    if (before.riderId) await inbox(`unassign_${context.eventId}`, before.riderId, 'Delivery reassigned',
      `Order #${after.orderNumber || id} is no longer assigned to you.`, 'order', id);
  }
  if (before.status !== after.status) {
    await inbox(`status_${context.eventId}`, after.customerId, 'Order update',
      `Order #${after.orderNumber || id}: ${after.status}`, 'order', id);
    if (after.status === 'cancelled' && after.riderId) await inbox(`cancel_${context.eventId}`, after.riderId,
      'Delivery cancelled', `Order #${after.orderNumber || id} was cancelled. Stop delivery.`, 'order', id);
  }
});
exports.notifyChatMessage = functions.runWith({failurePolicy:true}).firestore.document('chats/{chatId}/messages/{messageId}').onCreate(async (snap, context) => {
  const message = snap.data();
  const chat = (await snap.ref.parent.parent.get()).data();
  if (!chat) return;
  let recipients = [];
  if (message.senderRole === 'customer') {
    const users = await db.collection('users').where('branchId','==',chat.branchId).get();
    recipients = users.docs.filter(doc => {
      const u = doc.data();
      const permissions = u.permissions || {};
      return enabled(u.isActive) && (u.role === 'admin' && !u.parentAdminId ||
        ['staff','sub_admin','admin'].includes(u.role) &&
        (Array.isArray(permissions) ? permissions.includes('chats') || permissions.includes('manage_chats') : permissions.chats || permissions.manage_chats));
    }).map(doc => doc.id);
  } else recipients = [chat.customerId];
  await Promise.all(recipients.filter(uid => uid && uid !== message.senderId).map(uid =>
    inbox(`chat_${context.params.messageId}_${uid}`, uid, 'New support message',
      message.type === 'image' ? 'Photo attachment' : String(message.text || '').slice(0,200), 'chat', context.params.chatId)));
});
exports.pushInboxNotification = functions.firestore.document('notifications/{id}').onCreate(async snap => {
  const n = snap.data();
  const user = (await db.collection('users').doc(n.userId).get()).data();
  if (!user?.fcmToken) return;
  const settings = await getSystemSettings();
  if (settings.pushNotificationsEnabled === false) return;
  try {
    await admin.messaging().send({token:user.fcmToken, notification:{title:n.title,body:n.message},
      data:{type:n.type || 'general', referenceId:n.referenceId || '',
        ...(n.type === 'chat' ? {chatId:n.referenceId} : n.type === 'order' ? {orderId:n.referenceId} : {})}});
  } catch (error) {
    if (['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(error.code)) {
      await db.runTransaction(async t => {
        const ref=db.collection('users').doc(n.userId), fresh=await t.get(ref);
        if (fresh.data()?.fcmToken === user.fcmToken) t.update(ref,{fcmToken:FieldValue.delete()});
      });
    } else throw error;
  }
});

exports.reconcileTerminalOrder = functions.runWith({failurePolicy:true}).firestore.document('orders/{orderId}').onUpdate(async (change, context) => {
  const before = change.before.data(), order = change.after.data();
  if (before.status === order.status || !['cancelled','delivered'].includes(order.status)) return;
  const marker = db.collection('orderReconciliations').doc(`${order.status}_${context.params.orderId}`);
  await db.runTransaction(async t => {
    if ((await t.get(marker)).exists) return;
    const stocks=[];
    if (order.status === 'cancelled' && order.verifiedByServer) {
      for (const reservation of order.inventoryReservations || []) {
        const ref=db.doc(reservation.path), snap=await t.get(ref);
        if (snap.exists) stocks.push({ref,data:snap.data(),...reservation});
      }
    }
    const branchRef=order.branchId ? db.collection('branches').doc(order.branchId) : null;
    const branch=branchRef && order.status === 'cancelled' ? await t.get(branchRef) : null;
    const couponRef=order.couponId ? db.collection('coupons').doc(order.couponId) : null;
    const coupon=couponRef && order.status === 'cancelled' ? await t.get(couponRef) : null;
    const riderRef=order.riderId ? db.collection('riders').doc(order.riderId) : null;
    const rider=riderRef && order.status === 'delivered' ? await t.get(riderRef) : null;
    for(const stock of stocks) t.update(stock.ref,{[stock.field]:Number(stock.data[stock.field] || 0)+stock.quantity});
    if(branch?.exists && order.verifiedByServer) t.update(branchRef,{
      totalRevenue:Math.max(0,Number(branch.data().totalRevenue || 0)-Number(order.total || 0))});
    if(coupon?.exists && order.verifiedByServer) t.update(couponRef,{usageCount:Math.max(0,Number(coupon.data().usageCount || 0)-1)});
    if(rider?.exists) t.update(riderRef,{totalDeliveries:Number(rider.data().totalDeliveries || 0)+1});
    t.set(marker,{orderId:context.params.orderId,status:order.status,createdAt:FieldValue.serverTimestamp()});
  });
});

exports.submitOrderReview = functions.https.onCall(async (data, context) => {
  if (!context.auth) fail('unauthenticated','Sign in to review an order.');
  const orderId=validId(data.orderId,'order'), itemId=validId(data.itemId,'review target');
  const targetType=data.targetType === 'rider' ? 'rider' : 'item';
  const rating=Number(data.rating), reviewText=String(data.reviewText || '').trim();
  if (!Number.isInteger(rating) || rating < 1 || rating > 5 || reviewText.length > 2000) fail('invalid-argument','Choose a rating from 1 to 5 and a shorter comment.');
  const uid=context.auth.uid, id=require('crypto').createHash('sha256').update(`${uid}:${orderId}:${targetType}:${itemId}`).digest('hex');
  return db.runTransaction(async t => {
    const order=(await t.get(db.collection('orders').doc(orderId))).data();
    const user=(await t.get(db.collection('users').doc(uid))).data() || {};
    if (!order || order.customerId !== uid || order.status !== 'delivered') fail('permission-denied','Only your delivered orders can be reviewed.');
    if (targetType === 'rider' ? order.riderId !== itemId : !(order.items || []).some(item => (item.food?.id || item.menuItemId || item.foodId) === itemId)) {
      fail('invalid-argument','This item or rider does not belong to the order.');
    }
    const ref=db.collection('reviews').doc(id), previous=await t.get(ref);
    const review={id,userId:uid,orderId,itemId,targetType,rating,reviewText,branchId:order.branchId,
      userName:user.name || 'Customer',isHidden:previous.data()?.isHidden || false,
      createdAt:previous.data()?.createdAt || Date.now(),updatedAt:Date.now()};
    t.set(ref,review,{merge:true});
    return review;
  });
});
exports.aggregateReviewRatings = functions.runWith({failurePolicy:true}).firestore.document('reviews/{id}').onWrite(async change => {
  const data=change.after.exists ? change.after.data() : change.before.data();
  if (!data?.itemId) return;
  const type=data.targetType || 'item';
  if (!['item','rider'].includes(type)) return;
  const target=db.collection(type === 'rider' ? 'riders' : 'menuItems').doc(data.itemId);
  await db.runTransaction(async t => {
    if (!(await t.get(target)).exists) return;
    const snapshot=await t.get(db.collection('reviews').where('itemId','==',data.itemId));
    const rows=snapshot.docs.map(doc=>doc.data()).filter(r => !r.isHidden && (r.targetType || 'item') === type && Number(r.rating)>=1 && Number(r.rating)<=5);
    t.update(target,{rating:rows.length ? Math.round(rows.reduce((sum,r)=>sum+Number(r.rating),0)/rows.length*10)/10 : 0,reviewCount:rows.length});
  });
});
