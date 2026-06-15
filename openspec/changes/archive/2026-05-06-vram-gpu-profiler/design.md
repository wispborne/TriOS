## Context

The TriOS Companion Mod is an existing Starsector mod (`TriOS-Companion-Mod/`) that ships as a JAR inside TriOS's assets and gets copied into the game's mods folder. It currently handles portrait replacement via direct OpenGL texture manipulation. The mod extends `BaseModPlugin` and runs during `onApplicationLoad()`, which fires after the game has eagerly loaded all ship, weapon, and projectile textures from all enabled mods.

The game's `TextureLoader` (in `fs.common_obf.jar`) maintains a private `HashMap<String, Object>` mapping resource paths to texture wrapper objects. Each wrapper holds a GL texture ID. The game uses LWJGL 2 for OpenGL, which provides `GL11.glGetTexLevelParameteri()` for querying GPU-side texture properties.

The game's `SettingsAPI` provides `writeTextFileToCommon()`/`readTextFileFromCommon()` for persisting data to `saves/common/{name}.data`, with a 1MB per-file limit. TriOS (Flutter) can read these files directly from the filesystem.

## Goals / Non-Goals

**Goals:**
- Query actual GPU texture storage properties (dimensions, format, bits/channel, mipmap levels) for every loaded texture in a running Starsector instance.
- Output per-texture data with resource paths so results can be matched against TriOS's file-based estimates and grouped by mod.
- Dump the `forceMipmapsFor` override set for diagnostic visibility.
- Run on-demand only, triggered by TriOS writing a file to saves/common.

**Non-Goals:**
- TriOS Flutter-side consumption/comparison UI (future work).
- Fixing the VRAM estimator's known bugs (separate change, informed by profiler data).
- Profiling non-texture GPU resources (VBOs, FBOs, shaders).
- Supporting the Console Commands mod as a trigger mechanism.

## Decisions

### 1. Texture enumeration via MethodHandle-based reflection

**Decision**: Copy the reflection bypass technique from MagicLib's `ReflectionUtils` (https://github.com/MagicLibStarsector/MagicLib/blob/dev/src/org/magiclib/ReflectionUtils.kt, LGPL-3.0) into our own utility class. Standard Java reflection is blocked by the game engine's custom classloader; the bypass loads `java.lang.reflect.Field/Method` via the **bootstrap classloader** and uses `MethodHandles` to invoke them.

**Why**: The `TextureLoader` HashMap is the only complete registry of all loaded textures with their resource paths. The public `SpriteAPI` has `getTextureId()` but no enumeration. `getSpriteKeys(category)` only covers categorized sprites, missing directly-loaded textures.

**The bypass technique** (from MagicLib, credited to Starficz, Lukas04, Lyravega, Float, Andylizi):
```java
// Load reflect classes via bootstrap classloader, bypassing game's restrictions
Class<?> fieldClass = Class.forName("java.lang.reflect.Field", false, Class.class.getClassLoader());
// Get MethodHandles for field operations
MethodHandle getFieldValue = MethodHandles.lookup().findVirtual(fieldClass, "get", ...);
MethodHandle getFieldType = MethodHandles.lookup().findVirtual(fieldClass, "getType", ...);
MethodHandle setAccessible = MethodHandles.lookup().findVirtual(fieldClass, "setAccessible", ...);
// Now use these handles to access any field on any object
```

We only need a small subset of MagicLib's full ReflectionUtils — just enough to:
1. Get declared fields of a class and read their types/values
2. Find and invoke no-arg methods by return type

**Approach**:
1. From `Global.getSettings()`, walk declared fields to find one whose type is `com.fs.graphics.TextureLoader`.
2. On the `TextureLoader`, find the no-arg method returning `HashMap` — this is the texture cache getter.
3. For each HashMap entry: key = resource path (String), value = texture wrapper object (`com.fs.graphics.Object`). Find the `int`-returning no-arg method that yields a positive value — that's the GL texture ID.

**No external dependencies** for reflection. The technique is self-contained.

### 2. GL queries per texture

**Decision**: For each texture, bind it and call `glGetTexLevelParameteri` at level 0 for dimensions, internal format, and per-channel bit sizes. Then probe levels 1, 2, ... until width returns 0 to count mipmap levels.

**Why**: This is the only way to get ground truth about GPU-side storage. The game's internal VRAM counter uses ByteBuffer capacity (CPU-side), which underestimates for RGB textures (3 bytes vs GPU's 4-byte RGBA).

**GL constants used** (all standard LWJGL 2 `GL11`):

| Query | Constant | Value |
|-------|----------|-------|
| Width | `GL_TEXTURE_WIDTH` | 0x1000 |
| Height | `GL_TEXTURE_HEIGHT` | 0x1001 |
| Internal format | `GL_TEXTURE_INTERNAL_FORMAT` | 0x1003 |
| Red bits | `GL_TEXTURE_RED_SIZE` | 0x805C |
| Green bits | `GL_TEXTURE_GREEN_SIZE` | 0x805D |
| Blue bits | `GL_TEXTURE_BLUE_SIZE` | 0x805E |
| Alpha bits | `GL_TEXTURE_ALPHA_SIZE` | 0x805F |

### 3. Trigger via Console Commands mod

**Decision**: Implement a Console Commands command (`TriOS_ProfileVram`) that runs the profiler synchronously when invoked. Console Commands is a soft dependency — the command class implements `BaseCommand` and is registered in `data/console/commands.csv`, but if Console Commands isn't installed the class is never loaded.

**Why**: Console Commands is the standard way to run on-demand operations in Starsector. The user explicitly triggers the scan, so there's no polling overhead. The command runs on the render thread (Console Commands executes commands on the main thread), which is required for GL calls.

**Alternatives considered**:
- *EveryFrameScript polling a trigger file*: Works without Console Commands but adds constant polling overhead and requires TriOS to write trigger files. More complex for no real benefit since Console Commands is near-universal among modders.
- *onApplicationLoad() only*: Requires game restart to re-scan. Too inflexible.

**Compilation**: The Console Commands JAR is needed on the compile classpath for the `BaseCommand` import. At runtime, if Console Commands is absent, Java never loads the command class so no `ClassNotFoundException` occurs.

### 4. Chunked JSON output

**Decision**: Write results as numbered chunks (`trios_vram_results_0.data`, `_1.data`, etc.) each under 900KB, plus a manifest file (`trios_vram_manifest.data`) with the chunk count and summary totals.

**Why**: `writeTextFileToCommon()` has a hard 1MB limit. A heavily-modded install can have 10,000+ textures at ~200 bytes/entry = ~2MB.

### 5. Synchronous scan on command execution

**Decision**: Run the full scan synchronously when the console command is invoked. The game is already paused while the console is open, so a brief stall (sub-second even for 10,000+ textures) is acceptable.

**Why**: `glGetTexLevelParameteri` is a cheap query — it reads driver metadata, not pixel data. Even 10,000 calls complete in well under a second. The added complexity of batching across frames isn't justified when the user is explicitly triggering from a console that pauses the game.

**Alternatives considered**:
- *Batched across frames*: Necessary if polling via EveryFrameScript during gameplay, but overkill for a console command that runs while the game is paused.

## Decompiled Game Code Reference

These findings come from decompiling `com.fs.graphics.TextureLoader` out of `fs.common_obf.jar` using vineflower. An implementing session should NOT need to re-read the decompiled code — everything needed is captured here.

### TextureLoader structure

```java
public class TextureLoader {
    // Texture cache: resource path → texture wrapper object
    private HashMap cache = new HashMap();           // the field we need
    public HashMap o00000() { return this.cache; }   // public getter (obfuscated name)

    // forceMipmapsFor set — textures forced to have mipmaps regardless of size
    public static Set<String> null = new LinkedHashSet<>();  // public static, obfuscated as "null"
}
```

The `TextureLoader` instance is reachable from `Global.getSettings()` — the settings implementation holds it as a field. Use `ReflectionUtils.getFieldsMatching` with `type = TextureLoader.class` to find it.

### Texture wrapper object (`com.fs.graphics.Object`)

Each HashMap value is a `com.fs.graphics.Object` with several `int`-returning no-arg methods. The GL texture ID is one of them. To identify it: call each `int`-returning method and pick the one returning a positive value that's also a valid GL texture name.

### How the game loads textures — the code that matters

**POT rounding** (starts at 2, doubles until >= dimension):
```java
private int roundToPOT(int dim) {
    int pot = 2;
    while (pot < dim) { pot *= 2; }
    return pot;
}
// Note: dim=1 → returns 2 (TriOS special-cases 1→1, which is wrong)
```

**Internal format is always GL_RGBA** — callers pass `6408` (GL_RGBA) as `internalFormat`:
```java
this.loadTexture(null, path, GL_TEXTURE_2D, /*internalFormat=*/6408, GL_LINEAR, GL_LINEAR, false);
//                                           ^^^^^^^^^^^^^^^^^^^^
// 6408 = 0x1908 = GL_RGBA → GPU stores RGBA8 (4 bytes/pixel) regardless of alpha
```

**Pixel format varies by alpha** (but this only affects CPU→GPU transfer, not GPU storage):
```java
if (image.getColorModel().hasAlpha()) {
    pixelFormat = 6408;  // GL_RGBA
} else {
    pixelFormat = 6407;  // GL_RGB
}
// ByteBuffer size: alpha → potW*potH*4, no alpha → potW*potH*3
// But GPU stores 4 bytes/pixel either way because internalFormat=GL_RGBA
```

**Mipmap decision** (dimension-based, not type-based):
```java
boolean useMipmaps = (width <= 1024 && height <= 1024);
if (TextureLoader.forceMipmapsSet.contains(resourcePath)) {
    useMipmaps = true;
}

if (useMipmaps) {
    GL11.glTexParameteri(target, GL_TEXTURE_MIN_FILTER, 9987);  // GL_LINEAR_MIPMAP_LINEAR
    GL11.glTexParameteri(GL_TEXTURE_2D, 33169, 1);              // GL_GENERATE_MIPMAP = ON
} else {
    GL11.glTexParameteri(target, GL_TEXTURE_MIN_FILTER, 9729);  // GL_LINEAR
    GL11.glTexParameteri(target, 33169, 0);                      // GL_GENERATE_MIPMAP = OFF
}
```

**Game's VRAM counter** (for reference — NOT what we use for true GPU estimation):
```java
vramCounter += buffer.capacity();              // base size
if (useMipmaps) {
    vramCounter += (long)(buffer.capacity() * 0.33F);  // +33% for mipmaps
}
```

### Known TriOS estimator bugs (to be verified by the profiler)

1. **Mipmap multiplier**: TriOS uses `background→1.0×, sprite→4/3×`. Game uses `both dims ≤1024→mipmaps, else none`. Large sprites (>1024px) are over-counted by 33%.
2. **Bytes per pixel**: TriOS reads actual channels from file header (3 for JPEG). GPU stores 4 bytes/pixel always (`internalFormat=GL_RGBA`). Non-alpha textures under-counted by 25%.
3. **Width/height swap**: In `vram_scan_one_mod.dart:428-432`, `textureHeight` is computed from `image.width` and vice versa.
4. **POT rounding for dim=1**: Game rounds 1→2, TriOS keeps 1→1.

### Eager loading confirmation

`ResourceLoaderState.queueShipAndWeaponSprites()` iterates ALL weapon specs, projectile specs, and hull specs (including mods) and queues their sprites during startup. These are loaded into GPU memory before `onApplicationLoad()` fires. The profiler will capture nearly all mod textures in a single scan.

## Risks / Trade-offs

**Reflection breaks on game update** → Type-based discovery (match by `HashMap` return type, `int` return type) is more resilient than name-based. The companion mod already ships per-game-version. If reflection fails, log a warning and skip — no crash.

**GL context assumptions** → Console Commands executes on the main/render thread where the GL context is current. No threading issues.

**Stale textures in cache** → `TextureLoader`'s HashMap retains textures even after `unloadTexture()` removes the sprite reference (the HashMap entry persists). The profiler reports allocated VRAM, which matches estimation goals (estimator predicts peak allocation, not active-render set).

**Output size for extreme modlists** → 900KB chunks with manifest. TriOS reads all chunks and concatenates. Worst case (30,000 textures) = ~6MB across ~7 chunks.
