# Tatsächlicher Prüfstand

Stand: **5. September 2026**, Quellversion **2.0.0+6**.

## Ausgeführt und bestanden

- flutter analyze: keine Befunde.
- flutter test: alle **51** Logik- und Widget-Tests bestanden, einschliesslich 320/390/1024 Pixel Breite, Dialog-Lebenszyklen und Branding-Zeichen.
- Android-Debug-APK mit Flutter 3.44.9 und JDK 17 erfolgreich gebaut, auf einem Samsung SM-S928B installiert und gestartet.
- Der tatsächliche Swift-Code aus `ios/Runner/DeviceDatabase.swift` wurde mit Swift 6.2.1 unter Linux gegen SQLite3 kompiliert und ausgeführt. Das ist derselbe SQL-Reader, den die iOS-Anbindung aufruft, aber kein iOS-App-Build.
- Vergleich mit der privat bereitgestellten Datenbank: **1’525 Geräte**, sämtliche 19 projizierten Rohfelder und Kundeneinträge stimmen mit einer unabhängigen Python/SQLite-Abfrage überein. Der SHA-256-Hash der Originaldatei war vor und nach der Prüfung identisch.
- Zusätzlicher Vergleich mit **80 rein fiktiven Geräten**: alle Rohwerte identisch, Originalhash unverändert.
- Minimaldatenbank ohne optionale Gerätespalten und ohne Kundentabelle: erfolgreich gelesen; fehlende Werte bleiben leer/null.
- Falsches Geräteschema: kontrolliert abgelehnt.
- **13 Swift- und 13 Java-Prüffälle** zur Pfadvalidierung wurden tatsächlich ausgeführt und bestanden.
- Die fünf iOS-Swift-Dateien wurden vom Swift-Parser syntaktisch akzeptiert. Dabei wurden UIKit-, Flutter- und Apple-Dateianbindungs-APIs unter Linux ausdrücklich nicht typgeprüft.
- Dart-Quellen wurden zusätzlich mit dem Dart-Analyzer geprüft.
- Projektkonfigurationen, XML-/Plist-Dateien, Xcode-Objektreferenzen und öffentliche Dateiinhalte wurden statisch geprüft. Das öffentliche Paket enthält keine Originaldatenbank, privaten Schlüssel oder Schriftdateien.

Die Native-Prüfungen sind mit `python tool/test_native.py` reproduzierbar, sofern Swift, SQLite-Header und JDK vorhanden sind. Eine private Datenbank kann optional mit `--database /lokaler/pfad/pcdrdata.sqlite3` zusätzlich verglichen werden; ihre Datensätze werden dabei nicht ausgegeben.

## Noch nicht vollständig ausgeführt

- Flutter-Integrationstest für den ausdrücklich gekennzeichneten Demomodus.
- Android-Release-/App-Bundle-Build mit produktiver Signierung sowie Xcode-/Flutter-iOS-Build.
- Native Android-SAF- und iOS-Bookmark-/Security-Scope-Tests auf echten Geräten.
- Die GitHub-Actions-Workflows und das Windows-PowerShell-Uploadscript.

## Konsequenz

Der Flutter-Quellstand und der Android-Debug-Pfad sind lokal geprüft. Eine produktive Android-Signierung, Store-Abnahme und iOS-Abnahme bleiben plattformspezifisch offen.

Erste Prüfung nach dem Entpacken: `flutter pub get`, `flutter analyze`, `flutter test`, danach der gewünschte Plattform-Build. Eventuelle Analyzer-, SDK- oder Plattformfehler sind vor einer produktiven Installation beziehungsweise Store-Einreichung zu beheben. Der bereitgestellte CI-Workflow macht diese Prüfung beim späteren Upload sichtbar.
