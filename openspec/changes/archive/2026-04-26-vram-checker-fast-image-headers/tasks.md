## 1. Async-ify the existing PNG reader

- [x] 1.1 Replace `File.openSync()` and `RandomAccessFile.readSync(...)` in `lib/vram_estimator/image_reader/png_chatgpt.dart::readPngFileHeaders` with `await File(path).open()` and `await raf.read(33)` respectively. Keep the IHDR parsing in `readPngHeadersFromBytes` exactly as-is.
- [x] 1.2 Read 33 bytes (PNG signature 8 + IHDR length 4 + IHDR type 4 + IHDR content 13 + 4 byte CRC unused) instead of the current `8 + 8 + 13`. Confirm the existing parser still operates on `bytes[0..28]` only — the extra read is a future-proof against a CRC-aware tweak; if it complicates anything, keep `29`.
- [x] 1.3 Wrap the open/read in `try { ... } finally { await raf?.close(); }` so close runs even on parse failure. Confirm the existing `RandomAccessFile?` nullable pattern is preserved.

## 2. New JPEG header reader

- [x] 2.1 Create `lib/vram_estimator/image_reader/jpeg_header.dart` exporting `Future<ImageHeader?> readJpegFileHeaders(String path)`.
- [x] 2.2 Open the file via `await File(path).open()`, read an initial 4 KB chunk via `await raf.read(4096)`, set up a 64 KB total-bytes-read cap.
- [x] 2.3 Verify SOI marker `FF D8` at byte 0; on mismatch throw `Exception('This file is not a JPEG.')` to match the existing PNG reader's failure shape.
- [x] 2.4 Walk markers: at offset 2, expect `FF` followed by a marker byte. For non-SOF / non-SOI / non-EOI markers, read the next 2 bytes (big-endian segment length, including the 2 length bytes themselves but not the marker), and skip `length - 2` bytes. If skipping would run past the loaded buffer, read more — bounded by the 64 KB cap.
- [x] 2.5 On encountering any of `FFC0..FFC3, FFC5..FFC7, FFC9..FFCB, FFCD..FFCF` (every defined SOF marker), read the SOF segment's `precision(1) height(2) width(2) components(1)` and return `ImageHeader(width, height, precision, components)`. Treat `precision` as `bitDepth` and `components` as `numChannels`.
- [x] 2.6 If the 64 KB cap is reached without seeing an SOF, throw `Exception('JPEG SOF not found within first 64 KB.')`. Cap re-reads with a counter — never read unbounded.
- [x] 2.7 `try / finally` ensures the file is closed.

## 3. New GIF header reader

- [x] 3.1 Create `lib/vram_estimator/image_reader/gif_header.dart` exporting `Future<ImageHeader?> readGifFileHeaders(String path)`.
- [x] 3.2 Open the file, `await raf.read(13)`. Verify bytes 0–5 are ASCII `GIF87a` or `GIF89a`; on mismatch throw `Exception('This file is not a GIF.')`.
- [x] 3.3 Decode width as `bytes[6] | (bytes[7] << 8)`, height as `bytes[8] | (bytes[9] << 8)` (little-endian).
- [x] 3.4 Hard-code `bitDepth = 8` and `numChannels = 4`. Comment explicitly that this matches what `package:image` returned for GIFs after palette expansion, and that the LSD packed field's "color resolution" bits are intentionally ignored (they encode palette bit depth, not channel count).
- [x] 3.5 `try / finally` close.

## 4. New WEBP header reader

- [x] 4.1 Create `lib/vram_estimator/image_reader/webp_header.dart` exporting `Future<ImageHeader?> readWebpFileHeaders(String path)`.
- [x] 4.2 Open the file, `await raf.read(30)`. Verify bytes 0–3 are `RIFF` and bytes 8–11 are `WEBP`; on mismatch throw `Exception('This file is not a WEBP.')`.
- [x] 4.3 Read the 4-byte FourCC at offset 12. Branch:
- [x] 4.4 Branch `VP8 ` (lossy): the VP8 bitstream starts at offset 20. Width is the 14 LSBs of the 16-bit LE value at offset 26, height is the 14 LSBs of the 16-bit LE value at offset 28. `bitDepth = 8`, `numChannels = 3`.
- [x] 4.5 Branch `VP8L` (lossless): the VP8L body starts at offset 20. Verify signature byte `0x2F` at offset 20. The next 4 bytes pack `(width-1):14, (height-1):14, alpha:1, version:3` little-endian. `bitDepth = 8`, `numChannels = alpha ? 4 : 3`.
- [x] 4.6 Branch `VP8X` (extended): VP8X body starts at offset 20. Bit 4 of `bytes[20]` is alpha. Width-1 is the 24-bit LE value at offset 24, height-1 is the 24-bit LE value at offset 27. `bitDepth = 8`, `numChannels = alpha ? 4 : 3`.
- [x] 4.7 Default branch (other FourCC): throw `Exception('Unknown WEBP chunk: $fourcc')`.
- [x] 4.8 `try / finally` close.

## 5. Wire the readers into the dispatch

- [x] 5.1 In `lib/vram_estimator/image_reader/image_reader_async.dart`, replace the body of `readImageDeterminingBest` with a switch over the lowercased path extension that calls the matching reader. PNG → `readPngFileHeaders`; JPG / JPEG → `readJpegFileHeaders`; GIF → `readGifFileHeaders`; WEBP → `readWebpFileHeaders`. On unknown extension, throw the same "Not an image." exception.
- [x] 5.2 Delete `readPng` and `readGeneric` methods. Delete the `import 'package:image/image.dart' as img;` line.
- [x] 5.3 Keep the `ReadImageHeaders` class shape (callers in `_processAssets` go through it). The class becomes a thin dispatcher.
- [x] 5.4 Run `dart analyze` and resolve any unused-import / dead-code warnings introduced.

## 6. Remove `package:image` from `pubspec.yaml` if unused

- [x] 6.1 Grep `lib/` and `test/` for any remaining `package:image/` import after step 5. List every match.
- [x] 6.2 If the only remaining matches are this change's old-test-fixture parity references (which compare against `package:image`'s output during the test, intentionally), keep `image:` as a `dev_dependency` only. Otherwise (production import remains) leave it as a `dependency`.
- [x] 6.3 If no remaining `lib/` matches AND the parity test machinery is moved to `dev_dependencies` only, run `flutter pub get` to regenerate `pubspec.lock` and confirm the build still succeeds.

## 7. Parity fixtures and tests

- [x] 7.1 Add `test/vram_estimator/image_reader/` with subdirs per format. Each fixture is a small real file (a few KB to ~1 MB max) covering one parse path:
  - PNG: 24-bit truecolor, 32-bit truecolor + alpha, palette (color type 3), grayscale (color type 0), grayscale + alpha (color type 4).
  - JPEG: baseline (SOF0), progressive (SOF2), extended sequential (SOF1), lossless (SOF3), with and without an EXIF APP1 segment.
  - GIF: GIF87a static, GIF89a static, GIF89a animated.
  - WEBP: VP8 (lossy), VP8L (lossless) with alpha and without, VP8X with alpha and without.
- [x] 7.2 Per-fixture parity test: read the fixture with the new per-format reader, read the same fixture with `package:image` (kept as a `dev_dependency` for the test only), assert `(width, height, bitDepth, numChannels)` are equal.
- [x] 7.3 Where strict tuple equality cannot hold for a documented reason (e.g. a specific GIF whose `package:image` channel count is 4 but a header-reader-derivable value would be 1), assert byte-level VRAM equivalence instead — compute `ModImageView.bytesUsed` for both header tuples and assert equality. Document the deviation in a comment in the test, citing the format spec section that justifies it.
- [x] 7.4 Truncation tests per format: take each parse-path fixture, truncate it to a length shorter than the format's required header, run the reader, assert it throws (does not hang, does not return a partial header).
- [x] 7.5 Corruption tests per format: flip the magic bytes / signature and assert the reader throws.
- [x] 7.6 JPEG-specific: a fixture with a giant APP1 (EXIF) segment that pushes SOF past 1 KB but stays under 64 KB. Assert the reader still finds SOF and returns correct dims.
- [x] 7.7 JPEG-specific: a fixture (constructable by hand) whose markers chain past 64 KB without an SOF. Assert the reader throws within the cap (i.e. read budget is enforced).

## 8. Mod-corpus integration check

- [x] 8.1 Stand up a tiny benchmark-style integration test under `test/vram_estimator/` that walks a small fixture mod folder containing a representative mix (PNG sprites, one big JPG background, one GIF, one WEBP) and runs `_processAssets` end-to-end. Assert the resulting referenced+unreferenced VRAM total matches a recorded golden value.
- [ ] 8.2 Optional CI/local benchmark: run the full VRAM scan against a configurable mods-folder path under `--dart-define=VRAM_BENCHMARK_DIR=...` and print per-mod header-read time. Manual; not blocking.

## 9. Manual verification

- [ ] 9.1 Run a single-threaded VRAM scan against a Starsector install that includes Kaleidoscope and Darksector. Confirm: UI does not freeze; per-mod `headerRead time=` log lines drop from tens of seconds to sub-second; total VRAM bytes per mod match the pre-change scan within rounding (i.e. `bytesUsed` parity holds).
- [ ] 9.2 Run a multi-threaded VRAM scan against the same set. Confirm: workers no longer log multi-second per-asset reads; UI is more responsive than before; per-mod totals match the single-threaded run from 9.1.
- [ ] 9.3 Run a Folder Scan (no parsers) against the same set. Confirm: UI does not freeze; totals match a pre-change Folder Scan run for the same mods.
- [ ] 9.4 Cancel a scan mid-flight. Confirm: cancellation latency is no worse than before, and no orphan file handles persist (Windows: process handle count returns to baseline within seconds).

## 10. Spec update

- [ ] 10.1 Merge the delta requirements from `openspec/changes/vram-checker-fast-image-headers/specs/vram-estimator/spec.md` into `openspec/specs/vram-estimator/spec.md` via the standard archive step when this change is archived.
