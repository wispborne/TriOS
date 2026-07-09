import 'package:flutter_test/flutter_test.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';

void main() {
  group('trilinkToDeepLinkUri', () {
    test('converts a trilink into a parseable starsector-mod deep link', () {
      const trilink =
          'https://trilink.wispborne.com/open.html'
          '?mod=%7B%22url%22%3A%22https%3A%2F%2Fa.com%2FMod.version%22%7D'
          '&dep=%7B%22url%22%3A%22https%3A%2F%2Fb.com%2FDep.version%22%7D';

      final deepLink = trilinkToDeepLinkUri(trilink);
      expect(deepLink, isNotNull);
      expect(deepLink, startsWith('$deepLinkScheme://install?'));

      // The swapped link parses back into the same mod + dependency.
      final request = parseDeepLink(deepLink!);
      expect(request, isNotNull);
      expect(request!.action, DeepLinkAction.install);
      expect(request.mainMod.url.toString(), 'https://a.com/Mod.version');
      expect(request.dependencies.single.url.toString(),
          'https://b.com/Dep.version');
    });

    test('keeps a bare-url mod param', () {
      final deepLink = trilinkToDeepLinkUri(
        'https://trilink.wispborne.com/open.html'
        '?mod=https%3A%2F%2Fa.com%2FMod.version',
      );
      final request = parseDeepLink(deepLink!);
      expect(request!.mainMod.url.toString(), 'https://a.com/Mod.version');
    });

    test('returns null for a non-trilink URL', () {
      expect(
        trilinkToDeepLinkUri('https://example.com/open.html?mod=x'),
        isNull,
      );
    });

    test('returns null for a trilink with no mod param', () {
      expect(
        trilinkToDeepLinkUri('https://trilink.wispborne.com/open.html'),
        isNull,
      );
    });

    test('returns null for garbage input', () {
      expect(trilinkToDeepLinkUri('not a url'), isNull);
    });
  });
}
