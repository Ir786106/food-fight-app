# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Older release history is available in Git tags.

## [1.8.6+23] - Unreleased

- Connect Android and Windows candidates to the configured trusted HTTPS backend.
- Display actionable Super Admin account save failures inside the edit dialog.
- Limit authenticated backend requests and preserve checkout retry safety.
- Keep checkout on Cash on Delivery while provider-managed card capture is unavailable.

## [1.8.5+22] - Unreleased

- Verify account identity and role before restoring privileged sessions.
- Keep Admin menu refresh scoped to the current branch and display a retry on read failures.
- Improve Super Admin dashboards, forms and recovery messages, and keep Rider delivery errors on the relevant tabs.
- Add local authorization, order lifecycle and migration regression coverage.
- Require verified Android and Windows artifacts with checksums before the release workflow publishes.

## [1.8.2+19] - 2026-11-11

- Use the supplied transparent Food Fight artwork for the in-app logo, Android launcher and splash, and Windows app and installer icon.

## [1.8.1+18] - Unreleased

- Added a resumable tenant backfill with export validation and a separate, guarded public financial cleanup.
- Added English and Urdu ARB catalogs with matching-key checks and a device-language default.
- Hardened Android update redirects and Android build-number comparison.
- Added staging and signed upgrade verification instructions.

## [1.7.5+13] - 2026-10-22

### Added
- Review-count-backed ratings; stale legacy ratings are no longer shown without visible reviews.
- Chronological customer and admin chat timelines with near-bottom auto-follow.
- System share-sheet support for food details.

### Changed
- Saved payment methods are wallet references only; the app does not collect card numbers or CVV or claim to process payments.
- Google Maps keys are read from ignored platform-specific runtime configuration instead of tracked platform files.
- Developer-only seeding helpers are outside the production `lib/` tree.
- README, security policy, and environment template now describe the configured application.

### Fixed
- Saved payment-method Firestore access is restricted to the account owner.
- User model serialization no longer reads or writes password fields.
- Unconfigured email and SMS providers no longer report simulated delivery success.
- Removed obsolete release artifacts, duplicated documentation, an unused navigation sheet, and an unused Cloud Functions dependency.
