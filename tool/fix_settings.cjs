const fs=require('node:fs');
const p='lib/screens/settings/settings_screen.dart';
let s=fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n');
s="import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:firebase_auth/firebase_auth.dart';\nimport 'package:geolocator/geolocator.dart';\nimport '../../services/fcm_service.dart';\nimport 'policy_screen.dart';\n"+s;
s=s.replace('    _loadVersion();','    _loadVersion();\n    _loadPreferences();');
const before=s.indexOf('  Future<void> _loadVersion');
s=s.slice(0,before)+`  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailOffers = prefs.getBool('email_offers') ?? true;
      _locationAccess = prefs.getBool('location_access') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (key == 'push_notifications') await FcmService.setPushEnabled(value, user?.uid);
      if (key == 'email_offers') await FcmService.setOffersEnabled(value);
      if (key == 'location_access' && value) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw StateError('Enable location permission in your device settings.');
        }
      }
      if (user != null) await FirebaseFirestore.instance.collection('users').doc(user.uid)
        .set({'preferences': {key: value}}, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      await _loadPreferences();
    } catch (error) {
      if (mounted) AppSnackbar.showError(context, error.toString().replaceFirst('Bad state: ', ''));
    }
  }

`+s.slice(before);
s=s.replace('    setState(() => _isCheckingUpdate = false);\n    if (!mounted) return;', '    if (!mounted) return;\n    setState(() => _isCheckingUpdate = false);');
s=s.replace('(v) => setState(() => _pushNotifications = v)', "(v) => _savePreference('push_notifications', v)");
s=s.replace('(v) => setState(() => _emailOffers = v)', "(v) => _savePreference('email_offers', v)");
s=s.replace('(v) => setState(() => _locationAccess = v)', "(v) => _savePreference('location_access', v)");
const start=s.indexOf('  void _showDocumentSheet(');
s=s.slice(0,start)+`  void _showDocumentSheet(String title, String content) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PolicyScreen(
      title: title, field: title == 'Terms of Service' ? 'termsOfService' : 'privacyPolicy')));
  }
  static const _termsOfServiceContent = '';
  static const _privacyPolicyContent = '';
}
`;
fs.writeFileSync(p,s);
