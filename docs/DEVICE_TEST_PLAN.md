# Abnahme auf echten Geräten

Diese Tests sind noch auszuführen, nicht als bestanden dokumentiert.

1. **Erster Start:** Ohne Freigabe sinnvolle Startseite. Demomodus öffnen und beenden; echte Daten dürfen nicht mit Demo-Daten gemischt werden.
2. **Quelle:** Lokalen Ordner wählen, Freigabe bestätigen, `pcdrdata.sqlite3` laden. Unterordnerpfad testen. Abbruch, falscher Pfad, unlesbare Datei und falsches Schema müssen verständliche Meldungen liefern.
3. **Persistenz:** App vollständig beenden und erneut öffnen, Tablet/iPhone neu starten. Erteilte Freigabe und Einstellungen prüfen. Unter Android ein echtes signiertes Update über die bestehende Version testen.
4. **Datenänderung:** Gerät in der Prüf-App verändern, Prüfung speichern, zurück zum Viewer. Prüfen, dass der neue Stand geladen wird. Bei aktivem WAL muss der Viewer ablehnen, nicht veraltete Daten als frisch bezeichnen.
5. **Kunden:** Datenbanken mit einem, zwei und ohne benannten Kunden testen. Gleiche Geräte-ID bei unterschiedlichen Kunden darf nicht zu einer Zusammenführung führen.
6. **Filter:** Mehrere Standorte auswählen, Suchtreffer hinzufügen, Suche ändern, Auswahl behalten, leeren Standort auswählen. Dashboard und Geräteliste müssen denselben Standortbereich verwenden.
7. **Stichtag:** Manuelles Datum wählen, neu laden, neu starten. Wieder auf automatisch stellen und Tageswechsel einschliesslich einer Sommerzeitgrenze testen.
8. **Vorschau:** Alle fünf Zeiträume, aktuelle Teilmonate, Jahreswechsel, leere Monate, horizontales Scrollen und Antippen eines Balkens prüfen. Überfällige Einträge werden nicht nochmals als Vorschau gezählt.
9. **Geräteliste:** Text- und Ergebnisfilter kombinieren, alle Sortierungen auf-/absteigend, ungültige Termine am Ende, führende ID-Nullen. Alle fünf Seitengrössen und die letzte unvollständige Seite prüfen.
10. **Display:** Smartphone und Tablet, Hoch-/Querformat, Bildschirmtastatur, grössere Schrift, TalkBack/VoiceOver. Die Hauptseite scrollt vollständig. Fehlermeldungen und lange Kundennamen dürfen nicht abgeschnitten werden.
11. **Originalschutz:** Vorher/nachher Hash der Quelldatei vergleichen. Keine Datei der Prüf-App und keine originale WAL-/Journaldatei darf verändert oder gelöscht werden.
12. **Release:** Flugmodus testen, App-Name/Icon, Bundle-ID, Signatur und Build-Nummer kontrollieren. Android-AAB beziehungsweise iOS-Archiv mit den eigenen Store-Werkzeugen validieren.
