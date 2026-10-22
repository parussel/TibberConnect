# Historical price-filter reconstruction

## Evidence searched

On 2026-10-17 the available TibberConnect source, both retained design/plan copies,
the accessible local Codex project files, and the referenced earlier project chat
were searched for `is_supercheap`, `next_cheapest_time`, and
`cheapest_block_2h`. The names occur only in the approved requirement to perform
this reconstruction. No earlier formula, unit, threshold, boundary convention, or
missing-data rule was recoverable from the material available to this worktree.

The old names are therefore not recreated with guessed semantics.

## Explicit successors

| Historical name | Status | Documented successor |
| --- | --- | --- |
| `is_supercheap` | Semantics unrecoverable | `priceIsNegative`: `1` only while the current total price is strictly below `0`; otherwise `0`. Missing current data produces `unknown`, never a guessed Boolean. |
| `next_cheapest_time` | Semantics unrecoverable | `nextCheapestWindowStart`: start timestamp of the cheapest complete contiguous window selected with `priceWindowHours` (`1..6`, default `2`) in the cached horizon. Equal-cost ties choose the earliest start. Missing/gapped horizons produce `unknown`. |
| `cheapest_block_2h` | Semantics unrecoverable | `cheapestWindow2hStart`, `cheapestWindow2hEnd`, and `cheapestWindow2hAverage`: earliest cheapest contiguous two-hour block. For quarter-hour data this is eight slots; it is emitted only when all eight adjacent intervals exist. |

All successor calculations use absolute epoch boundaries derived from each
ISO-8601 offset. This makes midnight and daylight-saving transitions continuous
without assuming that every local day contains 96 quarter-hours.

## Safety contract

The module publishes advice only. `automationMode` is `advisory` and
`automationDecision` records what a later automation could do. TibberConnect does
not execute an FHEM command or control an actuator.
