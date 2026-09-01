## ADDED Requirements

### Requirement: Profiles change only through explicit saving
TriOS SHALL keep a saved mod profile unchanged when the enabled loadout changes.
Only an explicit Save changes, Save and deactivate, or Save and activate action SHALL
replace the profile's members.

#### Scenario: User toggles a mod
- **WHEN** the user enables or disables a mod while a profile is tracked
- **THEN** TriOS SHALL leave the tracked profile unchanged

#### Scenario: User saves changes
- **WHEN** the user chooses Save changes
- **THEN** TriOS SHALL replace the tracked profile's members with the current enabled variants and update its modification time

### Requirement: Loading-aware profile comparison
TriOS SHALL wait for both the first mod-folder scan and the enabled-mod file
before comparing the current loadout with a tracked profile.

#### Scenario: Comparison inputs are not ready
- **WHEN** either required input is still loading
- **THEN** TriOS SHALL show a loading state and disable Save, Revert, Stop, and Switch actions

#### Scenario: Comparison inputs become ready
- **WHEN** both required inputs are ready
- **THEN** TriOS SHALL compare mod IDs and exact variant IDs while ignoring order and display data

### Requirement: Modified loadout state
TriOS SHALL derive Modified from the current loadout and tracked profile without
persisting a flag. A missing member, additional enabled mod, or different active
variant SHALL make the current loadout Modified.

#### Scenario: Loadout matches by identity
- **WHEN** the same mod IDs and variant IDs are enabled in a different list order
- **THEN** TriOS SHALL treat the current loadout as unchanged

#### Scenario: Dependency checks change activation results
- **WHEN** normal dependency behavior leaves the enabled loadout different from the saved profile
- **THEN** TriOS SHALL show the current loadout as Modified without rewriting the profile

### Requirement: Revert to profile
TriOS SHALL provide an explicit Revert to profile action that reapplies the
tracked profile using ordinary profile-activation behavior.

#### Scenario: Exact members are available
- **WHEN** the user confirms Revert and every saved member is available
- **THEN** TriOS SHALL restore the saved enabled variants

#### Scenario: A saved member is unavailable
- **WHEN** ordinary profile activation cannot enable a saved member or variant
- **THEN** TriOS SHALL warn, apply what is available, leave the saved profile unchanged, and derive the resulting Modified state

#### Scenario: Tracked profile is selected in the picker
- **WHEN** the user selects the already tracked profile in the profile picker
- **THEN** TriOS SHALL do nothing rather than treating the selection as Revert

### Requirement: Stop using profile
TriOS SHALL clear profile tracking without changing the enabled loadout.

#### Scenario: Current loadout is unchanged
- **WHEN** the user stops using an unchanged tracked profile
- **THEN** TriOS SHALL clear tracking immediately

#### Scenario: Current loadout is Modified
- **WHEN** the user stops using a profile with a Modified loadout
- **THEN** TriOS SHALL offer Save and deactivate, Deactivate without saving, and Cancel

### Requirement: Single profile-switch confirmation
When switching away from a Modified loadout, TriOS SHALL show one confirmation
containing the target profile's changes and warnings together with Save and
switch, Activate without saving, and Cancel.

#### Scenario: User chooses Save and activate
- **WHEN** the user confirms Save and activate
- **THEN** TriOS SHALL save the old profile and then apply the target profile

#### Scenario: Saving fails
- **WHEN** saving the old profile fails during Save and activate
- **THEN** TriOS SHALL leave the old profile tracked and SHALL not apply the target profile

#### Scenario: User cancels
- **WHEN** the user cancels the combined confirmation
- **THEN** TriOS SHALL neither save the old profile nor apply the target profile

### Requirement: Profile action availability
TriOS SHALL show Modified as a current-loadout state in the profile picker and
tracked profile card. While Starsector is running, actions that only change
saved TriOS data SHALL remain available, while actions that change the enabled
loadout SHALL not.

#### Scenario: Game is running
- **WHEN** Starsector is running with a profile tracked
- **THEN** Save changes and Stop using profile SHALL remain available while Revert and profile switching are disabled

#### Scenario: Stored profile ID is missing
- **WHEN** the stored tracked-profile ID does not name a loaded profile
- **THEN** TriOS SHALL behave as though no profile is tracked without requiring a special cleanup operation

