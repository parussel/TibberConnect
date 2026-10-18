# Historische Preis-Readings

Einige ältere Namen werden von dieser Version nicht mehr bereitgestellt. Für
die jeweiligen Anzeigen und Automationen können die folgenden Readings verwendet
werden:

| Älterer Name | Aktuelles Reading | Bedeutung |
| --- | --- | --- |
| `is_supercheap` | `priceIsNegative` | `1`, wenn der aktuelle Gesamtpreis unter null liegt, sonst `0`; ohne aktuellen Preis `unknown`. |
| `next_cheapest_time` | `nextCheapestWindowStart` | Beginn des günstigsten vollständigen, zusammenhängenden Zeitfensters gemäß `priceWindowHours`; bei fehlenden oder lückenhaften Preisen `unknown`. |
| `cheapest_block_2h` | `cheapestWindow2hStart`, `cheapestWindow2hEnd`, `cheapestWindow2hAverage` | Start, Ende und Durchschnittspreis des günstigsten zusammenhängenden Zwei-Stunden-Fensters. |

Bei gleichen Preisen wird das früheste passende Zeitfenster gewählt. Ein Fenster
wird nur ausgegeben, wenn alle dafür benötigten Preisintervalle vorhanden sind.
Tageswechsel und Sommer-/Winterzeit werden anhand der Zeitstempel berücksichtigt.

Alle Preis- und Automations-Readings sind beratend. `TibberConnect` führt keine
FHEM-Befehle aus und steuert keine Geräte.
