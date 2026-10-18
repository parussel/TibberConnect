# Tibber-API, Sicherheit und Datenschutz

`TibberConnect` fragt die Tibber-GraphQL-API über HTTPS ab. Preiswerte werden
zwischengespeichert; Verbrauchsdaten werden getrennt und seltener abgefragt.
Wiederholungsversuche sind begrenzt und erfolgen mit Wartezeit.

`TibberLive` liest die für das Home verfügbare Live-URL aus und verwendet das
GraphQL-WebSocket-Protokoll. Tibber erlaubt höchstens zwei gleichzeitige
Live-WebSocket-Verbindungen. Fehler bei der Authentifizierung führen nicht zu
unbegrenzten Wiederholungsversuchen mit demselben Token.

Der offizielle Live-Datensatz enthält ein Signalstärke-Feld, jedoch keinen
Messwert für Batterieladestand oder Batteriespannung. `batteryMaintenance` ist
eine Wartungserinnerung anhand des eingestellten Alters und kein gemessener
Batteriezustand. Das Standardintervall beträgt 365 Tage; 30 Tage vor dem
Fälligkeitstermin wird gewarnt. Die tatsächliche Lebensdauer hängt unter anderem
von Batterietyp und Einsatzbedingungen ab.

## Zugangstoken und persönliche Daten

Zugangstoken werden im geschützten FHEM-Schlüsselspeicher abgelegt. Sie sollten
nicht in Definitionen, Logs, Screenshots, öffentlichen Fehlerberichten oder
Diagnoseausgaben erscheinen. Wird ein Token aus einer älteren Definition
übernommen, zeigt das Modul den Befehl an, mit dem die tokenfreie Definition
hergestellt werden kann. Die bestehende Definition wird nicht stillschweigend
geändert.

Home-IDs, Adressen, Verbrauchs- und Kostendaten sowie Live-Messwerte können
personenbezogen sein. Entferne solche Angaben vor dem Teilen von Logs oder
Konfigurationsauszügen. Persönliche Zugriffstoken sind für die eigene
Integration bestimmt; für eine verteilte Drittanbieter-Anwendung gelten andere
Anforderungen.

## Offizielle Quellen

- [Tibber API aufrufen](https://developer.tibber.com/docs/guides/calling-api)
- [Tibber API-Referenz](https://developer.tibber.com/api/reference.md)

Der optionale persönliche [Tibber-Einladungslink](https://invite.tibber.com/3mhcd54v)
ist keine Voraussetzung für Installation oder Nutzung der Software.

Projektinformationen: [153er-netz.de – Entwicklung](https://153er-netz.de/seiten/entwicklung.html)
