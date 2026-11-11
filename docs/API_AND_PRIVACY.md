# Tibber-API, Sicherheit und Datenschutz

TibberConnect ruft `https://api.tibber.com/v1-beta/gql` mit einem identifizierenden User-Agent auf. Tibber dokumentiert ein Limit von **100 Anfragen in fünf Minuten pro IP-Adresse**. Preise werden zwischengespeichert; verzögerte Verbrauchsdaten werden getrennt und seltener abgerufen. Wiederholungsversuche verwenden eine begrenzte exponentielle Wartezeit mit zufälliger Streuung.

TibberLive liest zuerst `realTimeConsumptionEnabled` und die dynamische `websocketSubscriptionUrl` und verwendet anschließend das Unterprotokoll `graphql-transport-ws`. Tibber erlaubt höchstens zwei Live-WebSockets. Authentifizierungsfehler werden mit demselben Token nicht erneut versucht.

Das offizielle Live-Schema liefert `signalStrength`, jedoch kein unterstütztes Feld für Batterieladung oder Batteriespannung. `batteryMaintenance` ist lediglich eine kalenderbasierte Erinnerung und niemals ein gemessener Batteriestand. Der Standardwert beträgt 365 Tage für eine handelsübliche Batterie, mit einer Warnung 30 Tage im Voraus. Die tatsächliche Lebensdauer hängt von Chemie, Zähler, Funkbedingungen und bisherigem Einsatz ab. Nach eigener sachkundiger Entscheidung kann `batteryLifetimeDays` angepasst werden.

Token werden im geschützten FHEM-Schlüssel-Wert-Speicher abgelegt. Sie dürfen nicht in Definitionen, Protokollen, Bildschirmfotos, Issues, Release-Dateien oder Diagnoseausgaben erscheinen. Aus Gründen der Rückwärtskompatibilität wird ein Token aus einer älteren Definition in den geschützten Speicher kopiert und ein tokenfreier Befehl `modify <name> TibberConnect` angezeigt. Diesen Befehl muss der Benutzer selbst ausführen und anschließend speichern; das Modul schreibt eine bestehende Definition bewusst nicht automatisch um.

Home-IDs, Adressen, Verbräuche, Kosten und Live-Messwerte sind personenbezogene Daten und müssen vor einer Weitergabe bereinigt werden. OAuth eignet sich für eine verteilte Drittanbieteranwendung; persönliche Zugriffstoken sind für die eigene Integration des Kontoinhabers vorgesehen.

Offizielle Quellen:

- <https://developer.tibber.com/docs/guides/calling-api>
- <https://developer.tibber.com/api/reference.md>

Eine Fähigkeit der Data API wird nur behauptet, wenn sie gesondert bestätigt und getestet wurde.

## Freiwilliger Hinweis zum Einladungslink

Der bestätigte persönliche Tibber-Einladungslink lautet <https://invite.tibber.com/3mhcd54v>. Er ist klar von den technischen Anleitungen getrennt und für Installation oder Nutzung nicht erforderlich. Die Vorteile richten sich nach den jeweils geltenden Bedingungen des Tibber-Einladungsprogramms und sind deshalb nicht fest in dieser Dokumentation hinterlegt.

Projektinformationen: [153er-netz.de – Entwicklung](https://153er-netz.de/seiten/entwicklung.html)
