import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  static const preferenceKey = 'ff_app_language';
  static const english = Locale('en');
  static const urdu = Locale('ur');
  static const supportedLocales = [english, urdu];

  Locale _locale = english;
  Locale get locale => _locale;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _locale = preferences.getString(preferenceKey) == 'ur' ? urdu : english;
    } catch (_) {
      _locale = english;
    }
    notifyListeners();
  }

  Future<void> select(Locale locale) async {
    if (!supportedLocales.contains(locale) || locale == _locale) return;
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(preferenceKey, locale.languageCode)) {
      throw StateError('Could not save language preference.');
    }
    _locale = locale;
    notifyListeners();
  }
}

extension AppTranslation on BuildContext {
  String tr(String text) {
    if (Localizations.maybeLocaleOf(this)?.languageCode != 'ur') return text;
    return _urdu[text] ?? text;
  }
}

const _urdu = <String, String>{
  'Waiting for pickup': 'آرڈر وصول کرنے کا انتظار ہے',
  'Finding a rider': 'رائیڈر تلاش کیا جا رہا ہے',
  'Delivery rider': 'ڈیلیوری رائیڈر',
  'Update Available': 'اپ ڈیٹ دستیاب ہے',
  'Install Now': 'ابھی انسٹال کریں',
  'Update Now': 'ابھی اپ ڈیٹ کریں',
  'Later': 'بعد میں',
  'Open Release Page': 'ریلیز کا صفحہ کھولیں',
  'Open Settings to Allow Install': 'انسٹال کی اجازت کے لیے ترتیبات کھولیں',
  'Download verified. Tap Install to continue.': 'ڈاؤن لوڈ کی تصدیق ہو گئی۔ جاری رکھنے کے لیے انسٹال کریں۔',
  'Food Fight is up to date.': 'فوڈ فائٹ تازہ ترین ورژن پر ہے۔',
  'Settings': 'ترتیبات',
  'Language': 'زبان',
  'Could not save language preference.': 'زبان کی ترجیح محفوظ نہیں ہو سکی۔',
  'PREFERENCES': 'ترجیحات',
  'Push Notifications': 'اطلاعات',
  'Get notified about order updates': 'آرڈر کی تازہ معلومات حاصل کریں',
  'Email Offers': 'ای میل آفرز',
  'Receive deals and promotions via email': 'آفرز اور رعایتیں ای میل پر حاصل کریں',
  'Location Access': 'مقام تک رسائی',
  'Allow app to access your location': 'ایپ کو اپنا مقام استعمال کرنے دیں',
  'ABOUT & UPDATES': 'تعارف اور اپ ڈیٹس',
  'App Version': 'ایپ ورژن',
  'Check for Updates': 'اپ ڈیٹس دیکھیں',
  'See if a newer version is available': 'دیکھیں کہ نیا ورژن دستیاب ہے یا نہیں',
  'Replay App Intro': 'ایپ کا تعارف دوبارہ دیکھیں',
  'See the onboarding screens again': 'ابتدائی تعارفی اسکرینیں دوبارہ دیکھیں',
  'LEGAL': 'قانونی معلومات',
  'Terms of Service': 'سروس کی شرائط',
  'Privacy Policy': 'رازداری کی پالیسی',
  'Light': 'روشن',
  'Dark': 'تاریک',
  'System': 'ڈیوائس کے مطابق',
  'Theme': 'ظاہری انداز',
  'Home': 'ہوم',
  'Orders': 'آرڈرز',
  'Chat': 'چیٹ',
  'Profile': 'پروفائل',
  'Home tab': 'ہوم ٹیب',
  'Orders tab': 'آرڈرز ٹیب',
  'Support chat tab': 'معاونت کی چیٹ کا ٹیب',
  'Profile tab': 'پروفائل ٹیب',
  'Search the menu': 'مینو میں تلاش کریں',
  'Clear all filters': 'تمام فلٹر ہٹائیں',
  'See all': 'سب دیکھیں',
  'My Orders': 'میرے آرڈرز',
  'Track Live': 'لائیو ٹریکنگ',
  'Support': 'معاونت',
  'Rate': 'درجہ دیں',
  'Total Paid': 'کل ادا شدہ رقم',
  'Reorder': 'دوبارہ آرڈر کریں',
  'Pending': 'زیرِ انتظار',
  'Accepted': 'قبول ہو گیا',
  'Preparing': 'تیاری جاری ہے',
  'Ready': 'تیار',
  'Assigned': 'رائیڈر مقرر',
  'Picked Up': 'رائیڈر نے وصول کیا',
  'Out for Delivery': 'ڈیلیوری کے لیے روانہ',
  'Delivered': 'پہنچا دیا گیا',
  'Cancelled': 'منسوخ',
  'Order Placed': 'آرڈر دے دیا گیا',
  'Order submitted to restaurant': 'آرڈر ریستوران کو بھیج دیا گیا ہے',
  'Order Confirmed': 'آرڈر کی تصدیق ہو گئی',
  'Kitchen received and confirmed order': 'کچن نے آرڈر وصول کر کے تصدیق کر دی',
  'Preparing Food': 'کھانا تیار ہو رہا ہے',
  'Chefs are cooking fresh meal': 'آپ کا کھانا تازہ تیار کیا جا رہا ہے',
  'Order Ready': 'آرڈر تیار ہے',
  'Meal packed and awaiting rider': 'کھانا پیک ہو گیا ہے اور رائیڈر کا انتظار ہے',
  'Rider assigned': 'رائیڈر مقرر ہو گیا',
  'Awaiting rider acceptance and collection': 'رائیڈر کی منظوری اور وصولی کا انتظار ہے',
  'Picked up': 'رائیڈر نے وصول کیا',
  'Your rider has collected the meal': 'رائیڈر نے آپ کا کھانا وصول کر لیا ہے',
  'Delivery champion is on the way': 'رائیڈر راستے میں ہے',
  'Order Cancelled': 'آرڈر منسوخ ہو گیا',
  'Order Live Tracking': 'آرڈر کی لائیو ٹریکنگ',
  'Order Not Found': 'آرڈر نہیں ملا',
  'Go Back': 'واپس جائیں',
  'Delivery Status Timeline': 'ڈیلیوری کی پیش رفت',
  'Chat Support': 'چیٹ معاونت',
  'Chat with Support': 'معاونت سے بات کریں',
  'Help': 'مدد',
  'My Cart': 'میری ٹوکری',
  'Clear Cart': 'ٹوکری خالی کریں',
  'Clear All': 'سب ہٹائیں',
  'Browse Menu': 'مینو دیکھیں',
  'Total Amount': 'کل رقم',
  'Proceed to Checkout': 'چیک آؤٹ پر جائیں',
  'Please sign in to proceed to checkout': 'چیک آؤٹ کے لیے سائن اِن کریں',
  'Total Payable': 'کل قابلِ ادائیگی رقم',
  'Order Summary': 'آرڈر کا خلاصہ',
  'Subtotal': 'ذیلی کل',
  'Subtotal ({count} items)': 'ذیلی کل ({count} آئٹمز)',
  'Delivery Fee ({area})': 'ڈیلیوری فیس ({area})',
  'Delivery Fee': 'ڈیلیوری فیس',
  'FREE': 'مفت',
  'Total': 'کل',
  'Waiting for the restaurant to accept': 'ریستوران کی منظوری کا انتظار ہے',
  'The chefs have confirmed your meal': 'کچن نے آپ کے آرڈر کی تصدیق کر دی ہے',
  'Fresh food is being prepared right now': 'آپ کا کھانا تیار ہو رہا ہے',
  'Meal is packaged and awaiting pickup': 'کھانا پیک ہو گیا ہے اور وصولی کا انتظار ہے',
  'Your rider is preparing to collect the order': 'رائیڈر آرڈر وصول کرنے کی تیاری کر رہا ہے',
  'Your rider has collected your meal': 'رائیڈر نے آپ کا کھانا وصول کر لیا ہے',
  'Your rider is on the way to your address': 'رائیڈر آپ کے پتے کی طرف روانہ ہے',
  'This order has been cancelled': 'یہ آرڈر منسوخ ہو گیا ہے',
  'Pay PKR {amount} when your order arrives.': 'آرڈر پہنچنے پر {amount} روپے ادا کریں۔',
  'Checkout': 'چیک آؤٹ',
  'Confirm cash on delivery': 'ڈیلیوری پر نقد ادائیگی کی تصدیق کریں',
  'Confirm order': 'آرڈر کی تصدیق کریں',
  'Preparing Branch': 'تیاری کرنے والی برانچ',
  'Select your area': 'اپنا علاقہ منتخب کریں',
  'Active': 'فعال',
  'Delivery Address': 'ڈیلیوری کا پتہ',
  'Add New': 'نیا شامل کریں',
  'Add Address': 'پتہ شامل کریں',
  'Payment Method': 'ادائیگی کا طریقہ',
  'Cash on Delivery': 'ڈیلیوری پر نقد ادائیگی',
  'Pay in cash when your order arrives': 'آرڈر پہنچنے پر نقد ادائیگی کریں',
  'Fee Breakdown': 'فیس کی تفصیل',
  'Grand Total': 'مجموعی رقم',
  'Review order': 'آرڈر کا جائزہ لیں',
  'Checking order...': 'آرڈر کی جانچ ہو رہی ہے…',
  'Back': 'واپس',
  'Cancel': 'منسوخ کریں',
  'Sign Out': 'سائن آؤٹ',
  'Log In': 'سائن اِن',
  'Log In Button': 'سائن اِن کا بٹن',
  'Email Address': 'ای میل پتہ',
  'Email Address Field': 'ای میل درج کرنے کی جگہ',
  'Password Field': 'پاس ورڈ درج کرنے کی جگہ',
  'Enter your email': 'اپنی ای میل درج کریں',
  'Enter a valid email address': 'درست ای میل پتہ درج کریں',
  'Enter your password': 'اپنا پاس ورڈ درج کریں',
  'Password must be at least 6 characters': 'پاس ورڈ کم از کم ۶ حروف کا ہونا چاہیے',
  'OR': 'یا',
  'Email': 'ای میل',
  'Password': 'پاس ورڈ',
  'Forgot Password?': 'پاس ورڈ بھول گئے؟',
  'Continue with phone': 'موبائل نمبر سے جاری رکھیں',
  'Continue with Google Button': 'گوگل سے جاری رکھنے کا بٹن',
  'Verify your phone': 'اپنا موبائل نمبر تصدیق کریں',
  'Enter the code sent by SMS.': 'ایس ایم ایس میں موصول ہونے والا کوڈ درج کریں۔',
  'Firebase will use your number to verify your sign-in and prevent abuse.':
      'فائر بیس سائن اِن کی تصدیق اور غلط استعمال کی روک تھام کے لیے آپ کا نمبر استعمال کرے گا۔',
  'Enter a valid Pakistani mobile number.': 'درست پاکستانی موبائل نمبر درج کریں۔',
  'Enter the six-digit code.': 'چھ ہندسوں کا کوڈ درج کریں۔',
  'SMS code': 'ایس ایم ایس کوڈ',
  'Mobile number': 'موبائل نمبر',
  'Request new code': 'نیا کوڈ منگوائیں',
  'Verify': 'تصدیق کریں',
  'Send code': 'کوڈ بھیجیں',
  'Deliveries': 'ڈیلیوریز',
  'Confirm delivery': 'ڈیلیوری کی تصدیق کریں',
  'Delivery failed': 'ڈیلیوری مکمل نہیں ہوئی',
  'Report failure': 'مسئلہ رپورٹ کریں',
  'Notifications': 'اطلاعات',
  'Online': 'آن لائن',
  'Offline': 'آف لائن',
  'Retry': 'دوبارہ کوشش کریں',
  'Call': 'فون کریں',
  'Navigate': 'راستہ دیکھیں',
  'Updating…': 'اپ ڈیٹ ہو رہا ہے…',
  'Decline': 'پیشکش رد کریں',
  'Failed delivery': 'ڈیلیوری کا مسئلہ',
  'Accept': 'قبول کریں',
  'On the way': 'راستے میں',
};
