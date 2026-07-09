# Add Sector System Finder (find-my-perfect-system mode)

## Problem

The shipped Sector Map viewer shows the player everything: every system, plotted, named,
owned. That is the whole point of an atlas — but it also deletes the best part of
Starsector, which is finding a great system yourself. Reading the save out-of-game turns
exploration into a spoiler.

The real chore players want gone is not the *finding* — it's the *scanning*: surveying
hundreds of systems to locate the few that fit what they want (good resources, low hazard,
a habitable world, room for stations, a cryosleeper nearby). They want help narrowing the
hunt without being handed the answer.

## Solution

Add a **System Finder** mode to the Sector Map tool. The player describes their ideal
colony system with a panel of knobs, and the tool helps in two deliberate phases:

1. **Tuning** — the player drags knobs and sees only a **count**: "14 systems fit." No map,
   no places. Tightening until the number is small but not zero is the core loop; the count
   tells them how rare their dream is.
2. **Reveal** — when satisfied, the player clicks **Hint**, which gives a blurred location
   for their single best-scoring match and escalates one click at a time:
   "somewhere in these 5 constellations" → "narrowed to these 2" → "the Aspis
   constellation" → "Galatia" (full spoiler). They stop whenever they have enough to go hunt
   in-game, and can ask for the next-best match if the first disappoints.

The knobs are hybrid:

- **Hard toggles** are deal-breakers (must be habitable, must have a gas giant, needs
  ≥N stable locations, must be near a cryosleeper).
- **Soft sliders** say how much the player cares; they set the score that ranks matches and
  therefore decides reveal order.
- **Each resource** (ore, rare ore, organics, volatiles, farmland) shows **two** controls,
  always: an optional minimum-tier **floor** (hard cutoff) and a **weight** slider (soft).

A system is the unit of search, scored **best-of**: it gets credit for a thing if *any* of
its planets has it (the classic "this system has everything between its planets" find).

**Preset buttons** (Colony Hunter, Resource Baron, Cryosleeper Nearby, …) pre-fill the
panel; the full knob set always stays available.

The existing show-everything atlas is not removed — it becomes the **bottom rung of the
hint ladder** and an overflow-menu item, so the spoiler is opt-in rather than the default.

This builds directly on the shipped Sector Map viewer (`lib/sector_map/`). Data feasibility
is confirmed against a real 10 MB `campaign.xml`: every surveyable planet carries a flat
condition list in a `PCMarket`, joined to its system by the *same* join the current parser
already does; landmarks (cryosleeper, gate, coronal tap) are entities that name their
system. The current parser simply discards this condition data — the finder keeps it.

## Scope

- Extend the parser to harvest, per system: each planet's condition/resource list, planet
  type, and computed hazard rating; plus sector landmarks (cryosleeper, coronal tap, active
  gate) with the system each sits in.
- A matching + scoring engine: hard toggles/floors filter; soft sliders score each surviving
  system best-of; landmark "nearby" matched by system-to-system distance against the
  game-defined benefit radius (default ~10 LY, widenable).
- Finder UI: the knob panel (toggles, resource floor+weight rows, landmark proximity,
  distance-from-core), preset buttons, and a live match **count**.
- Reveal UI: the **Hint** button and the escalating constellation→system ladder, focused on
  the best match, with "next match" support. The atlas full-reveal render is the ladder's
  final step.
- Mod support (option C): polished hard-coded knobs for the stable vanilla resource ladder
  and known conditions/landmarks, **plus** a raw "other conditions" section built from
  whatever condition ids exist in the loaded save, as plain toggles.
- Zero-match help: name the toggle that is the bottleneck ("Turn off Habitable → 4 fit").
- Persist the player's knob state and reveal preferences with the page (existing persisted
  page-state pattern).

## Non-goals

- **Re-surveying respect.** The finder reads everything in the save regardless of in-game
  survey level — finding unsurveyed gems is the point. No "only systems I've surveyed" mode
  in this change.
- **Exact hazard parity with the game** down to the last percent, or modded hazard formulas.
  We compute hazard from the condition list with the known vanilla formula; modded
  hazard-altering conditions are best-effort.
- **Drill into a single system** (planets/orbits view). Out of scope here, as in the atlas.
- **Editing the save**, fleets, economy, or anything non-spatial.
- **Ranked multi-match map view.** Reveal focuses on one best match at a time, not a
  heatmap of all matches.
- **Curated knobs for modded content.** Modded conditions appear only in the raw "other
  conditions" section, without nice labels or tier ordering.
