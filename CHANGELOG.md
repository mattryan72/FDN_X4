# Changelog

All notable changes to LI Freight Distribution Network (FDN) for X4: Foundations will be listed here.

## [1.01] - Unreleased

### Added

- **DC manager skill sets range and fees** (new setting **Manager skill sets range and fees**, ON by default). Each DC's station manager gives 0–5 stars (combined skill / 20, as the game counts stars).
  - Supply range: 3 jumps at 0–1 stars, 4 at 2–3 stars, 5 at 4–5 stars, never above **Maximum supply range** when the range limit is on.
  - DC-to-DC links: 6 / 8 / 10 jumps by the same steps, never above **DC network range**. A link between two DCs uses the smaller of their two ranges.
  - Fees a DC pays (supply, return, collection, DC-to-DC pull and NPC buy fees) are 10% lower per star of that DC's manager (5 stars = 50% off), after the normal fee formula. The charter fee is not changed.
- **A DC with no manager is offline** for FDN (not a home DC, source or target, and not supplied) until a manager is assigned. One warning in the logbook and `fdn.log`, an entry in the Overview's Needs attention list, and the DC comes back by itself at the next supply check after a manager is assigned.
- **FDN Overview:** a Manager row under each DC (stars, supply range, DC link range, fee discount, or "no manager"). The Network row follows the manager link ranges.

### Changed

- With **Manager skill sets range and fees** OFF, ranges and fees are flat and DCs without a manager still work, exactly as in 1.00.

## [1.00] – BETA – 2026-11-07

### Added

- Initial public **beta** release for **X4: Foundations 9.00**.
- **FDN Charter** on player stations (right-click): fee 75% of the average price of the most expensive qualifying dock (whitelist of operational dock areas/piers; excludes ship-build bays, equipment docks, Xenon and landmark parts), clamped to 1.5M–4M Cr, then standing discount. Standing 10+ with sector owner (player-owned/ownerless/Xenon/Kha'ak: best standing with an eligible economy faction); discounts 10%/25%/40% at standing 10/20/30; revoke ends DC status with no refund.
- **Automatic membership** for every player-owned station (including new builds). Per-station toggles (ON by default): resource supply and send products to DC (products toggle hidden on DCs). Global settings with per-station override.
- **Home DC / network:** nearest eligible DC by gate jumps is home DC; other DCs in range and in the home DC's network tried by distance; network is a chain of DCs each linked within 10 jumps; supply from another DC goes direct; home DC normally pays 0.1× the supply fee (source may pay full fee if home cannot); a receiving DC is its own home; no configurable primary DC or explicit network/DC-count cap is implemented.
- **Supply** from DC stock for N production cycles (default Cycles to cover: 2), with NPC fallback buy when short (on by default; price capped at the home DC's buy price, or receiving station's price if no usable home-DC price exists).
- **Product returns** above a cycle-based keep (default Product cycles to keep: 0; no stock kept; minimum transfer batch 100); per-ware override available.
- **Overstock collection** (default trigger 10% above keep), with anti-ping-pong rules for dual-use / self-made wares (collect only above 2× need, leave 1.5×, not within 10 minutes of an FDN delivery).
- **Stock-level bridge** for supplied resources via Mission Director scripts plus one small UI Lua file (vanilla storage-level overrides only; Protected UI Mode does not need to be turned off). Each DC keeps 10% of each ware by default.
- **Instant transfers** by default with value- and distance-based fees with adjustable flat volume/type factors paid by the DC: 2% of transfer value × (1 + 0.2 per jump) × volume factor 1.0 × ware type factor 1.0 (volume/type factors adjustable up to 3; range factor up to 1); returns 0.5×; collections 1×; DC-to-DC pulls 0.1×. Optional transfer delay (off; 8 s per jump when on). Returns/collections try another legal DC in range before holding the ware at the station.
- **FDN Overview** (read-only): DCs online, totals, network fees 1h/6h/24h with supply/return/collect split, Needs attention list, per-DC stock vs target, paged recent activity.
- **Warnings** deduped by station + ware + kind + reason until the fingerprint changes or a successful move clears it; low DC stock warning; logbook notices; **fdn.log** with log level 1–4 (default 3; logbook level 2).
- **Settings** via SirNukes Mod Support APIs options menu.
- Design choice: sell DC surplus with normal in-game sell offers on the DC; FDN never sells directly to NPC stations.
- Recommended uninstall steps documented — revoke charters, wait for RESTORED/SOLO in fdn.log, save to a new slot, then disable.

### Notes (beta)

- Defaults may change during beta.
- Dependency: SirNukes Mod Support APIs (`ws_2042901274`, folder `sn_mod_support_apis`).
- See internal release notes for test coverage details (not listed on public forum/Workshop posts).

### Notes

- Extension id: `fdn_x4`. content.xml `version` = `100`.
- This mod is new for X4; it is not a port of the X3 FDN script.
- Licence: MIT — Copyright (c) 2026 Matthew Ryan (Logain Abler).
- Hosting: Steam Workshop and GitHub https://github.com/mattryan72/FDN_X4
- Package: README.md and LICENSE in the extension root; PDF user guide in `docs/` on GitHub and attached to the release (not shipped in the package).
