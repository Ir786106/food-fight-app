# Release candidate 1.8.1+18

Build locally with the existing release keystore and ignored Firebase settings.

    pwsh -File tool/build_release.ps1 -Target Android -AppBundle
    pwsh -File tool/build_release.ps1 -Target Windows -InnoCompiler "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    pwsh -File tool/verify_apk_signing.ps1 -OldApk OLD.apk -NewApk build/release-candidate/FoodFight_v1.8.1_release.apk -ApkSigner PATH_TO_APKSIGNER

Android and Windows read the version from pubspec. The updater reads the GitHub release tag and the paired APK/checksum, so use tag `v1.8.1+18` or include `Build: 18` in the release body. Verify the build against the latest distributed APK before release.

## Branding assets

The project uses native asset wiring with no new package.

| Surface | Replacement paths |
| --- | --- |
| In-app brand artwork | `assets/images/branding/food_fight_logo_icon.png` |
| Android launcher and adaptive icons | `android/app/src/main/res/mipmap-*/ic_launcher.png`, `mipmap-anydpi-v26/ic_launcher.xml`, `drawable-*/ic_launcher_foreground.png` |
| Android splash | `android/app/src/main/res/drawable-nodpi/splash_logo.png` and the existing splash theme |
| Windows executable and installer | `windows/runner/resources/app_icon.ico` with multiple sizes. Runner resources and Inno Setup already reference it |
| Web favicon and installable icons | `web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, and `Icon-maskable-512.png` under `web/icons` |

Replace existing artwork in place and verify launcher cropping, splash legibility and Windows icon sizes. Existing artwork remains in the candidate.

## Release notes

**English:** Improved branch data privacy and added a safer tenant migration process. Urdu language selection now follows the device until a preference is saved. Android updates validate download destinations and build numbers.

**اردو:** برانچ کے مالی ریکارڈ کی رازداری بہتر کی گئی ہے اور پرانا ڈیٹا منتقل کرنے کے لیے تصدیقی طریقہ شامل کیا گیا ہے۔ زبان کی ترجیح محفوظ کرنے تک ایپ ڈیوائس کی زبان استعمال کرتی ہے۔ اینڈرائیڈ اپ ڈیٹ کے لیے ڈاؤن لوڈ کے پتے اور بلڈ نمبر کی جانچ کی جاتی ہے۔

## Operator checklist

Complete [staging checks](STAGING_VERIFICATION.md), verify the installer and certificate, and complete the [phone procedure](UPDATER_PHONE_TEST.md). Review the exact Git diff and stage only reviewed source files. Keep signing keys, Firebase/Supabase secrets, migration reports and local binaries out of Git. The following commands are for the operator after approval.

    git status --short
    git add -- <reviewed-source-paths>
    git diff --cached --check
    git diff --cached --stat
    git commit -m "Prepare Food Fight 1.8.1+18"
    git push origin HEAD
    git tag -a v1.8.1+18 -m "Food Fight 1.8.1+18"
    git push origin v1.8.1+18

If automatic publishing is enabled in GitHub Actions, pushing the version tag can publish the Android release. Check the repository workflow settings before pushing. For manual publishing, attach the matching APK, checksum and Windows installer to the same release.
