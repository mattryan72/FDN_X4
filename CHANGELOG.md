# Changelog

All notable changes to LI Freight Distribution Network (FDN) for X4: Foundations will be listed here.

## [1.03] – BETA – 2026-11-24

### Added

- **Localisation.** All player-facing FDN text now comes from the game's text files (text page **477605**): the settings page, the four Overview pages plus FDN Ware Rules, the station right-click menu, the charter, logbook entries, tickers, reasons and the kind names on FDN Alerts and FDN History. FDN follows the game language.
  - **English** is the source text (`t/0001-l044.xml`). `t/0001.xml` is an identical copy used for any language without its own file.
  - **12 draft translations:** German, French, Spanish, Italian, Russian, Polish, Czech, Brazilian Portuguese, Japanese, Korean, Simplified Chinese and Traditional Chinese (`t/0001-l007.xml` … `t/0001-l088.xml`). They are **machine-drafted** and marked as drafts; corrections from native speakers are welcome on the forum or GitHub. Game terms (station, ware, sector, logbook, station manager and so on) follow the game's own wording for each language where it exists.
  - Sentences that were built from pieces are now whole texts with numbered slots (`%1`, `%2` …), so translators can change the word order. English reads as before.
  - "FDN" and "Cr" are not translated. Station, sector and ware names come from the game in the current language.
  - content.xml has a translated extension description for each of the 12 languages; the extension name stays in English.
- **TRANSLATING.md** – how to correct or add a language.
- **tools/check_l10n.py** – checks the text files: every id used in md/ exists, slots match, no unescaped brackets, no English text left in md/, and every translation has exactly the English ids with the same `%n` slots.

### Changed

- The shortage check no longer compares the reason text ("station has no free storage for it"). It now uses an internal flag, so full stations do not raise false shortage alerts when the reasons are shown in another language. In English nothing changes.

### Notes

- `fdn.log` stays in **English** in every language, so log lines in bug reports read the same for everyone.
- Text already stored in a save (History, Alerts and logbook entries written before 1.03 or before a language switch) stays in the language it was written in. New entries use the current language. After switching language there can be one extra History entry or log line per station and ware before it settles.
- Longer languages (for example German and Russian) can make some labels wider; please report text that does not fit.
- Saves from 1.00–1.02 load as before. No settings were added or renamed, and nothing new is saved.
- content.xml `version` = `103` (the game shows 1.03). Dependency (SirNukes Mod Support APIs, `ws_2042901274`) and install path are unchanged. The new `t\` folder must be part of the install (manual installs: delete the old `extensions\fdn_x4` folder first, then extract the new zip).

## [1.02] – BETA – 2026-11-19

### Changed

- **FDN Overview split into four pages** (Extension Options). The Overview keeps the network summary, network fees and one short row per DC (name, status, stock %, fees in the last 24h), plus a one-line Needs attention count and links to:
  - **FDN DCs** – the full detail for one DC at a time (Network, Manager, totals, fees, ware stock vs target), with a **Next DC** button.
  - **FDN Alerts** – active Shortages (see Added), the Needs attention list and the Problems from recent activity (10 per page, Newer / Older).
  - **FDN History** – see Added.

### Added

- **FDN History page:** supplies, returns, collects, units and fees per hour for the last 24 hours, with a 24h totals row, for all DCs or one DC (**Showing:** button). Recent activity moved here and now lists every stored entry (up to 50) with the **Show:** filter.
- Hourly counts of supplies, returns, collects and units per DC, kept for 24 hours like the existing hourly fees.
- **Per-DC ware rules** (new page **FDN Ware Rules**, linked from **FDN DCs** for the DC shown). Each ware a DC stocks, produces, uses or trades gets a rule button:
  - **Stock** – normal behaviour (the default for every ware).
  - **Keep %** – the DC keeps that share of its storage target for the ware (10–100 %, steps of 10; starts at the **DC reserve** setting) and only supplies above it. The DC reserve setting still applies; the larger reserve wins.
  - **Never send** – the DC never supplies the ware to stations, directly or through the network. It still takes returns and collected overstock.
  - **Do not accept** – the DC takes no returns or collected overstock of the ware and is never chosen as a destination for it; the next DC in range that takes it is used instead. It can still supply what it has.
  - Click for the next rule, right-click for the previous one. **Reset all to Stock** (two clicks) clears every rule at that DC. The FDN DCs ware table shows the rule after the ware name.
  - Skips caused by a rule are the player's choice: no logbook or Needs attention entry, one fdn.log line at **Debug log detail** 4, throttled like other skip messages.
- **Shortage alerts** (new settings **Shortage alerts**, ON by default; **Shortage alert after**, 1–120 min, default 10; **Repeat shortage alert after**, 5–240 min, default 30). An on-screen message and a logbook entry (Alerts) when:
  - a managed station stays short of an input ware the FDN could not supply (no DC in range has it, every DC in range holds it back by ware rule, no DC in range, or not enough stock), or
  - a DC stays low on a ware (usable stock below what the stations it serves need; the same check as the existing low-stock warning, which is not duplicated).
  - The first alert comes once the shortage has lasted **Shortage alert after** game minutes, then at most once every **Repeat shortage alert after** minutes per station (or DC) and ware. The timer clears as soon as the station is supplied in full or the DC is restocked. A ware set to **Never send** at a DC never raises that DC's low-stock alert. A station with no free storage for a ware is not counted as short.
  - **FDN Alerts** lists the active shortages first (longest first, up to 30 rows), with minutes short, need and reason; red once the alert time is reached.
- **Trade buy limits** (new setting **Set trade buy limits**, ON by default). For every resource FDN sets a stock level for (Logical Overview), FDN now also sets that ware's trade **buy limit** to the same level and turns buying on, so NPC traders can top the station up to the FDN level too.
  - Same rules as the stock levels: never for wares the station makes itself, never for products, never on a DC, and only while **Supply station resources** is on for the station and a DC is in range.
  - Before the first change FDN saves your own buy limit (automatic or your manual amount) and whether buying was on. It puts them back when the setting is turned off, resource supply is turned off for the station, the ware is no longer needed, the station has no DC in range, becomes a DC, or the charter of the DC ends.
  - If you change a buy limit FDN manages, FDN logs it and sets its level again on the next pass; turn the setting off to keep your own.
  - Sell limits, prices and trade rules are not changed. fdn.log shows `trade limits:` lines (SET and RESTORED at **Debug log detail** 3).

### Notes

- Saves from 1.00 and 1.01 load as before. Hourly counts start at zero when 1.02 is installed; hourly fees already recorded still show.
- Ware rules are saved with the game, per DC. Older saves start with every ware on Stock. Rules are removed when the DC's charter ends.
- All rows on the FDN Overview pages can be highlighted. This lets long pages (FDN History, big DC ware lists) scroll and fixes FDN Ware Rules closing the menu when opened.
- Shortages are saved with the game. Older saves start with none and pick up the new settings at their defaults. Entries of removed stations, DCs whose charter ended, and shortages not seen for an hour (or twice the repeat time) are dropped.
- Buy limits FDN set are saved with the game, with the original values. Older saves start with none.
- **Set trade buy limits** needs a game restart after installing 1.02 (the FDN UI helper changed); it works with Protected UI Mode on, like the stock levels.
- Settings added: **Shortage alerts**, **Shortage alert after**, **Repeat shortage alert after**, **Set trade buy limits**.
- content.xml `version` = `102` (the game shows 1.02).
- v1.00 and v1.01 saves update in place; no steps needed. Settings, DC state, ware rules, shortage timers and saved buy limits live in the save. Manual installs: close the game, delete the old `extensions\fdn_x4` folder, then extract the new zip into `extensions\`.
- Workshop installs use extension id `ws_3835284205` and GitHub/manual installs use `fdn_x4`, so saves don't carry over between them. Pick one and don't install both.
- Dependency (SirNukes Mod Support APIs, `ws_2042901274`) and install path are unchanged.

## [1.01] – BETA – 2026-11-14

### Added

- **DC manager skill sets range and fees** (new setting **Manager skill sets range and fees**, ON by default). Each DC's station manager gives 0–5 stars (combined skill / 20, as the game counts stars).
  - Supply range: 3 jumps at 0–1 stars, 4 at 2–3 stars, 5 at 4–5 stars, never above **Maximum supply range** when the range limit is on.
  - DC-to-DC links: 6 / 8 / 10 jumps by the same steps, never above **DC network range**. A link between two DCs uses the smaller of their two ranges.
  - Fees a DC pays (supply, return, collection, DC-to-DC pull and NPC buy fees) are 10% lower per star of that DC's manager (5 stars = 50% off), after the normal fee formula. The charter fee is not changed.
- **A DC with no manager is offline** for FDN (not a home DC, source or target, and not supplied) until a manager is assigned. One warning in the logbook and `fdn.log`, an entry in the Overview's Needs attention list, and the DC comes back by itself at the next supply check after a manager is assigned.
- **FDN Overview:** a Manager row under each DC (stars, supply range, DC link range, fee discount, or "no manager"). The Network row follows the manager link ranges.

### Changed

- With **Manager skill sets range and fees** OFF, ranges and fees are flat and DCs without a manager still work, exactly as in 1.00.
- With Manager skill on, the manager's supply range (3–5 jumps) still applies even when Range limit is off; turn Manager skill off for unlimited range.
- content.xml `version` = `101` (the game shows 1.01).

### Notes

- v1.00 saves update in place; no steps needed. Settings and DC state live in the save. Manual installs: close the game, delete the old `extensions\fdn_x4` folder, then extract the new zip into `extensions\`.
- Workshop installs use extension id `ws_3835284205` and GitHub/manual installs use `fdn_x4`, so saves don't carry over between them. Pick one and don't install both.
- Dependency (SirNukes Mod Support APIs, `ws_2042901274`) and install path are unchanged.
- User guide: `docs/FDN_X4_User_Guide_v1.01_BETA.pdf` (also attached to the release).

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

### Notes

- Extension id: `fdn_x4`. content.xml `version` = `100`.
- This mod is new for X4; it is not a port of the X3 FDN script.
- Licence: MIT — Copyright (c) 2026 Matthew Ryan (Logain Abler).
- Hosting: Steam Workshop and GitHub https://github.com/mattryan72/FDN_X4
- Package: README.md and LICENSE in the extension root; PDF user guide in `docs/` on GitHub and attached to the release (not shipped in the package).
