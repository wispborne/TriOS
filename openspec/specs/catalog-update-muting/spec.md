# Catalog Update Muting

## Overview

The Mod Catalog respects, and can change, the update mutes the Mods page
already stores. One mute per mod, shared between the two pages.

## Requirements

### R1: One shared mute

- Muting from the Catalog writes the same `ModMetadata` fields the Mods page
  writes, keyed on the installed mod's id.
- A mute set anywhere takes effect everywhere: the Catalog, the Mods grid, and
  the Dashboard.
- Both kinds of mute are offered: the whole-mod mute and the single-version
  mute. Which one the menu offers is decided by the shared menu item, not by
  the Catalog.

#### Scenario: Muting in the Catalog quiets the Mods page

- **GIVEN** a mod with an update, shown on both pages
- **WHEN** the user mutes it from its Catalog card
- **THEN** the Mods grid shows it as muted too, with no further action

### R2: A muted card shows no update

- A card whose update is muted presents as installed, not as updatable: the
  button becomes the inert "Installed" marker and the left status bar shows the
  enabled or disabled colour rather than the update colour.
- The card's right-click menu still lists every download, so the mod can still
  be updated deliberately.

#### Scenario: The update styling goes away

- **GIVEN** an installed mod with an update, its card showing an "Update" button
- **WHEN** the user mutes the update
- **THEN** the button becomes the "Installed" marker and the status bar returns
  to its enabled or disabled colour

### R3: A bell marks a muted mod

- A bell shows on the card whenever the mod is muted entirely, or whenever the
  current remote version is the muted one.
- A mod muted entirely shows the bell even when no update is known, since
  version checks have stopped and there may never be one.
- The hover text is the same wording the Mods page uses.
- Right-clicking the bell offers "Recheck" plus the shared mute item. "Recheck"
  is left out when the mod is muted entirely.

#### Scenario: A muted mod stays findable

- **GIVEN** a mod muted entirely, with no known update
- **WHEN** its Catalog card is shown
- **THEN** the bell is visible, and right-clicking it offers to unmute

### R4: The update filter and count skip muted mods

- The "Has Update" filter does not match a mod whose update is muted.
- The badge count beside it does not include those mods.
- Beside the count, a "+ N" and a bell say how many mods with an update were
  left out for being muted. Neither shows when nothing is muted.
- Both recompute as soon as a mute is toggled.
- A mod is only skipped when the mute covers its *current* remote version. A
  single-version mute on an older version does not hide a newer update.

#### Scenario: The badge count drops on mute

- **GIVEN** the "Has Update" badge reads 5 with nothing muted
- **WHEN** the user mutes one of those five
- **THEN** the badge reads 4, followed by "+ 1" and a bell
- **AND** that mod no longer matches the filter

#### Scenario: A new version speaks up again

- **GIVEN** a mod whose version 1.5.0 update was muted
- **WHEN** the mod starts advertising 1.6.0
- **THEN** the card shows the update again and the mod counts toward the badge

### R5: Nothing to mute without an installed mod

- A catalog entry with no installed mod offers no mute control and no bell.
