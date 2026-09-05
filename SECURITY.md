# Sicherheit

Keine Originaldatenbanken, echten Gerätelisten, privaten Signaturschlüssel, Passwörter oder personenbezogenen Screenshots in öffentliche Issues, Commits oder Actions-Logs einfügen. Für Fehlerberichte ausschliesslich fiktive Beispieldaten und bereinigte Logs verwenden.

Der Viewer nimmt keine Gerätesicherheitsbewertung vor und schreibt nicht in die Originaldatenbank. Datumsstatus und Ergebniscode sind getrennt. Ein „später fälliges“ Gerät kann trotzdem einen negativen Prüfcode besitzen.

Das öffentliche Paket enthält keinen privaten Release-Key. Eine Schlüsseldatei gehört lokal in `signing/` oder in dafür vorgesehene geheime CI-Variablen. Eine `.gitignore` entfernt keine Dateien aus bereits vorhandener Git-Historie. Vor einer Veröffentlichung deshalb immer auch die Historie prüfen.

Mögliche Sicherheitsprobleme zunächst privat mit dem Herausgeber klären; keine realen Prüfdaten zur Reproduktion veröffentlichen.
