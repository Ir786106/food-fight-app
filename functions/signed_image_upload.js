const { randomUUID } = require("node:crypto");

const bucket = "food-images";
const maxBytes = 2 * 1024 * 1024;
const hourlyLimit = 60;

function signedImageUpload({ db, fail, validId, request = fetch, config }) {
  return async (input, context) => {
    if (!context.auth) fail("unauthenticated", "Sign in before uploading an image.");
    const { purpose, sizeBytes } = input || {};
    const permissions = { product: "menu", category: "categories" };
    const folders = { product: "products", category: "categories", profile: "profiles", banner: "banners" };
    if (typeof purpose !== "string" || !Object.hasOwn(folders, purpose) ||
        !Number.isSafeInteger(sizeBytes) || sizeBytes < 1 || sizeBytes > maxBytes) {
      fail("invalid-argument", "Choose a supported image smaller than 2 MB.");
    }
    const { url, key } = config();
    if (!url || !key) fail("failed-precondition", "Image uploads are not configured.");

    const uid = context.auth.uid;
    const now = Date.now();
    const scope = await db.runTransaction(async (transaction) => {
      const profile = (await transaction.get(db.collection("users").doc(uid))).data();
      if (!profile || profile.isBlocked === true || profile.status === "blocked" ||
          (profile.isActive != null && ![true, 1, "true", "1"].includes(profile.isActive))) {
        fail("permission-denied", "This account cannot upload images.");
      }
      let owner = uid;
      if (purpose !== "profile") {
        const role = profile.role;
        const permission = permissions[purpose];
        const keys = [permission, "manage_" + permission];
        const allowed = role === "admin" && !profile.parentAdminId || keys.some((key) =>
          Array.isArray(profile.permissions) ? profile.permissions.includes(key) : profile.permissions?.[key] === true);
        if (role === "super_admin") {
          owner = "platform";
        } else if (permission && ["admin", "sub_admin", "staff"].includes(role) &&
            allowed && profile.branchId) {
          owner = validId(profile.branchId, "branch");
        } else {
          fail("permission-denied", "You cannot upload this type of image.");
        }
      }
      if (!/^[A-Za-z0-9_-]+$/.test(owner)) fail("failed-precondition", "Invalid image scope.");
      const quotaRef = db.collection("imageUploadQuotas").doc(uid);
      const quota = (await transaction.get(quotaRef)).data();
      const hour = Math.floor(now / 3600000);
      const count = quota?.hour === hour ? quota.count : 0;
      if (count >= hourlyLimit) fail("resource-exhausted", "Image upload limit reached. Try again later.");
      transaction.set(quotaRef, { hour, count: count + 1 });
      return owner;
    });

    const path = [folders[purpose], scope, randomUUID() + ".jpg"].join("/");
    const objectPath = path.split("/").map(encodeURIComponent).join("/");
    try {
      const response = await request(
        url.replace(/\/$/, "") + "/storage/v1/object/upload/sign/" + bucket + "/" + objectPath,
        {
          method: "POST",
          headers: { apikey: key, Authorization: "Bearer " + key, "Content-Type": "application/json" },
          body: "{}",
          signal: AbortSignal.timeout(10000),
        },
      );
      if (response.ok) {
        const result = await response.json();
        const token = new URL(result.url, url).searchParams.get("token");
        if (token) return { path, token };
      }
    } catch (_) {
      // Provider details can contain signing credentials.
    }
    fail("unavailable", "Could not authorize this upload. Try again.");
  };
}

module.exports = { signedImageUpload };
