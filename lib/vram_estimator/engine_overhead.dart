// Measurement runs (2026-05-06, Starsector 0.98a-RC8, NVIDIA):
//
// | Run     | Cache (MB) | Task Mgr (MB) | Overhead (MB) | GraphicsLib |
// |---------|-----------|---------------|---------------|-------------|
// | 5 mods  |     588.8 |         650.3 |          61.5 | OFF         |
// | 10 mods |   1,019.7 |       1,375.2 |         355.5 | ON          |
// | 17 mods |   1,852.5 |       2,288.8 |         436.3 | ON          |

const int graphicsLibFixedOverheadBytes = 257 * 1024 * 1024;
const double cacheOverheadMultiplier = 0.10;

int engineOverheadBytes({
  required int estimatedCacheBytes,
  required bool graphicsLibEnabled,
}) {
  final fixed = graphicsLibEnabled ? graphicsLibFixedOverheadBytes : 0;
  final scaling = (estimatedCacheBytes * cacheOverheadMultiplier).round();
  return fixed + scaling;
}
