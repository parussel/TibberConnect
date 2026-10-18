# Wiederherstellung

Erstelle vor jedem Update eine Sicherung der beiden Moduldateien und der
FHEM-Konfiguration. Bewahre die Dateien mit ihren ursprünglichen Pfaden auf.

Wenn nach einem Update ein Problem auftritt:

1. TibberLive bei Bedarf deaktivieren; TibberConnect kann weiterhin REST-Daten
   bereitstellen.
2. Die zuvor gesicherte Version nur an den exakten Modulpfad zurückkopieren.
   Keine Wildcards oder breit wirkenden Löschbefehle verwenden.
3. FHEM mit `shutdown restart` neu starten.
4. Prüfen, ob die erwarteten Readings und Zustände wieder vorhanden sind.

Falls die Updatequelle nicht mehr verwendet werden soll, entferne sie mit dem
Befehl aus [UPDATE_CHANNEL.md](UPDATE_CHANNEL.md). Das entfernt nur die Quelle,
nicht die installierten Dateien.

Das Entfernen oder Deaktivieren von TibberLive löscht den geschützten
TibberConnect-Zugangstoken nicht. Zugangsdaten und persönliche Konfigurationen
sollten bei einer Wiederherstellung nicht durch fremde Beispielwerte ersetzt
werden.
