package wisp.trios;

import com.fs.starfarer.api.BaseModPlugin;

public class TriosCompanionModPlugin extends BaseModPlugin {
    @Override
    public void onApplicationLoad() throws Exception {
        super.onApplicationLoad();

        PortraitReplacer.replaceImagesBasedOnConfig();
    }

    @Override
    public void onGameLoad(boolean newGame) {
        super.onGameLoad(newGame);

        PortraitReplacer.replaceImagesBasedOnConfig();
    }
}
