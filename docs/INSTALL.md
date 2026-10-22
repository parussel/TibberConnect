# Installation / Installation

## Deutsch

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

1. Bestehende Moduldateien und FHEM-Konfiguration sichern.
2. Benutzergeführt `FHEM/70_TibberConnect.pm` und optional
   `FHEM/70_TibberLive.pm` in das FHEM-Modulverzeichnis kopieren.
3. Prüfsummen vergleichen und erst danach in FHEM laden.
4. Das Konto ohne Klartext-Token in der Definition anlegen:

```text
reload 70_TibberConnect.pm
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
reload 70_TibberLive.pm
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

Die Diagrammdateien aus `www/gplot` werden benutzergeführt nach `www/gplot` der
FHEM-Installation kopiert. Beispiele für FileLog und DbLog liegen unter
`examples/`. Sie müssen an lokale Gerätenamen und Pfade angepasst werden.
Für die zusätzliche, nur zukünftige Preisprognose erst
`TibberConnect_PriceForecast.gplot` kopieren und danach
`examples/tibber-forecast.cfg` Zeile für Zeile mit einem vorhandenen lokalen
Log-Verzeichnis prüfen. Das optionale Attribut `forecastLogFile` erzeugt nur
diese getrennte Quelle; vorhandene Logs bleiben unverändert. Die dort enthaltene
`fixedrange`-Zeile muss unveraendert bleiben: In einer gespeicherten FHEM-CFG
werden die Perl-Semikolons als `;;` geschrieben, damit FHEM die gesamte
Perl-Expression als ein Attribut speichert.

Deutsch – optionale stündliche Benachrichtigung: Ein eigener DOIF/notify darf
stündlich `liveStatus` und `batteryMaintenance` prüfen und anschließend den vom
Anwender gewählten Telegram-, Mail- oder anderen Dienst auslösen. Das Modul
selbst versendet nichts. Beispielbedingung:

```text
([+01:00] and ([TibberLive:liveStatus] ne "receiving" or [TibberLive:batteryMaintenance] =~ "due"))
```

## English

> **Safety and responsibility:** TibberConnect and TibberLive are provided
> without warranty. Use of the modules, their readings, price forecasts and
> examples is entirely at the operator's own risk. The modules do not switch
> loads themselves. Any user-created automation, control logic or actuation of
> real devices remains entirely the operator's responsibility. Back up,
> validate and test separately before production use.

### Demo without a Tibber contract

As of 18 October 2026, the official
[Tibber API Explorer](https://developer.tibber.com/explorer) provides a
**Load demo token** action. It can test TibberConnect price and home-selection
readings without a contract. Demo data is synthetic and does not validate real
consumption or Pulse live values. The project deliberately links to the
Explorer instead of copying a static demo token or home ID: Tibber may rotate
either value. After locally setting the token, run `refreshHomes` and choose
the demo home ID exposed in `availableHomes`.

Back up the existing modules and configuration, copy the two candidate files as
a user-operated action, verify their hashes, and then use the same commands shown
above. There is one TibberLive instance per home and never more than two live
connections. Store the token with `set TibberConnect token`; never put it on the
`define` line. For a legacy definition, wait for protected storage to succeed,
then run `modify TibberConnect TibberConnect` and `save`; the module deliberately
does not rewrite the definition automatically.

English – optional hourly notification: a user-owned DOIF/notify may evaluate
`liveStatus` and `batteryMaintenance` hourly and call the user's own notification
channel. The module sends no message and controls no actuator.

TibberLive detects `AnyEvent::WebSocket::Client` but never installs packages.
When it is missing, only TibberLive stays disabled and exposes dependency status
and guidance as readings. On Debian or Raspberry Pi OS, after confirming package
availability, the administrator can use
`sudo apt install libanyevent-websocket-client-perl`. The dependency set has been
confirmed on Raspberry Pi 4, Debian 13 (`trixie`), ARM64; on this target the
Debian package also installs the required `AnyEvent` and `EV` dependencies.
Raspberry Pi 3 with Raspbian 9 (`stretch`), ARMv7, required the legacy Debian
archive for `AnyEvent` and CPAN for the WebSocket client. Other platforms must
provide both `AnyEvent::WebSocket::Client` and usable `EV`. TibberConnect is the
master/account device and must be loaded and defined before its TibberLive
participant. During startup TibberLive may show `waitingForHome` until the
account has verified its home, then connects automatically.

After testing, use `save` only when the readings and selected homes are correct.
See [ROLLBACK.md](ROLLBACK.md) before replacing an existing installation.

For optional price planning, set `priceWindowHours` to an integer from one
through six; the default is two hours. The number is an exact contiguous duration. Recalculation
uses the local cache and never controls an appliance. See
[PRICE_PLANNING.md](PRICE_PLANNING.md) for all readings and a safe user-owned
display example.

For the optional future-only price forecast, first copy
`TibberConnect_PriceForecast.gplot`, then review and enter
`examples/tibber-forecast.cfg` line by line with an existing local log
directory. The optional `forecastLogFile` attribute creates only that separate
source; existing logs stay unchanged.
