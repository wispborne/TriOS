## ADDED Requirements

### Requirement: The sort is remembered

The Catalog SHALL save the chosen sort and its direction to app settings, and restore them on the next launch.

- "Best match" SHALL never be saved. While Best match is showing, the saved sort SHALL stay the one that Best match will go back to.
- A saved sort name that TriOS no longer knows SHALL fall back to the default: Popular, most first.

#### Scenario: Sort survives a restart
- **WHEN** the user picks "Newest", flips it to oldest first, and restarts TriOS
- **THEN** the Catalog opens sorted by Newest, oldest first

#### Scenario: Best match is not saved
- **GIVEN** the user had "Name" picked
- **WHEN** they type a search, so Best match takes over, and then close TriOS
- **THEN** the Catalog opens sorted by Name

### Requirement: Random sort

The Catalog SHALL have a "Random" sort.

- The order SHALL be picked once per launch, and SHALL hold while the user switches tabs, filters, or searches.
- The same mod SHALL keep its place relative to the others when filters change. Filtering removes mods from the order. It does not reshuffle it.
- A Shuffle button SHALL appear in place of the direction arrow while Random is picked. Pressing it picks a new order.
- If Random is the saved sort, the next launch SHALL open on Random with a new order.

#### Scenario: Order holds while filtering
- **GIVEN** Random is picked and mod A shows before mod B
- **WHEN** the user turns a filter on and off again
- **THEN** mod A still shows before mod B

#### Scenario: Shuffle picks a new order
- **WHEN** the user presses Shuffle
- **THEN** the grid shows the same mods in a new order
