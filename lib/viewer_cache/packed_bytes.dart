import 'dart:io';
import 'dart:typed_data';

/// Squeezing the scanned game data that the ships and weapons viewers keep in
/// memory between merges.
///
/// Each viewer holds one blob of packed data per installed mod so that turning
/// "only enabled mods" on or off can re-merge without going back to disk. On a
/// big mod list that was about 35 MB sitting there for the whole session.
/// It is msgpack-packed CSV rows and JSON maps, which is very repetitive text,
/// so zipping it gives most of that memory back and costs a tenth of a second
/// or so on the merges that actually need it.

/// The two bytes every gzip stream starts with.
const _gzipMagic = [0x1f, 0x8b];

/// [bytes], zipped.
Uint8List squeeze(Uint8List bytes) => Uint8List.fromList(gzip.encode(bytes));

/// [bytes] zipped, unless they already are.
///
/// Used when reading a cache file: files written by older versions hold
/// unzipped blobs, and without this they would stay unzipped in memory until
/// the mod they came from happened to be re-read.
Uint8List squeezeIfNeeded(Uint8List bytes) =>
    _looksZipped(bytes) ? bytes : squeeze(bytes);

/// The original of a [squeeze]d blob.
///
/// Blobs written by older versions were not zipped, and cache files from those
/// versions are still on disk, so anything that isn't a gzip stream is passed
/// straight through rather than treated as an error.
Uint8List unsqueeze(Uint8List bytes) =>
    _looksZipped(bytes) ? Uint8List.fromList(gzip.decode(bytes)) : bytes;

/// Whether [bytes] starts with the gzip header.
bool _looksZipped(Uint8List bytes) =>
    bytes.length >= 2 && bytes[0] == _gzipMagic[0] && bytes[1] == _gzipMagic[1];
