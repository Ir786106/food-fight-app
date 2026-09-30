/// Firestore document field constants
class FirestoreFields {
  // Generic
  static const String uid = 'id';
  static const String fieldUid = 'id';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldStatus = 'status';
  static const String fieldIsActive = 'isActive';

  // User fields
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPhone = 'phone';
  static const String fieldRole = 'role';
  static const String fieldProfileImage = 'profileImage';

  // Category fields
  static const String fieldCategoryName = 'name';
  static const String fieldCategoryDescription = 'description';
  static const String fieldCategoryImageUrl = 'imageUrl';
  static const String fieldCategoryOrder = 'order';

  // Menu item fields
  static const String fieldMenuItemName = 'name';
  static const String fieldMenuItemDescription = 'description';
  static const String fieldPrice = 'price';
  static const String fieldDiscount = 'discount';
  static const String fieldFinalPrice = 'finalPrice';
  static const String fieldImageUrl = 'imageUrl';
  static const String fieldCategoryId = 'categoryId';
  static const String fieldIsFeatured = 'isFeatured';
  static const String fieldIsVeg = 'isVeg';
  static const String fieldIsSpicy = 'isSpicy';
  static const String fieldPrepTime = 'prepTimeMinutes';

  // Order fields
  static const String fieldOrderNumber = 'orderNumber';
  static const String fieldCustomerId = 'customerId';
  static const String fieldItems = 'items';
  static const String fieldSubtotal = 'subtotal';
  static const String fieldDeliveryCharge = 'deliveryCharge';
  static const String fieldTotal = 'total';
  static const String fieldPaymentMethod = 'paymentMethod';
  static const String fieldDeliveryAddress = 'deliveryAddress';
  static const String fieldCancellationReason = 'cancellationReason';

  // Delivery Area fields
  static const String fieldAreaName = 'name';
  static const String fieldAreaCharge = 'deliveryCharge';

  // Coupon fields
  static const String fieldCouponCode = 'code';
  static const String fieldCouponType = 'type';
  static const String fieldCouponValue = 'value';
  static const String fieldMinOrder = 'minimumOrder';
  static const String fieldMaxDiscount = 'maximumDiscount';
  static const String fieldValidUntil = 'validUntil';

  // Real-time Chat fields
  static const String fieldBranchId = 'branchId';
  static const String fieldCustomerName = 'customerName';
  static const String fieldCustomerPhone = 'customerPhone';
  static const String fieldOrderId = 'orderId';
  static const String fieldChatType = 'type';
  static const String fieldLastMessage = 'lastMessage';
  static const String fieldLastMessageAt = 'lastMessageAt';
  static const String fieldLastSenderRole = 'lastSenderRole';
  static const String fieldUnreadForAdmin = 'unreadForAdmin';
  static const String fieldUnreadForCustomer = 'unreadForCustomer';
  static const String fieldAssignedAdminId = 'assignedAdminId';

  // Chat Message fields
  static const String fieldSenderId = 'senderId';
  static const String fieldSenderRole = 'senderRole';
  static const String fieldSenderName = 'senderName';
  static const String fieldText = 'text';
  static const String fieldMessageType = 'type';
  static const String fieldReadBy = 'readBy';
}
