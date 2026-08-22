package wisp.trios;

import com.fs.starfarer.api.Global;
import com.fs.starfarer.api.graphics.SpriteAPI;
import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.lwjgl.BufferUtils;
import org.lwjgl.opengl.GL11;

import java.io.IOException;
import java.nio.FloatBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * PortraitReplacer - A utility class for replacing textures in Starsector
 * <p>
 * This class reads a configuration file at data/config/trios_image_replacements.json
 * and performs texture replacements based on the configuration.
 * <p>
 * Problems are counted up and reported in a few lines at the end instead of one line per
 * image, so a long list of replacements doesn't fill the log.
 */
public class PortraitReplacer {
    private static final String CONFIG_PATH = "data/config/trios_image_replacements.json";
    private static final Logger log = Global.getLogger(PortraitReplacer.class);

    // Constants for OpenGL texture operations
    private static final int GL_TEXTURE_2D = GL11.GL_TEXTURE_2D;
    private static final int GL_RGBA = GL11.GL_RGBA;
    private static final int GL_FLOAT = GL11.GL_FLOAT;

    /** How many image names to list in a summary line before saying "and N more". */
    private static final int MAX_NAMES_IN_LOG = 5;

    private static boolean alreadyRan = false;

    private record TextureReplacement(String originalTexture, String replacementTexture) {

        public static Optional<TextureReplacement> fromJson(JSONObject jsonObject) {
            try {
                if (!jsonObject.has("original") || !jsonObject.has("replacement")) {
                    log.warn("JSON object missing required fields: " + jsonObject);
                    return Optional.empty();
                }

                String original = jsonObject.getString("original");
                String replacement = jsonObject.getString("replacement");

                if (original.isBlank() || replacement.isBlank()) {
                    log.warn("Empty texture path in replacement configuration: " + jsonObject);
                    return Optional.empty();
                }

                return Optional.of(new TextureReplacement(original, replacement));
            } catch (JSONException e) {
                log.warn("Error parsing texture replacement configuration", e);
                return Optional.empty();
            }
        }
    }

    /** What happened to a single image. */
    private enum ReplacementResult {
        REPLACED,
        NOT_ON_GRAPHICS_CARD,
        DIFFERENT_SIZE
    }

    /** Running count of what happened, so the log gets a summary instead of a line per image. */
    private static final class Tally {
        int replaced;
        int differentSize;
        int notOnGraphicsCard;
        int otherErrors;
        final List<String> imagesNotFound = new ArrayList<>();
        Exception firstError;
        String firstErrorImage;

        void recordError(String image, Exception error) {
            otherErrors++;

            if (firstError == null) {
                firstError = error;
                firstErrorImage = image;
            }
        }
    }

    /**
     * Performs texture replacements based on the configuration file at `data/config/trios_image_replacements.json`
     */
    public static void replaceImagesBasedOnConfig() {
        if (alreadyRan) {
            log.debug("PortraitReplacer already ran this process, skipping");
            return;
        }
        alreadyRan = true;

        try {
            // Load and parse the configuration file
            Optional<JSONArray> configOpt = loadConfigFile();

            if (configOpt.isEmpty()) {
                return;
            }

            JSONArray config = configOpt.get();

            if (config.length() == 0) {
                return;
            }

            // Process each replacement entry
            Tally tally = new Tally();

            for (int i = 0; i < config.length(); i++) {
                try {
                    JSONObject entry = config.getJSONObject(i);
                    processReplacementEntry(entry, tally);
                } catch (JSONException e) {
                    tally.recordError("entry " + i + " of " + CONFIG_PATH, e);
                }
            }

            logSummary(tally, config.length());

        } catch (Exception e) {
            log.warn("Unexpected error during texture replacement", e);
        }
    }

    /**
     * Writes one line saying how many images were replaced, plus one line for each kind of problem
     * that came up.
     */
    private static void logSummary(Tally tally, int total) {
        log.info("Image replacement finished: " + tally.replaced + " of " + total + " replaced.");

        if (!tally.imagesNotFound.isEmpty()) {
            log.warn(tally.imagesNotFound.size() + " image(s) skipped, the game could not find them"
                    + " (the mod they come from is probably not enabled): "
                    + namesForLog(tally.imagesNotFound));
        }

        if (tally.differentSize > 0) {
            log.warn(tally.differentSize + " image(s) skipped, the replacement is a different size than the original.");
        }

        if (tally.notOnGraphicsCard > 0) {
            log.warn(tally.notOnGraphicsCard + " image(s) skipped, they were not loaded on the graphics card yet.");
        }

        if (tally.otherErrors > 0) {
            log.warn(tally.otherErrors + " image(s) failed to be replaced. First failure was "
                    + tally.firstErrorImage, tally.firstError);
        }
    }

    private static String namesForLog(List<String> names) {
        if (names.size() <= MAX_NAMES_IN_LOG) {
            return String.join(", ", names);
        }

        return String.join(", ", names.subList(0, MAX_NAMES_IN_LOG))
                + ", and " + (names.size() - MAX_NAMES_IN_LOG) + " more";
    }

    /**
     * Loads the configuration file
     *
     * @return An Optional containing the JSONArray if successful, empty otherwise
     */
    private static Optional<JSONArray> loadConfigFile() {
        log.debug("Loading portrait replacement configuration from " + CONFIG_PATH);

        try {
            // Try to load using the game's built-in JSON loader
            JSONObject json;

            try {
                json = Global.getSettings().loadJSON(CONFIG_PATH);
            } catch (Exception ex) {
                // If config file is missing, no need to show any error in the load, it'll just worry people
                log.debug("Portrait replacement configuration file not found, not replacing any portraits.");
                return Optional.empty();
            }

            if (json != null && json.has("replacements")) {
                return Optional.of(json.getJSONArray("replacements"));
            } else if (json != null) {
                log.warn("Portrait replacement configuration file exists but doesn't contain 'replacements' array");
            } else {
                log.debug("Portrait replacement configuration file not found");
            }
        } catch (JSONException e) {
            log.warn("Error loading extant portrait replacement configuration file", e);
        }

        return Optional.empty();
    }

    /**
     * Processes a single replacement entry
     *
     * @param entry The JSONObject containing the replacement configuration
     * @param tally Counts of what happened, added to as each entry is processed
     */
    private static void processReplacementEntry(JSONObject entry, Tally tally) {
        Optional<TextureReplacement> parsed = TextureReplacement.fromJson(entry);

        if (parsed.isEmpty()) {
            tally.otherErrors++;
            return;
        }

        TextureReplacement replacement = parsed.get();
        log.debug("Processing replacement: " + replacement.originalTexture + " -> " + replacement.replacementTexture);

        // Original texture should already be loaded, but load it just in case.
        if (!loadTexture(replacement.originalTexture, tally)) return;
        if (!loadTexture(replacement.replacementTexture, tally)) return;

        try {
            SpriteAPI originalSprite = Global.getSettings().getSprite(replacement.originalTexture);
            SpriteAPI replacementSprite = Global.getSettings().getSprite(replacement.replacementTexture);

            if (originalSprite == null) {
                tally.imagesNotFound.add(replacement.originalTexture);
                return;
            }

            if (replacementSprite == null) {
                tally.imagesNotFound.add(replacement.replacementTexture);
                return;
            }

            switch (replaceTexture(originalSprite, replacementSprite)) {
                case REPLACED -> tally.replaced++;
                case DIFFERENT_SIZE -> tally.differentSize++;
                case NOT_ON_GRAPHICS_CARD -> tally.notOnGraphicsCard++;
            }
        } catch (Exception e) {
            tally.recordError(replacement.originalTexture, e);
        }
    }

    /**
     * Asks the game to load an image. A missing file is counted rather than logged, so a list of
     * images from a mod that is not enabled does not produce one warning per image.
     *
     * @return true if the image is loaded and can be used
     */
    private static boolean loadTexture(String path, Tally tally) {
        try {
            Global.getSettings().loadTexture(path);
            return true;
        } catch (IOException e) {
            tally.imagesNotFound.add(path);
            return false;
        }
    }

    /**
     * Replaces the texture of the target sprite with the texture of the source sprite
     *
     * @param target The sprite whose texture will be replaced
     * @param source The sprite whose texture will be used as replacement
     */
    private static ReplacementResult replaceTexture(SpriteAPI target, SpriteAPI source) {
        // Query actual GPU-side dimensions after binding. SpriteAPI.getTextureWidth()/getTextureHeight()
        // can return 1 during onApplicationLoad before texture metadata is populated, but the real
        // GPU texture is larger — sizing the buffer from those values causes glGetTexImage to write
        // past the buffer end, crashing in nvoglv64.dll.
        source.bindTexture();
        int srcW = GL11.glGetTexLevelParameteri(GL_TEXTURE_2D, 0, GL11.GL_TEXTURE_WIDTH);
        int srcH = GL11.glGetTexLevelParameteri(GL_TEXTURE_2D, 0, GL11.GL_TEXTURE_HEIGHT);

        target.bindTexture();
        int dstW = GL11.glGetTexLevelParameteri(GL_TEXTURE_2D, 0, GL11.GL_TEXTURE_WIDTH);
        int dstH = GL11.glGetTexLevelParameteri(GL_TEXTURE_2D, 0, GL11.GL_TEXTURE_HEIGHT);

        log.debug("Replacing texture: source GL " + srcW + "x" + srcH
                + ", target GL " + dstW + "x" + dstH);

        if (srcW <= 1 || srcH <= 1 || dstW <= 1 || dstH <= 1) {
            log.debug("Texture not loaded on GPU (source " + srcW + "x" + srcH
                    + ", target " + dstW + "x" + dstH + "), skipping replacement");
            return ReplacementResult.NOT_ON_GRAPHICS_CARD;
        }

        if (srcW != dstW || srcH != dstH) {
            log.debug("Texture size mismatch between source (" + srcW + "x" + srcH
                    + ") and target (" + dstW + "x" + dstH + "), skipping replacement");
            return ReplacementResult.DIFFERENT_SIZE;
        }

        int bufferSize = srcW * srcH * 4;
        FloatBuffer buffer = BufferUtils.createFloatBuffer(bufferSize);

        source.bindTexture();
        GL11.glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_FLOAT, buffer);

        target.bindTexture();
        GL11.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                srcW, srcH,
                0, GL_RGBA, GL_FLOAT, buffer);

        log.debug("Texture replacement completed successfully");
        return ReplacementResult.REPLACED;
    }
}
