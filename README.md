# TibberConnect und TibberLive für FHEM

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

> **Aktueller Korrekturstand 2.0.1 (25.10.2026):** TibberLive begrenzt einen
> hängenden WebSocket-Handshake auf 45 Sekunden und dokumentiert die letzte
> Trennung über `lastDisconnectAt` und `lastDisconnectReason`.

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
