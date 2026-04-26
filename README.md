🔋 TibberConnect für FHEM
Das ultimative Modul zur intelligenten Strompreis-Steuerung.
Features

    Auto-Ladelogik: Schaltet Geräte automatisch bei Negativpreisen oder zum Tagesminimum.
    Lastmanagement: Pausiert das Laden der Batterie, wenn der Hausverbrauch (Pulse) zu hoch wird.
    Trend-Analyse: Loggt Preise im Verhältnis zum Wochentag für Langzeit-Statistiken.
    Einfachheit: Ersetzt komplexe HTTPMOD-Definitionen und mehrere DOIF-Module.
    Geldverdienen/sparen bei negativem Strompreis

Installation

    Datei 70_TibberConnect.pm in den Ordner /FHEM/ deiner FHEM-Installation kopieren.
    In FHEM: reload 70_TibberConnect.

Konfiguration
define myTibber TibberConnect <API_TOKEN> <HOME_ID>
Wichtige Attribute:

    attr myTibber chargeDevice Batterie_Ladegerat (Das Gerät für die Preis-Automatik)
    attr myTibber washDevice Waschmaschine (Wird bei Bestpreis eingeschaltet)
    attr myTibber maxHousePower 8000 (Pausiert das Laden bei >8kW Hauslast)

Langzeit-Auswertung
Das Modul speichert Trends automatisch in Readings. In Kombination mit einem Wetter-Device lassen sich so Korrelationen zwischen Sonnenstunden und Strompreis-Stürzen grafisch darstellen.
