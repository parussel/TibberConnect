# FHEM-Updatequelle

Die Updatequelle umfasst ausschließlich diese sieben Dateien:

- `FHEM/70_TibberConnect.pm`
- `FHEM/70_TibberLive.pm`
- fünf bereitgestellte Dateien unter `www/gplot/`

Token, Home-IDs, Geräte-Definitionen, FileLogs, persönliche Diagramme,
`99_myUtils.pm` und FHEM-Konfiguration sind nicht enthalten.

Führe die Befehle einzeln im FHEM-Kommandoeingabefeld aus. Erstelle vorher eine
aktuelle Sicherung.

Quelle registrieren:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Vorschau abrufen:

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Prüfe, dass nur die beiden Module und die fünf GPlot-Dateien angeboten werden.
Wenn die Liste stimmt, installiere das Update:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Danach FHEM neu starten, damit die Moduländerungen geladen werden:

```text
shutdown restart
```

Um zukünftige Updates über diese Quelle abzumelden, ohne installierte Dateien
zu löschen:

```text
update delete https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Ein Updatekanal ersetzt keine Sicherung. Für die Wiederherstellung einer
vorherigen Modulversion siehe [ROLLBACK.md](ROLLBACK.md).
