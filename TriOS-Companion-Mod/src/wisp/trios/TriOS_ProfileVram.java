package wisp.trios;

import org.apache.log4j.Logger;
import org.lazywizard.console.BaseCommand;
import org.lazywizard.console.Console;

public class TriOS_ProfileVram implements BaseCommand {

    private static final Logger log = Logger.getLogger(TriOS_ProfileVram.class);

    @Override
    public CommandResult runCommand(String args, CommandContext context) {
        Console.showMessage("TriOS VRAM Profiler: Starting scan...");

        try {
            VramProfiler.ScanResult result = VramProfiler.scan();

            double cacheMB = result.totalGpuBytes / (1024.0 * 1024.0);
            GpuMemoryQuery.GpuMemoryResult gpu = result.gpuMemory;

            if (gpu.totalUsedBytes != null && !"none".equals(gpu.provider)) {
                double totalGpuMB = gpu.totalUsedBytes / (1024.0 * 1024.0);
                double overheadMB = totalGpuMB - cacheMB;
                Console.showMessage(String.format(
                        "TriOS VRAM Profiler: Scan complete.\n" +
                        "  Textures scanned: %d\n" +
                        "  Texture cache: %.2f MB\n" +
                        "  Total GPU memory: %.2f MB (via %s)\n" +
                        "  Engine overhead: %.2f MB\n" +
                        "  Output: saves/common/%s (manifest + %d chunk%s)",
                        result.textureCount,
                        cacheMB,
                        totalGpuMB,
                        gpu.provider,
                        overheadMB,
                        "trios_vram_manifest.data",
                        result.chunkCount,
                        result.chunkCount == 1 ? "" : "s"
                ));
            } else {
                Console.showMessage(String.format(
                        "TriOS VRAM Profiler: Scan complete.\n" +
                        "  Textures scanned: %d\n" +
                        "  Texture cache: %.2f MB\n" +
                        "  Total GPU memory: unavailable on this driver\n" +
                        "  Output: saves/common/%s (manifest + %d chunk%s)",
                        result.textureCount,
                        cacheMB,
                        "trios_vram_manifest.data",
                        result.chunkCount,
                        result.chunkCount == 1 ? "" : "s"
                ));
            }

            return CommandResult.SUCCESS;
        } catch (Exception e) {
            Console.showMessage("TriOS VRAM Profiler: Error during scan - " + e.getMessage());
            log.error("VRAM profiler scan failed", e);
            return CommandResult.ERROR;
        }
    }
}
