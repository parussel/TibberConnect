# Price planning / Preisplanung

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
