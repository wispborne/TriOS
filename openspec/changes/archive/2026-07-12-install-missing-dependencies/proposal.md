# Install missing mod dependencies from the catalog

## Problem

When a mod needs another mod that you don't have, you get stuck. The Mods
Page already shows a row of helper buttons under a mod with unmet requirements,
but today they only do two things:

- If the required mod is installed but turned off, show an "Enable" button.
- If the required mod is missing, show a "Search" button that just opens a
  Google search in your browser.

Two problems make this worse than it should be:

1. **The buttons never show for turned-off mods.** The helper row only renders
   for mods that are already on. But a mod with missing requirements can't be
   turned on at all — its Enable button is greyed out. So the one mod that most
   needs help is the one where no help appears. You're left with no way forward
   inside the app.

2. **"Search" is a dead end.** TriOS already has a catalog of downloadable mods.
   When the missing mod is in that catalog, we can install it with one click
   instead of sending you off to a web search.

## Solution

Show the helper buttons for **both on and off mods**, and add an **Install**
button that downloads the missing mod straight from the catalog when it's
available there.

Which button shows depends on the state of the required mod and whether the
parent mod is on:

| Parent mod | Required mod missing / wrong version | Required mod present but off |
|------------|--------------------------------------|------------------------------|
| On         | **Install**                          | **Enable**                   |
| Off        | **Install**                          | (nothing)                    |

- **Install** shows whenever a requirement is missing — for on *and* off mods.
  This is the case that blocks turning a mod on, so it matters most for off mods.
- **Enable** shows only for mods that are already on. Under an off mod, an
  "Enable LazyLib" button would be noise — turning on one requirement does
  nothing until you turn on the mod itself. The Enable button appears the moment
  you turn the parent mod on.
- When a required mod is **installed but older** than the mod needs, show an
  **Update** button (downloads the latest from the catalog) instead of treating
  it as missing. Today this case wrongly shows "Search," as if you don't have the
  mod at all.
- When the missing mod is **not** in the catalog (or has no direct download
  link), fall back to today's "Search" behavior.

## Scope

- Surface the existing helper-button row for turned-off mods, not just on ones.
- Add an "Install" button that downloads a missing requirement from the catalog
  when a direct download link exists for it.
- Keep "Enable" (present-but-off requirement) limited to mods that are on.
- Keep "Search" as the fallback when the catalog can't help.

## Non-goals

- Auto-turning-on a mod's requirements when you turn the mod on. (Today, turning
  on a mod whose requirement is present-but-off leaves a brief broken state until
  you click Enable. That stays as-is.)
- Matching an exact required version. The catalog only knows the newest version,
  so Install offers the newest — which is usually right but isn't guaranteed to
  match an older pinned requirement.
- Installing requirements in bulk, or chasing requirements-of-requirements
  automatically.
