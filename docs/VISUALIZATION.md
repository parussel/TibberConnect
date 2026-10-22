# Visualization / Visualisierung

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

## English

The package uses standard FHEM facilities: FileLog, SVG, and optionally
`weblink`. It requires neither SQLite nor DbLog. The update channel installs
the supplied files from `www/gplot` automatically. Create the two FileLogs from
`examples/tibber-filelog.cfg`, and then add the definitions from
`examples/tibber-dashboard.cfg`.

The example room provides a compact local-reading overview, a daily price plot,
and a daily live-power plot. It is display-only: it performs no switching and
sends no data. Use the Week, Month, and Year gplot names for longer price
views. Existing devices should be deliberately updated with `defmod` or given
a different name; create a backup before changing a production configuration.

`TibberConnect_PriceForecast.gplot` is an additional opt-in future-only price
view. It uses a separately, atomically refreshed source file and never changes
existing FileLog/DbLog history. The update channel installs the GPlot file;
then review and enter `examples/tibber-forecast.cfg` one line at a time with a
local log path.
`forecastLogFile` is the explicit switch. `priceForecastFrom` and
`priceForecastUntil` restrict the SVG range to the actual future cache horizon,
including 92/96/100 quarter-hour DST days. To undo it, deliberately remove the
attribute and optional FileLog/SVG definitions, then delete the separate file.

## Existing 99_myUtils.pm / Bestehende 99_myUtils.pm

If an installation already uses `define Tibber_Overview weblink htmlCode
{TibberOverview()}`, keep that working definition. Replace only the
`TibberOverview` subroutine in the existing `99_myUtils.pm` with the tested
snippet in `examples/99_myUtils_TibberOverview.pm`; do not replace unrelated
personal helper functions. The snippet uses larger, brighter text while keeping
the German price signal, price forecast, trend, and Pulse connection status.

Bei einer bestehenden Definition `define Tibber_Overview weblink htmlCode
{TibberOverview()}` bleibt diese Definition erhalten. Ersetze nur die Funktion
`TibberOverview` in der vorhandenen `99_myUtils.pm` durch das getestete Snippet
aus `examples/99_myUtils_TibberOverview.pm`; andere persoenliche Hilfsfunktionen
bleiben unveraendert. Das Snippet macht die Ansicht lesbarer und behaelt
Preisampel, Preisvorschau, Tendenz und Pulse-Status bei.
