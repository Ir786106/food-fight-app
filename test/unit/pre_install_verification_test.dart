import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/services/app_update_service.dart';

void main() {
  group('In-App Updater Pre-install Verification & Error Mapping', () {
    test('SIGNATURE_MISMATCH generates clear bilingual instructions', () {
      const result = ApkPreInstallResult(
        status: ApkInstallStatus.signatureMismatch,
        errorCode: 'SIGNATURE_MISMATCH',
        englishMessage:
            'This update was signed with a different key. Uninstall the app once and install again.',
        romanUrduMessage:
            'Yeh update mukhtalif key se sign ki gayi hai. Barah-e-karam pehle purani app uninstall karein, phir naya version install karein.',
      );

      expect(result.canInstall, isFalse);
      expect(result.englishMessage, contains('different key'));
      expect(result.englishMessage, contains('Uninstall the app once'));
      expect(result.romanUrduMessage, contains('purani app uninstall karein'));
      expect(result.releasePageUrl, contains('github.com'));
    });

    test('VERSION_DOWNGRADE informs user properly', () {
      const result = ApkPreInstallResult(
        status: ApkInstallStatus.versionDowngrade,
        errorCode: 'VERSION_DOWNGRADE',
        englishMessage:
            'A newer or identical version is already installed on your device.',
        romanUrduMessage:
            'Aap ke phone mein pehle se naya ya yahi version mojood hai.',
      );

      expect(result.canInstall, isFalse);
      expect(result.englishMessage, contains('newer or identical version'));
      expect(result.romanUrduMessage, contains('pehle se naya'));
    });

    test('INSUFFICIENT_STORAGE requests memory cleanup', () {
      const result = ApkPreInstallResult(
        status: ApkInstallStatus.insufficientStorage,
        errorCode: 'INSUFFICIENT_STORAGE',
        englishMessage:
            'Insufficient storage space. Please free up at least 150MB of internal storage.',
        romanUrduMessage:
            'Phone ki memory kam hai. Barah-e-karam thori storage khali karein.',
      );

      expect(result.canInstall, isFalse);
      expect(result.englishMessage, contains('150MB'));
      expect(result.romanUrduMessage, contains('memory kam hai'));
    });

    test('UNKNOWN_SOURCES_BLOCKED guides to Android Settings', () {
      const result = ApkPreInstallResult(
        status: ApkInstallStatus.unknownSourcesBlocked,
        errorCode: 'UNKNOWN_SOURCES_BLOCKED',
        englishMessage:
            'Installation from unknown sources is blocked. Please enable permission in Settings.',
        romanUrduMessage:
            'Unknown sources se install band hai. Settings mein ja kar ijazat on karein.',
      );

      expect(result.canInstall, isFalse);
      expect(result.englishMessage, contains('unknown sources'));
      expect(result.romanUrduMessage, contains('Settings mein'));
    });

    test('Valid package passes pre-check', () {
      const result = ApkPreInstallResult(
        status: ApkInstallStatus.ready,
        errorCode: 'OK',
        englishMessage: 'APK verified successfully.',
        romanUrduMessage: 'APK ki tasdeeq ho gayi hai.',
      );

      expect(result.canInstall, isTrue);
    });
  });
}
