/// Utility class for input validation
class ValidatorUtils {
  // Email validation
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Form field validator for required fields
  static String? validateRequired(String? value, {String? fieldName, String? message}) {
    if (value == null || value.trim().isEmpty) {
      if (fieldName != null) return '$fieldName is required';
      if (message != null) return message;
      return 'This field is required';
    }
    return null;
  }

  /// Form field validator for email fields
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!isValidEmail(value.trim())) return 'Enter a valid email address';
    return null;
  }

  // Phone validation (Pakistani format)
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final phoneRegex = RegExp(
      r'^(03[0-9]{2}|923[0-9]{2})[- ]?[0-9]{7}$',
    );
    return phoneRegex.hasMatch(phone);
  }

  // Name validation
  static bool isValidName(String? name) {
    if (name == null || name.isEmpty) return false;
    if (name.length < 2) return false;
    if (name.length > 50) return false;
    return true;
  }

  // Password validation
  static bool isValidPassword(String? password) {
    if (password == null || password.isEmpty) return false;
    if (password.length < 6) return false;
    return true;
  }

  // Price validation
  static bool isValidPrice(double? price) {
    return price != null && price >= 0;
  }

  // Discount validation
  static bool isValidDiscount(double? discount, double? price) {
    if (discount == null || discount < 0) return false;
    if (price != null && discount > price) return false;
    return true;
  }

  // Quantity validation
  static bool isValidQuantity(int? quantity) {
    return quantity != null && quantity > 0;
  }

  // String length validation
  static bool isValidLength(String? value, {int minLength = 1, int? maxLength}) {
    if (value == null || value.isEmpty) return false;
    if (value.length < minLength) return false;
    if (maxLength != null && value.length > maxLength) return false;
    return true;
  }

  // URL validation
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  // Number range validation
  static bool inRange(double? value, {required double min, required double max}) {
    return value != null && value >= min && value <= max;
  }
}
