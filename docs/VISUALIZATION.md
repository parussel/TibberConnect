# Visualization / Visualisierung

Das Paket verwendet FHEM-Bordmittel: FileLog, SVG und optional `weblink`. Es
braucht weder SQLite noch DbLog. Die fünf vorbereiteten Diagrammdateien liegen
in `www/gplot`:

- Preise: Tag, Woche, Monat und Jahr;
- TibberLive-Leistung: Tag.

Kopiere diese Dateien in das FHEM-Verzeichnis `www/gplot`. Richte anschließend
die beiden FileLogs aus `examples/tibber-filelog.cfg` ein. Erst danach die
Definitionen aus `examples/tibber-dashboard.cfg` in FHEM einfügen. Die
Beispiele erwarten daher genau die Namen `FileLog_TibberConnect` und
`FileLog_TibberLive`.

Die Beispielansicht im Raum **Tibber** enthält:

- eine kompakte Übersicht mit aktuellem Preis, aktueller Leistung, günstigstem
  konfigurierten Zeitfenster sowie Live-/Morgenstatus;
- ein Tagesdiagramm der Preise;
- ein Tagesdiagramm der Live-Leistung.

Die Übersicht liest nur vorhandene lokale Readings. Sie schaltet nichts und
überträgt keine Daten. `weblink` ist Teil einer üblichen FHEM-Installation;
wenn die Übersicht nicht gewünscht ist, können die beiden SVG-Diagramme auch
allein verwendet werden.

Für Woche, Monat oder Jahr erzeugst du weitere SVG-Instanzen nach demselben
Muster und ersetzt nur die gplot-Datei durch
`TibberConnect_Prices_Week`, `TibberConnect_Prices_Month` oder
`TibberConnect_Prices_Year`. Die längeren Ansichten verwenden bewusst
verdichtete Werte, damit sie übersichtlich und ressourcenschonend bleiben.

`define` ist für eine neue Instanz gedacht. Existiert ein gleichnamiges Gerät
bereits, verwende beim bewussten Aktualisieren `defmod` oder gib einen anderen
Namen. Vor Änderungen an einer produktiven FHEM-Konfiguration gilt weiterhin:
Sicherung anlegen und die Konfiguration selbst kontrolliert speichern.

## Vorhandene 99_myUtils.pm

Bei einer bestehenden Definition `define Tibber_Overview weblink htmlCode
{TibberOverview()}` bleibt diese Definition erhalten. Ersetze nur die Funktion
`TibberOverview` in der vorhandenen `99_myUtils.pm` durch das Beispiel aus
`examples/99_myUtils_TibberOverview.pm`; andere persönliche Hilfsfunktionen
bleiben unverändert. Das Beispiel macht die Ansicht lesbarer und behält
Preisampel, Preisvorschau, Tendenz und Pulse-Status bei.
