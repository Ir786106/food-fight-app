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

    beforeEach(async () => testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/admin-001').set({ role: 'admin', branchId: 'branch-1' });
    }));

    it('branch managers cannot provision privileged profiles or change branch status', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('branches/branch-1').set({ name: 'Branch', status: 'active' });
      });
      const db = testEnv.authenticatedContext(adminAuth.uid, adminAuth.token).firestore();
      await assertFails(db.doc('users/foreign-admin').set({ role: 'admin', branchId: 'branch-2' }));
      await assertSucceeds(db.doc('branches/branch-1').update({ name: 'New name' }));
      await assertFails(db.doc('branches/branch-1').update({ status: 'inactive' }));
    });

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
      await db.doc('users/manager').set({ role: 'admin', branchId: 'branch-1' });
      await db.doc('users/platform').set({ role: 'super_admin' });
      await db.doc('users/rider').set({ role: 'delivery_rider', branchId: 'branch-1' });
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

    beforeEach(async () => testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/superadmin-master').set({ role: 'super_admin', isActive: 1 });
    }));

    it('requires server writes for platform settings and immutable audit logs', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('auditLogs/server').set({ action: 'admin_created' });
      });
      const db = testEnv.authenticatedContext(superAdminAuth.uid, superAdminAuth.token).firestore();
      await assertSucceeds(db.doc('auditLogs/server').get());
      await assertFails(db.doc('auditLogs/server').update({ action: 'forged' }));
      await assertFails(db.doc('auditLogs/server').delete());
      await assertFails(db.doc('auditLogs/new').set({ action: 'forged' }));
      await assertFails(db.doc('settings/global_settings').set({ isStoreOpen: false }));
    });

    it('denies missing and suspended profiles despite a privileged token', async () => {
      const forged = testEnv.authenticatedContext('missing-profile', { role: 'super_admin' }).firestore();
      await assertFails(forged.doc('settings/app_update').set({ forceUpdate: true }));
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('users/superadmin-master').update({ status: 'suspended', isActive: 0 });
      });
      const db = testEnv.authenticatedContext(superAdminAuth.uid, superAdminAuth.token).firestore();
      await assertFails(db.doc('settings/app_update').set({ forceUpdate: true }));
    });

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
  it('keeps saved addresses, favorites and loyalty private to the account', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/manager').set({ role: 'admin', branchId: 'a' });
      await db.doc('addresses/private').set({ userId: 'customer' });
      await db.doc('favorites/private').set({ userId: 'customer' });
      await db.doc('loyaltyAccounts/customer').set({ balance: 50 });
    });
    const owner = testEnv.authenticatedContext('customer').firestore();
    const manager = testEnv.authenticatedContext('manager').firestore();
    for (const path of ['addresses/private', 'favorites/private', 'loyaltyAccounts/customer']) {
      await assertSucceeds(owner.doc(path).get());
      await assertFails(manager.doc(path).get());
    }
    await assertSucceeds(owner.doc('addresses/new').get());
    await assertFails(owner.doc('favorites/private').update({ userId: 'someone-else' }));
  });

  it('allows branch fleet queries and denies cross-branch fleet or promotion writes', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/manager').set({ role: 'admin', branchId: 'a' });
      await db.doc('users/rider-a').set({ role: 'rider', branchId: 'a' });
      await db.doc('riders/rider-a').set({ userId: 'rider-a', branchId: 'a', isOnline: 1 });
      await db.doc('riders/rider-b').set({ userId: 'rider-b', branchId: 'b' });
      for (const collection of ['coupons', 'deals', 'deliveryAreas', 'delivery_areas', 'optionTemplates', 'option_templates']) {
        await db.doc(collection + '/other').set({ branchId: 'b' });
        await db.doc(collection + '/shared').set({ name: 'Shared' });
      }
    });
    const manager = testEnv.authenticatedContext('manager').firestore();
    const rider = testEnv.authenticatedContext('rider-a').firestore();
    await assertSucceeds(manager.collection('riders').where('branchId', '==', 'a').get());
    await assertSucceeds(manager.collection('riders').where('branchId', '==', 'a').where('isOnline', 'in', [true, 1]).get());
    await assertFails(manager.collection('riders').get());
    await assertFails(manager.doc('riders/rider-b').update({ isOnline: 0 }));
    await assertSucceeds(rider.doc('riders/rider-a').update({ isOnline: 0 }));
    await assertFails(rider.doc('riders/rider-a').update({ branchId: 'b' }));
    for (const collection of ['coupons', 'deals', 'deliveryAreas', 'delivery_areas', 'optionTemplates', 'option_templates']) {
      await assertSucceeds(manager.doc(collection + '/own').set({ branchId: 'a' }));
      await assertFails(manager.doc(collection + '/own').update({ branchId: 'b' }));
      await assertFails(manager.doc(collection + '/other').delete());
      await assertSucceeds(manager.doc(collection + '/shared').get());
      await assertFails(manager.doc(collection + '/shared').update({ name: 'Changed' }));
    }
  });

  it('limits legacy order items to the parent order participants', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('orders/order').set({ customerId: 'customer', branchId: 'a' });
      await db.doc('orderItems/item').set({ orderId: 'order' });
    });
    const owner = testEnv.authenticatedContext('customer').firestore();
    const other = testEnv.authenticatedContext('unrelated').firestore();
    await assertSucceeds(owner.doc('orderItems/item').get());
    await assertFails(other.doc('orderItems/item').get());
    await assertFails(owner.doc('orderItems/item').update({ quantity: 5 }));
  });
  it('permits owner default-address queries for legacy integer and boolean defaults', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('addresses/bool').set({ userId: 'customer', isDefault: true });
      await db.doc('addresses/int').set({ userId: 'customer', isDefault: 1 });
      await db.doc('addresses/other').set({ userId: 'other', isDefault: 1 });
    });
    const owner = testEnv.authenticatedContext('customer').firestore();
    const snapshot = await assertSucceeds(owner.collection('addresses')
      .where('userId', '==', 'customer').where('isDefault', 'in', [1, true]).get());
    if (snapshot.size !== 2) throw new Error('Expected both legacy default formats.');
  });

  it('keeps branch financials private and prevents publishing them in branch profiles', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/manager-a').set({role: 'admin', branchId: 'a'});
      await db.doc('users/metrics-customer').set({role: 'customer', branchId: 'a'});
      await db.doc('users/metrics-rider').set({role: 'rider', branchId: 'a'});
      await db.doc('users/metrics-staff').set({role: 'staff', branchId: 'a', permissions: ['reports']});
      await db.doc('users/platform').set({role: 'super_admin'});
      await db.doc('branches/a').set({name: 'Kitchen A', status: 'active'});
      await db.doc('branchMetrics/a').set({totalRevenue: 1200});
      await db.doc('branchMetrics/b').set({totalRevenue: 2400});
    });
    const guest = testEnv.unauthenticatedContext().firestore();
    const manager = testEnv.authenticatedContext('manager-a').firestore();
    const platform = testEnv.authenticatedContext('platform').firestore();
    const profile = await assertSucceeds(guest.doc('branches/a').get());
    for (const field of ['revenue', 'expenses', 'orderCount', 'ordersCount', 'totalRevenue', 'totalOrders']) {
      if (profile.get(field) !== undefined) throw new Error(`Public profile exposes ${field}`);
    }
    await assertFails(guest.doc('branchMetrics/a').get());
    for (const uid of ['metrics-customer', 'metrics-rider']) {
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertFails(db.doc('branchMetrics/a').get());
      await assertFails(db.collection('branchMetrics').get());
    }
    const staff = testEnv.authenticatedContext('metrics-staff').firestore();
    await assertSucceeds(staff.doc('branchMetrics/a').get());
    await assertFails(staff.doc('branchMetrics/b').get());
    await assertSucceeds(manager.doc('branchMetrics/a').get());
    await assertFails(manager.doc('branchMetrics/b').get());
    await assertFails(manager.collection('branchMetrics').get());
    await assertSucceeds(platform.collection('branchMetrics').get());
    await assertFails(platform.doc('branchMetrics/a').update({totalRevenue: 0}));
    await assertFails(platform.doc('branches/a').update({totalRevenue: 1200}));
    await assertFails(platform.doc('branches/b').set({name: 'Kitchen B', expenses: 20}));
    await assertSucceeds(platform.doc('branches/a').update({name: 'Renamed kitchen'}));
  });

  it('requires an assigned branch for staff chat and legacy operational records', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/assigned').set({role: 'admin', branchId: 'a'});
      await db.doc('users/unassigned').set({role: 'admin'});
      await db.doc('users/wildcard').set({role: 'admin', branchId: 'all'});
      await db.doc('users/platform').set({role: 'super_admin'});
      await db.doc('chats/legacy').set({customerId: 'customer'});
      await db.doc('chats/own').set({customerId: 'customer', branchId: 'a'});
      await db.doc('chats/foreign').set({customerId: 'assigned', branchId: 'b'});
      await db.doc('menuReports/legacy').set({branchId: '', status: 'open'});
      await db.doc('riders/wildcard').set({branchId: 'all'});
      await db.doc('orders/legacy').set({branchId: ''});
      await db.doc('riderAssignments/legacy').set({orderId: 'legacy'});
      await db.doc('auditLogs/wildcard').set({branchId: 'all'});
      await db.doc('reviews/legacy').set({branchId: '', userId: 'customer'});
    });
    const assigned = testEnv.authenticatedContext('assigned').firestore();
    const unassigned = testEnv.authenticatedContext('unassigned').firestore();
    const wildcard = testEnv.authenticatedContext('wildcard').firestore();
    const platform = testEnv.authenticatedContext('platform').firestore();
    const customer = testEnv.authenticatedContext('customer').firestore();
    await assertFails(unassigned.doc('chats/legacy').get());
    await assertFails(unassigned.doc('menuReports/legacy').get());
    await assertFails(unassigned.doc('riderAssignments/legacy').get());
    await assertFails(unassigned.doc('reviews/legacy').update({isHidden: true}));
    await assertFails(wildcard.doc('riders/wildcard').get());
    await assertFails(wildcard.doc('auditLogs/wildcard').get());
    await assertSucceeds(platform.doc('chats/legacy').get());
    await assertSucceeds(customer.doc('chats/legacy').get());
    await assertSucceeds(assigned.collection('chats').where('branchId', '==', 'a').get());
    await assertSucceeds(assigned.doc('chats/own/messages/reply')
      .set({senderId: 'assigned', senderRole: 'admin'}));
    await assertFails(assigned.doc('chats/own/messages/spoof')
      .set({senderId: 'assigned', senderRole: 'super_admin'}));
    await assertFails(assigned.doc('chats/foreign/messages/spoof')
      .set({senderId: 'assigned', senderRole: 'admin'}));
    await assertFails(assigned.doc('chats/foreign').update({assignedAdminId: 'assigned'}));
    await assertSucceeds(assigned.doc('chats/foreign/messages/customer')
      .set({senderId: 'assigned', senderRole: 'customer'}));
  });

  it('scopes menu-report moderation to status fields and the owning branch', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/manager').set({ role: 'admin', branchId: 'a' });
      await db.doc('menuReports/own').set({ branchId: 'a', status: 'open', createdAt: 1 });
      await db.doc('menuReports/other').set({ branchId: 'b', status: 'open', createdAt: 1 });
    });
    const db = testEnv.authenticatedContext('manager').firestore();
    await assertSucceeds(db.collection('menuReports').where('branchId', '==', 'a')
      .orderBy('createdAt', 'desc').limit(100).get());
    await assertSucceeds(db.doc('menuReports/own').update({ status: 'resolved', updatedBy: 'manager' }));
    await assertFails(db.doc('menuReports/own').update({ status: 'open', updatedBy: 'another-user' }));
    await assertFails(db.doc('menuReports/own').update({ branchId: 'b' }));
    await assertFails(db.doc('menuReports/other').update({ status: 'resolved', updatedBy: 'manager' }));
  });
  it('paginates branch orders without dropping tied timestamps or including another branch', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/cursor-manager').set({ role: 'admin', branchId: 'a' });
      for (const [id, branchId, createdAt] of [
        ['first', 'a', 3], ['tied-a', 'a', 2], ['tied-b', 'a', 2],
        ['last', 'a', 1], ['foreign', 'b', 2],
      ]) {
        await db.doc('orders/' + id).set({ branchId, createdAt, customerId: 'customer' });
      }
    });
    const db = testEnv.authenticatedContext('cursor-manager').firestore();
    const query = db.collection('orders').where('branchId', '==', 'a').orderBy('createdAt', 'desc');
    const first = await assertSucceeds(query.limit(2).get());
    const next = await assertSucceeds(query.startAfter(first.docs.at(-1)).limit(2).get());
    const ids = [...first.docs, ...next.docs].map((doc) => doc.id).sort();
    if (ids.join(',') !== 'first,last,tied-a,tied-b') {
      throw new Error('Cursor skipped, repeated, or exposed an order.');
    }
  });
  it('restricts direct customer profile access and branch restrictions to the server', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/manager').set({role: 'admin', branchId: 'a'});
      await db.doc('users/customer-a').set({role: 'customer', branchId: 'a'});
      await db.doc('users/customer-b').set({role: 'customer', branchId: 'b'});
      await db.doc('users/staff-a').set({role: 'staff', branchId: 'a'});
      await db.doc('branches/a/customerRestrictions/customer-a').set({actorId: 'manager'});
    });
    const manager = testEnv.authenticatedContext('manager').firestore();
    const customer = testEnv.authenticatedContext('customer-a').firestore();
    await assertSucceeds(manager.doc('users/staff-a').get());
    await assertSucceeds(customer.doc('users/customer-a').get());
    await assertFails(manager.doc('users/customer-a').get());
    await assertFails(manager.doc('users/customer-b').get());
    await assertFails(manager.collection('users').where('role', '==', 'customer').get());
    await assertFails(manager.doc('users/customer-b').update({isActive: false}));
    await assertFails(manager.doc('branches/a/customerRestrictions/customer-a').delete());
    await assertFails(customer.doc('branches/a/customerRestrictions/customer-a').get());
  });

  it('paginates rider history without hiding active orders or exposing another rider', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/rider-a').set({role: 'delivery_rider', branchId: 'a'});
      await db.doc('orders/old-active').set({riderId: 'rider-a', status: 'assigned', createdAt: 1});
      await db.doc('orders/old-cancelled').set({riderId: 'rider-a', status: 'canceled', createdAt: 2});
      await db.doc('orders/new-completed').set({riderId: 'rider-a', status: 'delivered', createdAt: 3, updatedAt: new Date('2026-11-10')});
      await db.doc('orders/foreign-active').set({riderId: 'rider-b', status: 'assigned', createdAt: 4});
    });
    const db = testEnv.authenticatedContext('rider-a').firestore();
    const own = db.collection('orders').where('riderId', '==', 'rider-a');
    const history = own.orderBy('createdAt', 'desc').limit(1);
    const recent = await assertSucceeds(history.get());
    const next = await assertSucceeds(history.startAfter(recent.docs[0]).get());
    const active = await assertSucceeds(
      own.where('status', 'not-in', ['delivered', 'cancelled', 'canceled', 'failed']).get()
    );
    const earnings = await assertSucceeds(own.where('status', '==', 'delivered')
      .where('updatedAt', '>=', new Date('2026-11-01')).get());
    if (recent.docs[0].id !== 'new-completed' || next.docs[0].id !== 'old-cancelled' ||
        active.docs.map(doc => doc.id).join(',') !== 'old-active' ||
        earnings.docs.map(doc => doc.id).join(',') !== 'new-completed') {
      throw new Error('Rider query returned an unexpected set of orders.');
    }
    await assertFails(db.collection('orders').where('riderId', '==', 'rider-b').get());
  });

  it('keeps platform restaurant writes and unscoped orders away from branch admins', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('users/unscoped-admin').set({role: 'admin'});
      await db.doc('users/branch-admin').set({role: 'admin', branchId: 'a'});
      await db.doc('users/platform').set({role: 'super_admin'});
      await db.doc('orders/legacy').set({customerId: 'customer'});
      await db.doc('orders/branch-a').set({customerId: 'customer', branchId: 'a'});
    });
    const unscoped = testEnv.authenticatedContext('unscoped-admin').firestore();
    const branch = testEnv.authenticatedContext('branch-admin').firestore();
    const platform = testEnv.authenticatedContext('platform').firestore();
    await assertFails(unscoped.doc('orders/legacy').get());
    await assertSucceeds(branch.collection('orders').where('branchId', '==', 'a').get());
    await assertFails(branch.doc('restaurants/restaurant').set({name: 'Branch override'}));
    await assertSucceeds(platform.doc('restaurants/restaurant').set({name: 'Platform catalog'}));
    await assertSucceeds(branch.doc('restaurants/restaurant').get());
  });

  it('keeps customer active orders visible outside the first history page', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('orders/old-active').set({customerId: 'alice', status: 'preparing', createdAt: 1});
      await db.doc('orders/new-completed').set({customerId: 'alice', status: 'delivered', createdAt: 2});
      await db.doc('orders/foreign-active').set({customerId: 'bob', status: 'preparing', createdAt: 3});
    });
    const db = testEnv.authenticatedContext('alice').firestore();
    const owned = db.collection('orders').where('customerId', '==', 'alice');
    const latest = await assertSucceeds(owned.orderBy('createdAt', 'desc').limit(1).get());
    const active = await assertSucceeds(
      owned.where('status', 'not-in', ['delivered', 'cancelled', 'canceled', 'failed']).get()
    );
    if (latest.docs[0].id !== 'new-completed' ||
        active.docs.length !== 1 || active.docs[0].id !== 'old-active') {
      throw new Error('Customer history and active-order scopes diverged.');
    }
  });
});
