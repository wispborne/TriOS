## ADDED Requirements

### Requirement: Shared custom nav order across layouts

The system SHALL maintain a single user-customizable ordering of the 11 main navigation icons (`dashboard`, `modManager`, `modProfiles`, `catalog`, `chipper`, `vramEstimator`, `ships`, `weapons`, `hullmods`, `portraits`, `tips`) plus one section-divider sentinel. This ordering SHALL be applied identically to both the sidebar layout and the top-bar layout.

#### Scenario: Reorder in sidebar reflects in top-bar
- **WHEN** the user rearranges icons in the sidebar and then switches to the top-bar layout
- **THEN** the top-bar renders the icons in the same order the user set in the sidebar

#### Scenario: Reorder in top-bar reflects in sidebar
- **WHEN** the user rearranges icons in the top-bar and then switches to the sidebar layout
- **THEN** the sidebar renders the icons in the same order the user set in the top-bar

#### Scenario: Order persists across restarts
- **WHEN** the user sets a custom order and restarts the app
- **THEN** the previously-saved order is restored on next launch

### Requirement: Default order matches existing layout

The system SHALL use a default ordering of `dashboard, modManager, modProfiles, catalog, chipper, <divider>, ships, weapons, hullmods, portraits, vramEstimator, tips` when no custom order has been saved.

#### Scenario: Fresh install
- **WHEN** a user launches the app for the first time (no stored order)
- **THEN** the sidebar and top-bar render icons in the default order

#### Scenario: Existing user upgrade
- **WHEN** an existing user upgrades to a build that includes this feature and has no `navIconOrder` in their settings
- **THEN** the app shows the default order without writing the field to settings until the user customizes it

### Requirement: Non-reorderable items stay pinned

The system SHALL NOT allow reordering of: sidebar collapse toggle, launcher button, April-Fools chatbot button, `rules.csv` hot-reload button, layout toggle, `Settings` nav item, `DebugToolbarButton`, `GameFolderButton`, `LogFileButton`, `BugReportButton`, `ChangelogButton`, `AboutButton`, `DonateButton`, `FilePermissionShield`, `AdminPermissionShield`, or the rainbow accent bar.

#### Scenario: Drag attempt on pinned item
- **WHEN** drag mode is active and the user attempts to drag the Settings icon or any action button
- **THEN** the item does not move and no drag ghost is shown

#### Scenario: Pinned items render in fixed positions after reorder
- **WHEN** the user customizes the 11 reorderable icons
- **THEN** `Settings`, `rules.csv`, layout toggle, launcher, and action buttons remain in their existing fixed positions in both layouts

### Requirement: Drag mode toggle via right-click menu

The system SHALL expose a right-click context menu on the sidebar and top-bar backgrounds with at least two entries: "Rearrange icons" (toggles drag mode) and "Reset to default order" (restores the default order).

#### Scenario: Open context menu on sidebar
- **WHEN** the user right-clicks on the sidebar background (not on a pinned action button)
- **THEN** a context menu appears with "Rearrange icons" and "Reset to default order" entries

#### Scenario: Open context menu on top-bar
- **WHEN** the user right-clicks on the top-bar background (not on a pinned action button)
- **THEN** the same context menu appears

#### Scenario: Enter drag mode
- **WHEN** drag mode is off and the user selects "Rearrange icons" from the context menu
- **THEN** drag mode becomes active, reorderable icons show drag affordances, and a "Done" exit control appears

#### Scenario: Exit drag mode via menu
- **WHEN** drag mode is on and the user opens the context menu
- **THEN** the first entry reads "Exit rearrange mode" and selecting it deactivates drag mode

#### Scenario: Exit drag mode via Done button
- **WHEN** drag mode is on and the user clicks the "Done" control
- **THEN** drag mode deactivates

#### Scenario: Exit drag mode via Escape
- **WHEN** drag mode is on and the user presses the `Esc` key with the app focused
- **THEN** drag mode deactivates

### Requirement: Clicks do not navigate while drag mode is active

The system SHALL suppress navigation for reorderable icons while drag mode is active so that a misclick does not switch tabs.

#### Scenario: Click reorderable icon in drag mode
- **WHEN** drag mode is on and the user left-clicks one of the 11 reorderable icons
- **THEN** the current page does not change and the icon is treated as a drag target

#### Scenario: Click pinned icon in drag mode
- **WHEN** drag mode is on and the user left-clicks `Settings`
- **THEN** the app still navigates to the Settings page (pinned icons remain fully interactive)

### Requirement: Divider is a reorderable entry

The system SHALL represent the section divider as an entry in the order list that the user can drag to any position, including to the start or end of the list (resulting in an empty section above or below).

#### Scenario: Move divider
- **WHEN** drag mode is on and the user drags the divider past one or more icons
- **THEN** the divider's new position is persisted and both layouts render the divider at that position

#### Scenario: Empty section allowed
- **WHEN** the user drags the divider to the very start of the list
- **THEN** the "above the divider" section renders empty and the divider renders as a thin line at the top of the nav area

#### Scenario: Icons flow across divider
- **WHEN** drag mode is on and the user drags a core icon below the divider (or a viewer icon above it)
- **THEN** the move is accepted and the icon renders in its new section

### Requirement: Reset to default order

The system SHALL provide a "Reset to default order" menu action that restores the default ordering.

#### Scenario: Reset with customized order
- **WHEN** the user has a non-default order and selects "Reset to default order"
- **THEN** a confirmation dialog appears; on confirm, the order returns to the default and the stored `navIconOrder` is cleared

#### Scenario: Reset with default order
- **WHEN** the user has the default order and selects "Reset to default order"
- **THEN** the action is a no-op (no confirmation dialog is required) and the layout is unchanged

### Requirement: Robust reconciliation on load

The system SHALL reconcile a stored order against the current `TriOSTools` enum on every load so that added, removed, or renamed tools do not corrupt the user's layout.

#### Scenario: New tool added in a later release
- **WHEN** the app loads a stored order that is missing a tool present in the current `TriOSTools` enum
- **THEN** the missing tool is appended after the divider (or at the end if no divider exists) and the reconciliation is logged

#### Scenario: Stored order contains an unknown tool
- **WHEN** the app loads a stored order that references an enum value no longer present
- **THEN** that entry is dropped silently and the remaining order is kept intact

#### Scenario: Duplicate tool in stored order
- **WHEN** the stored order contains the same tool twice
- **THEN** only the first occurrence is kept and subsequent duplicates are dropped

### Requirement: Tooltips on all new icons

The system SHALL provide tooltips on every new icon or control introduced by this feature (drag-mode "Done" button, any new drag handle, menu entries) to comply with project UI conventions.

#### Scenario: Hover over Done control
- **WHEN** drag mode is active and the user hovers the "Done" control
- **THEN** a tooltip explaining that it exits rearrange mode is shown
