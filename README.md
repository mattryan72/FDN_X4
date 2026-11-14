# LI Freight Distribution Network (FDN) for X4: Foundations

**Version:** 1.00 **BETA**
**Author:** Logain Abler (Logain Industries)
**Game:** X4: Foundations **9.00**
**Extension id / folder:** `fdn_x4`
**Licence:** MIT — Copyright (c) 2026 Matthew Ryan (Logain Abler)

Logain Industries Freight Distribution Network (FDN) is a logistics mod for X4: Foundations. Designate player stations as Distribution Centres (DCs), then let FDN supply your production stations from DC stock, return surplus product, and collect overstock — with value- and distance-based fees with adjustable flat volume/type factors, a read-only Overview, and settings in the SirNukes Mod Support APIs options menu.

This is a **new** mod for X4. It is similar in idea to the Logain Industries FDN script for X3, but it is **not** the same mod and is **not** a port.

> **BETA.** Defaults may change during beta. Back up saves.

## Requirement

- **X4: Foundations 9.00**
- **[SirNukes Mod Support APIs](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274)** — **required** (Workshop id `2042901274`, folder `sn_mod_support_apis`). FDN uses its Simple Menu API (settings) and Lua loader. Subscribe and enable it yourself.

Protected UI Mode does **not** need to be turned off. FDN is Mission Director scripts plus one small UI Lua file that only reads, sets and clears station storage-level overrides with vanilla game functions (no buy/sell limits, prices or trade rules).

## Features

- **FDN Charter** — buy a one-off charter on a player station (right-click menu) to make it a Distribution Centre. Fee: 75% of the average price of the **most expensive qualifying dock** on the station (operational dock area or pier from FDN's whitelist: selected Argon/Boron/Terran dock areas and Argon/Paranid/Teladi/Split/Boron/Terran piers; the exact macro whitelist is CharterMacros in md/fdn_core.xml; **not** ship-build bays, equipment docks, Xenon or landmark parts), clamped to 1.5M–4M Cr, then the standing discount. Needs standing 10+ with the sector owner; in player-owned, ownerless, Xenon or Kha'ak sectors it uses your best standing with an eligible economy faction. Discounts 10% / 25% / 40% at standing 10 / 20 / 30. Revoking ends DC status with **no refund**.
- **Automatic membership** — FDN registers every player-owned station, including new ones as they are built. Two per-station right-click toggles, both ON by default: **FDN: resource supply ON/OFF** and **FDN: send products to DC ON/OFF** (the products toggle is hidden on DCs). Global equivalents in settings: **Supply station resources** and **Send products to DC**. Per-station setting overrides global, which overrides the default. A station with no DC in range gets no new FDN supply and runs as normal (its stock levels are handed back; previously queued deliveries may still finish).
- **Home DC and network** — the nearest eligible DC by gate jumps is the station's **home DC** and is tried first. Other DCs must be within the station's range (default 5 jumps) and in the home DC's network, tried in order of distance from the home DC. A network is a chain of DCs each linked within 10 jumps, so it can span further overall. Supply from another DC goes directly to the station; the home DC normally pays 0.1× the ordinary supply fee. If it cannot pay, the source DC may pay the full supply fee. A station that is itself a DC is its own home DC. There is no configurable primary DC; no network-size or DC-count cap is implemented in these paths.
- **Manager skill (1.01)** — each DC's station manager sets that DC's reach and fees: supply range 3 / 4 / 5 jumps at 0–1 / 2–3 / 4–5 stars (never above Maximum supply range), DC-to-DC links 6 / 8 / 10 jumps (never above DC network range; a link uses the smaller of the two DCs), and 10% off the fees that DC pays per manager star (5 stars = 50% off; not the charter fee). A DC with no manager is offline for FDN until one is assigned. Turn **Manager skill sets range and fees** off for flat ranges and fees as in 1.00.
- **Supply** — DCs supply stations with resources for N production cycles from DC stock. If the DC is short, FDN can fall back to an NPC buy (on by default), price capped at the home DC's buy price (the receiving station's buy price is the fallback if the DC has no usable buy price).
- **Product returns** — surplus product above a cycle-based keep goes to the DC (per-ware override available).
- **Overstock collection** — surplus resources follow "send products to DC". Dual-use / self-made wares a station also uses are only collected above 2× need, leaving 1.5×, and not within 10 minutes of an FDN delivery (stops ping-pong).
- **Stock levels** — FDN sets station stock levels for supplied resources, saves originals, restores them when a ware is no longer needed; never sets product levels; leaves self-made wares to the game.
- **Transfers** — instant by default, with value- and distance-based fees with adjustable flat volume/type factors paid by the DC, and an optional distance delay. For returns and collection, an illegal ware may use another legal DC in range; otherwise it stays at the station.
- **FDN Overview** (read-only) — DCs online, totals, network fees 1h/6h/24h with supply/return/collect split, Needs attention list, per-DC stock vs target, paged recent activity.
- **Warnings and logging** — deduped skip warnings (station + ware + kind + reason; a changed fingerprint or successful move can allow another warning), low DC stock warning, logbook notices, `fdn.log` (log level 1–4).
- **Settings** — in the SirNukes Mod Support APIs options menu.
- **Selling DC surplus** — use normal in-game sell offers on the DC. FDN never sells directly to NPC stations.

## Default settings

Defaults may change during beta.

| Setting | Default |
|--------|---------|
| Range limit | On |
| Max jumps to a DC | 5 (turn Range limit Off for no distance limit) |
| DC network link | DCs each linked within 10 jumps form a network chain |
| Manager skill sets range and fees (1.01) | On: supply range 3–5 jumps and DC links 6–10 jumps by manager stars (capped by the two rows above), 10% fee discount per star, DC with no manager offline |
| Cycles to cover | 2 |
| Product cycles to keep | 0 (no product keep; returns start at the minimum batch of 100, not a retained 100) |
| Overstock trigger | Pure resources: 10% above cargo.target; dual-use uses its separate cushion |
| Dual-use / self-made wares | Collect only above 2× need, leave 1.5×, not within 10 min of a delivery |
| DC keep per ware | 10% |
| NPC fallback buying | On |
| Resource supply (global / per-station) | On |
| Send products to DC (global / per-station) | On (per-station products toggle hidden on DCs) |
| Fee base | 2% of transfer value × (1 + 0.2 per jump) × volume factor 1.0 × ware type factor 1.0 (volume and ware-type factors adjustable up to 3; range factor up to 1) |
| Return fee | 0.5× the ordinary supply fee |
| Collection fee | 1× the ordinary supply fee |
| DC-to-DC pull fee | Normally 0.1× (home DC pays); source may pay full fee if home cannot |
| Who pays fees | The DC |
| Transfer delay | Off (8 s per jump when on) |
| Charter fee | 75% of most expensive qualifying dock average price, min 1.5M / max 4M Cr |
| Charter standing | Needs 10+ with sector owner (player/ownerless/Xenon/Kha'ak: best standing with an eligible economy faction); discounts 10% / 25% / 40% at standing 10 / 20 / 30 |
| Charter revoke | No refund |
| Log level | 3 (1–4) |
| Logbook level | 2 |
| DC ledger size | Adjustable in settings (default 200 entries per DC; range 50–1000); recent activity is a separate 50-entry list |

## How to use

1. Install FDN and SirNukes Mod Support APIs; enable both in the Extension Manager.
2. FDN registers all player-owned stations automatically. On a station, right-click and **buy an FDN Charter** to make it a Distribution Centre.
3. Use the per-station toggles (or the global settings) for **resource supply** and **send products to DC**.
4. Use the **FDN Overview** for status, fees and Needs attention.
5. Adjust **settings** in the SirNukes Mod Support APIs options menu.
6. **Revoke** a charter to stop using a station as a DC (no refund).

## Install

### Steam Workshop

1. Subscribe to this mod and to [SirNukes Mod Support APIs](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274).
2. Enable both in the Extension Manager.

Workshop link: [Workshop URL pending publication]

### Manual zip (GitHub / GOG)

1. Download the release zip from https://github.com/mattryan72/FDN_X4/releases
2. Extract the zip into `X4 Foundations\extensions\` (the zip contains the `fdn_x4` folder, so you end up with `X4 Foundations\extensions\fdn_x4\content.xml`)
3. Install SirNukes Mod Support APIs into `X4 Foundations\extensions\sn_mod_support_apis`
4. Enable both in the Extension Manager

> **Install location:** Manual installs must go in the game's own `X4 Foundations\extensions\` folder, not under `Documents\Egosoft\X4\<id>\extensions\`. The required Mod Support APIs dependency is not found when FDN is installed only in the Documents extensions folder (tested).

`README.md` and `LICENSE` ship in the extension root. The PDF user guide is on GitHub at https://github.com/mattryan72/FDN_X4/blob/main/docs/FDN_X4_User_Guide_v1.00_BETA.pdf and is also attached to each release (it is not shipped inside the mod package).

## Save safety / Uninstall

Adding FDN to an existing save creates FDN's data on load. The DC ledger defaults to 200 entries per DC (UI range 50–1000), and recent activity keeps 50 entries. There is no overall save-size bound; not every saved table or pending-transfer list has a fixed cap. Setting LedgerMax to 0 or below outside the UI bypasses ledger trimming. Back up first.

### Recommended uninstall steps

Reason: FDN sets real station storage levels, which stay in the save if the mod is simply removed.

1. Back up your save.
2. With FDN still enabled, revoke every charter (**FDN: revoke charter (no refund)**); optionally switch resource supply OFF.
3. Keep FDN and Mod Support APIs enabled until saved levels have been restored: check **RESTORED** (or already-original) messages and **SOLO** for managed stations losing service. Resolve restore/helper failures and inspect original manual/automatic levels. If transfer delay was on, let queued deliveries finish before removing FDN. Per-station switches override global settings.
4. Save to a new slot, disable FDN, load.

## Bug reports

Please report on the Egosoft forum thread ([forum thread URL pending publication]) and include:

- X4 version, DLC, and FDN v1.00
- What you did and what went wrong
- `fdn.log` from `Documents\Egosoft\X4\<id>\fdn.log`, with **log level 4**, then reproduce the issue

## Credits

- FDN by Logain Abler (Logain Industries)
- SirNukes Mod Support APIs by SirNukes — required dependency (Simple Menu API and Lua loader)

## Licence

MIT License — Copyright (c) 2026 Matthew Ryan (Logain Abler). See [LICENSE](LICENSE).

## Links

- Egosoft forum (X4 Scripts and Modding): [forum thread URL pending publication]
- Steam Workshop: [Workshop URL pending publication]
- GitHub: https://github.com/mattryan72/FDN_X4
- Releases: https://github.com/mattryan72/FDN_X4/releases
- User guide (PDF): https://github.com/mattryan72/FDN_X4/blob/main/docs/FDN_X4_User_Guide_v1.00_BETA.pdf
- SirNukes Mod Support APIs: https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274

Unofficial fan content. Requires a legally owned copy of X4: Foundations. Distributed free of charge under the MIT License (which permits commercial use). No Egosoft assets are redistributed.
