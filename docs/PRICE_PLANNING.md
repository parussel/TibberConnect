# Price planning / Preisplanung

## Deutsch

TibberConnect wertet die bereits zwischengespeicherten Preise beratend aus. Das
Modul schaltet weder Wallboxen noch andere Verbraucher und erzeugt für eine
Neuberechnung keine zusätzliche Tibber-Abfrage.

Die gewünschte, exakt zusammenhängende Blocklänge wird auf eine bis sechs
Stunden begrenzt. Ohne Attribut gelten zwei Stunden:

```text
attr TibberConnect priceWindowHours 6
```

Der Wert `6` bedeutet den günstigsten vollständigen Sechs-Stunden-Block im
verfügbaren Preisvorrat. Er bedeutet weder „irgendwo innerhalb der nächsten
sechs Stunden“ noch eine variable Dauer von null bis sechs Stunden.

Die konfigurierbare Auswertung liefert:

- `nextCheapestWindowStart`, `nextCheapestWindowEnd`
- `nextCheapestWindowAverage`, `nextCheapestWindowHours`
- `priceWindowState` und die rein beratende `automationDecision`

Die vorhandenen Readings `cheapestWindow2hStart`, `cheapestWindow2hEnd` und
`cheapestWindow2hAverage` bleiben unabhängig vom Attribut fest auf zwei Stunden.
`todayPrice...` und `tomorrowPrice...` enthalten getrennte Tagesstatistiken.
Solange Tibber die Preise des nächsten Tages noch nicht liefert, steht
`tomorrowPriceState` auf `pending`; Zahlenwerte bleiben dann `unknown`.

### Preisvorschau

Die folgenden Readings zeigen den wirklich noch vorausliegenden, lückenlosen
Preisvorrat. Damit lässt sich erkennen, wie lange Automationen noch mit
bekannten Preisen planen können:

- `priceForecastIntervals`: Anzahl vollständiger, noch nicht begonnener
  Preisintervalle;
- `priceForecastDurationMinutes`: deren zusammenhängende Restdauer in
  Minuten;
- `priceForecastUntil`: Ende des letzten dabei bekannten Intervalls;
- `priceForecastState`: `ready` oder `expired`.

Eine Anzeige kann daraus beispielsweise „Preisvorschau: 73 Preisintervalle /
18 h 15 min, bekannt bis ...“ bilden. Die Zahl 96 wird **nicht** als feste
Obergrenze ausgegeben: Tibber liefert kalenderbezogen Preise für heute und
morgen, der nutzbare Vorausblick ist daher je nach Tageszeit unterschiedlich;
an einer Zeitumstellung hat ein Tag zudem nicht immer 96 Viertelstunden.

### Maschinenlesbare Prognose und Zeitabfragen

`priceForecastData` enthält als einzelnes, kompaktes JSON-Reading die noch
zusammenhängenden Preise. Jedes Intervall enthält `startsAt`, `endsAt`,
`startEpoch`, `endEpoch`, `total`, `energy`, `tax`, `currency` und `level`.
Die Epoch-Zeiten machen die wiederholte Stunde einer Zeitumstellung eindeutig.
Das Reading wird absichtlich ohne Event geschrieben: Es entstehen weder
hunderte dauerhafte Einzelreadings noch zusätzliche Einträge in vorhandenen
FileLog-/DbLog-Historien.

Die folgenden Abfragen verwenden ausschließlich den lokalen Cache und lösen
keine Tibber-Anfrage aus. Ohne Zusatz geben sie eine kurze deutsche
Statusmeldung aus:

```text
get TibberConnect pricesToday
get TibberConnect pricesTomorrow
get TibberConnect forecast
get TibberConnect priceAt 2026-10-25T02:15:00+02:00
get TibberConnect priceAt 1792890900
```

Der ausdr&uuml;ckliche Zusatz `json` liefert stattdessen kanonisches JSON, zum Beispiel
`get TibberConnect forecast json` oder
`get TibberConnect priceAt 1792890900 json`. `pricesTomorrow` meldet
`state=pending`, solange Tibber noch keine morgigen Preise geliefert hat; es
werden keine Werte erfunden. `priceAt` meldet `state=not_found`, wenn der
Zeitpunkt au&szlig;erhalb des Caches liegt. Die optionale getrennte Prognosedatei
und das GPlot-Beispiel stehen in [VISUALIZATION.md](VISUALIZATION.md).

### Preisentwicklung der nächsten Werte

`priceTrend...` bewertet ohne zusätzliche API-Abfrage die zehn nächsten
vollständigen, lückenlosen Preisintervalle. Es vergleicht den Durchschnitt der
ersten fünf mit dem Durchschnitt der folgenden fünf Werte. Ab einer Differenz
von 0,5 ct/kWh lautet die Richtung `rising` oder `falling`; darunter
`steady`. Bei weniger als zehn zusammenhängenden Werten lautet sie
`unavailable`.

- `priceTrendDirection`: `rising`, `steady`, `falling` oder `unavailable`;
- `priceTrendDelta`: Differenz der beiden Durchschnittswerte in EUR/kWh;
- `priceTrendIntervals`: verwendete Intervallzahl, normalerweise `10`;
- `priceTrendHorizonMinutes`: tatsächlich betrachtete Zeitspanne; bei
  Viertelstundenpreisen normalerweise `150`.

Die Anzeige darf diese technischen Werte deutsch darstellen, etwa als
„Preistendenz: ↑ steigend“, „→ etwa gleichbleibend“ oder
„↓ fallend“. Sie ist eine Orientierung, keine Schaltentscheidung.

### Beispiel: eigenes übersichtliches Reading

Nach Auswahl der gewünschten Dauer kann ein Anwender mit FHEMs
`userReadings` ein eigenes Anzeige-Reading zusammensetzen:

```text
attr TibberConnect priceWindowHours 5
attr TibberConnect userReadings myCarWindow { ReadingsVal("TibberConnect","nextCheapestWindowStart","unknown")." - ".ReadingsVal("TibberConnect","nextCheapestWindowEnd","unknown") }
```

Das Reading `myCarWindow` fasst nur Start und Ende zusammen. Eine eigene
Perl-/DOIF-Logik kann zusätzlich Fahrzeugstatus, Mindestpreis oder eine lokale
Zeitgrenze berücksichtigen. Eine tatsächliche Schaltung muss der Anwender
bewusst außerhalb von TibberConnect erstellen und absichern.

Persönliche Tibber-Tokens gehören niemals in Definitionen, Perl-Skripte,
Logdateien, Screenshots oder ein Repository.

Eine einrichtbare klassische FHEMWEB-Ansicht mit Preis- und Leistungsdiagramm
beschreibt [VISUALIZATION.md](VISUALIZATION.md).

## English

TibberConnect evaluates prices already held in its local cache and remains
advisory. It neither controls a wallbox or another appliance nor makes an extra
Tibber request merely to recalculate a window.

Select an exact contiguous duration from one through six hours. Two hours is the
default when the attribute is absent:

```text
attr TibberConnect priceWindowHours 6
```

The value `6` means the cheapest complete six-hour block in the available price
horizon. It does not mean “somewhere during the next six hours” or a variable
duration from zero through six hours.

The configured result is exposed through `nextCheapestWindowStart`,
`nextCheapestWindowEnd`, `nextCheapestWindowAverage`, and
`nextCheapestWindowHours`. The existing `cheapestWindow2h...` readings always
remain fixed at two hours. Separate `todayPrice...` and `tomorrowPrice...`
statistics are published; `tomorrowPriceState=pending` and numerical values are
`unknown` until Tibber supplies the next day's prices.

### Price forecast

The local cache also exposes its usable, contiguous future horizon:

- `priceForecastIntervals`: complete price intervals that have not started;
- `priceForecastDurationMinutes`: their contiguous remaining duration in
  minutes;
- `priceForecastUntil`: end of that horizon;
- `priceForecastState`: `ready` or `expired`.

For example, a display can render “Price forecast: 73 price intervals / 18 h
15 min, known until ...”. The module intentionally does **not** use 96 as a
fixed maximum: Tibber supplies calendar-day prices for today and tomorrow, so
the usable horizon varies throughout the day; daylight-saving transitions also
do not always have 96 quarter-hours per day.

### Machine-readable forecast and time lookups

`priceForecastData` is one compact JSON reading containing the remaining
contiguous prices. Every interval carries `startsAt`, `endsAt`, `startEpoch`,
`endEpoch`, `total`, `energy`, `tax`, `currency`, and `level`. Epoch values
make repeated daylight-saving hours unambiguous. The reading is intentionally
written without an event: it creates neither hundreds of persistent individual
readings nor extra records in existing FileLog/DbLog histories.

The following queries use only the local cache and never make a Tibber request.
Without an extra argument they return a concise German status message:

```text
get TibberConnect pricesToday
get TibberConnect pricesTomorrow
get TibberConnect forecast
get TibberConnect priceAt 2026-10-25T02:15:00+02:00
get TibberConnect priceAt 1792890900
```

The explicit `json` argument returns canonical JSON instead, for example
`get TibberConnect forecast json` or
`get TibberConnect priceAt 1792890900 json`. `pricesTomorrow` returns
`state=pending` until Tibber has supplied tomorrow's prices; no prices are
invented. `priceAt` returns `state=not_found` outside the cache. The optional
separate forecast file and GPlot example are documented in
[VISUALIZATION.md](VISUALIZATION.md).

### Upcoming price trend

Without another API request, `priceTrend...` evaluates the next ten complete,
contiguous price intervals. It compares the average of the first five with the
average of the following five. A difference of at least 0.5 ct/kWh produces
`rising` or `falling`; a smaller difference produces `steady`. Fewer than ten
contiguous values produce `unavailable`.

- `priceTrendDirection`: `rising`, `steady`, `falling`, or `unavailable`;
- `priceTrendDelta`: difference between both averages in EUR/kWh;
- `priceTrendIntervals`: used interval count, normally `10`;
- `priceTrendHorizonMinutes`: actual evaluated duration, normally `150` for
  quarter-hour prices.

The display may map these technical values to a local-language arrow and text.
They remain advisory and never make a switching decision.

### Example: a user-owned display reading

```text
attr TibberConnect priceWindowHours 5
attr TibberConnect userReadings myCarWindow { ReadingsVal("TibberConnect","nextCheapestWindowStart","unknown")." - ".ReadingsVal("TibberConnect","nextCheapestWindowEnd","unknown") }
```

This only combines start and end for display. Advanced Perl/DOIF logic may add
vehicle readiness, price thresholds, or local scheduling rules. Users must build
and safeguard any actual switching outside TibberConnect. Never place a personal
Tibber token in a definition, script, log, screenshot, or repository.

For a copyable classic FHEMWEB view with price and live-power plots, see
[VISUALIZATION.md](VISUALIZATION.md).
