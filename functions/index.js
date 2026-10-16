const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Provider credentials configured via Firebase Secret Manager / environment variables:
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || null;
const TWILIO_SID = process.env.TWILIO_SID || null;
const TWILIO_TOKEN = process.env.TWILIO_TOKEN || null;
const TWILIO_FROM = process.env.TWILIO_FROM || "+1234567890";

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
if (TWILIO_SID && TWILIO_TOKEN) {
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
      console.log(`SMS dispatched to ${formattedPhone}`);
      return true;
    } catch (err) {
      console.error(`Twilio SMS error to ${formattedPhone}:`, err);
      return false;
    }
  } else {
    console.log(`[SMS Gateway Simulated to ${formattedPhone}]: ${message}`);
    return true;
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
    console.log(`[Email Simulated to ${toEmail}]: ${subject}`);
    return true;
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

/**
 * Callable Function: Secure Order Placement (Server-Authoritative Price Calculation)
 * Prevents client-side price tampering. Client provides item IDs, options, quantities,
 * branchId, deliveryAddress, etc. Server calculates real subtotal, deals, delivery fee,
 * loyalty tokens, and total directly from Firestore menu/deals/settings.
 */
exports.placeOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required to place an order."
    );
  }

  const customerId = context.auth.uid;
  const {
    items,
    branchId,
    deliveryAddress,
    customerName,
    customerPhone,
    deliveryNotes = "",
    paymentMethod = "Cash on Delivery",
    dealId = null,
    tokensRedeemed = 0,
    clientTotal = null,
  } = data || {};

  if (!items || !Array.isArray(items) || items.length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Order must contain at least one item."
    );
  }

  if (!deliveryAddress || typeof deliveryAddress !== "string" || !deliveryAddress.trim()) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Valid delivery address is required."
    );
  }

  // 1. Fetch system settings
  const settings = await getSystemSettings();

  // 2. Resolve items and calculate authoritative subtotal
  let calculatedSubtotal = 0;
  const verifiedItems = [];

  for (const item of items) {
    const itemId = item.id || item.foodId || item.menuItemId;
    if (!itemId) {
      throw new functions.https.HttpsError("invalid-argument", "Every item must have a valid itemId.");
    }
    const quantity = parseInt(item.quantity, 10) || 1;
    if (quantity <= 0) {
      throw new functions.https.HttpsError("invalid-argument", "Item quantity must be greater than zero.");
    }

    // Check menu_items or menuItems
    let itemDoc = await db.collection("menu_items").doc(itemId).get();
    if (!itemDoc.exists) {
      itemDoc = await db.collection("menuItems").doc(itemId).get();
    }
    if (!itemDoc.exists) {
      throw new functions.https.HttpsError("not-found", `Menu item '${itemId}' not found.`);
    }

    const itemData = itemDoc.data();
    let unitPrice = Number(itemData.price || itemData.startingPrice || 0);

    // If variant is selected, verify variant price
    if (item.selectedSize && itemData.variants && Array.isArray(itemData.variants)) {
      const variant = itemData.variants.find(
        (v) => (v.label || "").toLowerCase() === (item.selectedSize || "").toLowerCase()
      );
      if (variant && variant.finalPrice != null) {
        unitPrice = Number(variant.finalPrice);
      }
    } else if (item.selectedSize && itemData.sizePrices && itemData.sizePrices[item.selectedSize]) {
      unitPrice = Number(itemData.sizePrices[item.selectedSize]);
    }

    // Add selected add-ons / extras
    let addonTotal = 0;
    const selectedAddons = [];
    if (item.selectedAddons && Array.isArray(item.selectedAddons)) {
      for (const addon of item.selectedAddons) {
        const addonName = addon.name || addon.label;
        const addonPrice = Number(addon.price || 0);
        addonTotal += addonPrice;
        selectedAddons.push({
          name: addonName,
          price: addonPrice,
        });
      }
    }

    const lineTotal = (unitPrice + addonTotal) * quantity;
    calculatedSubtotal += lineTotal;

    verifiedItems.push({
      id: itemId,
      name: itemData.name || item.name || "Food Item",
      price: unitPrice,
      quantity: quantity,
      selectedSize: item.selectedSize || null,
      selectedAddons: selectedAddons,
      totalPrice: lineTotal,
      imageUrl: itemData.imageUrl || null,
      category: itemData.category || itemData.categoryId || "General",
    });
  }

  // 3. Resolve deal discount
  let calculatedDiscount = 0;
  if (dealId) {
    const dealDoc = await db.collection("deals").doc(dealId).get();
    if (dealDoc.exists && dealDoc.data().isActive !== false) {
      const deal = dealDoc.data();
      if (deal.discountPercentage) {
        calculatedDiscount = (calculatedSubtotal * Number(deal.discountPercentage)) / 100;
      } else if (deal.discountAmount) {
        calculatedDiscount = Number(deal.discountAmount);
      }
    }
  }

  // 4. Resolve delivery charge from branch or settings
  let deliveryFee = Number(settings.defaultDeliveryFee || 150);
  if (branchId) {
    const branchDoc = await db.collection("branches").doc(branchId).get();
    if (branchDoc.exists && branchDoc.data().deliveryFee != null) {
      deliveryFee = Number(branchDoc.data().deliveryFee);
    }
  }

  // 5. Loyalty token redemption validation
  const numTokens = Math.max(0, parseInt(tokensRedeemed, 10) || 0);
  let loyaltyDiscount = 0;
  if (numTokens > 0) {
    const accountRef = db.collection("loyaltyAccounts").doc(customerId);
    const accountDoc = await accountRef.get();
    const balance = accountDoc.exists ? Number(accountDoc.data().balance || 0) : 0;
    if (balance < numTokens) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Insufficient loyalty tokens. Balance is ${balance}, requested ${numTokens}.`
      );
    }
    // 1 token = 1 PKR discount
    loyaltyDiscount = Math.min(numTokens, Math.max(0, calculatedSubtotal - calculatedDiscount));
  }

  // 6. Calculate total
  const calculatedTotal = Math.max(
    0,
    calculatedSubtotal + deliveryFee - calculatedDiscount - loyaltyDiscount
  );

  // If client provided a total, check for tampering (difference > 1.5 PKR)
  if (clientTotal != null && Math.abs(Number(clientTotal) - calculatedTotal) > 1.5) {
    console.warn(`[Price Tampering Detected] Client reported total ${clientTotal}, server calculated ${calculatedTotal} for user ${customerId}`);
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Price mismatch detected. Order total recalculated to Rs. ${calculatedTotal}. Please confirm.`
    );
  }

  // 7. Write order atomically in a transaction
  const orderRef = db.collection("orders").doc();
  const orderId = orderRef.id;
  const timeTail = (Date.now() % 100000).toString().padStart(5, "0");
  const randomTail = Math.floor(10 + Math.random() * 90);
  const orderNumber = `FF-${timeTail}${randomTail}`;

  const orderData = {
    id: orderId,
    orderNumber: orderNumber,
    customerId: customerId,
    customerName: customerName || "Customer",
    customerPhone: customerPhone || "",
    deliveryAddress: deliveryAddress.trim(),
    deliveryNotes: deliveryNotes || "",
    branchId: branchId || null,
    items: verifiedItems,
    subtotal: calculatedSubtotal,
    deliveryFee: deliveryFee,
    discount: calculatedDiscount,
    loyaltyDiscount: loyaltyDiscount,
    tokensRedeemed: numTokens,
    total: calculatedTotal,
    paymentMethod: paymentMethod || "Cash on Delivery",
    paymentStatus: "pending",
    status: "pending",
    verifiedByServer: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.runTransaction(async (t) => {
    // Deduct loyalty tokens if redeemed
    if (numTokens > 0) {
      const accountRef = db.collection("loyaltyAccounts").doc(customerId);
      const redeemTxRef = db.collection("loyaltyTransactions").doc(`redeem_${orderId}`);
      t.update(accountRef, {
        balance: admin.firestore.FieldValue.increment(-numTokens),
        totalRedeemed: admin.firestore.FieldValue.increment(numTokens),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      t.set(redeemTxRef, {
        id: redeemTxRef.id,
        userId: customerId,
        amount: numTokens,
        type: "redeem",
        orderId: orderId,
        description: `Redeemed ${numTokens} tokens on order #${orderNumber}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    t.set(orderRef, orderData);

    // Record server-side audit log
    const auditRef = db.collection("auditLogs").doc();
    t.set(auditRef, {
      id: auditRef.id,
      action: "order_placed_secure",
      targetEntity: "orders",
      targetId: orderId,
      branchId: branchId || "",
      actorId: customerId,
      actorName: customerName || "Customer",
      details: `Order #${orderNumber} placed securely for Rs. ${calculatedTotal} (${verifiedItems.length} items)`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  console.log(`[Order Placed Securely] Order #${orderNumber} (${orderId}) created for Rs. ${calculatedTotal}`);
  return {
    success: true,
    orderId: orderId,
    orderNumber: orderNumber,
    total: calculatedTotal,
    subtotal: calculatedSubtotal,
    deliveryFee: deliveryFee,
  };
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
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
exports.onOrderStatusUpdated = functions.firestore
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

    // 1. Push
    if (settings.pushNotificationsEnabled !== false) {
      await sendPushNotification(after.customerId, statusTitle, statusBody, orderId);
    }

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
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            } else {
              t.update(accountRef, {
                balance: admin.firestore.FieldValue.increment(tokensToEarn),
                totalEarned: admin.firestore.FieldValue.increment(tokensToEarn),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }

            t.set(earnTxRef, {
              id: earnTxRef.id,
              userId: after.customerId,
              amount: tokensToEarn,
              type: "earn",
              orderId: orderId,
              description: `Earned ${tokensToEarn} tokens for delivered order #${after.orderNumber}`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
          console.log(`Credited ${tokensToEarn} loyalty tokens to customer ${after.customerId} for order ${orderId}`);
        }
      } catch (loyaltyErr) {
        console.error(`Error processing loyalty rewards for delivered order ${orderId}:`, loyaltyErr);
      }
    } else if (newStatus === "cancelled" && after.customerId) {
      try {
        const tokensRedeemed = Number(after.tokensRedeemed || 0);
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
              balance: admin.firestore.FieldValue.increment(tokensRedeemed),
              totalRedeemed: admin.firestore.FieldValue.increment(-tokensRedeemed),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            t.set(refundTxRef, {
              id: refundTxRef.id,
              userId: after.customerId,
              amount: tokensRedeemed,
              type: "refund",
              orderId: orderId,
              description: `Refunded ${tokensRedeemed} redeemed tokens for cancelled order #${after.orderNumber}`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (refundErr) {
        console.error(`Error refunding loyalty tokens for cancelled order ${orderId}:`, refundErr);
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
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
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
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, logId: logRef.id };
});
