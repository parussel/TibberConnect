# Changelog

## Public release candidate

- Preserved the proven TibberConnect REST readings and multi-home selection.
- Added protected token storage, safe retry/backoff, separated price and
  consumption requests, quarter-hour cache, DST-safe price windows, and
  advisory automation readings.
- Added the separate optional TibberLive module with `graphql-transport-ws`
  protocol handling, dynamic `websocketSubscriptionUrl`, reconnect controls,
  complete official live-reading mapping, health watchdog, and calendar-based
  battery maintenance.
- Added FileLog/DbLog examples, day/week/month/year price plots, a live-power
  plot, tests, rollback guidance, and privacy documentation.
- Added an optional standard-FHEM overview example that combines current price,
  live power, price window, and ready-made SVG plots without requiring SQLite
  or DbLog.
- Added advisory `priceForecast...` readings for the contiguous known price
  horizon: future interval count, remaining minutes, final known end, and
  ready/expired state.
- Added advisory `priceTrend...` readings that compare the first and second
  half of the next ten complete cached price intervals without another API
  request.
- Added compact machine-readable local-cache exports for today, tomorrow,
  forecast and an exact timestamp, including ISO and epoch validity bounds.
  The optional dedicated future-price FileLog/GPlot source is opt-in and does
  not modify operational history or create hundreds of individual readings.
- Made normal forecast `get` commands concise German operator messages; the
  explicit `json` argument retains their full machine-readable export.
- Added the confirmed personal Tibber invitation link with a transparent,
  voluntary-use disclosure and the common 153er-netz.de development reference.
- Published as a public release candidate with a deliberately limited FHEM
  update channel: only the two module files and six supplied GPlot files are
  updated automatically. Tokens, Home IDs, definitions, logs, FHEM
  configuration and personal `99_myUtils.pm` helpers remain untouched.
