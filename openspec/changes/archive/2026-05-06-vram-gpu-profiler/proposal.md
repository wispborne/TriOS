## Why

TriOS's VRAM Estimator computes GPU memory from image file headers and heuristic rules. Investigation of the decompiled game `TextureLoader` (`fs.common_obf.jar`) revealed the estimator's mipmap threshold is type-based (background vs sprite) when the game's is dimension-based (≤1024px), and non-alpha textures are under-counted because the game always uses `internalFormat=GL_RGBA` (4 bytes/pixel on GPU regardless of alpha). We need ground truth from the GPU to validate and correct the estimation logic.

## What Changes

- Extend the existing TriOS Companion Mod (`TriOS-Companion-Mod/`) with an on-demand VRAM profiler that queries OpenGL for every loaded texture's actual GPU storage properties.
- Add a Console Commands mod command (`TriOS_ProfileVram`) that triggers the profiler scan. Console Commands is a soft dependency — the command class is simply unused if the mod isn't installed.
- Profiler enumerates all loaded textures via a MethodHandle-based reflection bypass (technique copied from MagicLib's `ReflectionUtils`, since standard Java reflection is blocked by the game engine) into `TextureLoader`'s internal `HashMap`, binds each texture, and queries `GL11.glGetTexLevelParameteri` for width, height, internal format, bits per channel, and mipmap level count.
- Also dumps the `forceMipmapsFor` set (public static field on `TextureLoader`) so forced-mipmap overrides are visible.
- Output is chunked JSON (≤900KB per file) written via `writeTextFileToCommon()`, containing per-texture GPU VRAM data with resource paths for mod-level grouping.

## Capabilities

### New Capabilities
- `gpu-vram-profiler`: On-demand in-game GPU texture profiler that queries OpenGL state for all loaded textures and writes per-texture VRAM data to saves/common for consumption by the TriOS Flutter app.

### Modified Capabilities

(none)

## Impact

- **Code**: New Java classes added to `TriOS-Companion-Mod/src/wisp/trios/` — `VramProfiler.java` (core logic) and `TriOS_ProfileVram.java` (Console Commands command). No changes needed to `TriosCompanionModPlugin.java`.
- **Dependencies**: Uses LWJGL 2 `GL11.glGetTexLevelParameteri` (already bundled with the game). Uses `org.json` (already available in the game runtime). Console Commands mod (soft dependency for the command trigger). No external mod dependencies for reflection — the MethodHandle bypass technique is copied from MagicLib (LGPL-3.0) into our own utility class.
- **APIs**: Uses `Global.getSettings().writeTextFileToCommon()` for output. Implements Console Commands' `BaseCommand` interface (soft dependency — class is never loaded if Console Commands mod is absent).
- **Systems**: No changes to the TriOS Flutter app in this change. Flutter-side consumption of results is future work.
