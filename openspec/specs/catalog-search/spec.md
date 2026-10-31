## ADDED Requirements

### Requirement: Text clean-up
Typed text and every searched fact SHALL be cleaned the same way before they are compared:

1. Apostrophes (`' ’ ‘ ´ \``) are removed without leaving a space.
2. Every character that is not a letter, a digit or a dot becomes a space.
3. Text is lowercased and accents are removed.
4. A dot is kept only when it has a digit on both sides, so "0.98a" survives and "end." does not.
5. Runs of spaces become one space, and the ends are trimmed.

Letters of every alphabet are kept.

#### Scenario: Accents and apostrophes
- **WHEN** the text is "Amazigh's Café"
- **THEN** it cleans to "amazighs cafe"

#### Scenario: Version dots survive
- **WHEN** the text is "[0.98a] Ship/Weapon Pack."
- **THEN** it cleans to "0.98a ship weapon pack"

### Requirement: What a mod can be found by
Each mod SHALL be searchable by a list of facts. Each fact has a cost, which is taken off the score of any match on it. Facts are worked out once per mod and reused.

| Fact | Cost |
|---|---|
| The shown name, the catalog name and each nickname, as written and with spaces removed | 0 |
| Each word of the shown name, also split where a small letter meets a capital ("GraphicsLib" → "graphics lib"), and each word of the catalog name | 10 |
| The initials of names with two or more words; also the initials without the little words "of the and for a an in on to by or at" | 0 |
| Each author and each other name of that author, as written and with spaces removed | 0 |
| Each category | 20 |
| The game version and the mod version | 20 |
| The summary | 40 |
| The full description | 45 |
| Every link: forum, Discord, NexusMods, direct download, download page, and every download link the scraper found | 45 |

- Nicknames come from the scraper's answer for the mod (`nicknames` in the details file) and from a hand-kept list keyed by catalog mod id, copied from Starmodder's `nicknames.js`.
- Other author names come from `otherAuthorNames` in `mod-catalog-extras.json` when TriOS has it. Until then they come from `Constants.modAuthorAliases`.
- The summary fact is the author's short text. The AI sentence is added at the same cost only while AI summaries can be shown, so a match never comes from text the user has turned off.
- When two facts clean to the same text, the cheaper one is kept.

#### Scenario: Description matches rank low
- **WHEN** the search is "nexerelin" and one mod is named Nexerelin and another only mentions Nexerelin in its description
- **THEN** both are listed, and Nexerelin is first

#### Scenario: AI text is not searched when AI is off
- **WHEN** AI features are turned off and a word appears only in a mod's AI sentence
- **THEN** that mod does not match the word

### Requirement: How one typed word scores
A typed word SHALL be compared with every fact of a mod. The best result counts. Each fact scores as follows, minus its cost:

- The fact is exactly the word: 100. An exact match on initials scores 140 instead.
- The fact starts with the word: 80.
- A word inside the fact starts with the word: 70.
- The fact holds the word anywhere: 50.

A word that matches no fact scores below zero.

#### Scenario: Exact initials win
- **WHEN** the search is "swp"
- **THEN** Ship/Weapon Pack scores 140 from its initials and is listed first

### Requirement: Word-start shorthand
A typed word SHALL also match when it can be built from the starts of words standing next to each other in the shown name, in order. Little words may be skipped. Such a match scores 45, and only when nothing scored higher.

- The typed word has three or more letters and only letters.
- The name has two or more words.
- Either every piece is one letter, or every piece except the last is two letters or more. This stops "faction" from matching Fleet Action History as "f" + "action".
- It is not tried for a word with a minus in front.

#### Scenario: indevo
- **WHEN** the search is "indevo"
- **THEN** Industrial Evolution matches, built from "ind" + "evo"

#### Scenario: kol
- **WHEN** the search is "kol"
- **THEN** Knights of Ludd matches, built from "k" + "o" + "l"

#### Scenario: Ordinary words are not shorthand
- **WHEN** the search is "faction"
- **THEN** Fleet Action History does not match through shorthand

### Requirement: Close spellings
A typed word SHALL also match a word in a name or an author's name that is spelled almost the same. This is tried only when the word matched no name, name word, initials or author fact.

- Only for typed words of five letters or more with no digits.
- The first letter must be the same.
- One change is allowed for words of five to seven letters. Two are allowed for eight letters or more.
- A change is one letter added, removed or swapped, or two letters next to each other trading places.
- The typed word is also compared with the start of each longer word, so a half-typed word with a mistake still matches.
- One change scores 38. Two changes score 34.
- It is not tried for a word with a minus in front.

#### Scenario: One typo
- **WHEN** the search is "nexerlin"
- **THEN** Nexerelin matches

#### Scenario: Short words need to be right
- **WHEN** the search is "lazt"
- **THEN** LazyLib does not match, because close spellings need five letters or more

#### Scenario: Wrong first letter
- **WHEN** the search is "faction"
- **THEN** a mod named "Action" does not match through close spelling

### Requirement: Reading the search text
The typed text SHALL be read like this:

- Commas split it into groups. A mod matches if any group matches it. The best-scoring group counts.
- Inside a group, spaces split it into pieces. A plus works like a space. Every piece must match.
- A piece in double quotes is a phrase. It is matched as one cleaned text, without shorthand or close spellings. Commas and spaces inside quotes are part of the phrase. A quote that is never closed is closed at the end of its group.
- A piece that cleans into several words ("seeker-unidentified") is several pieces.
- A minus in front of a piece leaves out mods that match it. Within a group, it narrows that group. A group made only of minus pieces removes mods from the whole list.
- Typing only minus pieces starts from every mod.
- A lone minus, plus or quote with nothing else is ignored.

The total score of a group is the sum of its pieces' scores plus a name bonus. The bonus is 60 when the group's plain words are a mod's whole name or nickname (also compared with spaces removed), 40 when a name starts with them, and 30 when a name contains them.

#### Scenario: Every word must match
- **WHEN** the search is "graphics lib"
- **THEN** GraphicsLib matches, and a mod with only "graphics" in its name does not

#### Scenario: OR with commas
- **WHEN** the search is "portrait, faction"
- **THEN** mods matching either word are listed

#### Scenario: Leaving words out
- **WHEN** the search is "pirate -junk"
- **THEN** mods matching "pirate" are listed, except those that also match "junk"

#### Scenario: Only minus words
- **WHEN** the search is "-portrait"
- **THEN** every mod is listed except those matching "portrait"

#### Scenario: Exact phrase
- **WHEN** the search is `"unknown contact"`
- **THEN** only mods with those two words next to each other in a fact match

### Requirement: Asking about one field
A piece written as `name:value` SHALL match only when one of that field's values, cleaned, contains the cleaned value. Such a match scores 100. A minus in front leaves those mods out. A field name that is not in this list is searched as ordinary text.

| Field | Also accepted | Looks in |
|---|---|---|
| `name` | | Shown name and catalog name |
| `author` | `authors` | Authors and their other names |
| `category` | `categories` | Categories |
| `version` | `gameversion` | Game version |
| `modversion` | | Mod version |
| `from` | `source`, `sources` | Where the mod was posted: `forum` (mod index or modding subforum), `index`, `discord`, `nexus` |
| `url` | | Every link listed in the facts table |
| `summary` | | The summary facts |

#### Scenario: Author field
- **WHEN** the search is "author:wisp"
- **THEN** only mods credited to Wisp, or to one of Wisp's other names, are listed

#### Scenario: Unknown field
- **WHEN** the search is "foo:bar"
- **THEN** it is searched as the words "foo" and "bar"

### Requirement: Yes-or-no questions
A piece written as `has:word` or `is:word` SHALL keep or remove mods without changing their score. Both `has:` and `is:` accept every word. A minus in front reverses it.

| Word | Also accepted | True when |
|---|---|---|
| `source` | `code`, `sourcecode` | The mod has a source code link |
| `download` | | The mod has a direct download link, by the same rule as the "Has Download Link" filter |
| `addable` | `safe` | The author says the mod can be added to a running save |
| `wip` | | The forum marks the mod as a work in progress |
| `tool` | | The mod is a tool rather than a game mod |
| `ai` | | The author says AI was used |
| `noai` | | The author says AI was not used |

A mod whose author says nothing about AI is false for both `ai` and `noai`.

Until `mod-catalog-extras.json` is read, `addable`, `tool`, `ai` and `noai` use the scraper's answer in the details file (`extras.canAdd`, `isTool`, `extras.aiUse.usesAi`). Once that file is read, the same questions use it first.

#### Scenario: Leaving out works in progress
- **WHEN** the search is "-is:wip"
- **THEN** mods marked as works in progress are not listed

#### Scenario: Questions do not change the order
- **WHEN** the search is "nexerelin has:source"
- **THEN** the order is the same as for "nexerelin" alone, minus the mods with no source link

### Requirement: Best match sort
The sort list SHALL offer "Best match" only while the search box has text. Best match orders mods by score, highest first. Ties go by name, then by catalog id. The direction button does not apply to it.

- When the search box goes from empty to holding text, and the user has not picked a sort by hand during this search, the sort switches to Best match. The sort in use before is kept aside.
- When the search box is cleared, a Best match sort goes back to the kept sort, with its direction.
- A sort the user picks by hand while there is text stays in use until the search is cleared.
- Best match is never saved as the remembered sort.

#### Scenario: Typing picks Best match
- **WHEN** the sort is Popular and the user types "kol"
- **THEN** the sort becomes Best match and Knights of Ludd is first

#### Scenario: Clearing restores the sort
- **WHEN** the user clears the search after the previous scenario
- **THEN** the sort is Popular again, most popular first

#### Scenario: A hand-picked sort is kept
- **WHEN** the user picks Name while searching and then types more letters
- **THEN** the sort stays Name

### Requirement: Search box
The Catalog SHALL use `SmartSearchBar` for its search.

- Field names (`author:`, `category:`, `version:`, `from:`, `has:`, `is:` and the rest) are suggested as the user types. So are values for `author`, `category`, `version`, `from`, `has` and `is`.
- Mod names are not suggested.
- Text stays exactly as typed. Fields do not become pills, because pills would move fields to the front and break comma groups.
- The help button opens a panel that explains the search rules.
- Pressing `/` puts the cursor in the box, as it does today.
- No search history is kept.

#### Scenario: Field suggestion after a comma
- **WHEN** the user types "kol, auth"
- **THEN** `author:` is suggested, and choosing it gives "kol, author:"
