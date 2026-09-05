# Changelog

## 2.0.1+7 · Android-only maintenance update

- Restored German user-facing text while keeping developer documentation, source comments, and test descriptions in English.
- Removed unsupported non-Android platform files, build targets, native tests, and GitHub Actions jobs.
- Updated the supported toolchain to Flutter 3.47.2, Dart 3.13, and Kotlin 2.3.20.
- Revalidated analysis, logic/widget tests, native Android path tests, an Android emulator launch, and the signed release APK.

## 2.0.0+6 · Flutter port

- Introduced the Test Viewer identity with Test-Master's blue color palette and a distinctive eye app icon.
- Rebuilt the dashboard and device list entirely with Flutter widgets and Dart.
- Added native Android folder access with persisted permissions and a temporary SQLite snapshot.
- Added dynamic customer names, searchable multi-location filters, and a configurable monthly forecast.
- Added automatic or manual reference dates, persistent filters, and page sizes from 5 to 100.
- Added a table layout for tablets and a fully expanded device list for narrow displays.
- Added a clearly identified demo mode with synthetic records.
- Added the Gradle project, tests, local build scripts, and GitHub Actions.
- Retained the Android release ID while giving debug installations a separate suffix.
- Legacy WebView filters are not migrated; the native Android folder grant can be retained when the same release key is used.

This entry describes the source version, not a store publication.
