# Test Viewer · Flutter

Offline-Erweiterung zur Test-Master App für die Auswertung von Geräteprüfungen auf Android und iOS. Version **2.0.0+6**. Die Oberfläche und Auswertungslogik sind mit Dart und Flutter-Widgets umgesetzt; **keine WebView**.

**Projektstatus:** Flutter-Analyse, Widget-/Logiktests und Android-Debug-Build wurden lokal erfolgreich ausgeführt. Der iOS-Build benötigt weiterhin macOS mit Xcode. Details: [Build- und Teststatus](docs/BUILD_AND_TEST_STATUS.md).

## Starten

Projektordner mit `pubspec.yaml` in Android Studio mit Flutter-Plugin oder VS Code öffnen. Vorgesehenes SDK: **Flutter 3.44.9 / Dart 3.12**; `.fvmrc` legt die Flutter-Version fest. Android verwendet JDK 17.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Für den ersten Blick ohne eigene Datenbank auf **„Mit fiktiven Daten ausprobieren“** tippen. Alternativ:

```sh
flutter run --dart-define=DEMO_MODE=true
```

Die App ist für Android 8.0+ und iOS 15+ konfiguriert. Die Signierung für echte Geräte und Stores erfolgt mit den eigenen Schlüsseln beziehungsweise dem eigenen Apple-Team.

### Windows: gleicher Paketcache in IDE und Build-Werkzeugen

Bei paketierten Windows-Apps (beispielsweise Codex) kann `AppData` in einen eigenen App-Datenbereich umgeleitet werden. Dann verweist `.dart_tool/package_config.json` auf Pakete, die für den erzeugenden Prozess existieren, für VS Code aber nicht. Ein Android-Build kann trotzdem erfolgreich sein, während F5 mit `Exited (1)` abbricht und die App in der Startpause bleibt.

In diesem Fall `PUB_CACHE` für alle Werkzeuge auf denselben Ordner **ausserhalb von AppData** setzen, zum Beispiel `C:\Users\<Benutzer>\development\pub-cache`, und `flutter pub get` erneut ausführen. In VS Code denselben Wert unter `dart.env.PUB_CACHE` und `terminal.integrated.env.windows.PUB_CACHE` verwenden; bestehende Terminals nach einer Umgebungsänderung neu öffnen. Die lokale `.vscode/launch.json` startet `lib/main.dart` im Flutter-Debugmodus.

## Enthaltene Ansichten

**Dashboard:** Kundentitel aus `tblCustomer.Name`, sechs Kennzahlen, Fälligkeitsverteilung, acht Standorte mit den grössten Rückständen und eine anklickbare Monatsvorschau. Der Zeitraum ist auf 12, 24, 36, 48 oder 60 Monate einstellbar. Die Vorschau beginnt am Stichtag, zeigt dessen angebrochenen Monat mit an und zählt keine bereits überfälligen Termine erneut.

**Geräte:** Suche, mehrere Standorte gleichzeitig, Standortsuche, Ergebnis- und Fälligkeitsfilter, numerisch sinnvolle Sortierung sowie Gerätedetails. Auf breiten Displays erscheint die Tabelle, auf schmalen Displays eine Kartenliste. 25 Einträge pro Seite sind voreingestellt; wählbar sind 5, 10, 25, 50 und 100. Die gesamte Seite scrollt vertikal, nicht ein begrenzter Tabellenbereich.

**Stichtag:** Automatisch der aktuelle lokale Tag oder ein gespeichertes manuelles Datum. „Heute · automatisch“ schaltet zurück. Einstellungen bleiben erhalten. Kundenbezeichnungen werden aus der Datenbank gelesen, nicht als feste Firmenmarke eingebaut.

## Datenbank verbinden

„Datenbank“ → „Ordner wählen“ → Zugriff bestätigen → Dateiname oder relativen Pfad eintragen → „Pfad speichern & laden“.

Voreingestellt ist `pcdrdata.sqlite3`. Ein Unterordnerpfad wie `Prüfungen/pcdrdata.sqlite3` ist möglich. Absolute Pfade und `..` sind absichtlich gesperrt. Android verwendet eine gespeicherte SAF-Ordnerfreigabe, iOS eine gespeicherte Dateiauswahl mit Bookmark. Beim Start, bei der Rückkehr in die App und über „Aktualisieren“ wird erneut aus der ausgewählten Quelle gelesen.

Nur eine private temporäre Lesekopie wird mit SQLite geöffnet. Die Quelldatei wird nicht verändert. Aktive WAL-/Journaldateien, unterschiedliche Hashes der zwei Lesedurchgänge und inkonsistente Datenbanken führen zu einer Meldung. In diesem Fall die Prüfung fertig speichern, die Prüf-App schliessen und neu laden; Journaldateien nicht löschen. Ein alter Datenstand nach einem Ladefehler wird ausdrücklich markiert.

## Builds

Windows, PowerShell im Projektordner:

```powershell
.\Build.ps1 -Target Check
.\Build.ps1 -Target Debug
.\Build.ps1 -Target Release
.\Build.ps1 -Target AppBundle
```

`Release` und `AppBundle` benötigen `android/key.properties` mit dem privaten Schlüssel. Vorlage: `android/key.properties.example`. Schlüssel gehören ausschliesslich in den ignorierten lokalen Ordner `signing/`. **Nicht** in Git einchecken.

macOS/Linux:

```sh
bash tool/build.sh android-debug
bash tool/build.sh ios-simulator
bash tool/build.sh ios-archive
```

Die Scripts führen vor dem Build `flutter analyze` und `flutter test` aus und stoppen bei Fehlern. Der Android-Gradle-Wrapper wird beim ersten Flutter-Build aus dem Flutter SDK erzeugt; `local.properties`, `Generated.xcconfig` und die Plugin-Registrierung werden ebenfalls durch Flutter generiert. Kein `flutter create` oder Überschreiben der Plattformordner nötig.

**Release-ID:** `com.pezezzle.testmasterviewer` auf beiden Plattformen. Android-Debug-Builds verwenden absichtlich `com.pezezzle.testmasterviewer.debug`, damit sie neben einer bereits installierten, anders signierten Release-App getestet werden können.

## GitHub veröffentlichen

Das Quellpaket ist für ein **neues öffentliches Repository `pezezzle/testmaster-viewer-flutter`** vorbereitet. Das Paket selbst bedeutet nicht, dass dieses Repository bereits online angelegt wurde.

In einem frisch entpackten Quellordner mit installiertem Git und GitHub CLI:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Publish-ToGitHub.ps1
```

Das Script prüft das Konto `pezezzle`, blockiert offensichtliche private Dateitypen, verweigert vorhandene Git-Historie und überschreibt kein bestehendes Repository. Vor der Veröffentlichung alle Quelldateien prüfen. Bereits vorhandene Git-Historie oder ein Repository aus einem Git-Bundle bewusst mit normalen Git-Befehlen veröffentlichen, nicht durch dieses Initial-Uploadscript.

GitHub Actions enthält Prüfungen, einen Android-Debug-Build, einen iOS-Simulator-Build und einen manuell auslösbaren signierten Android-Build. Die Workflows sind vorbereitet, **nicht bereits erfolgreich ausgeführt**. Simulator- und Debug-Artefakte sind keine Store-Releases.

## Weiterführende Dokumente

- [Architektur und Datenmodell](docs/ARCHITECTURE.md)
- [Build- und Teststatus](docs/BUILD_AND_TEST_STATUS.md)
- [Release, Signierung und Migration](docs/RELEASE.md)
- [Testplan auf echten Geräten](docs/DEVICE_TEST_PLAN.md)
- [Fiktive Beispieldaten](example/README.md)

Es ist keine allgemeine Open-Source-Lizenz festgelegt. Eine öffentliche Ablage allein ist keine Lizenzfreigabe. Private Prüfdaten, Signaturschlüssel, Zugangsdaten und Schriftdateien sind nicht Bestandteil dieses Projekts.
