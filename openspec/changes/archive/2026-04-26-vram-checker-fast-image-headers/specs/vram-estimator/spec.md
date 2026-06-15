<!--
This delta hardens an existing capability: per-asset image header reading,
which today silently performs synchronous file I/O and full-file decode on
the calling isolate. It is selector-independent (applies to FolderScanSelector
and ReferencedAssetsSelector identically) and orthogonal to the in-flight
`vram-checker-optional-multithreading` change — both can land in either order.
-->

## ADDED Requirements

### Requirement: Image header reads SHALL use bounded async file I/O

Every per-asset image header read performed by the VRAM scanner SHALL use asynchronous file I/O (`File.open()` + `RandomAccessFile.read(...)`) on the calling isolate, and SHALL read no more than a small bounded prefix of the file. No synchronous file I/O call (`openSync`, `readSync`, `readAsBytesSync`, `readAsStringSync`, etc.) SHALL appear in the image-header read path. No reader SHALL read the entire file. Per-format read caps:

- **PNG**: at most 33 bytes (signature + IHDR length + IHDR type + IHDR content).
- **GIF**: at most 13 bytes (signature + Logical Screen Descriptor).
- **WEBP**: at most 32 bytes (RIFF + WEBP + first chunk header + first chunk body up to size fields).
- **JPEG**: at most 65,536 bytes (4 KB initial read, bounded segment-skip up to a 64 KB total cap; reader throws on cap overrun).

#### Scenario: PNG header read does not block the calling isolate
- **WHEN** `readPngFileHeaders` is called on a 100 MB PNG (artificially large)
- **THEN** the call SHALL read at most 33 bytes from disk, SHALL complete its read step via `await raf.read(...)` (not `readSync`), and SHALL NOT load the file's contents into memory beyond the 33-byte prefix

#### Scenario: JPEG header read does not load the whole file
- **WHEN** `readJpegFileHeaders` is called on a 50 MB JPEG background
- **THEN** the call SHALL read at most 64 KB from disk, SHALL complete every read step via `await raf.read(...)`, and SHALL return the dimensions parsed from the first SOF marker encountered

#### Scenario: JPEG with no SOF within the cap throws
- **WHEN** `readJpegFileHeaders` is called on a malformed file whose markers chain past the 64 KB cap without an SOF
- **THEN** the call SHALL throw an exception within the cap (it SHALL NOT read further, SHALL NOT hang) and the surrounding `_processAssets` try/catch SHALL log the file as skipped, identical to existing behavior for non-image files

#### Scenario: Truncated file of any format throws
- **WHEN** any of the per-format readers is called on a file truncated to fewer bytes than the format's required header
- **THEN** the reader SHALL throw an exception (it SHALL NOT hang, SHALL NOT return a partial header)

#### Scenario: Synchronous I/O is not present in the header read path
- **WHEN** the project is grepped under `lib/vram_estimator/image_reader/` for `openSync`, `readSync`, `readAsBytesSync`, `readAsStringSync`
- **THEN** there SHALL be zero matches

### Requirement: Image header reads SHALL not invoke full image decode

The header read path SHALL NOT invoke any full image decoder. Specifically, `package:image`'s `Command()..decodeNamedImage(...).executeThread()` SHALL NOT be called from the VRAM scanner. Each supported format SHALL be read by a header-only parser dedicated to that format.

#### Scenario: package:image is not invoked during a scan
- **WHEN** a VRAM scan runs end-to-end against any selector and any mod
- **THEN** no call to `img.Command`, `img.decodeNamedImage`, `executeThread`, or any other `package:image` decode entry point SHALL occur as part of the per-asset header read

#### Scenario: Each supported format has a dedicated header reader
- **WHEN** an asset is dispatched to a header reader by `ReadImageHeaders.readImageDeterminingBest`
- **THEN** the dispatcher SHALL select exactly one of the per-format readers (`readPngFileHeaders`, `readJpegFileHeaders`, `readGifFileHeaders`, `readWebpFileHeaders`) based on file extension, and that reader SHALL parse the format's on-disk header structure directly without invoking any third-party decoder

### Requirement: VRAM byte totals SHALL be preserved across the change

For every mod whose scan succeeded prior to this change, the post-change scan SHALL produce the same `bytesNotIncludingGraphicsLib()` total. The `ImageHeader(width, height, bitDepth, numChannels)` tuple emitted per file MAY differ from the pre-change value in narrow cases where an on-disk header field cannot be derived from the bytes alone (e.g. a GIF's effective channel count post palette-expansion); in such cases the per-image `ModImageView.bytesUsed` SHALL still match the pre-change value.

#### Scenario: Mod totals do not change
- **WHEN** a Starsector mod folder containing a representative mix of PNG, JPG, GIF, and WEBP assets is scanned before and after this change with the same selector
- **THEN** the post-change scan's `bytesNotIncludingGraphicsLib()` for every mod SHALL equal the pre-change value (computed from the same on-disk inputs)

#### Scenario: Documented tuple deviation still produces equal bytes
- **WHEN** a fixture file is identified during testing where the new header reader produces a different `(width, height, bitDepth, numChannels)` tuple than the pre-change `package:image` decode produced
- **THEN** the fixture's `ModImageView.bytesUsed` SHALL be equal under both tuples, AND the deviation SHALL be documented in a code comment on the relevant test case citing the format-spec section that justifies it

## MODIFIED Requirements

### Requirement: ImageHeader retains its existing shape and semantics

The `ImageHeader` class SHALL retain its four fields (`width`, `height`, `bitDepth`, `numChannels`) and their existing semantics for VRAM byte calculation. The class SHALL continue to be the single value returned by every header reader. The header readers SHALL populate every field; no field SHALL be left at a sentinel value.

#### Scenario: Every reader populates every field
- **WHEN** any of the per-format header readers returns a non-null `ImageHeader`
- **THEN** all four fields SHALL be populated with values consistent with the file's format-spec contents (or the format's documented constants in the GIF/WEBP cases where on-disk fields are not the right abstraction for `numChannels`)
