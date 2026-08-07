# starsector_json

Reads JSON files the same way Starsector does, quirks included.

Nothing here imports anything outside this folder, so it can be lifted into its
own package later without changes.

```dart
import 'package:trios/starsector_json/starsector_json.dart';

final map = parseStarsectorJson(fileText);
```

## What it's a port of

`SettingsAPI.loadJSON` does two things to a file's text, and this is both of
them:

1. **Strip `#` comments** — the loop in
   `com.fs.starfarer.loading.LoadingUtils.Ö00000`. Ported in
   `hash_comments.dart`.
2. **Parse it** — `new JSONObject(text)`, using the org.json release in
   `starsector-core/json.jar`. That jar is dated 2010-05-09 and is the only
   `org.json` on the game's classpath. Ported in `json_parser.dart`
   (`JSONTokener`, and the parsing constructors of `JSONObject` and
   `JSONArray`) and `java_values.dart` (`stringToValue`, plus the Java number
   parsing and formatting it leans on).

Source for the port was the decompiled `json.jar` and
`decompiled_obf/com/fs/starfarer/loading/LoadingUtils.java`.

## Things the game accepts that strict JSON doesn't

- Unquoted keys and unquoted string values. An unquoted token runs until a
  control character or one of `, : ] } / \ " [ { ; = #`, so **spaces are part of
  the token** — `a: two words` gives `'two words'`.
- Single-quoted strings.
- `#` comments to end of line.
- Trailing commas, in objects and arrays.
- `;` in place of `,`, and `=` or `=>` in place of `:`.
- `true` / `false` / `null` in any capitalisation.
- `0xFF` hex integers, when the value fits in a signed 32-bit int.
- A missing array element: `[1,,2]` gives `[1, null, 2]`.

## Things the game rejects that you might expect to work

These all throw. They throw in game too — that's the point of the port.

- **`//` comments.** The comment stripper only knows about `#`, and this
  org.json release has no comment support at all, so `/` just ends a token and
  the parse fails. TriOS's own `parseJsonToMap()` strips `//` and is therefore
  more forgiving than the game.
- **Duplicate keys.** `{"a": 1, "a": 2}` throws `Duplicate key "a"`.
- **A string spanning lines.**
- **Unknown backslash escapes,** including `\#`.
- **Infinity or NaN as an object value** — `{a: 1e999}` throws. Oddly, the same
  value inside an array is fine, because the array code skips the check.
- **Anything but an object at the top level.**

## Quirks worth knowing about

- The comment stripper flips its "inside a string" flag on **every** `"`,
  including one inside a comment and one written as `\"`. So in
  `{"a": "x \" # y"}` the four quotes before the `#` leave the flag off and
  everything from the `#` on is dropped.
- A line break clears that flag, so a string can never span lines as far as
  step 1 is concerned.
- `\r` is thrown away, so CRLF files come out with LF endings.
- Keys go through the same value reader as everything else and then have Java's
  `toString()` applied, so an unquoted key that looks like a number is turned
  into a number and back. `{ 1.50: x }` gives the key `"1.5"`.
- Line numbers in error messages can be one higher than you'd expect. Java's
  "step back one character" rolls back the character but not the line, so a
  newline that gets read twice is counted twice. Reproduced on purpose so
  messages match the game's log.
- `1.5f` parses as the double `1.5`, but `1f` stays the string `'1f'` — the
  suffix is only accepted on the path that has a `.`, `e` or `E` in it. Use
  `toDoubleOrNullAllowingJavaSuffix()` when reading a value you expect to be a
  number.

## Where it deliberately differs

Three places, none of which changes what a real file parses to:

- **Key order.** Java uses a `HashMap`, so its key order is arbitrary. This uses
  a Dart map, so keys come out in the order the file lists them.
- **JSON `null`.** Java stores a `JSONObject.NULL` sentinel; this stores Dart
  `null` and keeps the key, which means the same thing and reads better from
  Dart.
- **Bad `\u` escapes.** Java throws `NumberFormatException` here rather than a
  `JSONException`; this throws `StarsectorJsonException` like everything else.

One gap: Java's `Double.valueOf` accepts hex floating-point literals like
`0x1.8p1`. This doesn't, so such a token stays a string. No game or mod file
uses that form.

## How it compares to TriOS's `parseJsonToMap()`

Measured over a full install — 59,566 files, 108 MB — with
`test/benchmark/json_parse_benchmark.dart`.

**Speed:** 718 ms against 3853 ms, so about 5.4x faster. The old
`parseJsonToMap()` spent 85% of its time in the YAML fallback; this has no
fallback to spend time in.

That 718 ms started as 843 ms; the difference is scan work. The comment
stripper jumps from `#` to `#` with `indexOf` and strips `\r`s with
`replaceAll` instead of walking every character, and the parser's three
per-character loops (whitespace, quoted strings, bare tokens) scan by index
and settle the line/character bookkeeping in one step. The bookkeeping still
comes out identical — a full-install comparison against the unoptimized code
(every file, parsed whole and cut short, error messages included) found no
difference.

**Which files each one reads:** 11 files this reads that `parseJsonToMap()`
can't, including vanilla `data/config/settings.json` and
`data/strings/ship_names.json`. 15 the other way, of which 13 are files the game
itself would refuse — mostly a mod shipping `"fleetPoints":,` with no value —
and 2 are `.idea` schema files that aren't game data.

**Where both read a file but disagree — 2834 files.** Almost all of it is one
thing: `parseJsonToMap()`'s YAML fallback quietly retypes quoted strings.

| In the file | `parseJsonToMap()` | this, and the game |
| --- | --- | --- |
| `"utility":"true"` | `true` | `'true'` |
| `"version":"1.4"` | `1.4` | `'1.4'` |
| `"fluxCapacitors": "10"` | `10` | `'10'` |
| `"IndEvo_...Num":1.5f` | `'1.5f'` | `1.5` |

So code that reads those fields now gets a `String` where it used to get a
`bool`, `int` or `double`.

**None of it turned out to matter.** Every call site was checked:

- The fields that changed from `bool`/`int` to `String` in `.wpn` and `.variant`
  files — `renderBelowAllWeapons`, `alwaysAnimate`, `autofire`,
  `fluxCapacitors`, and the rest — aren't read by TriOS at all.
- Everything TriOS does read goes through lenient coercion that already accepts
  either form: `doubleFromGameJson` / `boolFromGameJson`
  (`lib/utils/game_json_values.dart`), `_toDouble` in `ShipEngineStyleSpec`, or
  a dart_mappable hook. `mod_info.json` still decodes to `utility=true` and
  `version=1.20.0` from `"true"` and `{"major":"1"}`.
- 437 of 438 `mod_info.json` files still read. The one that doesn't is missing a
  key entirely (`"modPlugin":"a", "b"`), so the game refuses it too.
- 366 of 367 `.version` files produce a byte-identical `VersionCheckerInfo`.

Two call-site changes were needed, both now done:

- Seven places called `removeJsonComments()` before parsing. That helper is
  `line.split('#').first`, which knows nothing about quotes, so it truncated any
  string containing a `#`. It broke 23 files that parse fine without it and
  rescued none, so it's gone from all seven.
- `.version` files are parsed through `parseVersionCheckerJson` instead, which
  strips `//` and `/* */` first. The game never loads these files, modders do
  write `//` comments in them, and refusing one just means no update check for
  that mod.
