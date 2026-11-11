# Visualisierung

## Deutsch

Das Paket verwendet FHEM-Bordmittel: FileLog, SVG und optional `weblink`. Es
braucht weder SQLite noch DbLog. Die fünf vorbereiteten Diagrammdateien liegen
in `www/gplot`:

- Preise: Tag, Woche, Monat und Jahr;
- TibberLive-Leistung: Tag.

Zusätzlich liegt `TibberConnect_PriceForecast.gplot` für den ausschließlich
zukünftigen, von Tibber bekannten Preisvorrat bei. Diese Ansicht ist bewusst
opt-in: Sie verwendet eine separate, vom Modul atomar erneuerte Quelldatei und
verändert keine bestehenden FileLog-/DbLog-Daten. Die neue GPlot-Datei wird
über den Update-Kanal installiert; danach `examples/tibber-forecast.cfg` **Zeile für Zeile** nach Prüfung
des lokalen Logpfads einfügen. Das Attribut `forecastLogFile` ist der explizite
Schalter. `priceForecastFrom` und `priceForecastUntil` begrenzen den SVG-Bereich
auf die tatsächliche Zukunft; auch 92/96/100 Viertelstunden an DST-Tagen bleiben
dabei korrekt. Zum Abschalten das Attribut und die optionalen FileLog-/SVG-
Definitionen benutzergeführt entfernen; die getrennte Datei kann danach
gelöscht werden. Wichtig: Die `fixedrange`-Zeile aus dem Beispiel verwendet
innerhalb der Perl-Expression absichtlich `;;`. Das ist die FHEM-Escapesequenz
für ein Semikolon in einer gespeicherten CFG und darf nicht zu `;` gekürzt
werden.

Die sechs GPlot-Dateien werden über den Update-Kanal automatisch in das
FHEM-Verzeichnis `www/gplot` installiert. Richte anschließend die beiden
FileLogs aus `examples/tibber-filelog.cfg` ein. Erst danach die
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

## Bestehende 99_myUtils.pm

Bei einer bestehenden Definition `define Tibber_Overview weblink htmlCode
{TibberOverview()}` bleibt diese Definition erhalten. Ersetze nur die Funktion
`TibberOverview` in der vorhandenen `99_myUtils.pm` durch das getestete Snippet
aus `examples/99_myUtils_TibberOverview.pm`; andere persönliche Hilfsfunktionen
bleiben unverändert. Das Snippet macht die Ansicht lesbarer und behält
Preisampel, Preisvorschau, Tendenz und Pulse-Status bei.
