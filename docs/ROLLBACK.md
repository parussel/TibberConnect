# Sicherung und Rückkehr zum vorherigen Stand

Vor dem Ersetzen einer funktionsfähigen Datei Pfad, Dateigröße und SHA-256-Prüfsumme notieren und eine Sicherung mit Zeitstempel anlegen.

1. Am aktuellen Prüfschritt anhalten, wenn Syntax, Prüfsumme, Neuladen oder Readings vom erwarteten Ergebnis abweichen.
2. Das betroffene Gerät vor der Rückkehr deaktivieren und keine Automationen aktivieren.
3. Ausschließlich den exakt gesicherten Modulpfad wiederherstellen. Niemals Platzhalter oder eine breit angelegte rekursive Löschung verwenden.
4. Die wiederhergestellte Datei neu laden und `state`, `connection`, `transportState` sowie die erhaltenen Preis- und Verbrauchs-Readings prüfen.
5. Die gesicherte FHEM-Konfiguration nur dann wiederherstellen, wenn die Rückkehr der Moduldatei nicht ausreicht.

Eine Rückkehr löscht keine Protokolle. Das gesicherte Modul, seine Prüfsumme und etwaige Fehlerausgaben für die Diagnose getrennt aufbewahren.

TibberLive ist unabhängig: Es kann deaktiviert oder entfernt werden, während TibberConnect weiterhin REST-Daten bereitstellt. Beim Entfernen von TibberLive darf das geschützte TibberConnect-Token nicht gelöscht werden.

Falls das optionale Prognosediagramm eingerichtet wurde, zuerst `forecastLogFile` und die selbst erstellten Definitionen `FileLog_TibberForecast`/`SVG_TibberForecast` entfernen. Erst danach die separat gewählte Prognosedatei löschen. Ein vorhandenes normales TibberConnect-FileLog, DbLog, der Reading-Verlauf und das Token bleiben davon unberührt.
