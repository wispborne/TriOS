/// Reads JSON files the same way Starsector does, quirks included.
///
/// This folder is a Dart port of the two steps `SettingsAPI.loadJSON` runs on a
/// file's text:
///
///   1. Strip `#` comments, the loop in
///      `com.fs.starfarer.loading.LoadingUtils` — see [removeHashComments].
///   2. Parse it with the 2010 org.json release that ships in the game's
///      `json.jar` — see [parseJsonObject].
///
/// [parseStarsectorJson] does both, and is what you want for reading a file.
///
/// Nothing outside this folder is imported, so it can be lifted out into its own
/// package later without changes.
library;

export 'hash_comments.dart' show removeHashComments;
export 'json_exception.dart' show StarsectorJsonException;
export 'json_parser.dart' show parseJsonObject, parseStarsectorJson;
