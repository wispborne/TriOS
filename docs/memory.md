# Where TriOS's memory goes

Written while cutting memory use with
[flutter_ram](https://github.com/wispborne/flutter_ram). Everything here was
measured, not guessed. Numbers come from a Windows profile build on a mod
folder with **460 mods, 15,603 `.wpn` files and 10,862 `.ship` files** — an
extreme mod list, not a typical one.

## The tree moved under this work

On 18 August a merge from `origin/main` brought five commits, including an
upgrade from Flutter 3.44.2 to 3.47.0, and took a lot of uncommitted work with
it. **Every number in this document taken before that is against a different
Flutter and a different commit, so none of it compares to anything measured
now.** The baseline to compare against is `flutter347-base`.

It also left the tree not compiling: four helper files were deleted while the
code calling them stayed. `interned_strings.dart`, `packed_bytes.dart` and
`packed_numbers.dart` were put back; `shared_collections.dart` was not, because
nothing imports it any more — the change that used it went too.

Two things to know about building since the upgrade:

- `flutter build windows` used to need `--no-tree-shake-icons`. It no longer
  does. The category icon picker offers all 2,146 Material icons, and it used to
  build each `IconData` from a stored code point at run time, so the build could
  not work out which glyphs to keep and failed with "Avoid non-constant
  invocations of IconData". The generated list in
  `lib/mod_tag_manager/material_icons_all.dart` now holds `const IconData`
  values instead of plain numbers, and a saved icon is looked up in that list by
  code point. Turning the flag off shrank the bundled assets from 51 MB to
  17 MB: the three Material Symbols fonts drop from 34.5 MB to 12 KB (the app
  uses two of those icons, both on the debug-only Codex page), and
  MaterialIcons-Regular drops from 1.6 MB to 277 KB while still keeping all
  2,146 picker glyphs.
- `ModeSwitcher.iconsOnly` was reconstructed to make the tree compile. It drops
  the text label and shows the mode name as a tooltip. Nobody has checked that
  against what it originally did.

## How to measure it again

TriOS can walk through every tab on its own, so a memory tool can measure the
state you reach by clicking around:

```
flutter_ram --project . --label whatever \
  --wait-at-least 75 --settle-timeout 300 \
  --flutter-arg --dart-define=trios.openEveryTabAtStartup=true
```

`_visitEveryTab` in `app_shell.dart` does the walking. It waits three seconds
on each tab, which is how long the slowest of them needs to finish building.
**Do not shorten that wait to make measuring quicker.** Halving it made the
same build report 14 MB less, because pages had not finished when the sample
was taken.

`--wait-at-least` matters too. RSS holds still while the walk pauses between
tabs, so without a minimum wait the tool decides the app has settled after the
second tab.

Add `--dart-define=trios.tabWalkRounds=5` to go round the tabs five times
instead of once. Each round writes a line to `memory-report.txt` in the settings
folder, so you can see whether moving between tabs keeps costing memory.

## Moving between tabs does not leak

Five rounds through all fifteen tabs, watched for five and a half minutes:

```
  20s  405.0 MB      140s  594.7 MB      260s  600.2 MB
  40s  555.6 MB      160s  595.7 MB      280s  591.5 MB
  60s  586.4 MB      180s  598.9 MB      300s  597.1 MB
  80s  593.9 MB      200s  590.8 MB      320s  590.7 MB
 100s  592.1 MB      220s  599.7 MB      340s  594.6 MB
 120s  592.4 MB      240s  596.8 MB
```

Everything is built by about eighty seconds, and after that it sits between 590
and 600 MB with no trend. The image cache held steady at 101 or 102 pictures the
whole time. So what TriOS holds is the data itself, not something that piles up
— which is why every change on this page is about making the data smaller
rather than about disposing things.

One number worth knowing: the highest memory TriOS reached during that run was
**721 MB**, while the mod data was still loading, before settling back to about
600 MB.

## The biggest number is a setting, not a bug

TriOS merges one variant per mod — `findFirstEnabledOrHighestVersion`, so the
enabled version, or the highest one if none is enabled. It does not load every
version of everything.

But with **"only enabled mods" off, which is the default**, it merges every mod
you have *installed*, not every mod the game would load. This machine has 460
mods installed and 13 enabled. Measured on a release build with every tab open:

| | TriOS | graphics | altogether |
| --- | --- | --- | --- |
| Only enabled mods off (the default) | 549.6 MB | 100.7 MB | 650.3 MB |
| Only enabled mods on | **410.3 MB** | 64.8 MB | 475.1 MB |

**139 MB is merged data from the 447 mods that are installed but switched off.**
Nothing in this document comes close to that, and it costs nothing to turn on.

It is not a free win, of course — with it on, the viewers only show what the
game would load, which is the point of the setting. It is a choice, not a fix.
But anyone worried about TriOS's memory should be told about it first.

## What each page costs

Cumulative RSS as the walk opens each tab, release build, all 460 mods merged.
`_visitEveryTab` writes this to `memory-report.txt` on every run.

| Tab | RSS after | cost |
| --- | --- | --- |
| before any tab | 229.5 MB | — |
| dashboard | 257.8 MB | +28.3 |
| modManager | 262.0 MB | +4.2 |
| modProfiles | 276.4 MB | +14.4 |
| vramEstimator | 280.9 MB | +4.6 |
| chipper | 294.5 MB | +13.6 |
| portraits | 292.9 MB | — |
| **ships** | 363.7 MB | **+70.8** |
| **weapons** | 415.9 MB | **+52.2** |
| hullmods | 408.9 MB | — |
| **factions** | 544.9 MB | **+136.0** |
| settings | 503.8 MB | — |
| catalog | 524.3 MB | +20.5 |
| tips | 536.5 MB | +12.2 |
| sectorMap | 532.5 MB | — |
| codex | 560.9 MB | +28.4 |

Ships, weapons and factions are the whole story; everything else is inside the
noise, and several pages come back negative because a collection ran.

**Factions is not what it looks like.** No `Faction` class appears in the
retained-size table at all, so its 136 MB is allocation the page makes while
building and the heap then keeps — not data it holds. Two attempts at reducing
that allocation are in "Things tried that did not pay", and neither moved the
settled figure. A page that is expensive to open is a different problem from a
page that is expensive to keep open.

## The shape of the problem

| State | RSS | Dart heap |
| --- | --- | --- |
| Just started, one tab | 291 MB | 93 MB |
| Every tab open | 638 MB | 369 MB |

Opening every tab adds about 350 MB, and roughly 275 MB of that is Dart heap.
So this is a Dart-side problem, and the class table is where to look.

Two parts of the heap are not TriOS's to fix:

- **The accessibility tree**, about 17 MB of `SemanticsConfiguration` and
  `AttributedString` with every tab open. Flutter only builds it when something
  asks — a screen reader, or a tool attached to the app. Launched normally it is
  **off**: TriOS was asked directly and said so. Every flutter_ram measurement
  has `flutter run` attached and therefore pays for it, but RSS came out the
  same either way, so do not treat it as a discount.
- **About 30 MB is compiled code and its metadata** (`InstructionsSection`,
  `Code`, `CodeSourceMap`, `Function`, `Field`, `Class`, Read-Only Pages).

## What holds the strings

98 MB of the heap was `_OneByteString`. Blaming each string on the first real
object above it, rather than on the list or map holding it:

| Owner | MB |
| --- | --- |
| `ModImageTable.filePaths` | 10.7 |
| `ModImageTable.referencedBys` | 10.3 |
| `Ship.engineSlots` | 7.2 |
| `ForumModDetails.contentHtml` | 7.2 |
| `DescriptionsNotifier._cachedRowsByVariant` | 5.7 |
| `WeaponsPageState.weaponSearchIndices` | 4.6 |
| `_File._path` | 4.5 |
| `FactionFileData.json` | 2.7 |
| `GameFileSource.imageFiles` | 2.2 |
| `HullmodsPageState.hullmodSearchIndices` | 1.6 |

The rest was spread thinly across `Weapon` and `Ship` fields.

## What holds everything else

Retained size per class, which double counts nesting and is only a hint:

| Class | MB |
| --- | --- |
| `Ship` | 59.4 |
| `Weapon` | 46.9 |
| `VramMod` | 30.2 |
| `ModImageTable` | 27.5 |
| `ShipWeaponSlot` | 14.6 |
| `ForumModDetails` | 13.4 |
| `_File` | 10.3 |

Half a million `_GrowableList` objects and their backing arrays came to about
38 MB. Most were two-element coordinate lists.

## Native memory, and the processes nobody was counting

`tool/native_memory.ps1` asks Windows for the exact list of pages TriOS has
resident, then asks what each page belongs to. With every tab open:

| | MB |
| --- | --- |
| Mapped executables and DLLs | 68 |
| Mapped files | 8 |
| Private, in 512 KB blocks — this is the Dart heap | 343 |
| Private, in blocks of 1 MB and up | 149 |
| Private, small blocks | 9 |

At startup with one tab the same shape is 65 / 7 / 103 / 87 / 6. So opening
every tab adds 239 MB of Dart heap and about 69 MB of everything else.

Of that 69 MB, the image cache is **11.3 MB** — TriOS asked itself and wrote the
answer to `memory-report.txt`. It has a 32 MB budget and never gets near it, so
lowering the budget would save nothing. The rest is Windows heap segments the
engine and the graphics driver allocate, which nothing here can attribute
further without a native allocation profiler.

### The DLLs are not worth chasing

106 modules are loaded, 311 MB of address space between them, but only 64 MB of
that is resident. Of the resident part, TriOS's own plugin DLLs come to under
3 MB all together — the biggest is `flutter_inappwebview_windows_plugin.dll` at
under one megabyte. The rest is `flutter_windows.dll` (12 MB), the NVIDIA
display driver (15 MB) and Windows system DLLs. There is nothing here to cut.

### Graphics memory

Windows reports it per process, and `tool/all_memory.ps1` reads it. TriOS uses
**66.6 MB at startup and 72.3 MB with every tab open**, so nearly all of it is
fixed cost — the swapchain and the glyph atlases — and opening tabs barely
touches it. It is not in RSS, so add it on top when working out what TriOS
really costs.

### The 331 MB that was not in RSS at all

TriOS started **six `msedgewebview2.exe` processes within eight seconds of
launch**, holding about 331 MB between them, whether or not anyone opened a web
page. None of it is in TriOS's own RSS, which is why every memory tool used here
missed it. The real cost of TriOS with every tab open was 910 MB, not 579 MB.

`app_shell.dart` built the WebView2 environment in `initState`, on Windows,
unconditionally. The in-app browser is the only thing that uses it, and it
already showed a spinner while the environment was null, so the environment is
now made the first time something asks for it. Starting TriOS and opening every
tab now starts none.

**How to check this, because no memory tool will show it:** launch TriOS, then
add up every `msedgewebview2.exe` whose parent chain leads back to it.
`tool/webview_memory.ps1` does that, and `tool/all_memory.ps1` does it alongside
RSS and graphics memory.

## Changes made since the Flutter 3.47 upgrade

Against `flutter347-base`, every tab open, 460 mods installed.

| Change | Dart heap | RSS |
| --- | --- | --- |
| Hold the ship and weapon cache blobs zipped | −27.5 MB | −84.5 MB |
| Share the repeated tag, hint and built-in lists | −3.4 MB | noise |
| Pack the ship and weapon coordinate lists | −6.4 MB | noise |

All three together, measured against `flutter347-base` in one go:

| | before | after | change | |
| --- | --- | --- | --- | --- |
| Dart heap held | 370.4 MB | 330.9 MB | −39.5 MB | real |
| Dart heap after collection | 369.5 MB | 328.6 MB | −40.9 MB | real |
| Dart heap capacity held | 392.2 MB | 355.5 MB | −36.8 MB | real |
| RSS held | 756.2 MB | 714.7 MB | −41.5 MB | inside the spread |

**Believe the heap lines, not RSS.** Every heap figure is real and they agree
with each other; RSS moved the same way but by less than the spread between
launches, and one baseline run disagreed with its siblings by 41 MB. RSS on
this machine is no longer precise enough to see a forty-megabyte change.

The first is marked real on every line. The second is real only on the heap
after a forced collection — the leak-signal figure — at −3.4 MB; the other
eleven lines are inside the spread, though all four heap lines move the same
way. It was kept on that basis, not on RSS, which is far too noisy at this size
to show three megabytes. This restores work the merge lost rather than breaking new
ground: `packed_bytes.dart` was written for exactly this and its own comment
says "about 35 MB sitting there for the whole session". A retainer report put
21.2 MB in `ShipsCachePayload` and 14.3 MB in `WeaponsCachePayload`, held as
plain msgpack.

The on-disk cache format is unchanged — the bytes are zipped only in memory, so
`startsWithMsgpackMap` still recognises a cache file on load. `rawDataBytes` is
a getter that unzips, and both callers read it once per source per merge.

## Changes made before the Flutter 3.47 upgrade, and what each was worth

Each was measured on its own, three launches, against the one before it.

| Change | Dart heap | RSS |
| --- | --- | --- |
| Share short strings when decoding cached game data | −10.5 MB | −14.0 MB |
| Share the attribution lists in `ModImageTable` | −11.8 MB | −10.6 MB |
| Pack the coordinate lists | −8.2 MB | −15.4 MB |
| Shorter file paths, and one ship-size map for the class | −8.2 MB | noise |
| Hold the forum post HTML zipped | −17.3 MB | noise |
| Share the mod-attribution summaries | −6.8 MB | noise |
| Share the tag, hint and built-in lists | −15.4 MB | noise |

And separately, outside anything flutter_ram can see:

| Change | What it saved |
| --- | --- |
| Start the WebView2 environment only when something needs it | −331 MB of Edge processes |

Measured all together against the same baseline afterwards, every tab open:

| | before | after | change |
| --- | --- | --- | --- |
| RSS held | 638.3 MB | 568.3 MB | −70.0 MB |
| RSS after collection | 647.2 MB | 583.8 MB | −63.4 MB |
| Dart heap held | 368.8 MB | 307.6 MB | −61.2 MB |
| Dart heap after collection | 365.9 MB | 302.6 MB | −63.3 MB |

Every one of those is marked real by the tool — bigger than the spread between
launches and bigger than one percent of the baseline.

Counting the Edge processes and graphics memory as well, which is what the
machine actually pays for TriOS with every tab open: about **1,040 MB down to
about 650 MB**. `tool/all_memory.ps1` prints all three figures at once, and that
is the number to quote — RSS on its own missed a third of it.

RSS gets noisier as the numbers get smaller; one round came back 617.5, 617.1
and 597.6 across three launches while the heap held steady at 334.4, 334.6 and
323.5. Trust the heap figures and the class table over RSS when they disagree.

### Share short strings when decoding cached game data

`CachedStreamListNotifier.normalizeForMapper`. msgpack hands back a brand new
string for every field name and every value, so a big mod list decodes the same
few thousand words hundreds of thousands of times over. Plenty of that text
outlives the decode, on the ships and weapons themselves.

Strings up to 24 characters are shared, which covers field names, ids, tags and
enum-ish values but not paths or descriptions. The pool never shrinks, so
anything unique has to stay out of it.

Result: 1,339,368 string objects became 837,988.

### Share the attribution lists in `ModImageTable`

Every image a mod's `ship_data.csv` mentions carried its own copy of
`["ships: data/hulls/ship_data.csv"]`. There are hundreds of thousands of
images and only a few thousand distinct lists.

Result: 93,831 fewer string objects.

### Pack the coordinate lists

`Ship.bounds`, `center`, `shieldCenter`, `moduleAnchor`;
`ShipWeaponSlot.locations`, `position`; `Weapon`'s offset and glow-colour
lists. A `List<double>` keeps a separate sixteen-byte object for every number
plus a pointer to each, and these lists are tiny and numerous — two numbers per
weapon slot, and there are 67,861 weapon slots.

They are stored as `Float64List` now and still read as `List<double>`, so
nothing that reads them changed. `Float64List`, not `Float32List`: the smaller
type would have saved another 2.6 MB and cost precision for no good reason.

Result: 611,658 fewer boxed doubles, and 160,000 fewer lists.

### Shorter file paths

Every row of `ModImageTable` held a full absolute path, and there are over a
hundred thousand rows. The paths in one table nearly all start with the same
run of characters — the mod folder, usually with `graphics\` after it — so the
table keeps that start once and each row keeps only what follows.
`pathAt(index)` puts them back together.

`Ship.shipSizesMap` went the same round: it was an instance field, so every one
of the ten thousand ships built its own four-entry map of the same four words,
and wrote all four into its exported row. It is a class constant now.

Result: 6.2 MB less text, and 7,123 fewer maps.

### Hold the forum post HTML zipped

Every card on the Catalog page reads a `ForumModDetails` for the author, the
version and the images, so all nine hundred of them sit in memory while that
page is open — about seven megabytes of post HTML, of which only the post
someone opens is ever read.

`contentHtml` is stored gzipped now and unzipped on first read, using the same
`squeeze`/`unsqueeze` the viewer caches use. The text still reads as a plain
`String`, so the post dialog is unchanged.

Result: 7.2 MB of text became 2.9 MB of bytes.

### Share the mod-attribution summaries

`buildItemModSources` in `game_data_merge.dart`. Every ship and every weapon
carried its own `ItemModSources` saying which mod supplied it and what overrode
it — twenty-seven thousand of them, each only ever read if someone opens that
item's details dialog. Nearly all of them say the same thing, so there is one
copy of each distinct answer now.

It cannot be built on demand instead: it needs the merge results, which are
thrown away once the merge finishes.

Result: 67,000 fewer lists and 45,000 fewer backing arrays.

### Start the WebView2 environment only when something needs it

See "The 331 MB that was not in RSS at all" above. `webViewEnvironment` in
`main.dart` is a `FutureProvider` now, so Riverpod builds it the first time the
in-app browser watches it and never before.

**Still to check by hand:** open the Catalog page's browser panel and confirm a
page loads, and that your forum login is still there. The panel already had a
spinner for the moment the environment was null, so it should just wait a beat
longer than it used to, but nothing here has clicked through it.

## How far this can go

RSS minus Dart heap is about 235 MB of native memory, of which about 76 MB is
mapped executables and files. At startup, with one tab, the same figure is
about 165 MB.

So the floor for "every tab open" is roughly 165 MB of native memory, plus
about 69 MB more that the tabs add to it, plus 30 MB of compiled code. That is
around 265 MB before any of TriOS's own data. The data is about 290 MB today.

Getting TriOS's own process under 400 MB with every tab open would mean fitting
11,000 ships, 16,000 weapons, 114,000 VRAM image rows, 100,000 graphics paths,
the search indices and the codex into about 135 MB. It is 290 MB now, and it
has already had the easy half taken out of it. Shrinking will not close that on
a 460-mod install. The only thing that would is letting go of a page's data
once you leave its tab, and paying to load it again when you come back.

Worth keeping in mind that the 331 MB of Edge processes was bigger than
everything else on this page put together, and no memory tool showed it. If
another big number is hiding, it is somewhere nothing is looking — child
processes, GPU memory, or the file cache.

### Share the tag, hint and built-in lists

`lib/utils/shared_collections.dart`. Sixteen thousand weapons each built their
own set of hints and their own set of tags, out of a vocabulary of a few dozen
words, and most of them ended up with the same handful. Same for ships' hints,
tags, built-in hullmods and built-in wings. There is one copy of each distinct
arrangement now, and what comes back cannot be changed, because everyone shares
it.

Result: 63,661 fewer strings, 32,444 fewer lists, 21,926 fewer growable lists,
and `_HashSet` fell out of the fifteen biggest classes altogether.

### Where the text ended up

After all of the above, no single owner of string memory is bigger than
6.6 MB — `DescriptionsNotifier._cachedRowsByVariant`, then the graphics index
paths at 4.6 MB, the weapon search index at 4.6 MB, `_File._path` at 4.5 MB and
the VRAM path tails at 4.4 MB. The tail is flat, which is the sign that this
particular seam is worked out. Anything further here is three to five megabytes
at a time.

## Things tried that did not pay

- **A leaner search index for weapons.** The weapons list indexes every field
  of every weapon, seven sprite paths included, where ships already leave their
  geometry out. Writing a `toSearchMap` for `Weapon` saved 1.5 MB of text and
  moved the heap by nothing the spread could tell apart, so it was reverted —
  it changed what a search matches for no measurable gain.
- **Two goes at the Factions page.** Opening it costs 136–177 MB, more than
  ships and weapons together, and no `Faction` class appears anywhere in the
  retained-size table — so it is transient allocation, not something held.
  `computeRoleWeights` rebuilds four sets and four maps that depend only on the
  faction, and it runs eleven times per faction for the summaries; it also
  builds and sorts a `SpawnWeightEntry` per candidate that `_summarize` only
  reads a weight off. Hoisting the per-faction lookups measured **+14.1 MB, and
  the tool called that real**. Adding a `tally` callback so the summary never
  builds the entry list measured inside the spread on every line. Both
  reverted.

  The lesson is about what the per-page figures mean: the Factions spike raises
  RSS while the page builds, but by the end of the walk the settled number is
  the same either way. A page that costs a lot to open is not the same as a page
  that costs a lot to keep open, and only the second shows up here.
- **Slimmer weapon slots.** `ShipWeaponSlot` has 67,861 instances, and six of
  its fields come from a vocabulary of about fifty combinations, so they were
  moved onto a shared `SlotKind` and the two coordinate lists were merged into
  one block. Every line came back inside the spread and the class table barely
  moved: the coordinate lists were mostly empty already, and empty ones were
  being shared before the change. Reverted.
- **Zipping the cached `descriptions.csv` rows.** The same trick that worked on
  the forum HTML made things 8.8 MB *worse*. Unzipping happens on every merge,
  and the merge runs every half second while the mod list is loading. Worse, the
  merged descriptions used to share their string objects with the cached rows;
  once the rows are bytes, every merge builds fresh copies of all that text. The
  lesson: only zip something nothing else shares strings with, and that is read
  rarely.

## What is left at 410 MB, and why each piece is a trade

A heap snapshot taken with "only enabled mods" on — 13 mods merged out of 460
installed — says the biggest remaining owners are all **scan data for mods that
are not being shown**:

| Owner | MB | Why it is still held |
| --- | --- | --- |
| `ModImageTable._pathEnds` | 4.4 | The VRAM page charts every mod it has ever scanned, not just enabled ones |
| `GameFileSource.imageFiles` + `CastList._source` | 6.6 | So the sprite resolver can be rebuilt for either toggle value without re-reading |
| `ModImageTable.referencedBys` | 2.5 | As above |
| `_Uint8List` cache blobs | 8.2 | So flipping the toggle re-merges without going back to disk |

About 22 MB, and **every piece of it is deliberate**. Dropping it would either
change what the VRAM page charts, or turn flipping "only enabled mods" from
instant into a second or two. Neither is free, so neither was done.

Also worth knowing: roughly 19 MB of that snapshot is the accessibility tree
(`SemanticsConfiguration`, `AttributedString`, `_RenderObjectSemantics`), which
only exists because flutter_ram attaches. The 410.3 MB figure comes from a
release build launched normally, so it does not include that.

## Worth doing next

- **Load the VRAM estimator's cache when its tab is first opened.** About 20 MB
  of per-mod image tables is read from `TriOS-VRAM_CheckerCache-referenced.mp`
  (19 MB on disk) at startup and held for the whole session, whether or not
  anyone looks at the VRAM page. It is not filtered by the enabled-mods toggle
  either. This would not help the "every tab open" figure, since that opens the
  VRAM tab, but it would help every session where nobody does.
- **Keep only the per-mod totals in memory, and read the image rows when the
  breakdown dialog opens.** The bar chart only needs totals. The rows are about
  15 MB of the above, and this would help the "every tab open" figure too.
- **Prune the VRAM cache to mods that are still installed.** Nothing removes
  entries for mods that have been deleted, so the map can only grow.

## Things looked at and left alone

- **`Ship.engineSlots` raw maps.** Only about 2 MB of `_Map`. Most of what
  looked expensive about them was repeated text, which the string sharing above
  already deals with.
- **`ship_blueprint_view.dart` read `weaponListNotifierProvider(false)`** with
  the toggle hard-coded, so hovering a built-in weapon slot while "only enabled
  mods" was on merged a second copy of every weapon in every installed mod. It
  asks for the same list as everything else now. Not measurable here — it only
  fires on hover, which the tab walk never does — but it is plainly a bug, and
  it fires in exactly the configuration that gets closest to 400 MB.
