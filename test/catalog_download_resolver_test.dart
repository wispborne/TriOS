import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/scraped_mod.dart';

ScrapedMod mod({String? directDownload, String? forum}) => ScrapedMod(
  name: 'Test Mod',
  urls: {
    if (directDownload != null) ModUrlType.DirectDownload: directDownload,
    if (forum != null) ModUrlType.Forum: forum,
  },
);

ForumLlmDownload dl(
  String url, {
  LlmDownloadKind kind = LlmDownloadKind.direct,
  LlmDownloadConfidence confidence = LlmDownloadConfidence.high,
  String label = '',
  bool requiresManualStep = false,
  String? resolvedDirectUrl,
}) => ForumLlmDownload(
  url: url,
  label: label,
  kind: kind,
  confidence: confidence,
  requiresManualStep: requiresManualStep,
  resolvedDirectUrl: resolvedDirectUrl,
);

ForumLlmMod llmMod(List<ForumLlmDownload> downloads) =>
    ForumLlmMod(name: 'Test Mod', role: LlmModRole.main, downloads: downloads);

void main() {
  group('resolveDownloadCandidates', () {
    test('no llm data yields today\'s candidates only', () {
      final candidates = resolveDownloadCandidates(
        mod(directDownload: 'https://a.com/mod.zip', forum: 'https://forum'),
        null,
      );

      expect(candidates, hasLength(2));
      expect(candidates[0].kind, DownloadCandidateKind.catalogDirect);
      expect(candidates[0].url, 'https://a.com/mod.zip');
      expect(candidates[1].kind, DownloadCandidateKind.website);
      expect(candidates[1].url, 'https://forum');
    });

    test('trios link beats a high-confidence direct forum link', () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([
          dl('https://a.com/mod.zip', kind: LlmDownloadKind.direct),
          dl(
            'https://trilink.wispborne.com/open.html?mod=x',
            kind: LlmDownloadKind.trios,
            confidence: LlmDownloadConfidence.low,
          ),
        ]),
      );

      expect(candidates.first.kind, DownloadCandidateKind.triosDeepLink);
      expect(primaryCandidate(candidates)!.kind,
          DownloadCandidateKind.triosDeepLink);
    });

    test('catalog direct beats a forum direct link', () {
      final candidates = resolveDownloadCandidates(
        mod(directDownload: 'https://catalog.com/mod.zip'),
        llmMod([dl('https://forum.com/mod.zip', kind: LlmDownloadKind.direct)]),
      );

      expect(candidates.first.kind, DownloadCandidateKind.catalogDirect);
      expect(candidates.first.url, 'https://catalog.com/mod.zip');
    });

    test('forum direct links order by confidence, above mirrors', () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([
          dl('https://mirror.com/m.zip',
              kind: LlmDownloadKind.mirror,
              confidence: LlmDownloadConfidence.high),
          dl('https://low.com/m.zip',
              kind: LlmDownloadKind.direct,
              confidence: LlmDownloadConfidence.low),
          dl('https://high.com/m.zip',
              kind: LlmDownloadKind.direct,
              confidence: LlmDownloadConfidence.high),
        ]),
      );

      expect(candidates.map((c) => c.url), [
        'https://high.com/m.zip',
        'https://low.com/m.zip',
        'https://mirror.com/m.zip',
      ]);
    });

    test('resolvedDirectUrl is used as the candidate url when present', () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([
          dl('https://dropbox.com/m.zip?dl=0',
              resolvedDirectUrl: 'https://dropbox.com/m.zip?dl=1'),
        ]),
      );

      expect(candidates.single.url, 'https://dropbox.com/m.zip?dl=1');
    });

    test('a manual-step link is never the primary', () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([
          dl('https://manual.com/page',
              kind: LlmDownloadKind.direct,
              confidence: LlmDownloadConfidence.high,
              requiresManualStep: true),
          dl('https://direct.com/m.zip',
              kind: LlmDownloadKind.direct,
              confidence: LlmDownloadConfidence.low),
        ]),
      );

      // The manual-step link sorts first (higher confidence) but is skipped.
      expect(candidates.first.requiresManualStep, isTrue);
      expect(primaryCandidate(candidates)!.url, 'https://direct.com/m.zip');
    });

    test('primary is null when only a website and manual-step links exist', () {
      final candidates = resolveDownloadCandidates(
        mod(forum: 'https://forum'),
        llmMod([
          dl('https://manual.com/page',
              kind: LlmDownloadKind.direct, requiresManualStep: true),
        ]),
      );

      expect(primaryCandidate(candidates), isNull);
      expect(primaryTieSet(candidates), isEmpty);
    });

    test('tie set groups one-click candidates of the primary kind + confidence',
        () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([
          dl('https://a.com/full.zip',
              kind: LlmDownloadKind.direct,
              confidence: LlmDownloadConfidence.high,
              label: 'Download'),
          dl('https://a.com/patch.zip',
              kind: LlmDownloadKind.direct,
              confidence: LlmDownloadConfidence.high,
              label: 'Patch (0.3.1 → 0.3.1b)'),
          dl('https://a.com/old.zip',
              kind: LlmDownloadKind.direct,
              confidence: LlmDownloadConfidence.low),
        ]),
      );

      final tie = primaryTieSet(candidates);
      expect(tie, hasLength(2));
      expect(tie.map((c) => c.label),
          containsAll(['Download', 'Patch (0.3.1 → 0.3.1b)']));
    });

    test('tie set is a single candidate in the common case', () {
      final candidates = resolveDownloadCandidates(
        mod(directDownload: 'https://catalog.com/mod.zip'),
        null,
      );
      expect(primaryTieSet(candidates), hasLength(1));
    });
  });
}
