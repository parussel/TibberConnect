# Installation

Diese Anleitung verwendet die FHEM-Updatequelle des Projekts. Sie installiert
die beiden Module und die fünf mitgelieferten Diagrammdateien. Persönliche
Konfigurationen werden nicht über diese Updatequelle verteilt.

## Voraussetzungen

Für `TibberConnect` benötigst du FHEM, eine HTTPS-Verbindung zur Tibber-API und
einen persönlichen Tibber-Zugangstoken. Für `TibberLive` brauchst du zusätzlich
einen eingerichteten Tibber Pulse sowie die Perl-Module
`AnyEvent::WebSocket::Client` und `EV`. Die Live-Abhängigkeit ist optional und
wird vom Projekt nicht automatisch installiert. Prüfe die Paketverfügbarkeit
und den Installationsweg für deine Linux-Distribution.

## Installation in FHEM

Führe die folgenden Befehle einzeln im FHEM-Kommandoeingabefeld aus und warte
jeweils die Rückmeldung ab. Erstelle vorher eine aktuelle FHEM-Sicherung.

1. Updatequelle registrieren:

```text
update add https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

2. Vorschau abrufen:

```text
update check https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

3. Prüfen, dass nur `FHEM/70_TibberConnect.pm`, `FHEM/70_TibberLive.pm` und
   die fünf mitgelieferten Dateien unter `www/gplot/` aufgeführt sind. Bei einer
   abweichenden Liste nicht fortfahren.

4. Update ausführen:

```text
update all https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

5. FHEM neu starten, damit die Module geladen werden:

```text
shutdown restart
```

## TibberConnect einrichten

Nach dem Neustart das Hauptgerät anlegen. Den Zugangstoken getrennt eingeben;
keine Zugangsdaten in der `define`-Zeile speichern.

```text
define TibberConnect TibberConnect
set TibberConnect token <PERSÖNLICHER_TOKEN>
set TibberConnect refreshHomes
get TibberConnect homes
```

Wähle anschließend eine der von `availableHomes` gemeldeten Home-IDs:

```text
set TibberConnect selectHome <HOME_ID>
```

Falls eine ältere Definition den Token noch in der `define`-Zeile enthält,
übernimmt das Modul ihn in den geschützten FHEM-Schlüsselspeicher und zeigt den
notwendigen `modify`-Befehl an. Führe ihn aus und speichere erst danach:

```text
modify TibberConnect TibberConnect
save
```

## TibberLive optional einrichten

Aktiviere TibberLive erst, wenn die Voraussetzungen erfüllt und die
Abhängigkeiten auf dem System verfügbar sind. Richte `TibberConnect` zuerst ein:

```text
define TibberLive TibberLive TibberConnect
set TibberLive batteryAgeMonths 0..12
```

Eine TibberLive-Instanz ist je Home vorgesehen, höchstens zwei Live-Verbindungen
gleichzeitig. Der Wert `batteryAgeMonths` ist eine Wartungserinnerung, keine
Messung des Batterieladezustands. Weitere Informationen stehen in
[API_AND_PRIVACY.md](API_AND_PRIVACY.md).

## Demo ohne eigenen Vertrag

Der offizielle [Tibber API Explorer](https://developer.tibber.com/explorer)
bietet eine Funktion zum Laden eines Demo-Tokens. Damit können Preis- und
Home-Auswahl-Funktionen mit synthetischen Daten ausprobiert werden. Demo-Daten
belegen keine realen Verbrauchs- oder Pulse-Livewerte. Verwende den jeweils im
Explorer angebotenen Token und die dort für das Demo-Konto angezeigte Home-ID;
beide Werte können sich ändern.

## Eigene Preisfenster und Diagramme

Das Attribut `priceWindowHours` wählt ein zusammenhängendes Preisfenster von
einer bis sechs Stunden; ohne Attribut sind es zwei Stunden:

```text
attr TibberConnect priceWindowHours 6
```

Die mitgelieferten Diagrammdateien und FHEM-Beispiele sind in
[VISUALIZATION.md](VISUALIZATION.md) beschrieben. Persönliche Geräte- und
Konfigurationsbeispiele müssen an die eigenen Namen angepasst werden.

## Updatequelle entfernen

Wenn du keine weiteren Updates aus diesem Projekt beziehen möchtest, entferne
nur die registrierte Quelle:

```text
update delete https://raw.githubusercontent.com/parussel/TibberConnect/main/controls_TibberConnect.txt
```

Das meldet zukünftige Updates ab, deinstalliert aber keine Moduldateien. Für
eine Wiederherstellung siehe [ROLLBACK.md](ROLLBACK.md).
