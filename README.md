# TibberConnect and TibberLive for FHEM

TibberConnect is the account and REST module. It caches quarter-hour prices,
reports delayed consumption/cost data, and calculates advisory price windows.
TibberLive is a separate optional module for Pulse live data. This distinction is
important: **prices**, **delayed consumption**, and **Pulse live data** have
different update speeds and transports.

The package contains `FHEM/70_TibberConnect.pm` and
`FHEM/70_TibberLive.pm`. Use one TibberConnect per account and one TibberLive
instance per home; Tibber permits at most two simultaneous live sockets.

> **Status and risk:** Independent FHEM community project, currently not an
> official part of FHEM. This public release candidate has automated checks and
> user-operated Raspberry Pi 3/4 target tests. The documented clean-room
> installation remains the final acceptance step; back up the installation
> before use, especially when enabling TibberLive.

Project information: [153er-netz.de – Development](https://153er-netz.de/seiten/entwicklung.html)

## Quick start

Copy the files as described in [docs/INSTALL.md](docs/INSTALL.md), then enter in
FHEM:

```text
reload 70_TibberConnect.pm
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
reload 70_TibberLive.pm
define TibberLive TibberLive TibberConnect
set TibberLive batteryAgeMonths 0..12
```

`0` means a new battery; `12` means twelve months or older and recommends a
replacement after setup tests. After a replacement use `set TibberLive
batteryReplaced`.

## Compatibility and advice

Preserved readings include `current_price`, `price.current`,
`dailyConsumption`, and `dailyCost`. Clear successor readings are
`priceIsNegative`, `nextCheapestWindowStart`, and `cheapestWindow2hStart`.
The unrecoverable historic formulas are documented in
[docs/HISTORICAL_PRICE_FILTERS.md](docs/HISTORICAL_PRICE_FILTERS.md). All
automation output is advisory; this package does not switch an actuator.

## Price planning / Preisplanung

The `priceWindowHours` attribute accepts one through six and selects an exact
contiguous cheapest block; the default is two hours. The configurable readings include start, end,
average, and selected hours. Fixed `cheapestWindow2h...` readings remain for
compatibility, and separate `todayPrice...`/`tomorrowPrice...` readings show
calendar-day statistics. See [PRICE_PLANNING.md](docs/PRICE_PLANNING.md) for a
German/English EV example, a safe user-owned display reading, and the local
`priceForecast...` readings that show the remaining known price horizon.
The cache also publishes `priceTrend...` for a smoothed, advisory comparison of
the next ten complete known price intervals.

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

## Voluntary Tibber invitation link

If my work around Tibber and its possible applications has convinced you and
you would like to switch to Tibber, you may voluntarily use my personal
[Tibber invitation link](https://invite.tibber.com/3mhcd54v). This supports my
work, and both of us may benefit from the terms currently offered by Tibber's
invitation program. Using this link is not a requirement for installation or
use of this software.

**Deutsch:** Wenn dich meine Arbeit rund um Tibber und die damit möglichen
Anwendungen überzeugt hat und du selbst zu Tibber wechseln möchtest, kannst du
freiwillig meinen persönlichen
[Tibber-Einladungslink](https://invite.tibber.com/3mhcd54v) verwenden. Damit
unterstützt du meine Arbeit – und wir profitieren beide von den jeweils
geltenden Vorteilen des Tibber-Einladungsprogramms. Die Nutzung dieses Links ist
keine Voraussetzung für die Installation oder Verwendung der Software.

Official API documentation: <https://developer.tibber.com/docs/>

## FHEM update channel

After the initial manual installation, FHEM can receive later module and
GPlot updates from this repository. The update channel deliberately contains
only the two module files and the six supplied GPlot files. It never writes a
token, Home-ID, device definition, FileLog, SVG device, FHEM configuration or
personal `99_myUtils.pm`.

Enter the commands separately in the FHEM command field:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

```text
update check TibberConnect
```

Inspect the preview. Only when it lists the expected Tibber module/GPlot files:

```text
update all TibberConnect
```

To stop receiving future updates without deleting installed files:

```text
update delete https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

The complete scope, reloading steps and rollback path are in
[UPDATE_CHANNEL.md](docs/UPDATE_CHANNEL.md).

For a first installation, follow the manual backup, installation and
verification steps in [INSTALL.md](docs/INSTALL.md).
