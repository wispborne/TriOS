# Stop profiles from changing automatically

Status: ready-for-agent

## The problem

TriOS currently rewrites the tracked mod profile whenever the enabled loadout
changes. A saved profile therefore changes when someone experiments with one
mod, enables newly installed content, or uses a future modpack action.

This makes profiles unreliable as named loadouts. It also means a person can
lose the saved configuration without choosing to replace it.

## The solution

Keep profiles as explicit snapshots. When the enabled loadout differs from the
tracked profile, show Modified without changing the profile. Let the person
save the current loadout to the profile, revert the loadout to the profile, or
stop using the profile while leaving the current loadout unchanged.

Wait until the mod folder and enabled-mod file have loaded before comparing.
Warn in one combined confirmation before switching or stopping when unsaved
loadout changes exist.

## In scope

- Remove automatic profile rewriting when enabled mods or active variants
  change.
- Calculate whether the current loadout differs from the tracked profile.
- Show Modified in the Mod Manager profile picker and Profiles page.
- Add Save changes, Revert to profile, and Stop using profile.
- Add save/discard/cancel dialogs when switching or stopping with changes.
- Keep profile status and actions in a loading state until the inputs needed for
  comparison are ready.
- Preserve the current profile ID and existing profile files without a data
  migration.

## Related change

`modpack-links` depends on this behavior before it can safely offer Enable
installed members without silently changing a profile.

## Out of scope

- Changing profile membership or exact-variant semantics.
- Creating a profile from a modpack.
- Installing missing profile members.
- Replacing the Profiles page or the legacy shared-profile format.
