# QA plan — TriOS 1.7.0

Covers everything that changed between 1.6.1 (last stable) and 1.7.0-preview07:
221 files, about 28,000 lines added. Written from `changelog.md` plus the actual
diff, so it includes a few risky changes the changelog doesn't mention.

The plan has two halves: checks a machine runs, and checks a person runs.

---

## 1. Automated checks

### The gate: tests

```bash
fvm flutter test
```

Takes about 40 seconds and runs 687 tests. All pass. Before this plan it was
622; the 65 new ones are listed below. **A failure here blocks the release.**

### Analysis: compare, don't expect clean

```bash
fvm flutter analyze
```

This exits with a failure code today, and did before this plan too. It reports
467 issues: 0 errors, 142 warnings, 325 info. They are all pre-existing — mostly
unused imports, dead code, and `avoid_print` in `tool/`.

So the check isn't "is it clean", it's "did we add any". Compare the count
against the previous build, or run it on just the files you changed:

```bash
fvm flutter analyze lib/path/to/changed_file.dart
```

The five test files this plan adds report no issues.

### custom_lint doesn't run

`CLAUDE.md` lists `dart run custom_lint`, and `analysis_options.yaml` enables it
as a plugin, but `custom_lint` isn't in `pubspec.yaml`, so the command fails
with "Could not find package `custom_lint`". Either add the dev dependency or
drop it from the docs — right now it's a check nobody can run.

### What was already covered

These 1.7.0 changes already had tests before this plan, so they need no manual
checking beyond a quick look:

| Change | Test file |
| --- | --- |
| Catalog game versions missing a leading "0." | `test/catalog/mod_repo_entry_game_version_test.dart` |
| Forum entries with a comma-separated requires list | `test/forum_llm_data_test.dart` |
| Forum entries with no summary paragraph | `test/forum_llm_data_test.dart` |
| A ship listing the same built-in hullmod twice | `test/ship_viewer/ships_merge_test.dart` |
| Mods changing ship and weapon stats | `test/ship_viewer/ships_merge_test.dart`, `test/weapon_viewer/weapons_merge_test.dart`, `test/utils/game_data_merge_test.dart` |
| Faction Viewer "Only Enabled Mods" | `test/faction_viewer/merged_faction_list_test.dart` |
| Fleet spawn weights | `test/spawn_weight_calculator_test.dart` |
| Range filters and any/all chip matching | `test/widgets/advanced_filter_groups_test.dart` |
| Muting updates for one version | `test/mod_metadata_test.dart` |
| Large Google Drive downloads | `test/download_manager/google_drive_confirmation_test.dart` |
| Deep links finding installed mods | `test/deep_link_trilink_test.dart`, `test/deep_link_min_dependency_version_test.dart` |
| Zipped config backups | `test/backup_compression_test.dart` |

### What this plan added

Five gaps in new 1.7.0 code that had no tests at all.

| File | Tests | Why it matters |
| --- | --- | --- |
| `test/download_manager/download_target_test.dart` | 21 | The shared download button is new and is now used by every Install and Update button in the app. This is the logic that decides which running download a button belongs to. A mistake here means a button spins forever, or two unrelated mods share one progress bar. |
| `test/ship_viewer/ship_module_resolver_test.dart` | 17 | Works out which ships are modules and which ships dock them. Feeds the new "Show Ships That Are Modules" filter and the blueprint's module drawing. Had no tests. |
| `test/mod_manager/mods_grid_dependency_search_test.dart` | 14 | Mod search now searches dependencies, both by typing a name and with `dependency:`. |
| `test/widgets/filter_upgrade_path_test.dart` | 9 | The Ship Viewer's "Hide Modules" filter was removed and replaced. Anyone upgrading has a saved filter that no longer exists. These check it's ignored quietly instead of crashing or turning the wrong thing on. |
| `test/trios/ai_features_switch_test.dart` | 4 | The AI killswitch. When it's off no AI text may appear anywhere, and turning it off must not wipe the user's saved catalog setting. |

### What can't be automated, and why

Be aware of these when reading a green test run — it does not mean these work.

- **Ship modules written as a JSON object instead of a list.** Fixed in 1.7.0,
  but the code that reads it sits inside the file scanner and can't be called
  from a test. Needs the manual check in section 3. Pulling those 14 lines out
  into their own function would make it testable — worth doing, but it changes
  shipping code, so it isn't done here.
- **Anything drawn on screen**: animated engines and shields, ship backgrounds,
  sprite layers, background effects. No automated check for "does it look
  right".
- **Real downloads and installs.** Tests cover the decisions, not the network or
  the archive unpacking.
- **Deep links from a browser**, which involve the OS registering a URL handler.
- **Anything platform-native**: file pickers, Recycle Bin, 7-Zip, window setup.

---

## 2. Before you start

1. Test on a copy of your TriOS config, not your only one. Zip
   `%LOCALAPPDATA%/TriOS` (or the equivalent) first.
2. Keep a 1.6.1 config around — section 6 needs one.
3. Have a modlist with at least: a mod with modules or a station, two mods that
   change the same ship, a mod with dependencies, and one disabled mod.

---

## 3. Upgrade from 1.6.1 — do this first

This is the highest-risk area and the one real users hit first. Several caches
changed shape in 1.7.0, so the first launch after upgrading does more work than
normal.

- [ ] Launch 1.7.0 over a 1.6.1 config. It starts, no crash, no error dialog.
- [ ] First launch rescans: ships, weapons, hullmods, and factions all repopulate.
      Their cache formats changed (ships 1→4, factions 2→6, hullmods 1→2,
      weapons 1→3) so the old caches are thrown away on purpose.
- [ ] Wings, ship systems, and the graphics-path index are new caches. They
      build on first launch without an error.
- [ ] Second launch is noticeably faster than the first.
- [ ] Saved ship filters from 1.6.1 load. The old "Hide Modules" tick is gone
      and nothing else moved. (Automated, but confirm on a real config.)
- [ ] Saved mod grid layout, column order, and column widths survive.
- [ ] Mod profiles, tags, and categories survive.
- [ ] Toolbar tab order survives.
- [ ] Config backups are now `.7z`. Check one was made and that 7-Zip opens it.

---

## 4. Downloads and installs — the shared button

New in 1.7.0 and used everywhere, so it's worth its own pass.

- [ ] Install a mod from the Catalog. The button shows "Starting…", then
      progress, then "Installing…", then settles as installed.
- [ ] While that install runs, open the Mods page. The same mod's button there
      shows the same state — not idle, not a different number.
- [ ] Do the same with the mod's details dialog open. Three places, one state.
- [ ] Update a mod from the version-check icon. Same progression.
- [ ] Start two different mods downloading at once. Each button tracks its own
      one; they don't swap or merge.
- [ ] Install a mod whose folder name differs from its catalog name (e.g.
      "Ashpad" installs as "Aashpad"). It still shows as Installed afterwards.
- [ ] Cancel a download. The button goes back to idle rather than spinning.
- [ ] Click Install and then dismiss the confirmation dialog. The button stops
      spinning (it gives up after 10 seconds at the latest).
- [ ] Install a mod with a TriOS deep link from a forum page. Button state
      follows the whole way through.
- [ ] The Activity panel pops up when a download or install *starts* while the
      panel is closed, not only when one finishes.
- [ ] A download that fails shows an error rather than spinning forever.

---

## 5. Catalog

- [ ] Hovering a mod card shows the summary: image, description, latest
      changelog, support links, save compatibility.
- [ ] A mod pop-up shows that same summary at the top.
- [ ] Turning the summary off in the Catalog menu removes it from pop-ups.
- [ ] Forum activity ("active X ago") shows and looks sane.
- [ ] Game version badges all start with "0." — no bucket in the Game Version
      filter is missing it.
- [ ] Mods whose forum post lists requirements as one comma-separated line still
      appear, with their downloads and changelog.
- [ ] A mod with several download links shows the picker.
- [ ] Mod images fall back sensibly when a mod has none.
- [ ] The "Has Update" count badge matches the number of mods actually updatable.

### AI text

- [ ] With AI features on, catalog AI summaries appear per the chosen setting
      (Always / Only if missing / Never).
- [ ] Turn the master AI switch off in Settings. No AI-written text appears
      anywhere in the app.
- [ ] Turn it back on. The catalog goes back to the level you had chosen, not to
      a default.
- [ ] The About page has its AI disclosure section.

---

## 6. Mods page

- [ ] The "Last Updated" column shows and sorts correctly.
- [ ] Searching a dependency's name finds the mods that need it.
- [ ] `dependency:lazylib` finds the same mods.
- [ ] A mod with missing dependencies shows install and find buttons, and they
      work.
- [ ] Mute updates for a single version. That version stops nagging; a newer
      version still shows as an update.
- [ ] Mute all updates for a mod. Nothing from that mod nags.

---

## 7. Ship Viewer

- [ ] Engines animate.
- [ ] Shields animate.
- [ ] A ship is drawn over an in-game background, and the background can be
      changed.
- [ ] Blueprint view options (what's drawn, which background) survive an app
      restart.
- [ ] Large ships and stations open centred and zoomed to fit.
- [ ] The Low Tech station is centred.
- [ ] Station modules show straight away, not after a delay.
- [ ] Hovering a module shows its tooltip.
- [ ] **Modules written as a JSON object.** Find a mod whose `.variant` file
      writes `"modules": {"WS0001": "x_variant"}` rather than a list of
      single-entry objects, and confirm those modules appear. This is the one
      1.7.0 fix with no automated cover.
- [ ] "Show Ships That Are Modules" unticked hides module hulls; ticked shows
      them. Clearing all filters brings them back.
- [ ] Tech and Manufacturer grouping treats "Low Tech" and "low tech" as one
      group.
- [ ] Range filters (e.g. 12–60 DP) narrow the list correctly, and the slider
      ends cover the whole ship list rather than what's currently filtered.
- [ ] The Advanced checkbox switches chips between any and all matching.
- [ ] Shift-clicking a chip solos it.
- [ ] The filter search box finds filters by name.
- [ ] Searching by built-in hullmod works.
- [ ] A ship's details dialog lists which mods changed it.
- [ ] Two mods changing the same ship: the stats shown are the winning mod's,
      and the built-in hullmod list has no duplicates.

---

## 8. Weapons Viewer

- [ ] Range filters and any/all chip matching, as above.
- [ ] The filter search box works.
- [ ] Scrolling fast doesn't leave a previous weapon's sprite in a row.
- [ ] A weapon's details dialog lists which mods changed it.
- [ ] Weapon icons appear for weapons whose CSV row and `.wpn` file come from
      different mods.

---

## 9. Faction Viewer

- [ ] Fleet weights show and add up sensibly.
- [ ] Each faction shows which mod added it, separately from mods that only
      change it.
- [ ] "Only Enabled Mods" actually removes disabled mods' data — ship lists,
      doctrine, and fleet weights all change, and a faction only a disabled mod
      registered disappears.
- [ ] Doctrine pips are ordered the way the game orders them.

---

## 10. Settings and theme

- [ ] The new background effects all run, and can be switched off.
- [ ] Tooltips appear after a short delay, and mousing quickly across a grid
      doesn't stutter.
- [ ] The new app logo shows.

---

## 11. Smoke test — things a big release can break

Not new in 1.7.0, but cheap to check and expensive to ship broken.

- [ ] The game launches from TriOS.
- [ ] Enabling and disabling mods works and sticks.
- [ ] Installing a mod from a zip on disk works.
- [ ] Drag and drop install works.
- [ ] The VRAM estimator finishes and gives a sane number.
- [ ] Log viewer opens a log.
- [ ] vmparams RAM editing works.
- [ ] Mod profiles save and load.

---

## 12. Platforms

The automated tests only prove the logic; they say nothing about the three
runners. Run sections 3, 4, and 11 on each:

- [ ] Windows
- [ ] macOS — especially startup, given the 1.6.x drag-and-drop startup crash
- [ ] Linux

---

## 13. Sign-off

A build is ready when:

- `fvm flutter test` passes.
- `fvm flutter analyze` reports no new issues compared to the last build, and
  still no errors.
- Sections 3 and 4 pass on Windows, macOS, and Linux.
- Every remaining section passes on at least one platform.
- Any failure is either fixed or written into the changelog as a known issue.
