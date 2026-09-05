import 'package:flutter_test/flutter_test.dart';
import 'package:trios/ship_viewer/hull_styles_manager.dart';
import 'package:trios/ship_viewer/models/ships_cache_payload.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/ship_viewer_refresh.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';

import '../riverpod_test_helpers.dart';

class _BuildCounter {
  int ships = 0;
  int graphics = 0;
  int shieldSettings = 0;
}

class _FakeShipListNotifier extends ShipListNotifier {
  _FakeShipListNotifier(this.counter);

  final _BuildCounter counter;

  @override
  Stream<List<ShipsCachePayload>> build() {
    counter.ships++;
    return Stream.value(const []);
  }
}

class _FakeGraphicsIndexNotifier extends GraphicsIndexNotifier {
  _FakeGraphicsIndexNotifier(this.counter);

  final _BuildCounter counter;

  @override
  Stream<List<GraphicsIndexPayload>> build() {
    counter.graphics++;
    return Stream.value(const []);
  }
}

void main() {
  test('Ships refresh reloads ship files, graphics, and trios.json', () async {
    final counter = _BuildCounter();
    final container = createTestContainer(
      overrides: [
        shipSourcesProvider.overrideWith(() => _FakeShipListNotifier(counter)),
        graphicsIndexProvider.overrideWith(
          () => _FakeGraphicsIndexNotifier(counter),
        ),
        shieldTextureOverridesProvider.overrideWith((ref) async {
          counter.shieldSettings++;
          return ShieldTextureImages.empty;
        }),
      ],
    );

    container.listen(shipSourcesProvider, (_, _) {});
    container.listen(graphicsIndexProvider, (_, _) {});
    container.listen(shieldTextureOverridesProvider, (_, _) {});
    await Future.wait([
      container.read(shipSourcesProvider.future),
      container.read(graphicsIndexProvider.future),
      container.read(shieldTextureOverridesProvider.future),
    ]);

    expect(counter.ships, 1);
    expect(counter.graphics, 1);
    expect(counter.shieldSettings, 1);

    container.read(refreshShipViewerProvider)();
    await Future.wait([
      container.read(shipSourcesProvider.future),
      container.read(graphicsIndexProvider.future),
      container.read(shieldTextureOverridesProvider.future),
    ]);

    expect(counter.ships, 2);
    expect(counter.graphics, 2);
    expect(counter.shieldSettings, 2);
  });
}
