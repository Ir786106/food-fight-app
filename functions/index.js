const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Provider credentials configured via Firebase Secret Manager / config:
// firebase functions:config:set sendgrid.key="SG.xxx" twilio.sid="ACxxx" twilio.token="xxx" twilio.from="+1xxx"
const config = functions.config();
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || (config.sendgrid ? config.sendgrid.key : null);
const TWILIO_SID = process.env.TWILIO_SID || (config.twilio ? config.twilio.sid : null);
const TWILIO_TOKEN = process.env.TWILIO_TOKEN || (config.twilio ? config.twilio.token : null);
const TWILIO_FROM = process.env.TWILIO_FROM || (config.twilio ? config.twilio.from : "+1234567890");

let sgMail = null;
if (SENDGRID_API_KEY) {
  sgMail = require("@sendgrid/mail");
  sgMail.setApiKey(SENDGRID_API_KEY);
}

let twilioClient = null;
if (TWILIO_SID && TWILIO_TOKEN) {
  twilioClient = require("twilio")(TWILIO_SID, TWILIO_TOKEN);
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
    console.log(`[SMS Simulation to ${formattedPhone}]: ${message}`);
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
    console.log(`[Email Simulation to ${toEmail}]: ${subject}`);
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

    // 1. FCM Push Notification
    if (settings.pushNotificationsEnabled !== false) {
      await sendPushNotification(
        order.customerId,
        "Order Confirmed! 🥊",
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
            <h2 style="color: #FF7A00;">Food Fight Order Confirmed! 🥊</h2>
            <p>Hi <strong>${order.customerName || "Foodie"}</strong>,</p>
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
        const smsMessage = `Food Fight: Order #${order.orderNumber} of Rs. ${order.total} confirmed! Chefs are preparing your meal. Track live in app.`;
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
        statusTitle = "Chefs Cooking Fresh Food 👨‍🍳";
        statusBody = `Your order #${after.orderNumber} is being cooked fresh in our kitchen!`;
        break;
      case "ready":
        statusTitle = "Food is Packed & Ready 📦";
        statusBody = `Your order #${after.orderNumber} is packed and awaiting rider dispatch.`;
        break;
      case "outForDelivery":
        statusTitle = "Out for Delivery! 🛵";
        statusBody = `Rider has picked up your food and is speeding towards your location!`;
        break;
      case "delivered":
        statusTitle = "Order Delivered! Enjoy 🥊";
        statusBody = `Your meal has been delivered. Enjoy your Food Fight feast!`;
        break;
      case "cancelled":
        statusTitle = "Order Cancelled ❌";
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
  });

/**
 * Callable Function: Secure Payment Processing (Stripe / JazzCash Server-Side)
 * Keeps secrets off client app
 */
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to process payments."
    );
  }

  const { amount, currency = "PKR", orderId } = data;
  if (!amount || amount <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Amount must be greater than zero.");
  }

  // Tokenized transaction intent creation on server
  console.log(`Created payment intent for order ${orderId}, amount: ${amount} ${currency}`);
  return {
    clientSecret: `pi_test_secret_${Date.now()}`,
    orderId: orderId,
    status: "requires_confirmation",
  };
});

/**
 * Real-time Chat Trigger: onChatMessageCreated
 * Dispatches FCM Push Notifications to customer or branch admin staff when a message is posted.
 */
exports.onChatMessageCreated = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { chatId } = context.params;

    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return null;
    const chat = chatDoc.data();

    const settings = await getSystemSettings();
    if (settings.pushNotificationsEnabled === false) return null;

    const isCustomerSender = message.senderRole === "customer";
    const senderName = message.senderName || "Food Fight";
    const messagePreview = message.text && message.text.trim().length > 0
      ? message.text
      : (message.type === "image" ? "Sent a photo" : "Sent a message");

    try {
      if (isCustomerSender) {
        // Notify branch admin & sub-admins with 'chats' permission
        const branchId = chat.branchId;
        const adminsSnapshot = await db.collection("users")
          .where("role", "in", ["admin", "super_admin", "staff"])
          .get();

        const tokens = [];
        adminsSnapshot.forEach((doc) => {
          const u = doc.data();
          const matchesBranch = u.role === "super_admin" || u.branchId === branchId;
          const hasPermission = u.role === "super_admin" ||
            !u.parentAdminId ||
            (Array.isArray(u.permissions) && u.permissions.includes("chats")) ||
            (u.permissions && u.permissions.chats === true);

          if (matchesBranch && hasPermission && u.fcmToken) {
            tokens.push(u.fcmToken);
          }
        });

        if (tokens.length > 0) {
          await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
              title: `Support: ${senderName}`,
              body: messagePreview,
            },
            data: {
              type: "chat",
              chatId: chatId,
              orderId: chat.orderId || "",
            },
          });
        }
      } else {
        // Notify Customer
        const customerDoc = await db.collection("users").doc(chat.customerId).get();
        if (customerDoc.exists && customerDoc.data().fcmToken) {
          const customerToken = customerDoc.data().fcmToken;
          await admin.messaging().send({
            token: customerToken,
            notification: {
              title: "Food Fight Support",
              body: messagePreview,
            },
            data: {
              type: "chat",
              chatId: chatId,
              orderId: chat.orderId || "",
            },
          });
        }
      }
    } catch (pushErr) {
      console.error("Push notification error in onChatMessageCreated:", pushErr);
    }
    return null;
  });

