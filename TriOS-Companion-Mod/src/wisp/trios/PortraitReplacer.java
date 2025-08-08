package wisp.trios;

import com.fs.starfarer.api.Global;
import com.fs.starfarer.api.graphics.SpriteAPI;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.lwjgl.BufferUtils;
import org.lwjgl.opengl.GL11;

import java.io.IOException;
import java.nio.FloatBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * PortraitReplacer - A utility class for replacing textures in Starsector
 * <p>
 * This class reads a configuration file at data/config/trios_image_replacements.json
 * and performs texture replacements based on the configuration.
 */
public class PortraitReplacer {
    private static final String CONFIG_PATH = "data/config/trios_image_replacements.json";
    private static final Logger log = Global.getLogger(PortraitReplacer.class);

    // Constants for OpenGL texture operations
    private static final int GL_TEXTURE_2D = GL11.GL_TEXTURE_2D;
    private static final int GL_RGBA = GL11.GL_RGBA;
    private static final int GL_FLOAT = GL11.GL_FLOAT;

    static {
        log.setLevel(Level.DEBUG);
        log.info("PortraitReplacer initialized");
    }

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
                log.error("Error parsing texture replacement configuration", e);
                return Optional.empty();
            }
        }
    }

    /**
     * Performs texture replacements based on the configuration file at `data/config/trios_image_replacements.json`
     */
    public static void replaceImagesBasedOnConfig() {
        log.info("Starting texture replacement process");

        try {
            // Load and parse the configuration file
            Optional<JSONArray> configOpt = loadConfigFile();

            if (configOpt.isEmpty()) {
                log.warn("No valid configuration found, texture replacement skipped");
                return;
            }

            JSONArray config = configOpt.get();
            log.info("Successfully loaded configuration with " + config.length() + " entries");

            // Process each replacement entry
            Map<String, Integer> stats = new HashMap<>();
            stats.put("success", 0);
            stats.put("failure", 0);

            for (int i = 0; i < config.length(); i++) {
                try {
                    JSONObject entry = config.getJSONObject(i);
                    processReplacementEntry(entry, stats);
                } catch (JSONException e) {
                    log.error("Error processing replacement entry at index " + i, e);
                    stats.compute("failure", (k, v) -> v + 1);
                }
            }

            // Log summary statistics
            log.info("Texture replacement complete. Summary: " +
                    stats.get("success") + " successful, " +
                    stats.get("failure") + " failed");

        } catch (Exception e) {
            log.error("Unexpected error during texture replacement", e);
        }
    }

    /**
     * Loads the configuration file
     *
     * @return An Optional containing the JSONArray if successful, empty otherwise
     */
    private static Optional<JSONArray> loadConfigFile() {
        log.info("Loading configuration from " + CONFIG_PATH);

        try {
            // Try to load using the game's built-in JSON loader
            JSONObject json = Global.getSettings().loadJSON(CONFIG_PATH);

            if (json != null && json.has("replacements")) {
                return Optional.of(json.getJSONArray("replacements"));
            } else if (json != null) {
                log.warn("Configuration file exists but doesn't contain 'replacements' array");

                // If the JSON is valid but doesn't have the expected structure,
                // create a sample configuration
                createSampleConfigFile();
            } else {
                log.warn("Configuration file not found");

                // Create a sample configuration file
                createSampleConfigFile();
            }
        } catch (IOException | JSONException e) {
            log.error("Error loading configuration file", e);

            // Try to create a sample configuration file even if there was an error
            try {
                createSampleConfigFile();
            } catch (Exception ex) {
                log.error("Failed to create sample configuration after error", ex);
            }
        }

        return Optional.empty();
    }

    /**
     * Creates a sample configuration file
     */
    private static void createSampleConfigFile() {
        log.info("Creating sample configuration file");

        try {
            // Create a sample JSON configuration
            JSONObject sampleConfig = new JSONObject();
            JSONArray replacements = new JSONArray();

            // Add sample replacement entries
            JSONObject replacement1 = new JSONObject();
            replacement1.put("original", "graphics/portraits/portrait_mercenary01.png");
            replacement1.put("replacement", "graphics/portraits/portrait_mercenary01.png");
            replacements.put(replacement1);

            sampleConfig.put("replacements", replacements);

            // Save the sample configuration using the game's settings API
            Global.getSettings().writeTextFileToCommon(CONFIG_PATH, sampleConfig.toString(2));
            log.info("Sample configuration file created successfully");
        } catch (Exception e) {
            log.error("Failed to create sample configuration file", e);
        }
    }

    /**
     * Processes a single replacement entry
     *
     * @param entry The JSONObject containing the replacement configuration
     * @param stats A map to track success/failure statistics
     */
    private static void processReplacementEntry(JSONObject entry, Map<String, Integer> stats) {
        TextureReplacement.fromJson(entry).ifPresentOrElse(
                replacement -> {
                    log.info("Processing replacement: " + replacement.originalTexture + " -> " + replacement.replacementTexture);

                    try {
                        // Load the sprites
                        Global.getSettings().loadTexture(replacement.originalTexture); // Original texture should already be loaded, but just in case
                        SpriteAPI originalSprite = Global.getSettings().getSprite(replacement.originalTexture);
                        Global.getSettings().loadTexture(replacement.replacementTexture);
                        SpriteAPI replacementSprite = Global.getSettings().getSprite(replacement.replacementTexture);

                        // Validate sprites
                        if (originalSprite == null) {
                            log.warn("Original texture not found: " + replacement.originalTexture);
                            stats.compute("failure", (k, v) -> v + 1);
                            return;
                        }

                        if (replacementSprite == null) {
                            log.warn("Replacement texture not found: " + replacement.replacementTexture);
                            stats.compute("failure", (k, v) -> v + 1);
                            return;
                        }

                        // Perform the replacement
                        replaceTexture(originalSprite, replacementSprite);
                        log.info("Successfully replaced texture: " + replacement.originalTexture);
                        stats.compute("success", (k, v) -> v + 1);
                    } catch (Exception e) {
                        log.error("Error replacing texture: " + replacement.originalTexture, e);
                        stats.compute("failure", (k, v) -> v + 1);
                    }
                },
                () -> stats.compute("failure", (k, v) -> v + 1)
        );
    }

    /**
     * Replaces the texture of the target sprite with the texture of the source sprite
     *
     * @param target The sprite whose texture will be replaced
     * @param source The sprite whose texture will be used as replacement
     */
    private static void replaceTexture(SpriteAPI target, SpriteAPI source) {
        log.debug("Replacing texture: width=" + source.getWidth() + ", height=" + source.getHeight());

        try {
            // Create a buffer to hold the texture data
            int bufferSize = (int) (source.getWidth() * source.getHeight() * 4);
            FloatBuffer buffer = BufferUtils.createFloatBuffer(bufferSize);

            // Get the source texture data
            source.bindTexture();
            GL11.glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_FLOAT, buffer);

            // Replace the target texture
            target.bindTexture();
            GL11.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                    (int) source.getWidth(), (int) source.getHeight(),
                    0, GL_RGBA, GL_FLOAT, buffer);

            log.debug("Texture replacement completed successfully");
        } catch (Exception e) {
            log.error("OpenGL error during texture replacement", e);
            throw e; // Re-throw to be handled by the caller
        }
    }
}
