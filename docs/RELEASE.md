# Release und Migration

## Android

Das Projekt verwendet für Release `com.pezezzle.testmasterviewer`, Version `2.0.0`, versionCode `6`. Ein Update über die frühere App erfordert denselben bisherigen privaten Signaturschlüssel. Dieser ist absichtlich **nicht** im öffentlichen Projekt enthalten. Aus dem privaten Backup nur lokal übernehmen, `android/key.properties.example` nach `android/key.properties` kopieren und die tatsächlichen Werte eintragen.

Der Ordnerzugriff der bisherigen Android-App wird aus SharedPreferences `viewer` / `tree` und `path` übernommen, wenn die App unter derselben ID und Signatur aktualisiert wird. Die früher in der WebView gespeicherten Filter werden **nicht** migriert; Standorte, Seitengrösse und Stichtag können einmal neu eingestellt werden. Keine Deinstallation erforderlich, sobald ein korrekt signiertes Update vorliegt.

Debug-Builds sind absichtlich getrennte Installationen mit `.debug` am Ende der ID und übernehmen daher keine Freigaben aus Release. Eine Debug-APK ist kein signiertes Produktionsupdate.

Vor einem Store-Upload `flutter build appbundle --release` und die Prüfroutinen aus dem Testplan ausführen. Es ist kein automatischer Upload in Google Play eingerichtet.

## Android-Signierung in GitHub Actions

Optional ein GitHub-Environment **android-release** einrichten und Review-Freigaben aktivieren. Dort vier Secrets hinterlegen: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. Es wird ein PKCS12-Key erwartet. Der Workflow schreibt den Key nur in den temporären Runner-Speicher und löscht ihn am Ende. Private Werte gehören niemals in YAML oder Commits.

Die Datei `.github/workflows/android-release.yml` wird ausschliesslich manuell ausgelöst. Sie erstellt signierte APK/AAB-Artefakte, legt aber keine öffentliche GitHub-Release an und lädt nichts in einen Store hoch.

## iOS

Bundle-ID `com.pezezzle.testmasterviewer`, Deployment Target iOS 15. In `ios/Runner.xcworkspace` das eigene Team unter **Signing & Capabilities** auswählen. Kein fremdes Team und keine fremden Zertifikate sind vorkonfiguriert. Flutter erzeugt die Plugin-Registrierung und SDK-Konfiguration beim ersten `pub get`/Build.

`bash tool/build.sh ios-simulator` erzeugt einen unsignierten Simulator-Build. `bash tool/build.sh ios-archive` verwendet `flutter build ipa --release` und benötigt die eigene gültige Signierung. Das CI-Artefakt des iOS-Simulators kann nicht als IPA auf ein iPhone installiert oder in den App Store eingereicht werden.

Vor der Einreichung insbesondere die dauerhafte Ordnerfreigabe, den Zugriff nach Neustarts, den tatsächlichen Dateiprovider, Privacy Manifest, App-Icon und Geräteorientierungen prüfen. Apple-Team, Store-Einträge, rechtliche Angaben und Nutzungsrechte müssen vom Herausgeber festgelegt werden. Die mitgelieferte Beispielansicht kann für eine nachvollziehbare App-Prüfung verwendet werden.

## Projektwerkzeuge

Flutter ist auf 3.44.9 festgelegt. Android: Gradle 9.1.0, AGP 9.0.1, Java 17, minSdk 26. Die beiden AGP-9-Kompatibilitätsschalter entsprechen der Flutter-3.44.9-Vorlage. `flutter pub get` erzeugt beim ersten echten Lauf eine `pubspec.lock`; diese anschliessend mit dem geprüften Stand einchecken. Sie wurde nicht erfunden oder vorgetäuscht.

Referenzen zur Implementierung:
- https://docs.flutter.dev/platform-integration/platform-channels
- https://docs.flutter.dev/deployment/android
- https://docs.flutter.dev/deployment/ios
- https://github.com/flutter/flutter/tree/3.44.9/packages/flutter_tools/templates/app
- https://developer.android.com/training/data-storage/shared/documents-files
- https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
