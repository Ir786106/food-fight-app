const fs = require('node:fs');
let s = fs.readFileSync('firestore.rules','utf8').replace(/\r\n/g,'\n');
function block(marker, replacement) {
  const start = s.indexOf('    match /' + marker);
  if(start < 0) throw Error(marker);
  const open = s.indexOf(' {', start) + 1;
  let depth = 1, end = open + 1;
  for (;depth && end<s.length;end++) { if(s[end]==='{') depth++; if(s[end]==='}') depth--; }
  s = s.slice(0,start) + replacement + s.slice(end);
}
s = s.replace("return existingUser() && getUserData().get('parentAdminId', null) != null;", "return existingUser() && (getUserRole() in ['sub_admin', 'staff'] || getUserData().get('parentAdminId', null) != null);");
s = s.replace(" ||\n                       (isAuthenticated() && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['totalRevenue', 'totalOrders', 'updatedAt']))", '');
s = s.replace("(!isSubAdmin() || canManage('customers')) &&\n          existingRole() != 'super_admin' &&\n          incomingRole() != 'super_admin'", "canManage('customers') && existingRole() == 'customer' && incomingRole() == 'customer' &&\n          !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'permissions', 'parentAdminId', 'branchId', 'isAdmin', 'isSuperAdmin'])");
block('orders/{orderId}', `    match /orders/{orderId} {
      function staff() {
        return isSuperAdmin() || (canManage('orders') && resource.data.get('branchId', '') == getUserBranchId());
      }
      function rider() { return isDeliveryRider() && resource.data.get('riderId', '') == request.auth.uid; }
      function transition() {
        let old = resource.data.status;
        let next = request.resource.data.status;
        return (old == 'assigned' && next == 'pickedUp' && resource.data.get('riderAcceptedAt', null) != null) ||
          (old == 'pickedUp' && next == 'outForDelivery') ||
          (old == 'outForDelivery' && next == 'delivered') ||
          (old in ['assigned','pickedUp','outForDelivery'] && next == 'cancelled' && request.resource.data.get('cancellationReason','').size() > 2);
      }
      allow read: if staff() || (isAuthenticated() && resource.data.customerId == request.auth.uid) || rider();
      // All roles place orders through the authenticated callable transaction.
      allow create: if false;
      allow update: if staff() ||
        (isOwner(resource.data.customerId) && resource.data.status == 'pending' &&
          request.resource.data.status == 'cancelled' &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status','statusHistory','cancellationReason','updatedAt']) &&
          request.time < (resource.data.createdAt is timestamp ? resource.data.createdAt : timestamp.value(resource.data.createdAt)) + duration.value(5, 'm')) ||
        (rider() && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'status','statusHistory','riderAcceptedAt','deliveredAt','updatedAt','cancellationReason']) &&
          (transition() || (resource.data.status == 'assigned' && request.resource.data.status == 'assigned' &&
            resource.data.get('riderAcceptedAt', null) == null && request.resource.data.riderAcceptedAt == request.time)));
      allow delete: if isSuperAdmin();
      match /tracking/{trackingId} {
        function order() { return get(/databases/$(database)/documents/orders/$(orderId)).data; }
        allow read: if isAuthenticated() && (order().customerId == request.auth.uid ||
          order().get('riderId','') == request.auth.uid || isSuperAdmin() ||
          (canManage('orders') && order().branchId == getUserBranchId()));
        allow create, update: if isDeliveryRider() && order().get('riderId','') == request.auth.uid &&
          (order().status in ['pickedUp','outForDelivery'] || request.resource.data.get('isActive', true) == false);
        allow delete: if isSuperAdmin();
      }
    }`);
for (const name of ['loyaltyAccounts','loyalty_accounts']) block(name+'/{userId}', `    match /${name}/{userId} {
      allow read: if isOwner(userId) || canManage('customers');
      allow write: if false;
    }`);
for (const name of ['loyaltyTransactions','loyalty_transactions']) block(name+'/{txId}', `    match /${name}/{txId} {
      allow read: if isAuthenticated() && (resource.data.userId == request.auth.uid || canManage('customers'));
      allow write: if false;
    }`);
block('chats/{chatId}', `    match /chats/{chatId} {
      function access(data) {
        return isAuthenticated() && (data.customerId == request.auth.uid || isSuperAdmin() ||
          (canManage('chats') && data.get('branchId','') == getUserBranchId()));
      }
      allow get: if isAuthenticated() && (resource == null || access(resource.data));
      allow list: if access(resource.data);
      allow create: if access(request.resource.data) && request.resource.data.get('unreadForAdmin',0) == 0 &&
        request.resource.data.get('unreadForCustomer',0) == 0;
      allow update: if access(resource.data) &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'lastMessage','lastMessageAt','lastSenderRole','unreadForAdmin','unreadForCustomer','updatedAt','status','assignedAdminId']) &&
        (canManage('chats') || !request.resource.data.diff(resource.data).affectedKeys().hasAny(['assignedAdminId']));
      allow delete: if isSuperAdmin();
      match /messages/{messageId} {
        function parent() { return get(/databases/$(database)/documents/chats/$(chatId)).data; }
        allow read: if access(parent());
        allow create: if access(parent()) && request.resource.data.senderId == request.auth.uid &&
          ((parent().customerId == request.auth.uid && request.resource.data.senderRole == 'customer') ||
            (canManage('chats') && request.resource.data.senderRole != 'customer'));
        allow update: if access(parent()) && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['readBy']) &&
          request.resource.data.readBy.hasAll(resource.data.get('readBy', [])) &&
          request.resource.data.readBy.toSet().difference(resource.data.get('readBy', []).toSet()).hasOnly([request.auth.uid]);
        allow delete: if isSuperAdmin();
      }
    }`);
s = s.replaceAll("canManage('riders') || isAdmin()", "canManage('riders')");
s = s.replace("(isOwner(riderId) || (resource != null && resource.data.userId == request.auth.uid))\n      );", "(isOwner(riderId) || (resource != null && resource.data.userId == request.auth.uid)) &&\n        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isOnline','updatedAt','lastSeen'])\n      );");
s = s.replace('    match /orderItems/{itemId}', `    match /menuReports/{reportId} {
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid &&
        request.resource.data.message is string && request.resource.data.message.size() >= 10 && request.resource.data.message.size() <= 2000;
      allow read, update: if canManage('menu');
      allow delete: if isSuperAdmin();
    }

    match /orderItems/{itemId}`);
fs.writeFileSync('firestore.rules',s);
let storage = fs.readFileSync('storage.rules','utf8');
storage = storage.replace('    // Customer profile photos', `    match /chat_attachments/{chatId}/{fileName} {
      function participant() {
        let chat = firestore.get(/databases/(default)/documents/chats/$(chatId)).data;
        let user = firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data;
        let permissions = user.get('permissions', []);
        let canChat = user.role == 'admin' || user.role == 'super_admin' ||
          (permissions is list && permissions.hasAny(['chats','manage_chats'])) ||
          (permissions is map && (permissions.get('chats',false) || permissions.get('manage_chats',false)));
        return chat.customerId == request.auth.uid || user.role == 'super_admin' ||
          (canChat && user.get('branchId','') == chat.get('branchId',''));
      }
      allow read: if isAuthenticated() && participant();
      allow create: if isAuthenticated() && participant() && isImage() && request.resource.size < 5 * 1024 * 1024;
      allow update, delete: if isSuperAdmin();
    }

    // Customer profile photos`);
fs.writeFileSync('storage.rules',storage);
