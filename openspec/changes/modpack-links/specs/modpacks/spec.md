## ADDED Requirements

### Requirement: Shared modpack definition
TriOS SHALL represent a shared modpack as a stable UUID, positive integer
version, non-empty name, ordered unique mod members, and optional shared
metadata. Shared metadata SHALL include author, description, homepage, update
address, and a display-only Starsector-version label. Each member SHALL include
a mod ID, HTTP or HTTPS source, and explicit source type, and MAY include a
plain-text creator note of at most 2,000 characters.

#### Scenario: Starsector-version label is present
- **WHEN** a definition contains a Starsector-version label
- **THEN** TriOS SHALL display it in the library, preview, and installation review without using it to accept, reject, select, or install any member

#### Scenario: New pack is created
- **WHEN** TriOS knows the current Starsector installation's version
- **THEN** TriOS SHALL prefill the new pack's editable Starsector-version label with that value

#### Scenario: Member note is present
- **WHEN** a definition contains a member note
- **THEN** TriOS SHALL preserve and display the note in editing, preview, installation review, and library details

#### Scenario: Newer optional field is read
- **WHEN** TriOS reads a definition containing an unknown optional field
- **THEN** TriOS SHALL preserve that field through comparison, editing, link generation, and file export

### Requirement: Modpack identity and versioning
TriOS SHALL allocate a UUID when a new pack first enters the editor. New packs
and copies SHALL start at version 1. Saving changed shared content SHALL
increment the version once. Editing a draft or saving unchanged content SHALL
not increment it.

#### Scenario: Reordered members are saved
- **WHEN** the user changes member order and saves the pack
- **THEN** TriOS SHALL increment the pack version once

#### Scenario: Only draft state changes
- **WHEN** the user edits a draft without committing it to the library
- **THEN** TriOS SHALL leave the committed pack version unchanged

#### Scenario: Existing pack is copied
- **WHEN** the user chooses Add as a copy or Save as a new modpack
- **THEN** TriOS SHALL assign a new UUID and set the copy's version to 1

### Requirement: Independent persisted drafts
TriOS SHALL persist one draft per pack ID and SHALL allow more than one
unfinished new pack to exist.

#### Scenario: User switches between editors
- **WHEN** the user edits pack A, opens pack B, and later returns to pack A
- **THEN** TriOS SHALL restore pack A's draft without replacing pack B's draft

#### Scenario: Incoming definition matches a changed draft
- **WHEN** an incoming definition has the same ID as a different local draft
- **THEN** TriOS SHALL offer Discard draft and replace, Add incoming as a copy, and Cancel

### Requirement: Shareable source validation
TriOS SHALL validate every member source before Copy share link, Export, or
Publish update completes. A Version Checker source SHALL parse and resolve to a
usable download. A direct-download source SHALL begin returning a downloadable
file without requiring the complete archive to be downloaded. Local draft
saving SHALL remain available when validation fails. Within the current app
session, TriOS SHALL reuse a successful validation for 60 minutes while its
exact URL and source type remain unchanged.

#### Scenario: Every member validates
- **WHEN** all member sources validate
- **THEN** TriOS SHALL allow the requested sharing action

#### Scenario: One member fails validation
- **WHEN** any member source fails validation
- **THEN** TriOS SHALL identify the failed member and block the sharing action

#### Scenario: Recently validated source is unchanged
- **WHEN** a member's URL and source type passed validation within the last 60 minutes
- **THEN** TriOS SHALL reuse that result instead of issuing another network request

#### Scenario: Validated source changes
- **WHEN** a member's URL or source type changes after successful validation
- **THEN** TriOS SHALL discard the saved result and validate the changed source before sharing

#### Scenario: Update address is not hosted yet
- **WHEN** every member source validates but the configured update address does not resolve
- **THEN** TriOS SHALL allow sharing and export so the creator can upload the first definition there

### Requirement: Link and file transport
TriOS SHALL share the complete definition as versioned zlib-compressed JSON in
the registered-scheme payload. It SHALL read `.trios-modpack` files as JSON or
Hjson and SHALL write pretty-printed JSON using a filename slugged from the pack
name.

#### Scenario: Link is too large
- **WHEN** an outgoing or incoming link exceeds 30,000 characters
- **THEN** TriOS SHALL reject it with a size error that does not blame only the member count and, for outgoing links, suggests shortening descriptions or notes, removing members, or exporting a `.trios-modpack` file

#### Scenario: Expanded payload is too large
- **WHEN** payload decoding would exceed 4 MiB or 5,000 members
- **THEN** TriOS SHALL stop decoding and reject the payload

#### Scenario: File is opened while installation is unavailable
- **WHEN** a `.trios-modpack` file is dropped or opened while the game is running or the mods folder is not writable
- **THEN** TriOS SHALL still allow preview and Add to library while keeping installation actions unavailable

### Requirement: Incoming preview and update check
TriOS SHALL show an incoming embedded definition without saving or installing
it and SHALL immediately begin checking its update address. A failed check
SHALL leave the embedded definition available.

#### Scenario: Update check is running
- **WHEN** the embedded preview is visible and its update check has not finished
- **THEN** TriOS SHALL show that it is checking for updates without blocking the preview

#### Scenario: Higher online version is found
- **WHEN** the update address returns the same pack ID with a higher version
- **THEN** TriOS SHALL update the preview and identify both version numbers

#### Scenario: Same version has different contents
- **WHEN** the update address returns the same ID and version with different contents
- **THEN** TriOS SHALL show a comparison and offer Replace existing, Add as a copy, and Cancel

#### Scenario: Update address changes
- **WHEN** an online update changes its own update address
- **THEN** TriOS SHALL call out the address change and require explicit confirmation before accepting the complete update

### Requirement: Modpacks library
TriOS SHALL save accepted packs in a Modpacks library and calculate installed,
missing, source-problem, failure, and update state from the saved definition and
current app state. It SHALL not persist a pack-level installed or created flag.

#### Scenario: Library entry is deleted
- **WHEN** the user confirms deletion of a library entry
- **THEN** TriOS SHALL remove that pack and its draft without disabling or uninstalling mods

#### Scenario: Identical definition arrives
- **WHEN** an incoming definition exactly matches a saved definition with the same ID
- **THEN** TriOS SHALL reuse the existing library entry

### Requirement: Selective installation and enabling
TriOS SHALL always show installation confirmation for a modpack. Missing,
installable members SHALL be selected by default. The dialog SHALL include an
unchecked Enable installed members after installation option. A separate
confirmed Enable installed members library action SHALL remain available.

#### Scenario: Installation option is not selected
- **WHEN** installation completes without the enable option selected
- **THEN** TriOS SHALL not enable members automatically

#### Scenario: Installation option is selected
- **WHEN** installation completes with the enable option selected
- **THEN** TriOS SHALL use normal mod-manager behavior to enable every pack member that is then installed

#### Scenario: One selected download fails
- **WHEN** some selected members install and another fails
- **THEN** TriOS SHALL keep successful installations and, if requested, enable the pack members that are installed

### Requirement: Profile-safe modpack enabling
Modpack enabling SHALL be exposed only after profiles use explicit saving.
Modpack code SHALL never write profile membership.

#### Scenario: A profile is tracked
- **WHEN** a modpack action changes the enabled loadout
- **THEN** the current loadout SHALL become Modified and the tracked profile SHALL remain unchanged
