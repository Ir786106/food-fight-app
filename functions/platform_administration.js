const { randomBytes } = require("node:crypto");

const staffRoles = ["admin", "staff", "sub_admin", "super_admin"];
const statuses = ["active", "suspended", "deactivated"];
const modules = [
  "menu", "orders", "categories", "coupons", "customers", "delivery_areas",
  "riders", "reports", "chats", "reviews", "deals", "restaurants",
];

function isActiveProfile(profile) {
  return !!profile && profile.isBlocked !== true &&
    !["blocked", "suspended", "deactivated"].includes(profile.status) &&
    (profile.isActive == null || [true, 1, "1", "true"].includes(profile.isActive));
}

function platformAdministration({ db, auth, fail, timestamp, aggregateField }) {
  const users = db.collection("users");
  const branches = db.collection("branches");
  const audits = db.collection("auditLogs");

  async function requireAdministrator(context, allowBranchManager = false) {
    if (!context.auth) fail("unauthenticated", "Sign in first.");
    const actorId = context.auth.uid;
    const [profile, account] = await Promise.all([
      users.doc(actorId).get(),
      auth.getUser(actorId).catch((error) => {
        if (error.code === "auth/user-not-found") {
          fail("permission-denied", "The administrator login no longer exists.");
        }
        throw error;
      }),
    ]);
    const actor = profile.data();
    const branchManager = allowBranchManager && actor?.role === "admin" &&
      !actor.parentAdminId && typeof actor.branchId === "string" &&
      actor.branchId.trim() && actor.branchId !== "all";
    if (account.disabled || !isActiveProfile(actor) ||
        (actor.role !== "super_admin" && !branchManager)) {
      fail("permission-denied", "This action requires an active Super Admin account.");
    }
    return { ...actor, actorId };
  }

  const requireSuperAdmin = (context) => requireAdministrator(context);

  function ensureStaffScope(actor, profile) {
    if (actor.role === "super_admin") return;
    const staff = ["staff", "sub_admin"].includes(profile?.role) ||
      (profile?.role === "admin" && profile.parentAdminId === actor.actorId);
    if (!staff || profile.branchId !== actor.branchId) {
      fail("permission-denied", "Manage staff assigned to your branch.");
    }
  }

  function audit(transaction, actor, action, entity, id, branchId, description) {
    transaction.create(audits.doc(), {
      actorId: actor.actorId,
      actorName: actor.name || "Super Admin",
      actorEmail: actor.email || "",
      actorRole: actor.role,
      action, targetEntity: entity, targetId: id,
      branchId: branchId || "", description, timestamp: timestamp(),
    });
  }

  function documentId(value) {
    if (typeof value !== "string" || !value.trim() || value.length > 128 || value.includes("/")) {
      fail("invalid-argument", "Invalid record identifier.");
    }
    return value;
  }

  function text(value, max, required = false) {
    if (typeof value !== "string" || value.trim().length > max || (required && !value.trim())) {
      fail("invalid-argument", "A required field is missing or invalid.");
    }
    return value.trim();
  }

  function accountFields(data) {
    if (!staffRoles.includes(data.role)) fail("invalid-argument", "Choose a valid staff role.");
    const permissions = Array.isArray(data.permissions)
      ? [...new Set(data.permissions
        .filter((value) => typeof value === "string")
        .map((value) => value.replace(/^(manage_|view_)/, ""))
        .map((value) => value === "delivery" ? "delivery_areas" : value)
        .filter((value) => modules.includes(value)))]
      : [];
    return {
      name: text(data.name, 150, true), phone: text(data.phone ?? "", 40),
      role: data.role,
      branchId: data.role === "super_admin" ? null : documentId(data.branchId),
      permissions,
    };
  }

  function branchFields(input, branchId) {
    const latitude = input.latitude ?? null;
    const longitude = input.longitude ?? null;
    const radius = input.deliveryRadiusKm ?? 12;
    if ((latitude != null && (!Number.isFinite(latitude) || Math.abs(latitude) > 90)) ||
        (longitude != null && (!Number.isFinite(longitude) || Math.abs(longitude) > 180)) ||
        !Number.isFinite(radius) || radius <= 0 || radius > 100) {
      fail("invalid-argument", "Enter valid branch coordinates and delivery radius.");
    }
    return {
      id: branchId, name: text(input.name, 150, true),
      city: text(input.city, 100, true), address: text(input.address, 500, true),
      phone: text(input.phone ?? "", 40),
      latitude, longitude, deliveryRadiusKm: radius,
      status: "active",
      createdAt: Date.now(), updatedAt: Date.now(),
    };
  }

  async function mutate(input, context) {
    const data = input || {};
    const branchStaffStatus = data.action === "setBranchStaffStatus";
    const actor = await requireAdministrator(context, branchStaffStatus);
    if (data.action === "createAccount") {
      const fields = accountFields(data);
      const email = text(data.email, 254, true).toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) fail("invalid-argument", "Enter a valid email.");
      if (data.newBranch && (fields.role !== "admin" || data.newBranch.id !== fields.branchId)) {
        fail("invalid-argument", "A new branch needs a branch administrator.");
      }
      const newBranch = data.newBranch ? branchFields(data.newBranch, fields.branchId) : null;
      let account;
      try {
        account = await auth.createUser({
          email, displayName: fields.name, password: randomBytes(32).toString("base64url"),
        });
      } catch (error) {
        if (error.code === "auth/email-already-exists") {
          fail("already-exists", "An Auth account already uses this email.");
        }
        throw error;
      }
      try {
        await db.runTransaction(async (tx) => {
          if (fields.branchId) {
            const branch = await tx.get(branches.doc(fields.branchId));
            if (newBranch && branch.exists) fail("already-exists", "That branch already exists.");
            if (!newBranch && !branch.exists) fail("not-found", "The selected branch no longer exists.");
          }
          if (newBranch) {
            tx.create(branches.doc(fields.branchId), newBranch);
            audit(tx, actor, "branch_created", "branch", fields.branchId, fields.branchId, "Created a branch.");
          }
          tx.create(users.doc(account.uid), {
            ...fields, id: account.uid, uid: account.uid, email, status: "active",
            isActive: 1, createdAt: Date.now(), updatedAt: Date.now(),
          });
          audit(tx, actor, "admin_created", "admin_account", account.uid, fields.branchId,
            `Provisioned a ${fields.role} login.`);
        });
      } catch (error) {
        const profile = await users.doc(account.uid).get();
        if (!profile.exists) await auth.deleteUser(account.uid);
        throw error;
      }
      return { userId: account.uid };
    }

    if (data.action === "updateAccount" || data.action === "setAccountStatus" || branchStaffStatus) {
      const targetId = documentId(data.targetId);
      if (targetId === actor.actorId) fail("failed-precondition", "Another Super Admin must manage this account.");
      const ref = users.doc(targetId);
      const target = (await ref.get()).data();
      if (branchStaffStatus) ensureStaffScope(actor, target);
      if (!staffRoles.includes(target?.role)) fail("not-found", "Staff profile not found.");
      await auth.getUser(targetId).catch((error) => {
        if (error.code === "auth/user-not-found") {
          fail("failed-precondition", "This legacy profile has no Auth login. Provision a new account first.");
        }
        throw error;
      });

      if (data.action === "updateAccount") {
        const fields = accountFields(data);
        await db.runTransaction(async (tx) => {
          const profile = (await tx.get(ref)).data();
          if (!staffRoles.includes(profile?.role)) fail("not-found", "Staff profile not found.");
          if (fields.branchId && !(await tx.get(branches.doc(fields.branchId))).exists) {
            fail("not-found", "The selected branch no longer exists.");
          }
          const clearParent = ["admin", "super_admin"].includes(fields.role) ||
            fields.branchId !== profile.branchId;
          tx.update(ref, {
            ...fields, ...(clearParent ? { parentAdminId: null } : {}), updatedAt: Date.now(),
          });
          audit(tx, actor, "admin_updated", "admin_account", targetId, fields.branchId,
            "Updated staff profile and permissions.");
        });
        return { success: true };
      }

      if (!statuses.includes(data.status)) fail("invalid-argument", "Invalid account status.");
      const active = data.status === "active";
      await db.runTransaction(async (tx) => {
        const profile = (await tx.get(ref)).data();
        if (!staffRoles.includes(profile?.role)) fail("not-found", "Staff profile not found.");
        if (branchStaffStatus) ensureStaffScope(actor, profile);
        if (profile.status === data.status && profile.isActive === (active ? 1 : 0)) return;
        tx.update(ref, { status: data.status, isActive: active ? 1 : 0, updatedAt: Date.now() });
        audit(tx, actor, "admin_status_changed", "admin_account", targetId, profile.branchId,
          `Changed staff account status to ${data.status}.`);
      });
      // Firestore is authoritative. Reconcile against the latest status if another
      // administrator changed the same account while Auth was being updated.
      for (let attempt = 0; attempt < 3; attempt++) {
        const disabled = !isActiveProfile((await ref.get()).data());
        await auth.updateUser(targetId, { disabled });
        if (disabled) await auth.revokeRefreshTokens(targetId);
        if (disabled === !isActiveProfile((await ref.get()).data())) return { success: true };
      }
      fail("aborted", "The account changed during this operation. Reload and try again.");
    }

    if (data.action === "setBranchStatus") {
      const branchId = documentId(data.branchId);
      if (!["active", "inactive"].includes(data.status)) fail("invalid-argument", "Invalid branch status.");
      const ref = branches.doc(branchId);
      await db.runTransaction(async (tx) => {
        const branch = await tx.get(ref);
        if (!branch.exists) fail("not-found", "Branch not found.");
        if (branch.data().status === data.status) return;
        tx.update(ref, { status: data.status, updatedAt: Date.now() });
        audit(tx, actor, "branch_status_changed", "branch", branchId, branchId,
          `Changed branch status to ${data.status}.`);
      });
      return { success: true };
    }

    if (data.action === "saveSettings") {
      const input = data.settings || {};
      const strings = ["appName", "restaurantName", "contactEmail", "contactPhone", "supportWhatsApp"];
      const booleans = ["isStoreOpen", "maintenanceMode", "allowCashOnDelivery", "allowOnlinePayment",
        "pushNotificationsEnabled", "emailNotificationsEnabled", "smsNotificationsEnabled"];
      const numbers = ["defaultDeliveryCharge", "freeDeliveryThreshold", "orderCancellationWindowMinutes",
        "welcomeTokens", "loyaltyEarnRate", "loyaltyRedeemRate", "minTokensToRedeem"];
      const patch = { id: "global_settings", updatedAt: Date.now() };
      for (const key of strings) patch[key] = text(input[key], 254);
      for (const key of booleans) {
        if (typeof input[key] !== "boolean") fail("invalid-argument", "Invalid settings switch.");
        patch[key] = input[key];
      }
      for (const key of numbers) {
        if (!Number.isFinite(input[key]) || input[key] < 0 || input[key] > 10000000) {
          fail("invalid-argument", "Invalid numeric setting.");
        }
        patch[key] = input[key];
      }
      await db.runTransaction(async (tx) => {
        tx.set(db.collection("settings").doc("global_settings"), patch, { merge: true });
        audit(tx, actor, "settings_updated", "system", "global_settings", null,
          "Updated platform settings.");
      });
      return { success: true };
    }
    fail("invalid-argument", "Unknown platform action.");
  }

  async function metrics(_, context) {
    await requireSuperAdmin(context);
    const orders = db.collection("orders");
    const delivered = orders.where("status", "==", "delivered");
    const count = async (query) => (await query.count().get()).data().count;
    const [totalRestaurants, totalBranches, totalCustomers, totalAdmins, totalStaff,
      totalRiders, activeRiders, totalOrders, completedOrders, cancelledOrders, deliveredSales] =
      await Promise.all([
        count(db.collection("restaurants")), count(branches),
        count(users.where("role", "==", "customer")), count(users.where("role", "==", "admin")),
        count(users.where("role", "in", ["staff", "sub_admin"])),
        count(users.where("role", "in", ["rider", "delivery_rider"])),
        count(db.collection("riders").where("isOnline", "in", [true, 1])),
        count(orders), count(delivered), count(orders.where("status", "==", "cancelled")),
        delivered.aggregate({ gmv: aggregateField.sum("total") }).get(),
      ]);
    const dayMs = 86400000;
    const today = Math.floor(Date.now() / dayMs) * dayMs;
    const dailySales = await Promise.all(Array.from({ length: 7 }, async (_, index) => {
      const date = today - (6 - index) * dayMs;
      const snapshot = await delivered.where("createdAt", ">=", date)
        .where("createdAt", "<", date + dayMs).orderBy("createdAt", "desc")
        .aggregate({ revenue: aggregateField.sum("total"), ordersCount: aggregateField.count() })
        .get();
      const { revenue, ordersCount } = snapshot.data();
      return { date, revenue: revenue || 0, ordersCount };
    }));
    return { totalRestaurants, totalBranches, totalCustomers, totalAdmins, totalStaff,
      totalRiders, activeRiders, totalOrders, completedOrders, cancelledOrders,
      dailySales, deliveredGmv: deliveredSales.data().gmv || 0 };
  }

  return { requireSuperAdmin, mutate, metrics };
}

module.exports = { platformAdministration, isActiveProfile };
