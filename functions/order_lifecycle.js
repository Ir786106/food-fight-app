const kitchenTransitions = {
  pending: "accepted", accepted: "preparing", preparing: "ready",
};
const riderTransitions = {
  assigned: "pickedUp", pickedUp: "outForDelivery", outForDelivery: "delivered",
};
const activeDeliveries = Object.keys(riderTransitions);
const offerDurationMs = 2 * 60 * 1000;
const statuses = [...Object.keys(kitchenTransitions), "ready", ...activeDeliveries, "delivered", "cancelled"];
const staffRoles = ["admin", "sub_admin", "staff"];
const riderRoles = ["rider", "delivery_rider"];
const enabled = (value) => value === true || value === 1;
const activeProfile = (profile) => profile && profile.isBlocked !== true &&
  profile.status !== "blocked" &&
  (profile.isActive == null || [true, 1, "1", "true"].includes(profile.isActive));
const orderStatus = (value) => {
  const normalized = String(value ?? "").toLowerCase().replace(/[\s_-]/g, "");
  if (["canceled", "failed"].includes(normalized)) return "cancelled";
  return statuses.find((status) => status.toLowerCase() === normalized);
};

function permission(profile, name) {
  if (profile.role === "admin" && !profile.parentAdminId) return true;
  const permissions = profile.permissions;
  return [name, "manage_" + name].some((key) =>
    Array.isArray(permissions) ? permissions.includes(key) : permissions?.[key] === true);
}

function orderLifecycle({ db, fieldValue, fail, validId, cents, millis }) {
  return async (input, context, system = false) => {
    if (!system && !context.auth) fail("unauthenticated", "Sign in to manage orders.");
    const uid = system ? "dispatch-system" : context.auth.uid;
    const data = input || {};
    const orderId = validId(data.orderId, "order");
    const { action } = data;
    const actions = system ? ["dispatch", "expire"] :
      ["transition", "assign", "unassign", "accept", "decline", "dispatch", "settle"];
    if (!actions.includes(action)) {
      fail("invalid-argument", "Invalid order action.");
    }
    const orderRef = db.collection("orders").doc(orderId);
    const assignmentRef = db.collection("riderAssignments").doc(orderId);
    return db.runTransaction(async (transaction) => {
      const profile = system ? { role: "super_admin" } :
        (await transaction.get(db.collection("users").doc(uid))).data();
      if (!activeProfile(profile)) {
        fail("permission-denied", "This account cannot manage orders.");
      }
      const order = (await transaction.get(orderRef)).data();
      if (!order) fail("not-found", "Order no longer exists.");
      const current = orderStatus(order.status);
      if (!current) fail("failed-precondition", "Unknown order status.");
      const superAdmin = profile.role === "super_admin";
      const branchStaff = staffRoles.includes(profile.role) &&
        !!profile.branchId && profile.branchId === order.branchId;
      const canManage = (module) => superAdmin || (branchStaff && permission(profile, module));
      const ownsOrder = order.customerId === uid;
      const assignedRider = riderRoles.includes(profile.role) && order.riderId === uid;
      const now = Date.now();
      const timestamp = fieldValue.serverTimestamp();

      async function onlineRider(id, required = true) {
        const ref = db.collection("riders").doc(id);
        const rider = (await transaction.get(ref)).data();
        const account = id === uid ? profile :
          (await transaction.get(db.collection("users").doc(id))).data();
        if (!activeProfile(account) || !riderRoles.includes(account.role) ||
            (account.branchId && account.branchId !== order.branchId) ||
            !rider || rider.userId !== id ||
            (rider.isActive != null && !enabled(rider.isActive)) || !enabled(rider.isOnline) ||
            (rider.branchId && rider.branchId !== order.branchId)) {
          if (!required) return null;
          fail("failed-precondition", "Choose an active rider from this branch who is online.");
        }
        return { ref, rider };
      }

      function update(next, fields = {}, event = {}) {
        transaction.update(orderRef, {
          ...fields, status: next, updatedAt: timestamp,
          statusHistory: fieldValue.arrayUnion({ status: next, timestamp: now, actorId: uid, ...event }),
        });
        transaction.set(db.collection("auditLogs").doc(), {
          action: event.action || "order_" + next,
          targetEntity: "orders", targetId: orderId, actorId: uid,
          branchId: order.branchId || "", timestamp,
        });
        return { status: next };
      }

      function releaseAssignment(riderId, status) {
        transaction.set(assignmentRef, { orderId, riderId, status,
          updatedAt: timestamp, updatedBy: uid }, { merge: true });
        return update("ready", {
          riderId: null, riderName: null, riderPhone: null, riderAcceptedAt: null,
          offerExpiresAt: null, lastOfferedRiderId: riderId,
        }, { action: status });
      }

      async function hasCapacity(riderId) {
        const existing = await transaction.get(db.collection("orders").where("riderId", "==", riderId)
          .where("status", "in", [...activeDeliveries, "picked_up", "out_for_delivery", "picked up", "out for delivery"])
          .limit(1));
        return existing.empty;
      }

      function offer(riderId, candidate, previous, automatic) {
        const expiresAt = now + offerDurationMs;
        transaction.update(candidate.ref, { dispatchUpdatedAt: timestamp });
        transaction.set(assignmentRef, {
          orderId, riderId, previousRiderId: previous, assignedBy: uid,
          assignedAt: timestamp, status: "assigned", expiresAt,
        });
        return update("assigned", {
          riderId, riderName: candidate.rider.name || "", riderPhone: candidate.rider.phone || "",
          riderAcceptedAt: null, offerExpiresAt: expiresAt,
          ...(automatic && { autoDispatchAttempts: (order.autoDispatchAttempts || 0) + 1 }),
        }, { action: automatic ? "autoAssigned" : previous ? "reassigned" : "assigned" });
      }

      if (action === "expire") {
        if (current !== "assigned" || order.riderAcceptedAt != null ||
            !order.riderId || !Number.isFinite(order.offerExpiresAt) || order.offerExpiresAt > now) {
          return { status: current };
        }
        return releaseAssignment(order.riderId, "expired");
      }

      if (action === "dispatch") {
        if (!canManage("orders") || !canManage("riders")) {
          fail("permission-denied", "You cannot dispatch riders for this order.");
        }
        if (current !== "ready" || order.riderId || !order.branchId) return { status: current };
        if (system) {
          const branch = (await transaction.get(db.collection("branches").doc(order.branchId))).data();
          if (branch?.autoDispatchEnabled !== true || (order.autoDispatchAttempts || 0) >= 3) {
            return { status: current };
          }
        }
        const candidates = await transaction.get(db.collection("riders")
          .where("branchId", "==", order.branchId).where("isOnline", "in", [true, 1]).limit(30));
        const sorted = candidates.docs.sort((a, b) =>
          (millis(a.data().dispatchUpdatedAt) || 0) - (millis(b.data().dispatchUpdatedAt) || 0));
        for (const doc of sorted) {
          if (doc.id === order.lastOfferedRiderId) continue;
          const candidate = await onlineRider(doc.id, false);
          if (candidate && await hasCapacity(doc.id)) return offer(doc.id, candidate, null, true);
        }
        if (system) return { status: current };
        fail("failed-precondition", "No eligible rider is available. Try again or choose a rider manually.");
      }

      if (action === "settle") {
        if (!canManage("orders") || !canManage("reports")) {
          fail("permission-denied", "You cannot confirm cash settlement for this order.");
        }
        if (current !== "delivered") fail("failed-precondition", "The order has not been delivered.");
        const collectionRef = db.collection("codCollections").doc(orderId);
        const collection = (await transaction.get(collectionRef)).data();
        if (!collection || collection.branchId !== (order.branchId || "") || collection.riderId !== order.riderId) {
          fail("failed-precondition", "No matching COD collection was recorded.");
        }
        if (collection.settledAt) return { status: current, settlementStatus: "settled" };
        if (typeof data.amountPkr !== "number" || cents(data.amountPkr) !== collection.amountPaisa) {
          fail("invalid-argument", "The received amount must match the recorded COD collection.");
        }
        transaction.update(collectionRef, { settledAt: timestamp, settledBy: uid });
        transaction.update(orderRef, { codSettlementStatus: "settled", updatedAt: timestamp });
        transaction.set(db.collection("auditLogs").doc(), {
          action: "cod_settled", targetEntity: "orders", targetId: orderId, actorId: uid,
          branchId: order.branchId || "", timestamp,
        });
        return { status: current, settlementStatus: "settled" };
      }

      if (action === "decline") {
        if (!assignedRider) fail("permission-denied", "This delivery is no longer assigned to you.");
        if (current !== "assigned" || order.riderAcceptedAt != null) {
          fail("failed-precondition", "Only an unaccepted delivery can be declined.");
        }
        return releaseAssignment(uid, "declined");
      }

      if (action === "assign" || action === "unassign") {
        if (!canManage("orders") || !canManage("riders")) {
          fail("permission-denied", "You cannot assign riders for this order.");
        }
        const previous = order.riderId || null;
        if (previous !== (data.expectedRiderId || null) ||
            !["ready", "assigned"].includes(current)) {
          fail("failed-precondition", "This assignment changed. Refresh the order.");
        }
        if (action === "unassign") {
          if (current !== "assigned" || !previous) fail("failed-precondition", "No rider to unassign.");
          return releaseAssignment(previous, "unassigned");
        }

        const riderId = validId(data.riderId, "rider");
        if (riderId === previous && current === "assigned") return { status: current };
        if (order.riderAcceptedAt != null) {
          fail("failed-precondition", "Unassign the accepted delivery before choosing another rider.");
        }
        const candidate = await onlineRider(riderId);
        if (!await hasCapacity(riderId)) {
          fail("failed-precondition", "This rider already has an active delivery.");
        }
        return offer(riderId, candidate, previous, false);
      }

      if (action === "accept") {
        if (!assignedRider) fail("permission-denied", "This delivery is no longer assigned to you.");
        if (current !== "assigned") fail("failed-precondition", "This delivery has already moved on.");
        if (order.riderAcceptedAt != null) return { status: current };
        if (Number.isFinite(order.offerExpiresAt) && order.offerExpiresAt <= now) {
          fail("failed-precondition", "This rider offer expired.");
        }
        await onlineRider(uid);
        transaction.set(assignmentRef, { orderId, riderId: uid, status: "accepted", updatedAt: timestamp }, { merge: true });
        return update(current, { riderAcceptedAt: timestamp, offerExpiresAt: null }, { action: "riderAccepted" });
      }

      const next = data.status;
      const customerCancellation = ownsOrder && next === "cancelled";
      const riderAction = assignedRider && (activeDeliveries.includes(current) || current === "delivered" || current === "cancelled");
      const staffAction = canManage("orders") &&
        (Object.values(kitchenTransitions).includes(next) || next === "cancelled");
      if (!customerCancellation && !riderAction && !staffAction) {
        fail("permission-denied", "You cannot make this order change.");
      }
      if (current === next) return { status: current };
      if (next === "cancelled") {
        const reason = typeof data.reason === "string" ? data.reason.trim() : "";
        if (!reason || reason.length > 500) fail("invalid-argument", "Enter a cancellation reason.");
        const createdAt = millis(order.createdAt);
        const withinWindow = current === "pending" && Number.isFinite(createdAt) &&
          now < createdAt + 5 * 60 * 1000;
        if (current === "delivered" || (!staffAction && !riderAction && !withinWindow)) {
          fail("failed-precondition", "This order can no longer be cancelled.");
        }
        if (order.riderId) transaction.set(assignmentRef, { orderId, riderId: order.riderId,
          status: "cancelled", updatedAt: timestamp }, { merge: true });
        return update(next, { cancellationReason: reason, offerExpiresAt: null }, { reason });
      }
      if (!((staffAction && kitchenTransitions[current] === next) ||
          (riderAction && riderTransitions[current] === next))) {
        fail("failed-precondition", "This order status changed. Refresh before continuing.");
      }
      if (riderAction && activeDeliveries.includes(current)) {
        if (current === "assigned" && order.riderAcceptedAt == null) {
          fail("failed-precondition", "Accept this delivery before pickup.");
        }
        await onlineRider(uid);
      }
      if (next !== "delivered") return update(next);
      const cod = ["cash on delivery", "cod"].includes(String(order.paymentMethod).toLowerCase());
      const collect = cod && order.paymentStatus !== "paid";
      if (collect && data.codCollected !== true) {
        fail("failed-precondition", "Confirm that you collected the cash payment.");
      }
      if (collect) {
        transaction.create(db.collection("codCollections").doc(orderId), {
          orderId, riderId: uid, branchId: order.branchId || "",
          amountPaisa: cents(order.total, "order total"), currency: "PKR", collectedAt: timestamp,
        });
      }
      transaction.set(assignmentRef, { orderId, riderId: uid, status: "delivered", updatedAt: timestamp }, { merge: true });
      return update(next, { deliveredAt: now, ...(collect && { paymentStatus: "paid", codSettlementStatus: "pending" }) });
    });
  };
}

module.exports = { orderLifecycle };
