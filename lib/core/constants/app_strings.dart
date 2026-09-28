/// String constants for UI and business logic
class AppStrings {
  // Common text
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String close = 'Close';
  static const String refresh = 'Refresh';
  static const String retry = 'Retry';
  static const String search = 'Search...';
  static const String noData = 'No data available';
  static const String tryAgain = 'Please try again';

  // Error messages
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Server error. Please try again later';
  static const String authError = 'Authentication failed';
  static const String permissionError = 'You do not have permission';
  static const String invalidInput = 'Please enter valid input';
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String imageUploadFailed = 'Failed to upload image';
  static const String orderFailed = 'Failed to place order. Please try again';

  // Success messages
  static const String orderPlaced = 'Order placed successfully';
  static const String orderUpdated = 'Order updated successfully';
  static const String itemAdded = 'Item added successfully';
  static const String itemUpdated = 'Item updated successfully';
  static const String itemDeleted = 'Item deleted successfully';
  static const String profileUpdated = 'Profile updated successfully';
  static const String passwordChanged = 'Password changed successfully';

  // Validation messages
  static const String nameMinLength = 'Name must be at least 2 characters';
  static const String nameMaxLength = 'Name must not exceed 50 characters';
  static const String phoneInvalid = 'Please enter a valid phone number';
  static const String priceInvalid = 'Price must be a positive number';
  static const String discountInvalid = 'Discount cannot be greater than price';
  static const String quantityInvalid = 'Quantity must be at least 1';

  // Role names
  static const String roleCustomer = 'customer';
  static const String roleRider = 'delivery_rider';
  static const String roleStaff = 'staff';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Order status messages
  static const String statusPending = 'Pending';
  static const String statusAccepted = 'Accepted';
  static const String statusPreparing = 'Preparing';
  static const String statusReady = 'Ready';
  static const String statusAssigned = 'Assigned';
  static const String statusPickedUp = 'Picked Up';
  static const String statusOutForDelivery = 'Out for Delivery';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';

  // Payment methods
  static const String paymentCOD = 'Cash on Delivery';
  static const String paymentCard = 'Credit / Debit Card';
  static const String paymentEasypaisa = 'Easypaisa';
  static const String paymentJazzCash = 'JazzCash';
  static const String paymentJoker = 'Joker Pay';
}
