# Sicherheitsrichtlinie

## Unterstützter Entwicklungsstand

Dieses Repository ist ein öffentlicher Release Candidate in aktiver Entwicklung.
Es ist kein offizielles FHEM-Modul und besitzt noch keine unterstützte stabile Version.

## Meldung von Sicherheitsproblemen

Mögliche Sicherheitslücken bitte vertraulich an den Eigentümer des Repositorys melden. Keine öffentlichen Issues mit Zugriffstoken, Home-ID, Adresse, Zählerkennung, UUID, Konfigurationsexport oder Produktivprotokoll eröffnen.

## Regeln zum Umgang mit Geheimnissen

- Persönliche Tibber-Zugriffstoken, OAuth-Geheimnisse oder kopierte FHEM-Konfigurationen und -Zustände niemals einchecken.
- In Tests, Beispielen und Dokumentationen ausschließlich künstliche Kennungen und Daten verwenden.
- Autorisierungsdaten und Kennungen in Diagnosen maskieren, bevor sie in FHEM-Readings oder Protokolle gelangen.
- Ein versehentlich offengelegtes Token sofort widerrufen.
- Die Release-Prüfung muss versionierte Dateien und das erzeugte Paket auf Inhalte untersuchen, die wie Zugangsdaten aussehen.

Der geschützte FHEM-Schlüssel-Wert-Speicher ist der vorgesehene Ablageort für das Token des fertigen Moduls. Für ältere Klartextdefinitionen gibt es einen ausdrücklichen Migrationsweg; das Modul darf die Benutzerkonfiguration nicht unbemerkt umschreiben.
