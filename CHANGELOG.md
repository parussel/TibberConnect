# Änderungsprotokoll

## 2.0.1 — 2026-10-25

- Eine Wiederherstellungslücke in TibberLive wurde behoben: Ein WebSocket-Handshake ohne Rückmeldung wird nun durch einen unabhängigen 45-Sekunden-Zeitablauf begrenzt und wechselt in den vorhandenen kontrollierten Neuverbindungsablauf.
- Die Readings `lastDisconnectAt` und `lastDisconnectReason` wurden für eine übersichtliche Diagnose ergänzt. Gründe durchlaufen die vorhandene Token-Maskierung.
- Ein Regressionstest stellt sicher, dass ein abgelaufener oder überholter Handshake-Timer das Gerät weder blockiert noch einen neueren Verbindungsversuch beendet.

## Öffentlicher Release Candidate

- Die bewährten TibberConnect-REST-Readings und die Auswahl mehrerer Homes wurden beibehalten.
- Die GraphQL-Anfrage für die anonyme Home-Erkennung wurde korrigiert: `operationName` wird nur noch für eine benannte GraphQL-Operation gesendet. Dadurch wird der frühere HTTP-400-Fehler mit leerem `availableHomes` bei der Ersteinrichtung vermieden.
- Geschützte Token-Speicherung, sichere Wiederholungsversuche mit Wartezeit, getrennte Preis- und Verbrauchsabfragen, Viertelstunden-Cache, sommerzeitfeste Preisfenster und beratende Automations-Readings wurden ergänzt.
- Das getrennte optionale Modul TibberLive wurde mit `graphql-transport-ws`, dynamischer `websocketSubscriptionUrl`, kontrollierten Neuverbindungen, vollständiger Zuordnung der Live-Readings, Zustandsüberwachung und kalenderbasierter Batteriewartung ergänzt.
- FileLog-/DbLog-Beispiele, Preisdiagramme für Tag, Woche, Monat und Jahr, ein Live-Leistungsdiagramm, Tests, Rückkehranleitung und Datenschutzdokumentation wurden ergänzt.
- Ein optionales Standard-FHEM-Übersichtsbeispiel verbindet aktuellen Preis, Live-Leistung, Preisfenster und fertige SVG-Diagramme ohne SQLite oder DbLog.
- Beratende `priceForecast...`-Readings beschreiben den zusammenhängenden bekannten Preishorizont mit Intervallanzahl, Restminuten, bekanntem Endzeitpunkt und dem Zustand bereit/abgelaufen.
- Beratende `priceTrend...`-Readings vergleichen ohne weitere API-Anfrage die erste und zweite Hälfte der nächsten zehn vollständigen Preisintervalle.
- Kompakte maschinenlesbare Exporte aus dem lokalen Cache wurden für heute, morgen, die Prognose und einen exakten Zeitpunkt ergänzt. Die optionale getrennte FileLog-/GPlot-Quelle für zukünftige Preise verändert weder den Betriebsverlauf noch erzeugt sie Hunderte einzelne Readings.
- Normale Prognose-`get`-Befehle liefern kurze deutsche Bedienmeldungen; das Argument `json` behält den vollständigen maschinenlesbaren Export.
- Der bestätigte persönliche Tibber-Einladungslink wurde mit transparenter Freiwilligkeitserklärung und dem Verweis auf 153er-netz.de ergänzt.
- Die Veröffentlichung erfolgt als öffentlicher Release Candidate mit bewusst begrenztem FHEM-Update-Kanal: Automatisch aktualisiert werden nur die beiden Moduldateien und sechs GPlot-Dateien. Token, Home-IDs, Definitionen, Protokolle, FHEM-Konfiguration und persönliche `99_myUtils.pm`-Hilfen bleiben unangetastet.
