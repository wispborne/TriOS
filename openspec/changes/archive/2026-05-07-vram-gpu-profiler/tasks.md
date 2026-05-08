## 1. Build Setup

- [x] 1.1 Add Console Commands JAR to the companion mod's compile classpath (soft dependency — only needed at compile time for the `BaseCommand` import)
- [x] 1.2 Create `data/console/commands.csv` in the companion mod's assets to register the `TriOS_ProfileVram` command

## 2. Core Profiler Logic

- [x] 2.0 Create `ReflectionUtil.java` — copy the MethodHandle-based reflection bypass from MagicLib (LGPL-3.0, credit Starficz et al.): load `java.lang.reflect.Field/Method` via bootstrap classloader (`Class.class.getClassLoader()`), create MethodHandles for get/set/invoke/getType/getName/setAccessible. Only implement the subset needed: get declared fields by type, invoke no-arg methods by return type.
- [x] 2.1 Create `VramProfiler.java` — use `ReflectionUtil` to walk `Global.getSettings()` fields and find the one of type `com.fs.graphics.TextureLoader`
- [x] 2.2 In `VramProfiler`, use `ReflectionUtil` to find the `HashMap`-returning no-arg getter on `TextureLoader`, and the `int`-returning no-arg getter on texture wrapper objects for GL texture IDs
- [x] 2.3 In `VramProfiler`, implement per-texture GL query: bind texture, query `glGetTexLevelParameteri` at level 0 for width, height, internal format, RGBA bit sizes
- [x] 2.4 In `VramProfiler`, implement mipmap level probing: query successive levels until width returns 0, sum VRAM across all levels
- [x] 2.5 In `VramProfiler`, implement `forceMipmapsFor` set extraction: find the public static `Set<String>` field on `TextureLoader`
- [x] 2.6 In `VramProfiler`, add GL internal format name mapping (e.g., 32856 → "GL_RGBA8") for human-readable output

## 3. Output

- [x] 3.1 In `VramProfiler`, implement JSON output building: per-texture objects with path, glTextureId, gpuWidth, gpuHeight, internalFormat, internalFormatName, redBits, greenBits, blueBits, alphaBits, bitsPerPixel, mipmapLevels, totalBytes, level0Bytes
- [x] 3.2 In `VramProfiler`, implement chunked output: split textures array across files each under 900KB, write via `writeTextFileToCommon()`
- [x] 3.3 In `VramProfiler`, implement manifest output: gameVersion, scanTimestamp, totalGpuBytes, textureCount, chunkCount, forcedMipmapPaths array

## 4. Console Command

- [x] 4.1 Create `TriOS_ProfileVram.java` implementing Console Commands' `BaseCommand` — calls `VramProfiler.scan()`, prints summary (texture count, total MB, output location) to console
- [x] 4.2 Handle errors: catch exceptions from profiler, print error to console, log full stack trace

## 5. Build and Package

- [x] 5.1 Compile the companion mod JAR with the new classes
- [x] 5.2 Update `assets/common/TriOS-Mod/` with the new JAR and `data/console/commands.csv`
