const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

describe('Food Fight Firestore Security Rules', () => {
  let testEnv;

  before(async () => {
    const rulesPath = path.resolve(__dirname, '../../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
    testEnv = await initializeTestEnvironment({
      projectId: 'food-fight-demo-test',
      firestore: {
        rules: rules,
        host,
        port: Number(port),
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
    }
  });

  // 1. Unauthenticated Access
  describe('Unauthenticated Users', () => {
    it('can read public menuItems and branches', async () => {
      const unauthedDb = testEnv.unauthenticatedContext().firestore();
      await assertSucceeds(unauthedDb.collection('menuItems').doc('burger-1').get());
      await assertSucceeds(unauthedDb.collection('branches').doc('branch-1').get());
    });

    it('can read settings/app_update for in-app version checks', async () => {
      const unauthedDb = testEnv.unauthenticatedContext().firestore();
      await assertSucceeds(unauthedDb.doc('settings/app_update').get());
    });

    it('cannot write to any collection', async () => {
      const unauthedDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(unauthedDb.collection('menuItems').doc('burger-1').set({ name: 'Hacked' }));
      await assertFails(unauthedDb.collection('users').doc('u1').set({ role: 'super_admin' }));
      await assertFails(unauthedDb.doc('settings/app_update').set({ forceUpdate: true }));
    });
  });

  // 2. Customer Role
  describe('Customer Role', () => {
    const customerAuth = { uid: 'cust-123', token: { role: 'customer' } };

    it('can create their own profile with customer role only', async () => {
      const custDb = testEnv.authenticatedContext(customerAuth.uid, customerAuth.token).firestore();
      await assertSucceeds(
        custDb.collection('users').doc('cust-123').set({
          name: 'Regular Customer',
          email: 'customer@test.com',
          role: 'customer',
        })
      );
    });

    it('cannot escalate privileges or assign admin roles to themselves', async () => {
      const custDb = testEnv.authenticatedContext(customerAuth.uid, customerAuth.token).firestore();
      await assertFails(
        custDb.collection('users').doc('cust-123').set({
          name: 'Attacker',
          email: 'attacker@test.com',
          role: 'super_admin',
          isAdmin: true,
        })
      );
    });

    it('cannot modify other users profiles', async () => {
      const custDb = testEnv.authenticatedContext(customerAuth.uid, customerAuth.token).firestore();
      await assertFails(
        custDb.collection('users').doc('victim-456').set({
          name: 'Tampered',
          role: 'customer',
        })
      );
    });

    it('cannot remove the block flag or delete a blocked profile', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('users/cust-123').set({
          role: 'customer', isActive: false, isBlocked: true,
        });
      });
      const custDb = testEnv.authenticatedContext(customerAuth.uid, customerAuth.token).firestore();
      await assertFails(custDb.doc('users/cust-123').update({ isBlocked: false }));
      await assertFails(custDb.doc('users/cust-123').delete());
    });

    it('cannot arbitrarily alter loyalty balance', async () => {
      const custDb = testEnv.authenticatedContext(customerAuth.uid, customerAuth.token).firestore();
      await assertFails(
        custDb.collection('loyaltyAccounts').doc('cust-123').set({
          balance: 999999,
        })
      );
    });
  });

  // 3. Delivery Rider Role
  describe('Delivery Rider Role', () => {
    const riderAuth = { uid: 'rider-001', token: { role: 'delivery_rider', branchId: 'branch-1' } };

    it('can read their own profile and cannot read unrelated customer profiles', async () => {
      const riderDb = testEnv.authenticatedContext(riderAuth.uid, riderAuth.token).firestore();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('users/customer').set({ role: 'customer' });
      });
      await assertSucceeds(riderDb.collection('users').doc('rider-001').get());
      await assertFails(riderDb.doc('users/customer').get());
    });

    it('cannot write menu items or system settings', async () => {
      const riderDb = testEnv.authenticatedContext(riderAuth.uid, riderAuth.token).firestore();
      await assertFails(riderDb.collection('menuItems').doc('burger-1').set({ name: 'Tampered' }));
      await assertFails(riderDb.doc('settings/app_update').set({ forceUpdate: true }));
    });
  });

  // 4. Admin and Sub-Admin Roles
  describe('Admin and Sub-Admin Roles', () => {
    const adminAuth = { uid: 'admin-001', token: { role: 'admin', branchId: 'branch-1' } };

    it('admin can manage menu items and branch resources', async () => {
      const adminDb = testEnv.authenticatedContext(adminAuth.uid, adminAuth.token).firestore();
      await assertSucceeds(
        adminDb.collection('menuItems').doc('burger-1').set({
          name: 'Zinger Burger',
          branchId: 'branch-1',
          price: 450,
        })
      );
    });

    it('limits catalog changes to the owning branch', async () => {
      const adminDb = testEnv.authenticatedContext(adminAuth.uid, adminAuth.token).firestore();
      for (const collection of ['categories', 'menuItems', 'menu_items']) {
        await testEnv.withSecurityRulesDisabled(async (context) => {
          const db = context.firestore();
          await db.doc(collection + '/own').set({ branchId: 'branch-1' });
          await db.doc(collection + '/other').set({ branch_id: 'branch-2' });
          await db.doc(collection + '/shared').set({ name: 'Shared catalog' });
        });
        await assertSucceeds(adminDb.doc(collection + '/own').update({ name: 'Updated' }));
        await assertFails(adminDb.doc(collection + '/own').update({ branchId: 'branch-2' }));
        await assertFails(adminDb.doc(collection + '/other').update({ branchId: 'branch-1' }));
        await assertFails(adminDb.doc(collection + '/other').delete());
        await assertFails(adminDb.doc(collection + '/new').set({ branchId: 'branch-2' }));
        await assertSucceeds(adminDb.doc(collection + '/shared').get());
        await assertFails(adminDb.doc(collection + '/shared').update({ name: 'Tampered' }));
        await assertSucceeds(adminDb.doc(collection + '/own').delete());
      }
    });

    it('admin cannot promote anyone to super_admin', async () => {
      const adminDb = testEnv.authenticatedContext(adminAuth.uid, adminAuth.token).firestore();
      await assertFails(
        adminDb.collection('users').doc('user-promote').set({
          role: 'super_admin',
        })
      );
    });
  });

  it('requires the backend for order and assignment writes', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('orders/secure').set({
        branchId: 'branch-1', customerId: 'customer', riderId: 'rider', status: 'assigned',
      });
      await db.doc('riderAssignments/secure').set({ riderId: 'rider', status: 'assigned' });
    });
    for (const [uid, role] of [['customer', 'customer'], ['rider', 'delivery_rider'], ['manager', 'admin'], ['platform', 'super_admin']]) {
      const db = testEnv.authenticatedContext(uid, { role, branchId: 'branch-1' }).firestore();
      await assertSucceeds(db.doc('orders/secure').get());
      await assertFails(db.doc('orders/secure').update({ status: 'delivered' }));
      await assertFails(db.doc('riderAssignments/secure').update({ status: 'accepted' }));
    }
  });

  // 5. Super Admin Role
  describe('Super Admin Role', () => {
    const superAdminAuth = { uid: 'superadmin-master', token: { role: 'super_admin' } };

    it('super admin can update system settings and app_update', async () => {
      const superDb = testEnv.authenticatedContext(superAdminAuth.uid, superAdminAuth.token).firestore();
      await assertSucceeds(
        superDb.doc('settings/app_update').set({
          minSupportedVersion: '1.7.0',
          forceUpdate: false,
          message: 'Security update available',
        })
      );
    });

    it('super admin can configure branches and full system collections', async () => {
      const superDb = testEnv.authenticatedContext(superAdminAuth.uid, superAdminAuth.token).firestore();
      await assertSucceeds(
        superDb.collection('branches').doc('branch-new').set({
          name: 'Food Fight DHA Phase 6',
          isActive: true,
        })
      );
    });
  });
});
