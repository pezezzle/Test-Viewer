# Verified build and test status

Status date: **September 5, 2026**, source version **2.0.1+7**.

## Current scope

Test Viewer is an Android-only app. Unsupported platform files, build scripts, and CI jobs are not part of the project.

## Completed successfully

- Flutter was upgraded to **3.47.2** with Dart **3.13.2**.
- `flutter analyze` completed without findings.
- `flutter test` passed all logic and widget tests.
- The Flutter integration test built, installed, and launched the debug app on an Android 16 emulator; the German demo dashboard and device page both passed.
- The native Java database-path policy tests passed with JDK 17.
- The Android debug APK and production-signed Android release APK were built locally.
- The release APK signature and certificate fingerprint were verified.
- Earlier read-only comparison with the privately supplied database matched **1,525 devices**, all 19 projected raw fields, and customer records. The source file hash was unchanged.
- Public source checks confirmed that the repository contains no original database, private signing key, or proprietary font files.

## Still requiring release acceptance

- Complete the physical-device acceptance plan after each release candidate.
- Build and validate the production-signed Android App Bundle before a Google Play upload.
- Confirm the updated GitHub Actions workflow on a hosted runner after the reviewed changes are pushed.

## Reproduction

For a fresh checkout, run:

```sh
flutter pub get
flutter analyze
flutter test
python tool/test_native.py
flutter build apk --debug
```

Use `Build.ps1 -Target Release` for a locally signed release APK or `Build.ps1 -Target AppBundle` for a signed Android App Bundle. Both signed targets require the ignored `android/key.properties` file and the publisher-owned signing key.
