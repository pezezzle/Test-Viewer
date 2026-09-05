# Verified build and test status

Status date: **September 5, 2026**, source version **2.0.0+6**.

## Completed successfully

- `flutter analyze`: no findings.
- `flutter test`: all **51** logic and widget tests passed, including widths of 320/390/1024 pixels, dialog lifecycles, and branding marks.
- Android debug APK built with Flutter 3.44.9 and JDK 17, installed on a Samsung SM-S928B, and launched successfully.
- Android release APK built locally with the production signing configuration; its APK signature and certificate SHA-256 fingerprint were independently verified.
- The actual Swift code from `ios/Runner/DeviceDatabase.swift` was compiled and run against SQLite3 with Swift 6.2.1 on Linux. This is the same SQL reader called by the iOS integration, but it is not an iOS app build.
- Comparison with the privately supplied database: **1,525 devices**, all 19 projected raw fields, and customer records matched an independent Python/SQLite query. The source file's SHA-256 hash was identical before and after the test.
- An additional comparison using **80 entirely synthetic devices** matched every raw value and left the source hash unchanged.
- A minimal database without optional device columns or a customer table loaded successfully; missing values remained empty/null.
- An invalid device schema was rejected as expected.
- **13 Swift and 13 Java cases** for path validation were executed and passed.
- All five iOS Swift files were accepted by the Swift parser. UIKit, Flutter, and Apple file-integration APIs were deliberately not type-checked on Linux.
- Dart sources were also checked with the Dart analyzer.
- Project configuration, XML/plist files, Xcode object references, and public file contents were checked statically. The repository contains no original database, private signing key, or proprietary font files.

The native checks can be reproduced with `python tool/test_native.py` when Swift, SQLite headers, and a JDK are available. A private database can optionally be compared with `--database /local/path/pcdrdata.sqlite3`; records are never printed.

## Not yet fully completed

- Flutter integration test for the clearly marked demo mode.
- Android App Bundle build with production signing and the Xcode/Flutter iOS build.
- Native Android SAF and iOS bookmark/security-scope tests on physical devices.
- Full verification of the GitHub Actions workflows on their hosted runners.

## Conclusion

The Flutter source, Android debug path, and signed Android release APK have been verified locally. Store acceptance and iOS acceptance remain platform-specific work.

For a fresh checkout, run `flutter pub get`, `flutter analyze`, and `flutter test`, followed by the required platform build. Resolve analyzer, SDK, and platform errors before production installation or store submission. The supplied CI workflows make these checks visible after each push.
