# Visualisierung

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

## Eigene Diagrammanpassungen vor Updates schützen

Die vom Update-Kanal gelieferten GPlot-Dateien können bei einer späteren
Aktualisierung ersetzt werden. Ändere diese Originaldateien deshalb nicht
direkt. Kopiere eine anzupassende Datei stattdessen unter einen eigenen Namen
mit dem Präfix `Privat_`, beispielsweise
`Privat_TibberConnect_Prices_Day.gplot`, und wähle diese Kopie in der
zugehörigen SVG-Definition aus. Die Originaldatei bleibt damit updatefähig,
während persönliche Farben, Linien und Beschriftungen erhalten bleiben.

In der geprüften Referenzinstallation werden die fünf normalen Preis- und
Leistungsdiagramme aus solchen `Privat_`-Kopien erzeugt. Die ausschließlich
zukünftige Preisvorschau verwendet weiterhin die unveränderte gelieferte Datei
`TibberConnect_PriceForecast.gplot`.

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

## Getrennte Hilfsdatei für die Übersicht

Die Referenzinstallation hält die Übersicht bewusst in der eigenen Datei
`FHEM/99_myUtils_TibberOverview.pm`. Dadurch bleibt eine vorhandene
`99_myUtils.pm` mit anderen persönlichen Hilfsfunktionen unangetastet. Kopiere
die Beispieldatei `examples/99_myUtils_TibberOverview.pm` unter genau diesem
Namen in das FHEM-Verzeichnis und lade sie anschließend kontrolliert neu.

Die Definition `define Tibber_Overview weblink htmlCode {TibberOverview()}`
verwendet danach die Funktion aus dieser getrennten Datei. Die Übersicht liest
nur lokale Readings, überträgt keine Daten und schaltet nichts. Wer die Funktion
bereits in einer vorhandenen `99_myUtils.pm` betreibt, kann diese funktionierende
Einbindung beibehalten; persönliche Hilfsfunktionen dürfen dabei nicht ersetzt
werden.
