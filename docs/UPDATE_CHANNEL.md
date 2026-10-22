# FHEM update channel / FHEM-Updatequelle

## Deutsch

Die Updatequelle aktualisiert ausschließlich Dateien, die ohne Überschreiben
persönlicher Konfigurationen sicher automatisiert werden können:

- `FHEM/70_TibberConnect.pm`
- `FHEM/70_TibberLive.pm`
- die sechs mitgelieferten Dateien unter `www/gplot/`

Nicht Teil des automatischen Updates sind `99_myUtils.pm`, Geräte-Definitionen,
Token, Home-IDs, FileLogs, SVG-Geräte, persönliche Diagramme und die
FHEM-Konfiguration. Die Übersicht ist bewusst ein Beispiel; ein Update darf
niemals eigene Hilfsfunktionen überschreiben.

README, Installationshilfe, Rückweg-Hinweise und weitere Beispiele bleiben im
GitHub-Projekt als lesbare Dokumentation. Auch eine Neuinstallation verwendet
den Update-Kanal; Modul- und GPlot-Dateien werden nicht manuell kopiert.

Die Befehle einzeln im FHEM-Kommandoeingabefeld ausführen:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Erst wenn die Vorschau ausschließlich die erwarteten zwei Moduldateien und
gegebenenfalls die sechs Tibber-GPlot-Dateien nennt:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Danach FHEM neu starten:

```text
shutdown restart
```

Bestehende Geräte, Readings und persönliche Konfigurationen bleiben
unangetastet. Vor jedem Update gilt weiterhin: Sicherung und Sichtprüfung der
Vorschau.

Das Entfernen der Updatequelle beendet nur zukünftige Updates und löscht keine
installierten Dateien:

```text
update delete https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Für einen Rückweg zu einer vorherigen Modulversion gilt die dokumentierte
Dateisicherung aus [ROLLBACK.md](ROLLBACK.md); ein Updatekanal ist kein Ersatz
für ein Backup.

## English

The update source intentionally updates only the two module files and the six
supplied GPlot files. It never overwrites tokens, Home IDs, device definitions,
FHEM configuration, logs, SVG devices, or personal `99_myUtils.pm` helpers.

Add, review and apply updates separately:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Restart FHEM afterwards. To stop future updates without removing files:

```text
update delete https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Always inspect the preview and keep a local backup. See [ROLLBACK.md](ROLLBACK.md)
for the manual return path.
