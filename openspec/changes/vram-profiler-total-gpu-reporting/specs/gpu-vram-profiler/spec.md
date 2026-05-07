## ADDED Requirements

### Requirement: Query total GPU memory via vendor extensions
The profiler SHALL attempt to obtain an estimate of total GPU memory in use by querying NVIDIA/AMD OpenGL extensions exposed by the active driver. The result SHALL be included in the manifest alongside the existing texture-cache total. When no supported extension is present, the profiler SHALL omit the GPU-total fields rather than fabricate a value.

#### Scenario: NVIDIA driver with GL_NVX_gpu_memory_info available
- **WHEN** a scan runs and the GL extension string contains `GL_NVX_gpu_memory_info`
- **THEN** the profiler SHALL query `GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX` (0x9047) and `GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM_NVX` (0x9049), compute used bytes as `(dedicated − available) × 1024` (the queries return KB), and record the result with `gpuMemoryProvider: "NVX"`

#### Scenario: AMD driver with GL_ATI_meminfo available
- **WHEN** a scan runs, the NVX extension is absent, and the GL extension string contains `GL_ATI_meminfo`
- **THEN** the profiler SHALL query `TEXTURE_FREE_MEMORY_ATI` (0x87FC), record the available memory, derive a used-bytes estimate if the dedicated total is obtainable, and record `gpuMemoryProvider: "ATI"` with a `gpuMemoryNote` describing how AMD reports available memory

#### Scenario: No supported extension
- **WHEN** neither `GL_NVX_gpu_memory_info` nor `GL_ATI_meminfo` is present
- **THEN** the profiler SHALL set `gpuMemoryProvider: "none"`, leave `gpuMemoryTotalUsedBytes` and `gpuMemoryDedicatedBytes` absent or null in the manifest, and continue the scan with texture-cache reporting unchanged

#### Scenario: Driver returns implausible values
- **WHEN** an extension query returns a value that is negative or exceeds 64 GB
- **THEN** the profiler SHALL log a warning, treat the provider as if unavailable, and write `gpuMemoryProvider: "none"`

#### Scenario: Extension query throws
- **WHEN** an extension query throws an exception (driver bug, context lost, etc.)
- **THEN** the profiler SHALL catch the exception, log a single warning, treat the provider as unavailable, and complete the rest of the scan normally

## MODIFIED Requirements

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
- **THEN** it SHALL contain a JSON object with the following always-present fields: `gameVersion` (String), `scanTimestamp` (ISO-8601 String), `totalGpuBytes` (long, texture-cache-only sum), `textureCount` (int), `chunkCount` (int), `forcedMipmapPaths` (String array), `gpuMemoryProvider` (String, one of `"NVX"`, `"ATI"`, `"none"`); and the following optional fields, present only when a vendor extension supplied them: `gpuMemoryTotalUsedBytes` (long), `gpuMemoryDedicatedBytes` (long), `gpuMemoryNote` (String)

#### Scenario: Manifest preserves backward-compatible meaning of totalGpuBytes
- **WHEN** the manifest is read by an older Dart client that does not know about `gpuMemoryTotalUsedBytes`
- **THEN** the `totalGpuBytes` field SHALL retain its existing meaning (texture-cache sum) so the older client continues to display correctly

### Requirement: Command feedback
The console command SHALL provide feedback to the user about scan progress and results.

#### Scenario: Successful scan with vendor extension available
- **WHEN** the scan completes successfully and `gpuMemoryProvider` is `"NVX"` or `"ATI"`
- **THEN** the command SHALL print a summary including: texture count, texture-cache MB, total GPU MB, derived engine-overhead MB (`total − texture cache`), the provider name, and the output file location

#### Scenario: Successful scan without vendor extension
- **WHEN** the scan completes successfully and `gpuMemoryProvider` is `"none"`
- **THEN** the command SHALL print a summary including: texture count, texture-cache MB, output file location, and a one-line note that total GPU memory is unavailable on this driver

#### Scenario: Error during scan
- **WHEN** an error occurs during the scan
- **THEN** the command SHALL print the error message to the console and log the full stack trace
