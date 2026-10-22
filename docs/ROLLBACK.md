# Backup and rollback

All Raspberry steps are user-operated. Do not overwrite the known-working file
until its path, byte size, SHA-256 hash, and timestamped backup have been recorded.

1. Stop at the current test gate if syntax, checksum, reload, or readings differ
   from the expected result.
2. Disable the candidate device before rollback; do not enable automations.
3. Restore only the exact backed-up module path. Never use a wildcard or broad
   recursive delete.
4. Reload the restored file, verify `state`, `connection`, `transportState`, and
   the preserved price/consumption readings.
5. Restore the saved FHEM configuration only if the module-file rollback is not
   sufficient.

A rollback does not delete logs. Keep the backed-up module, its hash, and any
failure output separately for diagnosis.

TibberLive is independent: it may be disabled or removed while TibberConnect
continues to provide REST data. Removing TibberLive must not delete the protected
TibberConnect token.

If the optional forecast chart was configured, remove `forecastLogFile` and the
user-created `FileLog_TibberForecast`/`SVG_TibberForecast` definitions first.
Only then remove the separately chosen forecast file. This does not alter an
existing normal TibberConnect FileLog, DbLog, readings history, or token.
