## Requirements

### Requirement: Debug mode setting exists
The `Settings` class SHALL include a `debugMode` field of type `bool` with a default value of `false`. The field SHALL be persisted to the settings JSON file.

#### Scenario: Fresh install has debug mode off
- **WHEN** the app launches with no prior settings
- **THEN** `debugMode` SHALL be `false`

#### Scenario: Setting persists across restarts
- **WHEN** the user enables debug mode and restarts the app
- **THEN** `debugMode` SHALL be `true` after restart

### Requirement: Debug mode toggle in Settings UI
The Settings page SHALL include a toggle control for enabling/disabling debug mode. The toggle SHALL be labeled "Debug mode" with a description indicating it shows internal diagnostics in the toolbar.

#### Scenario: User enables debug mode
- **WHEN** the user toggles debug mode on in Settings
- **THEN** the `debugMode` setting SHALL be set to `true` and persisted

#### Scenario: User disables debug mode
- **WHEN** the user toggles debug mode off in Settings
- **THEN** the `debugMode` setting SHALL be set to `false` and persisted
