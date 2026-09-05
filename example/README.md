# Fiktive Beispieldaten

Die App bietet auf der Startseite **„Mit fiktiven Daten ausprobieren“**. Der Demomodus ist ausdrücklich gekennzeichnet und mischt sich nicht mit einer ausgewählten Datenbank.

Für einen echten Test der Android- oder iOS-Ordnerauswahl lässt sich zusätzlich eine SQLite-Datei mit ausschliesslich fiktiven Daten erzeugen:

```sh
python tool/create_demo_database.py example/demo.sqlite3
```

Diese Datei in einen freigegebenen Ordner des Testgeräts kopieren. In der App diesen Ordner und `demo.sqlite3` auswählen. Die Datei wird von Git ignoriert. Der Generator überschreibt keine vorhandene Datei.

Alle Personen-, Kunden-, Hersteller- und Gerätedaten des Beispiels sind erfunden. Sie sind kein Prüfprotokoll und nicht zur Beurteilung der Sicherheit von Geräten geeignet.
