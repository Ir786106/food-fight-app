const admin = require("firebase-admin");

const projectId = "demo-food-fight";
if (process.env.GCLOUD_PROJECT !== projectId ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== "127.0.0.1:9187" ||
    process.env.FIRESTORE_EMULATOR_HOST !== "127.0.0.1:8687") {
  throw new Error("Use firebase.demo.json with --project demo-food-fight before seeding.");
}

const app = admin.initializeApp({ projectId });
const db = admin.firestore();
const password = "FoodFight-Demo-123";
const branchId = "demo-kitchen";
const accounts = [
  { uid: "demo-customer", role: "customer", name: "Demo Customer" },
  { uid: "demo-admin", role: "admin", name: "Demo Kitchen Manager", branchId },
  { uid: "demo-rider", role: "rider", name: "Demo Rider", branchId },
];

async function createIfMissing(collection, id, data) {
  const ref = db.collection(collection).doc(id);
  await db.runTransaction(async (transaction) => {
    if (!(await transaction.get(ref)).exists) transaction.create(ref, { id, ...data });
  });
}

async function seed() {
  const now = Date.now();
  const timestamps = { createdAt: now, updatedAt: now };
  for (const { uid, ...profile } of accounts) {
    const email = uid + "@example.test";
    try {
      await app.auth().getUser(uid);
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
      await app.auth().createUser({ uid, email, password, displayName: profile.name });
    }
    await createIfMissing("users", uid, {
      ...profile, email, phone: "03001234567", isActive: true, ...timestamps,
    });
  }

  await createIfMissing("branches", branchId, {
    name: "Demo Kitchen", city: "Lahore", address: "123 Demo Street", status: "active", ...timestamps,
  });
  await createIfMissing("categories", "demo-burgers", {
    branchId, name: "Burgers", isActive: true, ...timestamps,
  });
  await createIfMissing("menuItems", "demo-burger", {
    branchId, categoryId: "demo-burgers", name: "Demo Burger", price: 100.5, stock: 100,
    isActive: true, isAvailable: true, ...timestamps,
  });
  await createIfMissing("deliveryAreas", "demo-area", {
    branchId, name: "Demo Area", deliveryCharge: 25, isActive: true, ...timestamps,
  });
  await createIfMissing("riders", "demo-rider", {
    branchId, userId: "demo-rider", name: "Demo Rider", phone: "03001234567", isActive: 1,
    isOnline: 1, ...timestamps,
  });
  console.log("Local demo accounts, kitchen, menu and delivery area are ready.");
}

seed().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
}).finally(() => app.delete());
