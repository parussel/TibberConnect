🔋 TibberConnect für FHEM

Das ultimative Modul zur intelligenten Strompreis-Steuerung.

Haftungsausschluss (Disclaimer)
Hiermit erkenne ich an (Sie als Benutzer), dass die Nutzung dieses Codes TibberConnect und deren Anwendung ausdrücklich auf eigene Gefahr erfolgt.
Keine Gewährleistung: Das Projekt wird in der vorliegenden Form ("as is") bereitgestellt, ohne jegliche Zusicherung oder Garantie auf Funktion, Richtigkeit oder Sicherheit.
Haftungsausschluss: Der Autor übernimmt keinerlei Haftung für Schäden an Hardware, Software oder Daten, die durch die Nutzung oder Fehlfunktion des Codes entstehen könnten. Dies gilt insbesondere auch für Folgeschäden.
Eigenverantwortung: Jeder Nutzer handelt in voller Selbstverantwortung. Es liegt in der Pflicht des Nutzers, den Code vor der Verwendung zu prüfen und geeignete Sicherheitsmaßnahmen (z. B. Backups, Tests in isolierten Umgebungen) zu ergreifen.

Hinweise beachten: Die Einhaltung der Technischen Anschlussbedingungen (TAB) sowie der VDE-Anwendungsregeln (speziell VDE-AR-N 4100) ist für den sicheren und normgerechten Betrieb von Kundenanlagen essenziell.
Hier sind die wichtigsten Kernpunkte zusammengefasst:

1. Leitungsführung und Auswahl der Querschnitte
Spannungsfall: Nach DIN 18015 darf der Spannungsfall zwischen Zähler und Stromkreisverteiler maximal 3 % betragen.
Belastbarkeit: Querschnitte müssen nach DIN VDE 0298-4 (Verlegeart, Umgebungstemperatur, Häufung) dimensioniert werden. Für den Vorzählerbereich sind in der Regel 16 mm² Cu (min. 10 mm²) Standard, um die thermische Festigkeit bei Dauerlast zu garantieren.
Dauerstrombelastbarkeit: Bei Anlagen mit Dauerlastcharakter (z. B. Wallboxen, Wärmepumpen) sind reduzierte Belastbarkeitswerte und erhöhte Querschnitte einzuplanen, um eine Überhitzung der Betriebsmittel zu vermeiden. 

2. Lastmanagement und Steuerbarkeit
§ 14a EnWG: Neue steuerbare Verbrauchseinrichtungen (Wallboxen > 4,2 kW, Wärmepumpen, Speicher) müssen für den Netzbetreiber steuerbar sein (Dimmen statt Abschalten).Kommunikationsleitung: Es muss zwingend ein Leerrohr oder eine Datenleitung (mind. Cat. 7) vom Zählerplatz zum Stellplatz bzw. zum Lastmanagementsystem verlegt werden.Schnittstellen: Die Anbindung erfolgt meist über eine RJ45-Schnittstelle im anlagenseitigen Anschlussraum (AuR) des Zählerschranks.

3. Zählerplatz und Verdrahtung
Verdrahtung: Innerhalb des Zählerschranks ist bei Dauerlast (z. B. 63 A Direktmessung) eine Verdrahtung mit 16 mm² vorgeschrieben.
Platzreserve: Es muss Raum für das Intelligente Messsystem (iMSys) und das Steuergerät (z. B. Steuerbox) vorhanden sein.

4. Absicherung und Schutzmaßnahmen
Überspannungsschutz (SPD): Ein Typ 1/2 Kombi-Ableiter im netzseitigen Anschlussraum (NAR) auf dem 40-mm-Sammelschienensystem ist Pflicht.
RCD (FI-Schalter): Für Ladepunkte ist in der Regel ein separater FI Typ A (mit DC-Fehlerstromerkennung 6mA) oder ein FI Typ B vorzusehen.

Wenn du elektrische Anlagen in Eigenleistung errichtest, trägst du die volle Verantwortung für die Sicherheit und Haftung. Auch ohne Fachmann müssen die allgemein anerkannten Regeln der Technik strikt eingehalten werden, da im Schadensfall (Brand, Stromschlag) Versicherungen die Leistung verweigern, wenn die Installation nicht normgerecht ist.
Hier sind die kritischen Ergänzungen und Normen:

1. Rechtlicher Rahmen (NAV)
§ 13 Niederspannungsanschlussverordnung (NAV): Gesetzlich ist festgelegt, dass Arbeiten an der Elektroanlage (hinter dem Hausanschluss) nur durch ein in ein Installateurverzeichnis eines Netzbetreibers eingetragenes Installationsunternehmen ausgeführt werden dürfen.
Eigenleistung: In der Praxis bedeutet das: Du darfst vorinstallieren (Kabel ziehen, Dosen setzen), aber die Inbetriebnahme und der Anschluss an den Zählerschrank müssen durch einen eingetragenen Elektromeister abgenommen und protokolliert werden.

2. Die "5 Sicherheitsregeln" (DIN VDE 0105-100)
Bevor du an einer Anlage arbeitest, sind diese zwingend:

    Freischalten.
    Gegen Wiedereinschalten sichern.
    Spannungsfreiheit allpolig feststellen (mit zweipoligem Prüfer, kein "Lügenstift").
    Erden und kurzschließen.
    Benachbarte, unter Spannung stehende Teile abdecken.

3. Schutzmaßnahmen (DIN VDE 0100-410)
Personenschutz: Alle Steckdosenstromkreise (bis 32A) und Beleuchtungsstromkreise in Wohnungen müssen über einen Fehlerstrom-Schutzschalter (RCD/FI) mit maximal 30 mA Auslösestrom abgesichert sein.
Brandschutz: In bestimmten Bereichen (z. B. Holzhäuser, Schlafstätten) sind zusätzlich Fehlerlichtbogen-Schutzeinrichtungen (AFDDs), umgangssprachlich "Brandschutzschalter", nach DIN VDE 0100-420 empfohlen oder vorgeschrieben.

4. Installationszonen (DIN 18015-3)
Leitungen dürfen nicht kreuz und quer verlegt werden. In Wohnräumen gelten feste Zonen (z. B. waagerecht 15 cm bis 45 cm über dem Fußboden oder unter der Decke, senkrecht 10 cm bis 35 cm neben Ecken/Fenstern). Das verhindert das Anbohren von Leitungen.

5. Dokumentation und Prüfung (DIN VDE 0100-600)
Jede neu errichtete Anlage muss vor der Inbetriebnahme geprüft werden. Ohne ein Prüfprotokoll (Messung von Isolationswiderstand, Schleifenimpedanz und RCD-Auslösezeit) gilt die Anlage als nicht ordnungsgemäß errichtet.

6. Kennzeichnung und Material
Farben: Die Adernfarben nach DIN VDE 0293-308 (Blau = Neutralleiter, Grün-Gelb = Schutzleiter) sind strikt einzuhalten. Der grün-gelbe Leiter darf niemals für andere Zwecke (auch nicht als Schaltdraht) verwendet werden.
Prüfzeichen: Verwende nur Material mit VDE- oder CE-Kennzeichnung. Billigimporte ohne diese Zertifikate erfüllen oft nicht die Anforderungen an die Kurzschlussfestigkeit.

Wichtiger Hinweis: Wenn du die Anlage selbst baust, solltest du vorab einen Elektromeister suchen, der bereit ist, deine Arbeit zu begleiten und am Ende die rechtlich notwendige Abnahme/Unterschrift zu leisten.
Hast du bereits ein Messgerät, um die Wirksamkeit der Schutzmaßnahmen (z. B. die Abschaltzeit des FI-Schalters) nach der Installation zu prüfen?

!!! Sollten Sie sich in einem anderen Land befinden, machen Sie sich mit den dortigen anzuwendenden Regeln Normen und Vorschriften der Elektrotechnik vertraut !!!

Nun aber Endlich weiter zu dem Tool

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
(In der Datei README2.md findest Du eine Kurzanleitung, wei Du als Tibber Kunde zu dem <API_TOKEN> <HOME_ID> kommst.)
Wichtige Attribute:

    attr myTibber chargeDevice Batterie_Ladegerat (Das Gerät für die Preis-Automatik)
    attr myTibber washDevice Waschmaschine (Wird bei Bestpreis eingeschaltet)
    attr myTibber maxHousePower 4200 (Pausiert das Laden bei > 4.2 kW Hauslast)

    (Die Regelung nach § 14a des Energiewirtschaftsgesetzes (EnWG), die seit dem 1. Januar 2024 in Kraft ist, betrifft steuerbare Verbrauchseinrichtungen (wie
    Wärmepumpen, Wallboxen, Speicher) mit einer Leistung von mehr als 4,2 kW)

Langzeit-Auswertung
Das Modul speichert Trends automatisch in Readings. In Kombination mit einem Wetter-Device lassen sich so Korrelationen zwischen Sonnenstunden und Strompreis-Stürzen grafisch darstellen.

Es handelt sich um mein erstes eigens Tool in FHEM, daher bitte ich um Nachsicht, bin aber dankbar für Verbesserungsvorschläge.
„Software ist nie fertig, sie wird nur aufgegeben.“
(oft Leonardo da Vinci zugeschrieben, bekannt geworden im Kontext der Softwareentwicklung)
„Was nicht endet, öffnet den Weg ins Unendliche.“ (Leider habe ich nur nicht unendlich Zeit;-)
Frank Parussel

