# TibberConnect und TibberLive für FHEM

## Deutsch

TibberConnect ist das Konto- und REST-Modul. Es speichert Viertelstundenpreise
im Cache, meldet verzögerte Verbrauchs- und Kostendaten und berechnet beratende
Preisfenster. TibberLive ist ein separates, optionales Modul für Pulse-
Livewerte. Diese Unterscheidung ist wichtig: **Preise**, **verzögerte
Verbrauchsdaten** und **Pulse-Livewerte** haben unterschiedliche
Aktualisierungszeiten und Übertragungswege.

Das Paket enthält `FHEM/70_TibberConnect.pm` und `FHEM/70_TibberLive.pm`.
Verwende eine TibberConnect-Instanz pro Konto und eine TibberLive-Instanz pro
Home; Tibber erlaubt höchstens zwei gleichzeitige Live-Sockets.

> **Status und Risiko:** Unabhängiges FHEM-Community-Projekt und derzeit kein
> offizieller Bestandteil von FHEM. Dieser öffentliche Release Candidate wurde
> automatisiert sowie durch anwenderseitige Zieltests auf Raspberry Pi 3 und 4
> geprüft. Die dokumentierte Neuinstallation ist der abschließende
> Abnahmeschritt. Vor der Verwendung – insbesondere mit TibberLive – muss die
> Installation gesichert werden.

> **Sicherheit und Eigenverantwortung:** TibberConnect und TibberLive werden
> ohne Gewähr bereitgestellt. Die Nutzung der Module, ihrer Readings,
> Preisprognosen und Beispiele erfolgt ausschließlich auf eigene Verantwortung.
> Die Module schalten selbst keine Verbraucher. Jede selbst eingerichtete
> Automation, Schaltlogik oder Ansteuerung realer Geräte liegt vollständig in
> der Verantwortung des Anwenders. Vor dem produktiven Einsatz sind Sicherung,
> Plausibilitätsprüfung und ein getrennter Test erforderlich.

Projektinformationen: [153er-netz.de – Entwicklung](https://153er-netz.de/seiten/entwicklung.html)

### Schnellstart

Der normale Installationsweg erfolgt vollständig über den FHEM-Update-Kanal.
Die Befehle im FHEM-Kommandoeingabefeld jeweils einzeln eingeben:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Nur wenn die Vorschau die erwarteten Tibber-Modul- und GPlot-Dateien nennt:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Danach FHEM neu starten:

```text
shutdown restart
```

Erst anschließend die Geräte definieren und den persönlichen Token lokal
speichern:

```text
define TibberConnect TibberConnect
set TibberConnect token <PERSOENLICHER_ACCESS_TOKEN>
set TibberConnect refreshHomes
```

Wähle bei Bedarf ein gefundenes Home:

```text
set TibberConnect selectHome <HOME_ID_AUS_AVAILABLEHOMES>
```

Für Live-Daten erst die optionalen Abhängigkeiten prüfen und dann eingeben:

```text
define TibberLive TibberLive TibberConnect
set TibberLive batteryAgeMonths 0..12
```

`0` bedeutet neue Batterie; `12` bedeutet zwölf Monate oder älter und empfiehlt
nach den Einrichtungstests einen Austausch. Nach einem Batterietausch folgt
`set TibberLive batteryReplaced`.

### Kompatibilität und Hinweise

Erhaltene Readings sind unter anderem `current_price`, `price.current`,
`dailyConsumption` und `dailyCost`. Eindeutige Nachfolge-Readings sind
`priceIsNegative`, `nextCheapestWindowStart` und `cheapestWindow2hStart`.
Nicht wiederherstellbare historische Formeln sind in
[docs/HISTORICAL_PRICE_FILTERS.md](docs/HISTORICAL_PRICE_FILTERS.md)
dokumentiert. Alle Automationsausgaben sind beratend; dieses Paket schaltet
keinen Aktor.

### Preisplanung

Das Attribut `priceWindowHours` akzeptiert eins bis sechs und wählt einen exakt
zusammenhängenden günstigsten Block; voreingestellt sind zwei Stunden. Die
konfigurierbaren Readings enthalten Anfang, Ende, Durchschnitt und ausgewählte
Stunden. Feste `cheapestWindow2h...`-Readings bleiben aus Kompatibilitätsgründen
erhalten. Separate `todayPrice...`-/`tomorrowPrice...`-Readings zeigen
Kalendertagsstatistiken. [PRICE_PLANNING.md](docs/PRICE_PLANNING.md) enthält
ein deutsches und englisches E-Auto-Beispiel, ein sicheres eigenes
Anzeige-Reading sowie die lokalen `priceForecast...`-Readings für den noch
bekannten Preiszeitraum. Der Cache veröffentlicht außerdem `priceTrend...` für
einen geglätteten, beratenden Vergleich der nächsten zehn vollständigen,
bekannten Preisintervalle.

Für maschinelle Nutzung liefern `get TibberConnect pricesToday`,
`pricesTomorrow`, `forecast` und
`priceAt <ISO-8601-mit-Offset|Unix-Epoch>` kurze Bedienermeldungen. Mit `json`
kommen lokale Cache-Daten mit ISO- und Epoch-Gültigkeitsgrenzen hinzu. Ein
kompaktes `priceForecastData`-Reading vermeidet eine große Menge einzelner
Readings. Die optionale getrennte FileLog-/GPlot-Quelle für künftige Preise ist
in [PRICE_PLANNING.md](docs/PRICE_PLANNING.md) und
[VISUALIZATION.md](docs/VISUALIZATION.md) beschrieben; sie verändert keine
normale Historie.

Diagramme liegen unter `www/gplot`, sichere Logging-Beispiele unter `examples`.
Der [Visualisierungsleitfaden](docs/VISUALIZATION.md) enthält ein
Standard-FHEM-Dashboard-Beispiel ohne SQLite oder DbLog.

### Freiwilliger Tibber-Einladungslink

Wenn dich meine Arbeit rund um Tibber und die damit möglichen Anwendungen
überzeugt hat und du selbst zu Tibber wechseln möchtest, kannst du freiwillig
meinen persönlichen [Tibber-Einladungslink](https://invite.tibber.com/3mhcd54v)
verwenden. Damit unterstützt du meine Arbeit – und wir profitieren beide von
den jeweils geltenden Vorteilen des Tibber-Einladungsprogramms. Die Nutzung
dieses Links ist keine Voraussetzung für die Installation oder Verwendung der
Software.

Offizielle API-Dokumentation: <https://developer.tibber.com/docs/>

### FHEM-Update-Kanal

Der Schnellstart oben registriert diese Quelle dauerhaft. Sie stellt spätere
Modul- und GPlot-Aktualisierungen aus diesem Repository bereit. Der
Update-Kanal enthält bewusst nur die beiden Moduldateien und die sechs
mitgelieferten GPlot-Dateien.
Er schreibt niemals Token, Home-ID, Gerätedefinition, FileLog, SVG-Gerät,
FHEM-Konfiguration oder eine persönliche `99_myUtils.pm`.

Für spätere Aktualisierungen die Quelle direkt prüfen:

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Nur wenn die Vorschau die erwarteten Tibber-Modul-/GPlot-Dateien nennt:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Danach `shutdown restart` ausführen.

Um keine künftigen Aktualisierungen mehr zu empfangen, ohne installierte Dateien
zu löschen:

```text
update delete https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Vollständiger Umfang, Reload-Schritte und Rückweg stehen in
[UPDATE_CHANNEL.md](docs/UPDATE_CHANNEL.md). Für eine Erstinstallation die
dokumentierten Schritte zu Sicherung, Installation und Prüfung in
[INSTALL.md](docs/INSTALL.md) befolgen.

---

## English

TibberConnect is the account and REST module. It caches quarter-hour prices,
reports delayed consumption/cost data, and calculates advisory price windows.
TibberLive is a separate optional module for Pulse live data. This distinction
is important: **prices**, **delayed consumption**, and **Pulse live data** have
different update speeds and transports.

The package contains `FHEM/70_TibberConnect.pm` and
`FHEM/70_TibberLive.pm`. Use one TibberConnect per account and one TibberLive
instance per home; Tibber permits at most two simultaneous live sockets.

> **Status and risk:** Independent FHEM community project, currently not an
> official part of FHEM. This public release candidate has automated checks and
> user-operated Raspberry Pi 3/4 target tests. The documented clean-room
> installation remains the final acceptance step; back up the installation
> before use, especially when enabling TibberLive.

> **Safety and responsibility:** TibberConnect and TibberLive are provided
> without warranty. Use of the modules, their readings, price forecasts and
> examples is entirely at the operator's own risk. The modules do not switch
> loads themselves. Any user-created automation, control logic or actuation of
> real devices remains entirely the operator's responsibility. Back up,
> validate and test separately before production use.

Project information: [153er-netz.de – Development](https://153er-netz.de/seiten/entwicklung.html)

### Quick start

The normal installation path is fully handled through the FHEM update channel.
Enter the commands separately in the FHEM command field:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Only when the preview lists the expected Tibber module and GPlot files:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Then restart FHEM:

```text
shutdown restart
```

Only then define the devices and store the personal token locally:

```text
define TibberConnect TibberConnect
set TibberConnect token <YOUR_PERSONAL_ACCESS_TOKEN>
set TibberConnect refreshHomes
```

Select a discovered home if necessary:

```text
set TibberConnect selectHome <HOME_ID_FROM_AVAILABLEHOMES>
```

For live data, first complete the optional dependency inventory and then use:

```text
define TibberLive TibberLive TibberConnect
set TibberLive batteryAgeMonths 0..12
```

`0` means a new battery; `12` means twelve months or older and recommends a
replacement after setup tests. After a replacement use `set TibberLive
batteryReplaced`.

### Compatibility and advice

Preserved readings include `current_price`, `price.current`,
`dailyConsumption`, and `dailyCost`. Clear successor readings are
`priceIsNegative`, `nextCheapestWindowStart`, and `cheapestWindow2hStart`.
The unrecoverable historic formulas are documented in
[docs/HISTORICAL_PRICE_FILTERS.md](docs/HISTORICAL_PRICE_FILTERS.md). All
automation output is advisory; this package does not switch an actuator.

### Price planning

The `priceWindowHours` attribute accepts one through six and selects an exact
contiguous cheapest block; the default is two hours. The configurable readings
include start, end, average, and selected hours. Fixed `cheapestWindow2h...`
readings remain for compatibility, and separate
`todayPrice...`/`tomorrowPrice...` readings show calendar-day statistics. See
[PRICE_PLANNING.md](docs/PRICE_PLANNING.md) for a German/English EV example, a
safe user-owned display reading, and the local `priceForecast...` readings that
show the remaining known price horizon. The cache also publishes `priceTrend...`
for a smoothed, advisory comparison of the next ten complete known price
intervals.

For machine use, `get TibberConnect pricesToday`, `pricesTomorrow`, `forecast`,
and `priceAt <ISO-8601-with-offset|Unix-epoch>` return concise operator
messages. Add `json` for local-cache JSON with both ISO and epoch validity
bounds. One compact `priceForecastData` reading avoids a large set of individual
readings. The optional separate future-price FileLog/GPlot source is documented
in [PRICE_PLANNING.md](docs/PRICE_PLANNING.md) and
[VISUALIZATION.md](docs/VISUALIZATION.md); it never changes normal history.

Plots are in `www/gplot`; safe logging examples are in `examples`. The
[visualization guide](docs/VISUALIZATION.md) includes a standard-FHEM dashboard
example without SQLite or DbLog.

### Voluntary Tibber invitation link

If my work around Tibber and its possible applications has convinced you and
you would like to switch to Tibber, you may voluntarily use my personal
[Tibber invitation link](https://invite.tibber.com/3mhcd54v). This supports my
work, and both of us may benefit from the terms currently offered by Tibber's
invitation program. Using this link is not a requirement for installation or
use of this software.

Official API documentation: <https://developer.tibber.com/docs/>

### FHEM update channel

The quick start above registers this source persistently. It provides later
module and GPlot updates from this repository. The update channel deliberately
contains only the two module files and the six supplied GPlot files. It never
writes a token, Home ID, device definition, FileLog, SVG device, FHEM
configuration or personal `99_myUtils.pm`.

For later updates, check the source directly:

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Only when the preview lists the expected Tibber module/GPlot files:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Then run `shutdown restart`.

To stop receiving future updates without deleting installed files:

```text
update delete https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

The complete scope, reloading steps and rollback path are in
[UPDATE_CHANNEL.md](docs/UPDATE_CHANNEL.md). For a first installation, follow
the manual backup, installation and verification steps in
[INSTALL.md](docs/INSTALL.md).
