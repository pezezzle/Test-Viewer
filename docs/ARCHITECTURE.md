# Architektur

## Gemeinsamer Flutter-Teil

`lib/domain` enthält Datumsberechnung, Geräte-Datenmodell, Suche, natürliche Sortierung, Filter und Monatsaggregation. `CalendarDay` berechnet Tagesabstände über UTC-Mitternacht, liest den automatischen Stichtag aber aus dem lokalen Kalenderdatum. Dadurch verschieben Sommerzeitwechsel die Tagesabstände nicht.

`lib/state/viewer_controller.dart` verwaltet Quelle, Datenstand, Stichtag, Standortauswahl, Pagination und gespeicherte Einstellungen. Ein Fehler beim erneuten Einlesen lässt den alten Datenstand sichtbar, kennzeichnet ihn aber als veraltet. Beim Wechsel der Datenquelle werden alte Gerätedaten und Quellfilter verworfen. Ein manuelles Datum bleibt erhalten.

`lib/ui` enthält ausschliesslich Flutter-Widgets und einen `CustomPainter` für das Ringdiagramm. `lib/data/platform_store.dart` bildet die Grenze zur nativen Datei- und Datenbankanbindung. `DemoViewerStore` ist ein expliziter, rein fiktiver Ersatz für diese Schnittstelle.

## Native Anbindung

MethodChannel: `com.pezezzle.testmasterviewer/data`.

| Aufruf | Antwort |
|---|---|
| `configuration` | JSON mit Ordner, Quellkennung, relativem Pfad und Konfigurationsstatus |
| `chooseFolder` | Gespeicherte Ordnerfreigabe als JSON; bei Abbruch `null` |
| `savePath` | Validierter relativer Pfad und aktuelle Konfiguration |
| `readSnapshot` | JSON mit `devices`, `customers`, Quelle und erfolgreichem Lesezeitpunkt |
| `loadSettings` / `saveSettings` | Gemeinsamer JSON-Einstellungsstand |

Android: Java, `FlutterActivity`, Storage Access Framework, SharedPreferences und Android-SQLite. Das Lesen läuft auf einem seriellen Worker; Antworten werden auf den UI-Thread zurückgegeben.

iOS: Swift, `FlutterAppDelegate`/`FlutterSceneDelegate`, `UIDocumentPickerViewController`, Bookmark und Security-Scoped Resource, UserDefaults sowie SQLite3. Datei-Lesezugriffe werden mit `NSFileCoordinator` koordiniert und laufen auf einer seriellen Queue.

## Datenmodell

Erforderlich ist `tblIDNumbers` mit `CustomerNumber`, `IDNumber`, `Location`, `DeviceDescription` und `NextTest`. Weitere bekannte Spalten werden übernommen; fehlende optionale Spalten erscheinen als leer. Die Kunden werden aus `tblCustomer` gelesen, soweit vorhanden. Ohne Kundennamen wird die Kundennummer angezeigt.

Geräte werden über **Kundennummer + Geräte-ID** unterschieden. IDs bleiben Strings, damit führende Nullen erhalten bleiben. Geräte mit gleichen IDs bei verschiedenen Kunden werden nicht zusammengeführt. Leere Standorte sind als „Ohne Standort“ auswählbar. Mehrfachauswahl verknüpft Standorte mit ODER; verschiedene Filter und Suchwörter werden mit UND verknüpft.

Ausgewertet wird `NextTest` im Gerätestamm. Es werden keine Termine aus Prüfintervallen hochgerechnet und keine Prüfergebnisse aus anderen Tabellen rekonstruiert. `LastTest` und Ergebniscode stammen ebenfalls aus dem Gerätestamm. Eine neue Auswertung der Prüfhistorie ist nicht Teil der zwei gewünschten Ansichten.

Die Kategorien sind: vor Stichtag, am Stichtag, 1–30, 31–90, mehr als 90 Tage sowie kein gültiger Termin. Der Dashboard-Filter „bis 30 Tage“ umfasst den Stichtag. Ein guter Terminstatus ist keine Aussage über die technische Sicherheit. Ergebniscode `F` bleibt eine separate Auffälligkeit.

## Snapshot-Schutz

1. Nur Dateien innerhalb des vom Nutzer freigegebenen Ordners zulassen.
2. Aktive SQLite-Begleitdateien ablehnen.
3. Quelle in privaten temporären Speicher kopieren und SHA-256 bilden.
4. Quelle erneut vollständig hashen; Begleitdateien davor und danach prüfen.
5. Nur bei identischen Hashes und gültigem SQLite-Header die Kopie öffnen.
6. `PRAGMA quick_check(1)` ausführen, Schema prüfen, begrenzte Datensätze lesen.
7. Temporäre Kopie und nur deren Begleitdateien entfernen.

Grenzen: 512 MB Quelldatei, 200’000 Datensätze im mobilen Reader, 500 Zeichen im relativen Pfad. Diese Schutzmassnahmen ersetzen keinen Test des konkreten Dateiproviders. Eine laufende Prüf-App mit aktivem WAL muss ihre Änderungen erst sicher in die Hauptdatei übernehmen; die Übersicht erzwingt keinen Checkpoint in einer fremden Datenbank.

## Datenhaltung und Datenschutz

Keine eigene Serververbindung, keine Telemetrie, kein Konto, keine Remote-Schriftarten. Android-Release enthält keine `INTERNET`-Berechtigung. Android-Debug/Profile benötigen sie für Flutter-Werkzeuge. Die App speichert Quellenfreigabe und Filter lokal. Sicherheitskopien des Betriebssystems beziehungsweise die Herkunft einer freigegebenen Datei sind vom App-Code getrennt zu betrachten.

Öffentliche Quellen enthalten keine Originaldatenbank und keine privaten Schlüssel. Der iOS-Privacy-Manifest beschreibt die verwendeten lokalen APIs; vor einer Store-Einreichung mit dem tatsächlich erzeugten Archiv erneut prüfen.
