# Installation

> **Sicherheit und Eigenverantwortung:** TibberConnect und TibberLive werden
> ohne Gewähr bereitgestellt. Die Nutzung der Module, ihrer Readings,
> Preisprognosen und Beispiele erfolgt ausschließlich auf eigene Verantwortung.
> Die Module schalten selbst keine Verbraucher. Jede selbst eingerichtete
> Automation, Schaltlogik oder Ansteuerung realer Geräte liegt vollständig in
> der Verantwortung des Anwenders. Vor dem produktiven Einsatz sind Sicherung,
> Plausibilitätsprüfung und ein getrennter Test erforderlich.

Voraussetzungen: FHEM mit Perl, HTTPS für die Tibber-GraphQL-API, ein persönlicher
Tibber-Token und mindestens ein Home. Für TibberLive muss außerdem Pulse/Watty
gekoppelt und `realTimeConsumptionEnabled` wahr sein. Die Socket-Anbindung
`AnyEvent::WebSocket::Client` ist optional und wird nicht mitgeliefert. Fehlt sie,
bleibt ausschließlich TibberLive gefahrlos deaktiviert und zeigt
`state=dependencyMissing`, `dependencyStatus=missing` sowie eine
Installationsempfehlung als Readings. Das Modul installiert niemals selbst
Systempakete. Auf Debian beziehungsweise Raspberry Pi OS kann der Administrator
nach Prüfung der Paketverfügbarkeit installieren mit:

```text
sudo apt install libanyevent-websocket-client-perl
```

Dieses Debian-Paket installiert auf dem best&auml;tigten Ziel auch `AnyEvent` und
`EV` als ben&ouml;tigte Abh&auml;ngigkeiten. Auf anderen Plattformen m&uuml;ssen sowohl
`AnyEvent::WebSocket::Client` als auch ein nutzbares `EV` vorhanden sein.

Bestätigt wurden Paket und Abhängigkeiten auf Raspberry Pi 4 mit Debian 13
(`trixie`), ARM64. Auf Raspberry Pi 3 mit Raspbian 9 (`stretch`), ARMv7, war
`AnyEvent` noch über das Legacy-Debian-Archiv verfügbar; der WebSocket-Client
musste anschließend aus CPAN installiert werden. Diese abweichende Installation
wird getrennt dokumentiert und darf nicht ungeprüft auf andere Alt-Systeme
übertragen werden.

### Demo ohne eigenen Tibber-Vertrag

Stand dieser Anleitung: 18. Oktober 2026. Der offizielle
[Tibber API Explorer](https://developer.tibber.com/explorer) bietet mit
**Load demo token** einen Demo-Zugang. Damit kann TibberConnect ohne eigenen
Vertrag auf Preis- und Home-Auswahl-Readings getestet werden. Die Demo-Daten
sind synthetisch; sie sind kein Nachweis für reale Verbrauchs- oder
Pulse-Livewerte.

Der Demo-Token wird bewusst nicht als fester Text im Projekt hinterlegt: Tibber
kann ihn ersetzen oder sperren. Der direkte Explorer-Link erspart die Suche und
liefert stets den von Tibber aktuell bereitgestellten Zugang. Nach dem lokalen
Setzen des Tokens `refreshHomes` ausführen und die angezeigte Demo-Home-ID aus
`availableHomes` auswählen. Eine feste Home-ID wird ebenfalls nicht dokumentiert,
weil sie zum Demo-Konto gehört und sich ändern kann.

Wenn der Test überzeugt und ein Wechsel zu Tibber in Frage kommt, ist der
freiwillige Einladungslink getrennt von der technischen Anleitung im README
und in `API_AND_PRIVACY.md` genannt. Seine Nutzung ist keine Voraussetzung.

### Installation über den FHEM-Update-Kanal

1. Bestehende FHEM-Konfiguration sichern.
2. Die Update-Quelle registrieren:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

3. Ausschließlich diese Quelle prüfen:

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

4. Nur wenn die Vorschau die erwarteten Tibber-Modul- und GPlot-Dateien nennt,
   das Paket herunterladen und installieren:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

5. FHEM neu starten:

```text
shutdown restart
```

Die beiden Module und die sechs GPlot-Dateien werden dabei automatisch geladen;
sie dürfen nicht manuell kopiert werden. Nach dem Neustart das Konto ohne
Klartext-Token in der Definition anlegen:

```text
define TibberConnect TibberConnect
set TibberConnect token <TOKEN>
set TibberConnect refreshHomes
get TibberConnect homes
```

Falls eine alte Definition den Token noch enth&auml;lt, kopiert das Modul ihn
zuerst in den gesch&uuml;tzten Speicher und zeigt einen Hinweis an. Die
Definition wird absichtlich nicht automatisch ver&auml;ndert. Danach ausf&uuml;hren
und erst anschlie&szlig;end speichern:

```text
modify TibberConnect TibberConnect
save
```

Die Home-ID wird nur aus `availableHomes` gewählt:

```text
set TibberConnect selectHome <GEPRUEFTE_HOME_ID>
```

Optional kann der günstigste exakt zusammenhängende Preisblock auf eine bis
sechs Stunden eingestellt werden; ohne Attribut gelten zwei Stunden:

```text
attr TibberConnect priceWindowHours 6
```

Die Auswertung verwendet nur den vorhandenen Preis-Cache und schaltet keinen
Verbraucher. Readings, Zustände und ein Beispiel für ein eigenes Anzeige-Reading
sind in [PRICE_PLANNING.md](PRICE_PLANNING.md) beschrieben.

Optionales Live-Modul, genau eine Home-Zuordnung je Instanz:

```text
define TibberLive TibberLive TibberConnect
set TibberLive selectHome <GEPRUEFTE_HOME_ID>
set TibberLive batteryAgeMonths 0..12
```

Wie bei einem Master-/Teilnehmerpaar muss `TibberConnect` zuerst geladen und
definiert werden; erst danach folgt `TibberLive`. Beim Neustart kann die erneute
Home-Prüfung des Hauptmoduls einige Sekunden dauern. TibberLive zeigt in dieser
Zeit `waitingForHome` und verbindet sich automatisch, sobald TibberConnect das
Home bestätigt hat.

Für weitere Homes wird je Home eine weitere TibberLive-Instanz angelegt; insgesamt
höchstens zwei. Eine Instanz wechselt nicht automatisch, wenn das Standard-Home
von TibberConnect später geändert wird.

Die sechs Diagrammdateien aus `www/gplot` sind bereits über den Update-Kanal
installiert. Beispiele für FileLog und DbLog liegen unter `examples/`; deren
Definitionen müssen an lokale Gerätenamen und Pfade angepasst werden. Für die
zusätzliche, nur zukünftige Preisprognose `examples/tibber-forecast.cfg` Zeile
für Zeile mit einem vorhandenen lokalen Log-Verzeichnis prüfen. Das optionale
Attribut `forecastLogFile` erzeugt nur diese getrennte Quelle; vorhandene Logs
bleiben unverändert. Die dort enthaltene `fixedrange`-Zeile muss unveraendert
bleiben: In einer gespeicherten FHEM-CFG werden die Perl-Semikolons als `;;`
geschrieben, damit FHEM die gesamte Perl-Expression als ein Attribut speichert.

Deutsch – optionale stündliche Benachrichtigung: Ein eigener DOIF/notify darf
stündlich `liveStatus` und `batteryMaintenance` prüfen und anschließend den vom
Anwender gewählten Telegram-, Mail- oder anderen Dienst auslösen. Das Modul
selbst versendet nichts. Beispielbedingung:

```text
([+01:00] and ([TibberLive:liveStatus] ne "receiving" or [TibberLive:batteryMaintenance] =~ "due"))
```
