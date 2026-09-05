# Release and migration

## Android

The Android release uses application ID `com.pezezzle.testmasterviewer`, version `2.0.0`, and version code `6`. Updating an earlier installation requires the same private signing key. The key is deliberately **not** stored in this repository. Restore it only to a secure local location, copy `android/key.properties.example` to the ignored `android/key.properties`, and enter the real local values.

When the application ID and signature match, an update retains the previous Android folder grant stored in SharedPreferences under `viewer`, `tree`, and `path`. Filters previously stored by the WebView are **not** migrated; locations, page size, and reference date can be configured again. A correctly signed update does not require uninstalling the existing app.

Debug builds are deliberately separate installations with an application ID ending in `.debug`; they do not inherit release permissions. A debug APK is not a signed production update.

Before a store upload, run `flutter build appbundle --release` and complete the physical-device test plan. There is no automatic Google Play upload.

## Local Android signing

`Build.ps1 -Target Release` and the default VS Code build task create a signed release APK. `Build.ps1 -Target AppBundle` creates the Play Store bundle. The build fails rather than falling back to a debug key when `android/key.properties` is missing.

Never commit `android/key.properties`, signing keys, or passwords. The repository ignores these files, but ignore rules are not a substitute for reviewing Git history.

## Android signing in GitHub Actions

Optionally create a protected GitHub environment named **android-release** with required reviewers. Configure four secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD`. The workflow expects a PKCS12 key, writes it only to temporary runner storage, and removes it at the end. Private values must never appear in YAML or commits.

`.github/workflows/android-release.yml` is manual-only. It produces signed APK/AAB artifacts but does not create a public GitHub release or upload anything to an app store.

## iOS

The bundle ID is `com.pezezzle.testmasterviewer`, with iOS 15 as the deployment target. Open `ios/Runner.xcworkspace` and select your team under **Signing & Capabilities**. No third-party team or certificate is preconfigured. Flutter creates plugin registration and SDK configuration on the first `pub get`/build.

`bash tool/build.sh ios-simulator` creates an unsigned simulator build. `bash tool/build.sh ios-archive` runs `flutter build ipa --release` and requires valid signing owned by the publisher. The CI simulator artifact cannot be installed on an iPhone or submitted to the App Store as an IPA.

Before submission, verify persistent folder access, access after a device restart, the actual file provider, privacy manifest, app icon, and device orientations. The publisher must provide the Apple team, store listing, legal information, and usage rights. The included synthetic demo provides a reproducible review path.

## Project toolchain

Flutter is pinned to 3.44.9. Android uses Gradle 9.1.0, AGP 9.0.1, Java 17, and minSdk 26. The two AGP 9 compatibility switches match the Flutter 3.44.9 template. `pubspec.lock` records the verified dependency state and is committed.

Implementation references:

- https://docs.flutter.dev/platform-integration/platform-channels
- https://docs.flutter.dev/deployment/android
- https://docs.flutter.dev/deployment/ios
- https://github.com/flutter/flutter/tree/3.44.9/packages/flutter_tools/templates/app
- https://developer.android.com/training/data-storage/shared/documents-files
- https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
