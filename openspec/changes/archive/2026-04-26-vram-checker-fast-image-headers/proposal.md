## Why

The VRAM scanner's UI freezes — sometimes for many seconds at a time — during scans, regardless of selector (Selective Scan AND Folder Scan), regardless of multithreading mode (single- AND multi-threaded), and worst on background-heavy mods like Kaleidoscope and Darksector. The root cause is in the per-image header read, which both selectors funnel every selected asset through:

- `readPngFileHeaders` (`png_chatgpt.dart`) opens the file with `File.openSync()` and reads its first ~29 bytes with `RandomAccessFile.readSync(...)` — synchronous I/O on the calling isolate. In single-threaded mode that isolate is main; the renderer cannot get a frame for the duration of every open+read+close.
- `readGeneric` (`image_reader_async.dart`, the `.jpg/.jpeg/.gif/.webp` path) calls `File.readAsBytesSync()` on the **entire file** before handing those bytes to `img.Command()..decodeNamedImage(...).executeThread()`. For a multi-megabyte 4K/8K JPG background, that is a multi-megabyte synchronous read on the calling isolate, followed by a multi-megabyte cross-isolate memcpy, followed by a full JPEG decode — all to extract four integers (width, height, bitDepth, numChannels).

Together, hundreds of these run concurrently per mod via `Future.wait` inside `_processAssets`. The file-handle limiter is irrelevant because the I/O underneath is sync — every started call holds main until it returns. Mods with many high-resolution JPG backgrounds (Kaleidoscope's `home_plant.jpg`, Darksector's similar set) hit the worst case directly. Profiling-style logs from a real scan show wall-clock `headerRead time=50551ms` for a 107-asset mod, vs. expected sub-second.

The fix is to make every header read both **truly async** and **header-only** — read just enough bytes to parse dimensions, never the whole file, and use `RandomAccessFile.open()` / `read(...)` (the awaitable variants) so the calling isolate's event loop stays free during disk I/O.

## What Changes

- Convert `readPngFileHeaders` in `lib/vram_estimator/image_reader/png_chatgpt.dart` to async I/O: `File.open()` + `RandomAccessFile.read(...)` instead of `openSync`/`readSync`. Header parsing logic (PNG signature, IHDR chunk decode) is unchanged.
- Add three new header-only parsers next to `png_chatgpt.dart`, one per remaining supported format:
  - `jpeg_header.dart` — async-reads up to ~64 KB, walks JPEG markers (`FFE0…FFEF`/`FFDA`-style segment skip, SOF0/SOF1/SOF2/SOF3/SOF5–SOF7/SOF9–SOF11/SOF13–SOF15) until the Start-Of-Frame, returns `(width, height, precision, components)`.
  - `gif_header.dart` — async-reads the first 13 bytes and decodes the Logical Screen Descriptor (signature `GIF87a`/`GIF89a`, then 2-byte width, 2-byte height, packed field for color resolution).
  - `webp_header.dart` — async-reads the first ~30 bytes (RIFF/WEBP), dispatches on chunk header (`VP8 `, `VP8L`, `VP8X`) to read width/height and decide alpha presence.
- Replace `readGeneric` with a small dispatch in `ReadImageHeaders.readImageDeterminingBest` that picks one of the four header-only readers by extension. Drop the `package:image` dependency from the header read path entirely; the `image` package decode is no longer involved in scanning.
- Each new reader returns the existing `ImageHeader(width, height, bitDepth, numChannels)` with values that match what the previous `package:image` decode would have produced — bit-for-bit equality is not required, but VRAM totals MUST be unchanged for any mod that scanned successfully before this change. Parity is enforced by tests.
- Failure handling stays identical: a malformed file throws inside the per-format reader, `_processAssets` catches and logs "Skipped non-image" (same as today). No new "skipped" reasons.
- Drop `package:image` from `pubspec.yaml` IF no other call site uses it after this change. (If other features still depend on it, keep the dependency; the change only removes its use from the scanner.)

## Capabilities

### New Capabilities
<!-- None — this hardens an existing capability. -->

### Modified Capabilities
- `vram-estimator`: adds a requirement that per-asset header reads SHALL be header-only (bounded read size) and SHALL use async file I/O on the calling isolate, and SHALL produce the same `(width, height, bitDepth, numChannels)` tuple — for the purpose of VRAM byte calculation — that the prior `package:image` decode produced.

## Impact

- **Affected code**
  - `lib/vram_estimator/image_reader/png_chatgpt.dart` — async-ify the open + read.
  - `lib/vram_estimator/image_reader/image_reader_async.dart` — replace `readGeneric` with a per-extension dispatch; remove `package:image` import.
  - New: `lib/vram_estimator/image_reader/jpeg_header.dart`, `gif_header.dart`, `webp_header.dart`.
  - `pubspec.yaml` — possibly drop `image:` from `dependencies` (gated on no other in-tree use).
  - `test/vram_estimator/image_reader/` — new fixture-driven tests asserting the four readers produce the same `ImageHeader` as the pre-change `package:image` path on a representative corpus, including:
    - vanilla-sized PNG sprites (24-bit and 32-bit)
    - large JPG backgrounds (4K and 8K)
    - palette PNGs (color type 3)
    - grayscale PNGs (color type 0 / 4)
    - animated and static GIFs
    - lossy WEBP (`VP8 `), lossless WEBP (`VP8L`), extended WEBP (`VP8X` with and without alpha)
    - intentionally-truncated and intentionally-malformed files of each format (assert: throws, doesn't hang or read whole file)
- **APIs / contracts**
  - Internal only. `ImageHeader` shape is unchanged. `ReadImageHeaders` public surface is unchanged. Cache format is unchanged — `ModImageTable` rows depend only on the four ImageHeader integers, which retain their existing meaning.
- **Dependencies**
  - Possibly removes `image: ^…` from `pubspec.yaml` (subject to grep for other call sites). No new dependencies.
- **Performance**
  - Eliminates per-asset multi-MB sync reads and multi-MB cross-isolate memcpys on JPG/GIF/WEBP. Eliminates per-asset full image decode. Async I/O lets the renderer get a frame every time `await` yields. Net effect on a Kaleidoscope-shaped mod (107 assets, many big JPG backgrounds): expected drop from ~50 s of wall-clock header-read phase to sub-second, with no UI freeze.
- **Risk / known imprecision**
  - Per-format header parsers may compute `bitDepth` / `numChannels` slightly differently than `package:image` for unusual files (e.g. a GIF with a local color table whose effective channel count `package:image` reports as 4 vs. 3). The proposal calibrates each parser against the package's output via a fixture corpus and treats deviation as a bug to be fixed before merge. Where a benign deviation is unavoidable (rare exotic encodings), the spec requires VRAM-byte parity rather than tuple-byte parity — i.e. the divergent file must round to the same per-image byte total under `ModImageView.bytesUsed`.
  - Truncated or corrupt files MUST throw rather than read indefinitely. Each parser SHALL bound its read to the format's maximum reasonable header span (e.g. 64 KB for JPEG) and throw on overrun.
  - This change does NOT address the multithreaded-mode-specific main-isolate hot spots (the per-asset channel-message flood from workers, the 174-task upfront serialization, the chart rebuild on every flush). Those are real but separate; they get their own change once this one lands and we re-measure.
