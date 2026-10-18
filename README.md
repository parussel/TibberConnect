# TibberConnect und TibberLive für FHEM

`TibberConnect` verbindet FHEM mit der Tibber-REST-API. Das Modul liest Preise,
verzögerten Verbrauch und Kosten ein und stellt beratende Preisfenster bereit.
`TibberLive` ist ein separates, optionales Modul für Live-Messwerte eines
Tibber Pulse. Die Module unterscheiden sich bei Datenart und Aktualisierung.

> **Status und Hinweis:** Eigenständiges Community-Projekt, kein offizieller
> Bestandteil von FHEM. Die Module wurden automatisiert und im praktischen
> FHEM-Betrieb geprüft. Vor der Installation eine Sicherung erstellen und die
> Einstellungen sorgfältig kontrollieren. Die Nutzung erfolgt in eigener
> Verantwortung.

Projektinformationen: [153er-netz.de – Entwicklung](https://153er-netz.de/seiten/entwicklung.html)

## Installation und Updates

Die Schritte einzeln im FHEM-Kommandoeingabefeld ausführen und jeweils die
Rückmeldung abwarten. Vorher eine aktuelle FHEM-Sicherung anlegen.

Updatequelle eintragen:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Zuerst nur die Vorschau abrufen:

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Die Vorschau muss die beiden Tibber-Module und die fünf mitgelieferten
GPlot-Dateien nennen. Nur wenn die Liste passt, das Update ausführen:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Danach die Moduländerungen aktivieren:

```text
shutdown restart
```

Die Steuerdatei aktualisiert ausschließlich `FHEM/70_TibberConnect.pm`,
`FHEM/70_TibberLive.pm` und die fünf Projektdateien unter `www/gplot/`. Sie
enthält keine FHEM-Konfiguration, Geräte-Definitionen, Zugangsdaten, Home-IDs,
Logs oder persönlichen Hilfsfunktionen.

## Erste Einrichtung

Nach dem Neustart das Hauptmodul definieren und den persönlichen Token getrennt
setzen:

```text
define TibberConnect TibberConnect
set TibberConnect token <PERSÖNLICHER_TOKEN>
set TibberConnect refreshHomes
get TibberConnect homes
```

Eine gefundene Home-ID anschließend aus `availableHomes` übernehmen:

```text
set TibberConnect selectHome <HOME_ID>
```

Der Token wird im geschützten FHEM-Schlüsselspeicher abgelegt. Er gehört nicht
in die `define`-Zeile und sollte nicht in Screenshots, Logs oder öffentlichen
Nachrichten geteilt werden.

## TibberLive (optional)

Für Live-Daten müssen Tibber Pulse und Home entsprechend eingerichtet sein.
Zusätzlich benötigt TibberLive die Perl-Abhängigkeiten
`AnyEvent::WebSocket::Client` und `EV`. TibberLive installiert keine
Systempakete selbst. Bitte die Verfügbarkeit und Installation für die eigene
Linux-Distribution prüfen, bevor das Modul aktiviert wird.

`TibberConnect` muss zuerst eingerichtet sein. Danach kann eine
TibberLive-Instanz angelegt werden:

```text
define TibberLive TibberLive TibberConnect
set TibberLive batteryAgeMonths 0..12
```

Je Home ist eine Instanz vorgesehen; insgesamt sind höchstens zwei gleichzeitige
Live-Verbindungen möglich. Die Batterieanzeige ist eine Erinnerung anhand des
Alters und kein Messwert für den tatsächlichen Ladezustand.

## Funktionen

- Preise und verzögerte Verbrauchs-/Kostenwerte aus der Tibber-API;
- Auswahl eines vollständigen, zusammenhängenden Preisfensters von einer bis
  sechs Stunden (`priceWindowHours`, Standard: zwei Stunden);
- optionale Live-Messwerte und Batteriewartungshinweise mit TibberLive;
- Beispiele für FileLog, DbLog, Diagramme und eine FHEM-Übersicht.

Preisfenster und weitere Readings sind nur Empfehlungen. Die Module schalten
keine Wallboxen oder sonstigen Verbraucher. Weitere Hinweise stehen in
[docs/PRICE_PLANNING.md](docs/PRICE_PLANNING.md) und
[docs/VISUALIZATION.md](docs/VISUALIZATION.md).

## Lizenz und Tibber-Dokumentation

Lizenz: GNU General Public License, Version 2. Siehe [LICENSE](LICENSE).
Informationen zu Zugriffstoken und Datenschutz stehen in
[docs/API_AND_PRIVACY.md](docs/API_AND_PRIVACY.md).

Offizielle Dokumentation: [Tibber API](https://developer.tibber.com/docs/).

Wenn dich meine Arbeit rund um Tibber überzeugt hat und du selbst zu Tibber
wechseln möchtest, kannst du freiwillig meinen persönlichen
[Tibber-Einladungslink](https://invite.tibber.com/3mhcd54v) verwenden. Er ist
keine Voraussetzung für Installation oder Nutzung der Software.
