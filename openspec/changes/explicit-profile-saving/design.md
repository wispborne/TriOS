# Design

Profiles remain exact lists of enabled installed variants. The change is only
when those lists are replaced: saving becomes explicit instead of automatic.

## Current behavior to remove

`ModProfileManagerNotifier.build()` listens to `AppState.enabledModVariants`.
Every change calls `updateFromModList()`, which replaces the active profile's
members and modification time.

Remove that listener and the automatic update path. Remove
`_pauseAutomaticProfileUpdates` and its set, clear, guard, and logging because
it exists only to suppress that path during activation. Keep automatic
persistence when an explicit profile operation updates state.

## Tracked profile

Continue storing `Settings.activeModProfileId` for compatibility. In the UI
and documentation, call this the tracked profile. It is the profile TriOS last
applied and is currently comparing with the enabled loadout.

Stop using profile clears `activeModProfileId`. It does not enable, disable, or
swap any mod. An invalid stored ID is treated as no tracked profile. No special
cleanup path is required.

No profile-file or settings migration is needed. On the first launch after the
change, the existing tracked profile normally matches the current loadout
because the old behavior kept them synchronized.

## Calculating Modified

Do not persist a dirty or modified flag. Derive it from the tracked profile and
`AppState.enabledModVariants` whenever either changes. Treat the state as
loading until both the first mod-folder scan and `enabled_mods.json` are ready.
Do not expose Save, Revert, Stop, or Switch while either input is still loading.

Compare members by mod ID and `smolVariantId`. List ordering, names, and saved
display versions do not affect the result. Modified is true when:

- A profile member is not enabled.
- An additional mod is enabled.
- The enabled variant for a member differs from the saved variant.

Use one provider or pure comparison helper as the source for the profile
picker, profile cards, dialogs, and future modpack actions.

Dependency validation may change the enabled loadout after activation. If the
result differs from the saved profile, show Modified rather than rewriting the
profile to hide the difference.

## Explicit actions

### Save changes

Replace the tracked profile's members with the current enabled variants,
sorted by name as existing profile writes do, and update `dateModified`. The
existing `saveCurrentModListToProfile()` method already performs most of this
work, but it should use its requested profile ID or have that misleading
parameter removed.

Disable Save changes when the loadout matches the profile.

### Revert to profile

Run the existing profile-change comparison and confirmation, then apply the
saved variants. This action must work when the target profile is already the
tracked profile. The current early return in `activateModProfile()` therefore
needs a reapply path instead of treating the matching ID as proof that no work
is needed.

Missing mods and variants use the same behavior as ordinary profile activation:
show the existing warning, apply what is available, and skip what cannot be
enabled. Update warning text that says missing members will be discarded from
the profile; explicit saving leaves the saved profile unchanged. If the result
is not exact, the current loadout remains Modified.

Selecting the already tracked profile in the Mod Manager picker is a no-op.
Revert to profile is the explicit way to reapply it. Remove the old Back up
Profile & Activate action because activation no longer rewrites the old
profile.

### Stop using profile

When the loadout matches, clear the tracked profile immediately.

When the loadout is Modified, show:

- Save and stop. Save the current loadout to the profile, then clear it.
- Stop without saving. Clear it and leave the profile unchanged.
- Cancel.

Every path leaves the enabled loadout unchanged.

## Switching profiles

When the tracked profile is unchanged, selecting another profile uses the
existing activation comparison and confirmation.

When the current loadout is Modified, show one confirmation that also contains
the target profile's activation changes, missing-mod warnings, and alternate-
version information:

- Save and switch. After the person confirms the whole operation, save the
  current loadout to the old profile and then apply the target profile.
- Switch without saving. Keep the old profile unchanged and apply the target.
- Cancel.

Do not save anything when the person cancels. If Save and switch cannot save
the old profile, do not apply the target profile. Do not create an automatic
backup or clone.

## UI

The Mod Manager profile picker shows the tracked profile name and appends
Modified when the current loadout differs. It also exposes Stop using profile.

The tracked profile card keeps its existing accent border. Replace the current
disabled Enabled button with actions appropriate to its state:

- Modified: Save changes, Revert to profile, and Stop using profile.
- Unchanged: Stop using profile.

Untracked profile cards retain Enable. Selecting one passes through the switch
rules above.

Keep deletion of the tracked profile disabled. A person can stop using it and
then delete it.

While Starsector is running, allow Save changes and Stop using profile because
they do not change the enabled loadout. Disable Revert, profile switching, and
modpack member enabling until the game closes.

## Modpack interaction

The related modpack feature does not enable members by default. Its installation
option and separate Enable installed members action change the enabled loadout
through the normal mod manager. If a profile is tracked, the current loadout
becomes Modified. No modpack code writes profile membership.

## Likely code areas

- `lib/mod_profiles/mod_profiles_manager.dart`: remove automatic rewriting and
  its pause machinery, add loading-aware comparison and explicit tracking
  actions, return results from save and switch coordination, and allow
  explicitly reapplying the tracked profile.
- `lib/mod_profiles/mod_profile_card.dart`: show Modified and explicit actions.
- `lib/mod_manager/mods_grid_page.dart`: update the profile picker and switch
  flow.
- `lib/trios/settings/settings.dart`: keep `activeModProfileId`; no generated
  model change is required unless the field is renamed later.
- `test/mod_profiles_test.dart`: cover comparison and explicit actions.
