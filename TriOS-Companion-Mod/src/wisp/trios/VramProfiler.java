package wisp.trios;

import com.fs.starfarer.api.Global;
import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;
import org.lwjgl.opengl.GL11;

import java.text.SimpleDateFormat;
import java.util.*;

public class VramProfiler {

    private static final Logger log = Global.getLogger(VramProfiler.class);
    private static final int MAX_CHUNK_BYTES = 900 * 1024;
    private static final String RESULTS_PREFIX = "trios_vram_results_";
    private static final String MANIFEST_NAME = "trios_vram_manifest";

    private static final Map<Integer, String> GL_FORMAT_NAMES = new HashMap<>();

    static {
        GL_FORMAT_NAMES.put(0x1903, "GL_RED");
        GL_FORMAT_NAMES.put(0x1904, "GL_GREEN");
        GL_FORMAT_NAMES.put(0x1905, "GL_BLUE");
        GL_FORMAT_NAMES.put(0x1906, "GL_ALPHA");
        GL_FORMAT_NAMES.put(0x1907, "GL_RGB");
        GL_FORMAT_NAMES.put(0x1908, "GL_RGBA");
        GL_FORMAT_NAMES.put(0x1909, "GL_LUMINANCE");
        GL_FORMAT_NAMES.put(0x190A, "GL_LUMINANCE_ALPHA");
        GL_FORMAT_NAMES.put(0x2A10, "GL_R3_G3_B2");
        GL_FORMAT_NAMES.put(0x804F, "GL_RGB4");
        GL_FORMAT_NAMES.put(0x8050, "GL_RGB5");
        GL_FORMAT_NAMES.put(0x8051, "GL_RGB8");
        GL_FORMAT_NAMES.put(0x8052, "GL_RGB10");
        GL_FORMAT_NAMES.put(0x8053, "GL_RGB12");
        GL_FORMAT_NAMES.put(0x8054, "GL_RGB16");
        GL_FORMAT_NAMES.put(0x8055, "GL_RGBA2");
        GL_FORMAT_NAMES.put(0x8056, "GL_RGBA4");
        GL_FORMAT_NAMES.put(0x8057, "GL_RGB5_A1");
        GL_FORMAT_NAMES.put(0x8058, "GL_RGBA8");
        GL_FORMAT_NAMES.put(0x8059, "GL_RGB10_A2");
        GL_FORMAT_NAMES.put(0x805A, "GL_RGBA12");
        GL_FORMAT_NAMES.put(0x805B, "GL_RGBA16");
        GL_FORMAT_NAMES.put(0x8040, "GL_LUMINANCE8");
        GL_FORMAT_NAMES.put(0x8045, "GL_LUMINANCE8_ALPHA8");
        GL_FORMAT_NAMES.put(0x8D62, "GL_RGB565");
        GL_FORMAT_NAMES.put(0x83F0, "GL_COMPRESSED_RGB_S3TC_DXT1_EXT");
        GL_FORMAT_NAMES.put(0x83F1, "GL_COMPRESSED_RGBA_S3TC_DXT1_EXT");
        GL_FORMAT_NAMES.put(0x83F2, "GL_COMPRESSED_RGBA_S3TC_DXT3_EXT");
        GL_FORMAT_NAMES.put(0x83F3, "GL_COMPRESSED_RGBA_S3TC_DXT5_EXT");
    }

    public static ScanResult scan() throws Exception {
        log.info("Starting VRAM profiler scan");

        // Find TextureLoader via com.fs.graphics.oOoO — the static texture manager class.
        // The design doc assumed TextureLoader was a field of Global.getSettings(), but the
        // actual runtime structure puts it on oOoO as a protected static field with a public
        // static getter.
        Object textureLoader = findTextureLoader();
        if (textureLoader == null) {
            throw new RuntimeException("Could not locate TextureLoader instance via reflection");
        }
        log.info("Found TextureLoader: " + textureLoader.getClass().getName());

        // Get the texture cache HashMap from the TextureLoader instance
        HashMap<?, ?> textureCache = findTextureCache(textureLoader);
        if (textureCache == null) {
            throw new RuntimeException("Could not locate texture cache HashMap on TextureLoader");
        }
        log.info("Found texture cache with " + textureCache.size() + " entries");

        // Extract forceMipmapsFor set (public static Set<String> on TextureLoader)
        Set<String> forcedMipmapPaths = findForceMipmapsSet(textureLoader.getClass());
        log.info("Found forceMipmapsFor set with " + (forcedMipmapPaths != null ? forcedMipmapPaths.size() : 0) + " entries");

        // 2.3–2.4: Query GL for each texture
        List<JSONObject> textureEntries = new ArrayList<>();
        long totalGpuBytes = 0;
        int errorCount = 0;

        for (Map.Entry<?, ?> entry : textureCache.entrySet()) {
            String path = (String) entry.getKey();
            Object wrapper = entry.getValue();

            try {
                int glTextureId = findGlTextureId(wrapper);
                if (glTextureId <= 0) continue;

                JSONObject textureData = queryTexture(path, glTextureId);
                if (textureData != null) {
                    textureEntries.add(textureData);
                    totalGpuBytes += textureData.getLong("totalBytes");
                }
            } catch (Exception e) {
                errorCount++;
                if (errorCount <= 10) {
                    log.warn("Error querying texture '" + path + "': " + e.getMessage());
                }
            }
        }

        if (errorCount > 10) {
            log.warn("... and " + (errorCount - 10) + " more texture query errors");
        }

        log.info("Queried " + textureEntries.size() + " textures, total GPU bytes: " + totalGpuBytes);

        // Query GPU memory via vendor extensions (after texture loop, before manifest)
        GpuMemoryQuery.GpuMemoryResult gpuMemory = GpuMemoryQuery.query();
        log.info("GPU memory query: provider=" + gpuMemory.provider
                + ", usedBytes=" + gpuMemory.totalUsedBytes
                + ", dedicatedBytes=" + gpuMemory.dedicatedBytes);

        // 3.1–3.3: Write chunked output
        int chunkCount = writeChunkedOutput(textureEntries);
        writeManifest(totalGpuBytes, textureEntries.size(), chunkCount, forcedMipmapPaths, gpuMemory);

        return new ScanResult(textureEntries.size(), totalGpuBytes, chunkCount, gpuMemory);
    }

    // --- 2.1: Find TextureLoader ---

    private static Object findTextureLoader() {
        try {
            // TextureLoader is held as a protected static field on com.fs.graphics.oOoO —
            // the game's static texture manager. Load the class via the game's classloader
            // (the same one that loaded Global/SettingsAPI), then read the static field.
            ClassLoader gameLoader = Global.class.getClassLoader();
            Class<?> oOoOClass = Class.forName("com.fs.graphics.oOoO", false, gameLoader);
            // oOoO has a protected static TextureLoader field — find it by type name
            Object loader = ReflectionUtil.getStaticFieldValueByTypeName(oOoOClass, "TextureLoader");
            if (loader != null) return loader;
            // Fallback: search all static fields for one whose type contains "TextureLoader"
            loader = ReflectionUtil.getStaticFieldValueByTypeNameContains(oOoOClass, "TextureLoader");
            if (loader != null) return loader;
            log.warn("TextureLoader not found on oOoO. Static fields:");
            ReflectionUtil.logAllStaticFieldTypes(oOoOClass, log);
            return null;
        } catch (ClassNotFoundException e) {
            log.warn("Could not load com.fs.graphics.oOoO: " + e.getMessage());
        } catch (Throwable e) {
            log.warn("Failed to find TextureLoader: " + e.getMessage());
        }
        return null;
    }

    // --- 2.2: Find texture cache HashMap ---

    private static HashMap<?, ?> findTextureCache(Object textureLoader) {
        try {
            Object result = ReflectionUtil.invokeNoArgMethodByReturnType(textureLoader, HashMap.class);
            if (result instanceof HashMap) {
                return (HashMap<?, ?>) result;
            }
        } catch (Throwable e) {
            log.warn("Failed to find texture cache: " + e.getMessage());
        }
        return null;
    }

    // --- 2.2: Find GL texture ID from wrapper ---

    private static int findGlTextureId(Object wrapper) {
        try {
            List<Object> results = ReflectionUtil.invokeAllNoArgMethodsByReturnType(wrapper, int.class);
            for (Object result : results) {
                if (result instanceof Integer) {
                    int val = (Integer) result;
                    if (val > 0 && GL11.glIsTexture(val)) {
                        return val;
                    }
                }
            }
        } catch (Throwable e) {
            // silently skip
        }
        return -1;
    }

    // --- 2.3: Per-texture GL query ---

    private static JSONObject queryTexture(String path, int glTextureId) throws Exception {
        GL11.glBindTexture(GL11.GL_TEXTURE_2D, glTextureId);

        int width = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, 0, GL11.GL_TEXTURE_WIDTH);
        int height = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, 0, GL11.GL_TEXTURE_HEIGHT);

        if (width <= 0 || height <= 0) return null;

        int internalFormat = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, 0, GL11.GL_TEXTURE_INTERNAL_FORMAT);
        int redBits = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, 0, 0x805C);   // GL_TEXTURE_RED_SIZE
        int greenBits = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, 0, 0x805D); // GL_TEXTURE_GREEN_SIZE
        int blueBits = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, 0, 0x805E);  // GL_TEXTURE_BLUE_SIZE
        int alphaBits = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, 0, 0x805F); // GL_TEXTURE_ALPHA_SIZE
        int bitsPerPixel = redBits + greenBits + blueBits + alphaBits;

        // 2.4: Mipmap probing
        int mipmapLevels = 1;
        long totalBytes = (long) width * height * bitsPerPixel / 8;
        long level0Bytes = totalBytes;

        for (int level = 1; level < 20; level++) {
            int mipWidth = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, level, GL11.GL_TEXTURE_WIDTH);
            if (mipWidth <= 0) break;
            int mipHeight = GL11.glGetTexLevelParameteri(GL11.GL_TEXTURE_2D, level, GL11.GL_TEXTURE_HEIGHT);
            mipmapLevels++;
            totalBytes += (long) mipWidth * mipHeight * bitsPerPixel / 8;
        }

        // 2.6: Format name mapping
        String formatName = GL_FORMAT_NAMES.getOrDefault(internalFormat, "UNKNOWN_0x" + Integer.toHexString(internalFormat));

        // 3.1: Build JSON object
        JSONObject obj = new JSONObject();
        obj.put("path", path);
        obj.put("glTextureId", glTextureId);
        obj.put("gpuWidth", width);
        obj.put("gpuHeight", height);
        obj.put("internalFormat", internalFormat);
        obj.put("internalFormatName", formatName);
        obj.put("redBits", redBits);
        obj.put("greenBits", greenBits);
        obj.put("blueBits", blueBits);
        obj.put("alphaBits", alphaBits);
        obj.put("bitsPerPixel", bitsPerPixel);
        obj.put("mipmapLevels", mipmapLevels);
        obj.put("totalBytes", totalBytes);
        obj.put("level0Bytes", level0Bytes);
        return obj;
    }

    // --- 2.5: forceMipmapsFor set extraction ---

    @SuppressWarnings("unchecked")
    private static Set<String> findForceMipmapsSet(Class<?> textureLoaderClass) {
        try {
            Object result = ReflectionUtil.getStaticFieldValueByType(textureLoaderClass, Set.class);
            if (result instanceof Set) {
                return (Set<String>) result;
            }
        } catch (Throwable e) {
            log.warn("Failed to find forceMipmapsFor set: " + e.getMessage());
        }
        return Collections.emptySet();
    }

    // --- 3.2: Chunked output ---

    private static int writeChunkedOutput(List<JSONObject> textureEntries) throws Exception {
        int chunkIndex = 0;
        JSONArray currentChunk = new JSONArray();
        int currentSize = 20; // overhead for {"textures":[]}

        for (JSONObject entry : textureEntries) {
            String entryStr = entry.toString();
            int entrySize = entryStr.length() + 1; // +1 for comma

            if (currentSize + entrySize > MAX_CHUNK_BYTES && currentChunk.length() > 0) {
                writeChunk(chunkIndex, currentChunk);
                chunkIndex++;
                currentChunk = new JSONArray();
                currentSize = 20;
            }

            currentChunk.put(entry);
            currentSize += entrySize;
        }

        if (currentChunk.length() > 0) {
            writeChunk(chunkIndex, currentChunk);
            chunkIndex++;
        }

        return chunkIndex;
    }

    private static void writeChunk(int index, JSONArray textures) throws Exception {
        JSONObject chunk = new JSONObject();
        chunk.put("textures", textures);
        Global.getSettings().writeTextFileToCommon(RESULTS_PREFIX + index, chunk.toString());
        log.info("Wrote chunk " + index + " with " + textures.length() + " textures");
    }

    // --- 3.3: Manifest output ---

    private static void writeManifest(long totalGpuBytes, int textureCount, int chunkCount, Set<String> forcedMipmapPaths, GpuMemoryQuery.GpuMemoryResult gpuMemory) throws Exception {
        JSONObject manifest = new JSONObject();
        manifest.put("gameVersion", Global.getSettings().getVersionString());
        manifest.put("scanTimestamp", new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(new Date()));
        manifest.put("totalGpuBytes", totalGpuBytes);
        manifest.put("textureCount", textureCount);
        manifest.put("chunkCount", chunkCount);

        JSONArray mipmapArray = new JSONArray();
        if (forcedMipmapPaths != null) {
            for (String path : forcedMipmapPaths) {
                mipmapArray.put(path);
            }
        }
        manifest.put("forcedMipmapPaths", mipmapArray);

        manifest.put("gpuMemoryProvider", gpuMemory.provider);
        if (gpuMemory.totalUsedBytes != null) {
            manifest.put("gpuMemoryTotalUsedBytes", gpuMemory.totalUsedBytes);
        }
        if (gpuMemory.dedicatedBytes != null) {
            manifest.put("gpuMemoryDedicatedBytes", gpuMemory.dedicatedBytes);
        }
        if (gpuMemory.note != null) {
            manifest.put("gpuMemoryNote", gpuMemory.note);
        }

        Global.getSettings().writeTextFileToCommon(MANIFEST_NAME, manifest.toString());
        log.info("Wrote manifest: " + textureCount + " textures, " + totalGpuBytes + " bytes, " + chunkCount + " chunks");
    }

    public static class ScanResult {
        public final int textureCount;
        public final long totalGpuBytes;
        public final int chunkCount;
        public final GpuMemoryQuery.GpuMemoryResult gpuMemory;

        public ScanResult(int textureCount, long totalGpuBytes, int chunkCount, GpuMemoryQuery.GpuMemoryResult gpuMemory) {
            this.textureCount = textureCount;
            this.totalGpuBytes = totalGpuBytes;
            this.chunkCount = chunkCount;
            this.gpuMemory = gpuMemory;
        }
    }
}
