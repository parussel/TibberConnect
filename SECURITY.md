# Sicherheitshinweise

Dieses unabhängige Community-Projekt ist kein offizieller Bestandteil von FHEM.

## Sicherheitslücken melden

Teile vermutete Sicherheitslücken vertraulich mit dem Repository-Eigentümer.
Veröffentliche in öffentlichen Tickets keine Zugangstoken, Home-IDs, Adressen,
Zählerkennungen, UUIDs, Konfigurationsauszüge oder produktiven Logs.

## Zugangsdaten schützen

- Tibber-Zugangstoken und andere Geheimnisse nicht in GitHub-Dateien,
  Definitionen, Screenshots oder öffentliche Diagnoseausgaben einfügen.
- Für Beispiele nur allgemeine oder synthetische Daten verwenden.
- Werden Zugangsdaten versehentlich veröffentlicht, den betroffenen Token
  unverzüglich widerrufen und ersetzen.

Der geschützte FHEM-Schlüsselspeicher ist für den Tibber-Zugangstoken
vorgesehen. Bei älteren Definitionen mit Klartext-Token zeigt das Modul einen
Migrationshinweis an; die vorhandene Konfiguration wird nicht automatisch
umgeschrieben.
