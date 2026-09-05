# Test Viewer · Flutter

Offline companion app for Test-Master inspection data on Android and iOS. Version **2.0.0+6**. The interface and reporting logic use Dart and native Flutter widgets; there is **no WebView**. The current user interface and bundled documentation are English-only.

**Project status:** Flutter analysis and all 51 logic/widget tests pass. The Android debug APK and the production-signed Android release APK have been built locally; the release signature and certificate fingerprint were independently verified. The production-signed Android App Bundle and the iOS app build have not yet been fully verified. Building iOS requires macOS with Xcode. See [Build and test status](docs/BUILD_AND_TEST_STATUS.md) for details.

## Getting started

Open the folder containing `pubspec.yaml` in Android Studio with the Flutter plugin or in VS Code. The supported toolchain is **Flutter 3.44.9 / Dart 3.12**; `.fvmrc` pins the Flutter version. Android uses JDK 17.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Select **Try with sample data** on the welcome screen to explore the app without your own database. Alternatively:

```sh
flutter run --dart-define=DEMO_MODE=true
```

The app targets Android 8.0+ and iOS 15+. Android debug builds use standard debug signing. Android release/store builds require the publisher's private signing key, while physical-device and App Store builds for iOS require the publisher's Apple Developer team.

## Download

[Download the latest signed Android APK](https://github.com/pezezzle/Test-Viewer/releases/latest/download/Test-Viewer-2.0.0+6.apk)

Release files are published as GitHub Release assets and are not committed to the source repository. Verify the SHA-256 checksum listed in the corresponding release notes before installation.

### Windows: use one package cache for the IDE and build tools

Packaged Windows apps can redirect `AppData` into an app-specific data area. In that situation, `.dart_tool/package_config.json` can reference packages that are available to the process that created it but unavailable to VS Code. An Android build may still succeed while F5 exits with `Exited (1)` and the app remains paused at startup.

Set `PUB_CACHE` for all tools to the same directory **outside AppData**, for example `C:\Users\<user>\development\pub-cache`, and run `flutter pub get` again. In VS Code, use the same value for `dart.env.PUB_CACHE` and `terminal.integrated.env.windows.PUB_CACHE`; reopen existing terminals after changing the environment. The local `.vscode/launch.json` starts `lib/main.dart` in Flutter debug mode.

## VS Code release task

Press `Ctrl+Shift+B` in VS Code to run the default task **Test Viewer: build signed release APK**. It restores packages, runs analysis and all tests, and creates the signed APK at `build/app/outputs/flutter-apk/app-release.apk`.

The task runs entirely on the local computer. It does not invoke Git, contact GitHub, upload artifacts, or publish a release.

## Included views

**Dashboard:** Customer title from `tblCustomer.Name`, six summary metrics, a due-date breakdown, the eight locations with the largest backlogs, and an interactive monthly forecast. The forecast horizon can be 12, 24, 36, 48, or 60 months. It starts on the reference date, includes its partial month, and does not count already overdue inspections again.

**Devices:** Search, multi-location selection, location search, result and due-date filters, natural numeric sorting, and device details. Wide displays use a table; narrow displays use a card list. The default page size is 25, with 5, 10, 25, 50, and 100 available. The whole page scrolls vertically instead of using a constrained table area.

**Reference date:** Either the current local date or a saved manual date. **Today · automatic** switches back to the current date. Settings persist. Customer names come from the database and are not hard-coded branding.

## Connecting a database

Select **Database** → **Choose folder** → grant access → enter a file name or relative path → **Save path & load**.

The default file is `pcdrdata.sqlite3`. A subfolder path such as `Inspections/pcdrdata.sqlite3` is supported. Absolute paths and `..` are deliberately rejected. Android stores a Storage Access Framework folder grant; iOS stores a document-picker bookmark. The app reads the selected source at startup, when returning to the foreground, and when **Refresh** is selected.

SQLite opens only a private temporary read copy. The source file is never modified. Active WAL/journal files, mismatched hashes between two read passes, and inconsistent databases produce a clear error. Finish and save the inspection, close the inspection app, and refresh; never delete journal files. Data retained after a load failure is explicitly marked as stale.

## Builds

Windows PowerShell from the project folder:

```powershell
.\Build.ps1 -Target Check
.\Build.ps1 -Target Debug
.\Build.ps1 -Target Release
.\Build.ps1 -Target AppBundle
```

`Release` and `AppBundle` require a local `android/key.properties` file that references the private signing key. Use `android/key.properties.example` as a template. Keys and passwords must remain outside version control.

macOS/Linux:

```sh
bash tool/build.sh android-debug
bash tool/build.sh ios-simulator
bash tool/build.sh ios-archive
```

The scripts run `flutter analyze` and `flutter test` before building and stop on failure. Flutter generates the Android Gradle wrapper, `local.properties`, `Generated.xcconfig`, and plugin registration when required. Do not run `flutter create` over the existing platform folders.

**Release ID:** `com.pezezzle.testmasterviewer` on both platforms. Android debug builds deliberately use `com.pezezzle.testmasterviewer.debug`, allowing them to coexist with an installed release signed by a different key.

## GitHub repository

The source is stored in the public repository `pezezzle/Test-Viewer`. Local changes must be reviewed and explicitly approved before they are committed, pushed, or published. Build artifacts are not added to the Git repository.

GitHub Actions includes validation, an Android debug build, an iOS simulator build, and a manually triggered signed Android build. Simulator and debug artifacts are not store releases. Release secrets must only be configured through protected GitHub environment secrets.

Approved production APKs are attached to GitHub Releases as public download assets.

## Further documentation

- [Architecture and data model](docs/ARCHITECTURE.md)
- [Build and test status](docs/BUILD_AND_TEST_STATUS.md)
- [Release, signing, and migration](docs/RELEASE.md)
- [Physical-device test plan](docs/DEVICE_TEST_PLAN.md)
- [Synthetic sample data](example/README.md)

No general open-source license has been granted. Repository access alone is not a license grant. Private inspection data, signing keys, credentials, and proprietary fonts are not part of this project.
