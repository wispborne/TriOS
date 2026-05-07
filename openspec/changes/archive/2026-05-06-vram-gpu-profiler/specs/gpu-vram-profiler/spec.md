## ADDED Requirements

### Requirement: Console command trigger
The companion mod SHALL provide a Console Commands command named `TriOS_ProfileVram` that triggers a VRAM profiling scan. Console Commands is a soft dependency — the command class SHALL be unused if Console Commands mod is not installed.

#### Scenario: Command invoked
- **WHEN** the user runs `TriOS_ProfileVram` in the Console Commands console
- **THEN** the profiler SHALL execute a full VRAM scan and write results to saves/common

#### Scenario: Console Commands not installed
- **WHEN** Console Commands mod is not installed
- **THEN** the command class SHALL never be loaded and SHALL cause no errors

### Requirement: Enumerate all loaded textures
The profiler SHALL enumerate all textures currently loaded in the game's `TextureLoader` cache, including textures from all enabled mods and vanilla.

#### Scenario: Successful enumeration via MethodHandle reflection
- **WHEN** a scan is initiated
- **THEN** the profiler SHALL use MethodHandle-based reflection (bypassing the game engine's classloader restrictions) to access the `TextureLoader` instance from `Global.getSettings()` (by field type), locate its `HashMap` getter (by return type), and iterate all entries to obtain resource paths and GL texture IDs

#### Scenario: Reflection failure
- **WHEN** MethodHandle-based reflection cannot locate the `TextureLoader` or its HashMap
- **THEN** the profiler SHALL log a warning with the failure reason and write a results file containing an error field instead of texture data

### Requirement: Query GPU texture properties
For each enumerated texture, the profiler SHALL bind the texture and query OpenGL for actual GPU-side storage properties.

#### Scenario: Standard texture query
- **WHEN** a texture with a valid GL ID is bound
- **THEN** the profiler SHALL query `glGetTexLevelParameteri` at mip level 0 for: `GL_TEXTURE_WIDTH`, `GL_TEXTURE_HEIGHT`, `GL_TEXTURE_INTERNAL_FORMAT`, `GL_TEXTURE_RED_SIZE`, `GL_TEXTURE_GREEN_SIZE`, `GL_TEXTURE_BLUE_SIZE`, `GL_TEXTURE_ALPHA_SIZE`

#### Scenario: Mipmap level detection
- **WHEN** querying a texture's mipmap chain
- **THEN** the profiler SHALL probe successive mip levels (1, 2, 3, ...) by querying `GL_TEXTURE_WIDTH` until the returned width is 0, and record the total number of mipmap levels

#### Scenario: Per-texture VRAM computation
- **WHEN** all mip levels have been queried for a texture
- **THEN** the profiler SHALL compute total GPU bytes as the sum of `(width × height × bitsPerPixel / 8)` for each mip level

### Requirement: Dump forceMipmapsFor set
The profiler SHALL include the contents of the `TextureLoader`'s `forceMipmapsFor` static set in the output, so that forced-mipmap overrides are visible for diagnostic purposes.

#### Scenario: Force-mipmap set access
- **WHEN** a scan is initiated
- **THEN** the profiler SHALL read the `Set<String>` field on `TextureLoader` via MethodHandle reflection (identified by field type: `Set`) and include its contents in the output

### Requirement: Chunked JSON output to saves/common
The profiler SHALL write scan results as JSON to saves/common, chunked to respect the 1MB file size limit of `writeTextFileToCommon()`.

#### Scenario: Output within single chunk
- **WHEN** the total JSON output is under 900KB
- **THEN** the profiler SHALL write a single file `trios_vram_results_0` and a manifest file `trios_vram_manifest` containing chunk count 1

#### Scenario: Output exceeds single chunk
- **WHEN** the total JSON output exceeds 900KB
- **THEN** the profiler SHALL split the textures array across numbered files (`trios_vram_results_0`, `trios_vram_results_1`, ...) each under 900KB, and write a manifest with the chunk count

#### Scenario: Output JSON structure per chunk
- **WHEN** results are written
- **THEN** each chunk SHALL contain a JSON object with a `textures` array where each entry includes: `path` (String), `glTextureId` (int), `gpuWidth` (int), `gpuHeight` (int), `internalFormat` (int), `internalFormatName` (String), `redBits` (int), `greenBits` (int), `blueBits` (int), `alphaBits` (int), `bitsPerPixel` (int), `mipmapLevels` (int), `totalBytes` (long), `level0Bytes` (long)

#### Scenario: Manifest structure
- **WHEN** the manifest file is written
- **THEN** it SHALL contain a JSON object with: `gameVersion` (String), `scanTimestamp` (ISO-8601 String), `totalGpuBytes` (long), `textureCount` (int), `chunkCount` (int), `forcedMipmapPaths` (String array)

### Requirement: Command feedback
The console command SHALL provide feedback to the user about scan progress and results.

#### Scenario: Successful scan
- **WHEN** the scan completes successfully
- **THEN** the command SHALL print a summary to the console including texture count, total GPU bytes (in MB), and output file location

#### Scenario: Error during scan
- **WHEN** an error occurs during the scan
- **THEN** the command SHALL print the error message to the console and log the full stack trace
