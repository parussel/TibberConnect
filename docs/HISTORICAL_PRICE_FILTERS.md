# Rekonstruktion historischer Preisfilter

## Durchsuchte Grundlagen

Am 17.10.2026 wurden der verfügbare TibberConnect-Quelltext, beide erhaltenen Entwurfs- und Planungskopien, die zugänglichen lokalen Codex-Projektdateien und der referenzierte frühere Projekt-Chat nach `is_supercheap`, `next_cheapest_time` und `cheapest_block_2h` durchsucht. Die Namen kommen nur in der freigegebenen Anforderung für diese Rekonstruktion vor. Aus dem verfügbaren Material ließen sich weder frühere Formel, Einheit, Schwelle und Grenzdefinition noch eine Regel für fehlende Daten wiederherstellen.

Die alten Namen werden daher nicht mit geratenen Bedeutungen neu erzeugt.

## Eindeutige Nachfolger

| Historischer Name | Status | Dokumentierter Nachfolger |
| --- | --- | --- |
| `is_supercheap` | Bedeutung nicht wiederherstellbar | `priceIsNegative`: nur `1`, solange der aktuelle Gesamtpreis strikt unter `0` liegt, sonst `0`. Fehlende aktuelle Daten ergeben `unknown`, niemals einen geratenen Wahrheitswert. |
| `next_cheapest_time` | Bedeutung nicht wiederherstellbar | `nextCheapestWindowStart`: Startzeitpunkt des günstigsten vollständigen zusammenhängenden Fensters, das mit `priceWindowHours` (`1..6`, Standard `2`) im Cache gewählt wurde. Bei gleichen Kosten gewinnt der früheste Beginn. Fehlende oder lückenhafte Horizonte ergeben `unknown`. |
| `cheapest_block_2h` | Bedeutung nicht wiederherstellbar | `cheapestWindow2hStart`, `cheapestWindow2hEnd` und `cheapestWindow2hAverage`: frühester günstigster zusammenhängender Zweistundenblock. Bei Viertelstundendaten sind dies acht Abschnitte; ausgegeben wird er nur, wenn alle acht benachbarten Intervalle vorhanden sind. |

Alle Nachfolgeberechnungen verwenden eindeutige Unix-Zeitstempel, die aus dem
jeweiligen ISO-8601-Offset abgeleitet werden. So bleiben Mitternacht und
Zeitumstellungen zusammenhängend, ohne vorauszusetzen, dass jeder lokale Tag
96 Viertelstunden enthält.

## Sicherheitszusage

Das Modul veröffentlicht ausschließlich Empfehlungen. `automationMode` ist `advisory`, und `automationDecision` hält fest, was eine spätere Automation tun könnte. TibberConnect führt keinen FHEM-Befehl aus und steuert keinen Aktor.
