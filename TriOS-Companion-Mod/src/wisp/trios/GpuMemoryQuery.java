package wisp.trios;

import com.fs.starfarer.api.Global;
import org.apache.log4j.Logger;
import org.lwjgl.BufferUtils;
import org.lwjgl.opengl.GL11;

import java.nio.IntBuffer;

public class GpuMemoryQuery {

    private static final Logger log = Global.getLogger(GpuMemoryQuery.class);

    private static final long MAX_PLAUSIBLE_BYTES = 64L * 1024 * 1024 * 1024; // 64 GB

    // NVX extension tokens
    private static final int GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX = 0x9047;
    private static final int GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM_NVX = 0x9049;

    // ATI extension token
    private static final int TEXTURE_FREE_MEMORY_ATI = 0x87FC;

    public static GpuMemoryResult query() {
        String extensions;
        try {
            extensions = GL11.glGetString(GL11.GL_EXTENSIONS);
        } catch (Exception e) {
            log.warn("Failed to read GL extensions: " + e.getMessage());
            return GpuMemoryResult.none();
        }

        if (extensions == null) {
            log.warn("GL_EXTENSIONS returned null");
            return GpuMemoryResult.none();
        }

        boolean hasNvx = extensions.contains("GL_NVX_gpu_memory_info");
        boolean hasAti = extensions.contains("GL_ATI_meminfo");

        if (hasNvx) {
            return queryNvx();
        } else if (hasAti) {
            return queryAti();
        } else {
            return GpuMemoryResult.none();
        }
    }

    private static GpuMemoryResult queryNvx() {
        try {
            int dedicatedKB = GL11.glGetInteger(GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX);
            int availableKB = GL11.glGetInteger(GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM_NVX);

            long dedicatedBytes = (long) dedicatedKB * 1024;
            long usedBytes = ((long) dedicatedKB - (long) availableKB) * 1024;

            if (usedBytes < 0 || usedBytes > MAX_PLAUSIBLE_BYTES) {
                log.warn("NVX returned implausible used bytes: " + usedBytes + " (dedicated=" + dedicatedKB + " KB, available=" + availableKB + " KB)");
                return GpuMemoryResult.none();
            }
            if (dedicatedBytes < 0 || dedicatedBytes > MAX_PLAUSIBLE_BYTES) {
                log.warn("NVX returned implausible dedicated bytes: " + dedicatedBytes);
                return GpuMemoryResult.none();
            }

            return new GpuMemoryResult("NVX", usedBytes, dedicatedBytes, null);
        } catch (Exception e) {
            log.warn("NVX gpu memory query failed: " + e.getMessage());
            return GpuMemoryResult.none();
        }
    }

    private static GpuMemoryResult queryAti() {
        try {
            IntBuffer buf = BufferUtils.createIntBuffer(4);
            GL11.glGetInteger(TEXTURE_FREE_MEMORY_ATI, buf);
            int freeKB = buf.get(0);

            if (freeKB < 0 || (long) freeKB * 1024 > MAX_PLAUSIBLE_BYTES) {
                log.warn("ATI returned implausible free memory: " + freeKB + " KB");
                return GpuMemoryResult.none();
            }

            // ATI only reports free memory, not total or used.
            // Record available; dedicated total is not obtainable.
            return new GpuMemoryResult(
                    "ATI",
                    null,
                    null,
                    "AMD driver reports " + freeKB + " KB free via GL_ATI_meminfo. "
                            + "Total and used are not available from this extension."
            );
        } catch (Exception e) {
            log.warn("ATI gpu memory query failed: " + e.getMessage());
            return GpuMemoryResult.none();
        }
    }

    public static class GpuMemoryResult {
        public final String provider;
        public final Long totalUsedBytes;
        public final Long dedicatedBytes;
        public final String note;

        public GpuMemoryResult(String provider, Long totalUsedBytes, Long dedicatedBytes, String note) {
            this.provider = provider;
            this.totalUsedBytes = totalUsedBytes;
            this.dedicatedBytes = dedicatedBytes;
            this.note = note;
        }

        public static GpuMemoryResult none() {
            return new GpuMemoryResult("none", null, null, null);
        }
    }
}
