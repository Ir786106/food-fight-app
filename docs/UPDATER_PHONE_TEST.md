# Android in-app updater

**Status: manual, pending.** This procedure requires a physical Android phone and the signed APK currently in use.

1. Install the old signed APK and sign in. Save an address, choose a language and record the app version and build number.
2. Verify the candidate APK against the old APK with `tool/verify_apk_signing.ps1`. Compare the Android package ID and confirm the candidate versionCode is higher. Generate the matching SHA-256 sidecar.
3. When you are ready to publish, publish the signed candidate and sidecar together to the trusted GitHub release. Include the Android build number in the tag or release body. Do this only after the staging and release gates pass.
4. In the old app open Settings and check for updates. Confirm the candidate version appears. Download from the app. Turn the network off during one attempt and confirm it offers a clean retry. The current downloader restarts interrupted downloads from byte zero.
5. Choose Install Now. If Android blocks installs from this app, open the permission screen, enable permission for Food Fight and return. Choose Install Now again.
6. Cancel the first Android installer prompt. Confirm the old app still opens and Install Now is still available. Then retry and accept installation.
7. Relaunch Food Fight. Confirm the new version and build number are shown, then confirm sign-in, saved address and language are still present. Check for updates again and expect no newer version.

| Failure | Expected behavior |
| --- | --- |
| Interrupted or cancelled download | No install prompt. Retry downloads a new copy |
| Missing or invalid checksum, or untrusted redirect | Candidate is rejected |
| Low storage | Download or Android pre-install check fails. Free space and retry |
| Install permission denied | Android installation stays blocked until permission is granted |
| Wrong signer, package or versionCode | Installer launch is refused |
| User cancels installer or OS fails installation | Old build and app data remain. Reopen Settings and retry |
| Candidate already installed | Recovery requires a signed build with a higher versionCode. Do not uninstall to roll back if preserving local data is required |

The manifest is fetched from the fixed HTTPS GitHub repository endpoint. APK and checksum redirects are validated before requests. The SHA-256 sidecar verifies integrity and Android checks package, signer and version before opening its installer.
