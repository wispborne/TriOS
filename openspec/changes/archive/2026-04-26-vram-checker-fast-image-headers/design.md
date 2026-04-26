## Context

Both `VramChecker.check()` paths — the single-isolate path inside `_checkSingleIsolate` and the worker-isolate path inside `VramScanTask.run` — eventually call `scanOneMod`, which for every selected asset awaits `imagePool.readImageDeterminingBest(file.path)`. That call dispatches on extension to one of two functions in `lib/vram_estimator/image_reader/`:

- `readPngFileHeaders` — claims to be a fast header-only reader, but is implemented with **synchronous** `File.openSync()` + `RandomAccessFile.readSync(...)`.
- `readGeneric` — reads the **entire file** synchronously via `File.readAsBytesSync()`, then ships those bytes into `package:image`'s `Command`/`executeThread()` decode pipeline, which copies them into a worker isolate, runs a full image decode, and returns dimensions extracted from the decoded image.

In single-threaded VRAM-checker mode the calling isolate is main, so every sync read pins the event loop and starves the renderer. In multi-threaded mode the calling isolate is a worker, so main is spared the I/O — but the worker still does multi-megabyte reads + cross-isolate memcpy + full decode for every JPG asset, so wall-clock per-mod time is huge and the bytes-per-asset workload also feeds a port-message flood back to main. The freeze symptom on background-heavy mods (Kaleidoscope, Darksector) is the union of these effects; the two readers are the common bottleneck.

The image-decode pipeline only needs four integers per file: `width`, `height`, `bitDepth`, `numChannels`. All four formats Starsector mods ship — PNG, JPEG, GIF, WEBP — encode those values in well-defined header structures within the first few hundred bytes (KB at most for JPEG with thumbnail/EXIF). Reading those bytes is enough.

## Goals / Non-Goals

**Goals:**
- Eliminate every synchronous file I/O call on the calling isolate during VRAM scanning.
- Eliminate per-asset full-file reads. No reader SHALL read more than a small bounded prefix of the file (define per format).
- Eliminate the `package:image` decode call from the scanning hot path.
- Preserve VRAM totals for every mod that scanned successfully before this change. The (width, height, bitDepth, numChannels) tuple MAY differ in unusual cases, but `ModImageView.bytesUsed` MUST land on the same value for every file in the parity corpus.
- Keep the failure surface unchanged: malformed files still get caught by `_processAssets`'s try/catch and logged as skipped.

**Non-Goals:**
- Address the multithreaded-mode-specific main-isolate freezes (channel pump tightness, upfront task serialization, chart rebuild on every flush). Tracked separately.
- Address the cost of `JarStringReferences` per-jar `Isolate.run` spawns. Separate concern.
- Speed up the parsers in `ReferencedAssetsSelector`. Separate concern.
- Add new image formats. Mods don't ship anything beyond PNG/JPG/GIF/WEBP today; if that changes, a new reader file is the diff.
- Replace `package:image` everywhere in the project. Only the scanner's call site is in scope; if other features still depend on it, the dependency stays.

## Decisions

### 1. One reader per format, dispatched by extension

**Decision:** Add `jpeg_header.dart`, `gif_header.dart`, `webp_header.dart` next to the existing `png_chatgpt.dart`. Each exports a single async function `Future<ImageHeader?> read{Png,Jpeg,Gif,Webp}FileHeaders(String path)`. `ReadImageHeaders.readImageDeterminingBest` becomes a five-line extension switch.

**Rationale:** Per-format parsers are short (each well under 100 lines for the header-only subset), independently testable, and easy to diff against the format spec. A single "smart" reader that walks-then-dispatches by magic bytes adds complexity for no gain — extensions in mod folders are reliable, and `_isImage` already filters by extension before this code runs.

**Alternatives considered:**
- Keep `package:image` and just feed it an async-read prefix instead of the whole file. Rejected: the package's API doesn't expose "decode header only" cleanly, and we would still pay the worker-isolate hop and decode setup cost per file.
- Find a third-party "image-size" Dart package. Rejected: adding a dependency for ~300 lines of well-specified code that we can write inline, with a mostly-unmaintained candidate set on pub.dev.

### 2. Async I/O via `RandomAccessFile`

**Decision:** Every reader uses `await File.open(...)` to obtain a `RandomAccessFile`, then `await raf.read(N)` for bounded prefix reads, with a `try { ... } finally { await raf.close(); }` close. No `*Sync` calls anywhere in the new readers. Existing `readPngFileHeaders` is converted in place.

**Rationale:** This is the single-line change that eliminates the freeze. `RandomAccessFile.read` returns control to the event loop while the OS does the actual I/O; even hundreds of concurrent calls fan out cooperatively rather than blocking the isolate.

**Alternatives considered:**
- `File.openRead(start: 0, end: N).fold(...)`. Rejected: more complex for a fixed-size prefix, and the Stream layer is overkill when we know the byte count up front.
- `compute(...)` / `Isolate.run` per file. Rejected: spawning an isolate per asset is far more expensive than the read it's offloading. The async I/O + a properly-bounded read does the job without isolate gymnastics.

### 3. Bounded read sizes per format

**Decision:**

| Format | Initial read | Cap on additional reads | Why |
|--------|-------------:|------------------------:|-----|
| PNG    | 33 bytes (signature + IHDR length + IHDR type + IHDR content) | 0 | IHDR is the first chunk and is fixed-size. |
| GIF    | 13 bytes (header + Logical Screen Descriptor) | 0 | Dimensions are at fixed offset 6. |
| WEBP   | 30 bytes (RIFF + WEBP + first chunk header + first chunk body up to size fields) | 0 | All three sub-formats encode dimensions within the first chunk. |
| JPEG   | 4 KB initial, then bounded segment-skip up to **64 KB total** | 64 KB | EXIF / JFIF / thumbnail segments precede SOF; pathological files with a giant APP1 (EXIF) thumbnail can push SOF past the first KB but never past 64 KB in any sane file. |

**Rationale:** Hard caps make truncated/corrupt files fail predictably rather than degenerating into "read until EOF" on a 50 MB file. The 64 KB JPEG cap is conservative for sprites and backgrounds; if a real-world Starsector mod ships a JPG whose SOF is past 64 KB it almost certainly has an embedded camera-RAW thumbnail and is misuse.

**Alternatives considered:**
- Read the whole file unbounded into memory (today's behavior). Rejected — that's the bug.
- Memory-map. Rejected: the per-format prefixes are small enough that mmap setup cost dominates the savings, and Dart's mmap support on Windows has quirks.

### 4. ImageHeader parity vs. VRAM-byte parity

**Decision:** Parity tests assert two things: (a) for the corpus of test fixtures, the new readers produce the **exact same** `ImageHeader(width, height, bitDepth, numChannels)` as `package:image` produced for the same file; (b) for any case where (a) cannot be satisfied — e.g. a GIF where the package reported `numChannels=4` after expanding the palette and our header reader sees `numChannels=1` from the LSD packed field — the test instead asserts that `ModImageView.bytesUsed` rounds to the same value, given the existing power-of-two multiplier and channel-bit math.

**Rationale:** The user-visible contract is the byte estimate. The intermediate ImageHeader is internal and only matters as an input to that estimate. Holding the ImageHeader bit-for-bit invariant is a stricter goal than the user actually needs and would force us to replicate idiosyncratic decoder behavior. Asserting VRAM-byte equivalence captures the actual user-facing guarantee. We aim for tuple-byte parity first because it's a clearer signal, and only fall back to byte-equivalence on inputs where the package itself is making a decode-time choice that a header reader can't see.

**Alternatives considered:**
- Strict tuple-byte parity, no fallback. Rejected: would force the GIF reader to e.g. peek at GCT presence to recover the package's `numChannels=4` choice, which is decode-aware information not present in the LSD; arbitrary complexity for an internal field.
- Skip parity tests, trust the format spec. Rejected: too easy to drift from real-world VRAM totals; a fixture corpus is cheap insurance.

### 5. JPEG: which SOF markers to recognize, what to do with progressive

**Decision:** Recognize SOF0–SOF15 except SOF4 (DHT), SOF8 (JPG reserved), SOF12 (DAC) — i.e. every Start-Of-Frame marker the spec actually defines for a frame. For all of them the segment layout is `precision(1) height(2) width(2) components(1)`, regardless of baseline / extended / progressive / lossless. So the reader produces dimensions from the first SOF it encounters, regardless of which one it is. `bitDepth = precision`; `numChannels = components`.

**Rationale:** The on-disk header layout is uniform across SOF variants — only the decoder cares which one it is. We're a header reader, not a decoder.

**Alternatives considered:**
- Recognize only SOF0/SOF2 (the common ones). Rejected: any file using a less-common variant would bounce to the failure path and get logged as "non-image", silently shrinking the VRAM total. Cheap to support all of them.

### 6. WEBP: handle VP8/VP8L/VP8X uniformly

**Decision:** After reading the RIFF + WEBP header, branch on the FourCC of the first chunk:

- `VP8 ` (lossy) — width and height are 14-bit fields starting at byte 6 of the VP8 bitstream. Read the chunk's first 10 bytes, decode the start code, decode dims.
- `VP8L` (lossless) — bytes 1–4 of the chunk body are a packed `(width-1):14, (height-1):14, alpha:1, version:3`. Read 5 bytes of the chunk body, unpack.
- `VP8X` (extended) — bytes 4–9 of the chunk body are 24-bit `width-1` and 24-bit `height-1`. Bit 4 of the first body byte is alpha. Read 10 bytes, unpack.

`bitDepth = 8` always for WEBP (the format is fixed at 8 bits per channel); `numChannels = 4` if alpha is present, else `3`.

**Rationale:** WEBP is fragmented across three sub-formats but every container starts the same way and every sub-format encodes width/height in its first chunk. One reader handles all three with a small dispatch.

**Alternatives considered:**
- Only support VP8X. Rejected: lossy `VP8 ` and lossless `VP8L` are common; rejecting them for header-read reasons would silently shrink VRAM totals for any mod using them.

### 7. GIF: `numChannels` choice

**Decision:** Report `bitDepth = 8`, `numChannels = 4`. Do NOT consult the LSD packed field's "color resolution" bits.

**Rationale:** Every GIF rendered for VRAM-counting purposes will be displayed by the engine as RGBA (the engine doesn't read the on-disk palette and emit indexed textures to the GPU). The original `package:image` path returns `numChannels=4` for GIFs because that's what the decoded surface looks like. Hard-coding 4 here matches that and keeps VRAM totals identical. The packed-field "color resolution" is a palette-bit-depth artifact, not a channel count, and using it would give wrong numbers.

**Alternatives considered:**
- Read the packed field, derive channel count from palette bits. Rejected per the above — wrong abstraction.

### 8. PNG: keep the existing IHDR-driven channel decode

**Decision:** Async-ify the I/O but otherwise leave `readPngFileHeaders` alone. The existing color-type → channels switch (`0→1, 2→3, 3→1, 4→2, 6→4`) matches what `package:image` reports for PNGs, including indexed (color type 3) files which the package treats as 1-channel until it expands the palette.

**Rationale:** PNG is the well-tested path today. The freeze fix is the I/O change; keep parsing untouched.

### 9. Drop `package:image` from the scanner

**Decision:** Remove the `import 'package:image/image.dart' as img;` from `image_reader_async.dart` and remove the `Command()..decodeNamedImage(...).executeThread()` call entirely. If a grep for `package:image` across `lib/` returns no other use, also remove the dependency from `pubspec.yaml`.

**Rationale:** The decode call was the entire reason `readGeneric` looked async-friendly; replacing it with header parsers means we no longer need the package for scanning. Keeping it would invite drift back into the slow path. If other features (image preview, mod card thumbnails) use the package, the dependency stays — only the scanner's import is removed.

**Alternatives considered:**
- Keep the package as a generic fallback for unknown files. Rejected: today there is no "unknown" — the four extensions are filtered upstream by `_isImage`. A fallback would re-introduce the slow path under the most ambiguous condition.

## Risks / Trade-offs

- **Per-format reader correctness drift over time** → Locked down by a fixture corpus (sample files of each format / sub-format / encoding) plus a parity assertion against `package:image`'s output captured at change time. Future image-format weirdness gets a fixture and a test.
- **JPEG segment-skip can hit the 64 KB cap on a mod with embedded EXIF thumbnails** → File is treated as a read failure and skipped, exactly as a malformed file is today. We log the path so users can spot it. Real-world mod sprites do not embed thumbnails; if a future case appears, raise the cap.
- **WEBP VP8L bit-packing decode is fiddly** → Mitigated by a fixture-driven test that covers VP8L specifically. The code path for VP8L is the smallest of the three WEBP variants and has a single clearly-specified bit layout.
- **`package:image` dependency removal** → Gated on a grep audit; if any other call site exists the dependency stays. The change has no observable effect on those other call sites.
- **Multi-threaded scan still freezes after this change** → Possible. The mode-specific causes (channel pump, upfront serialization, chart rebuild) are independent of the image header path. After this change lands and we re-measure, the residual freeze (if any) gets its own change with its own design. Calling that out as out-of-scope here keeps the fix focused.
