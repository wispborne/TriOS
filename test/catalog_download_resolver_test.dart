import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/utils/extensions.dart';

ModRepoEntry mod({String? directDownload, String? forum}) => ModRepoEntry(
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

/// A trios "Install with TriOS" link whose `mod` entry points at [url], with an
/// optional version stated in the link.
ForumLlmDownload trilink(String url, {String? version}) {
  final entry = version == null
      ? url
      : jsonEncode({'url': url, 'version': version});
  return dl(
    'https://trilink.wispborne.com/open.html?mod=${Uri.encodeComponent(entry)}',
    kind: LlmDownloadKind.trios,
  );
}

VersionCheckerInfo remote(String? directDownloadUrl, {String? version}) =>
    VersionCheckerInfo(
      directDownloadURL: directDownloadUrl,
      modVersion: version == null
          ? null
          : VersionObject(
              version.split('.').elementAtOrNull(0),
              version.split('.').elementAtOrNull(1),
              version.split('.').elementAtOrNull(2),
            ),
    );

ForumLlmMod llmMod(List<ForumLlmDownload> downloads) =>
    ForumLlmMod(name: 'Test Mod', role: LlmModRole.main, downloads: downloads);

/// A thread mod with one download link, so [buildDownloadGroups] keeps it.
ForumLlmMod threadMod(
  String name, {
  LlmModRole role = LlmModRole.main,
  List<String>? requires,
}) => ForumLlmMod(
  name: name,
  role: role,
  requires: requires,
  downloads: [dl('https://example.com/${name.alphanumericLower()}.zip')],
);

ForumModIndex index(List<ForumLlmMod> mods) => ForumModIndex(
  topicId: 9035,
  title: 'Test Thread',
  inModIndex: true,
  isArchivedModIndex: false,
  author: 'Someone',
  replies: 0,
  views: 0,
  topicUrl: 'https://example.com/topic',
  isWip: false,
  llm: ForumLlmData(mods: mods),
);

List<DownloadGroup> groupsFor(
  List<ForumLlmMod> mods, {
  ForumLlmMod? dialogMod,
  Set<String> installed = const {},
}) => buildDownloadGroups(
  index: index(mods),
  dialogMod: dialogMod,
  isInstalled: installed.contains,
);

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

  group('version checker candidate', () {
    test('beats a stale catalog direct link', () {
      final candidates = resolveDownloadCandidates(
        mod(directDownload: 'https://github.com/x/download/v1.0/m_1.0.zip'),
        null,
        remoteVersion: remote(
          'https://github.com/x/download/v1.1/m_1.1.zip',
          version: '1.1',
        ),
      );

      expect(candidates.first.kind, DownloadCandidateKind.versionChecker);
      expect(candidates.first.url, 'https://github.com/x/download/v1.1/m_1.1.zip');
      expect(candidates.first.label, 'Version checker (1.1)');
    });

    test('a trios link with no version still wins', () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([trilink('https://a.com/m.zip')]),
        remoteVersion: remote('https://vc.com/m.zip', version: '1.1'),
      );

      expect(candidates.first.kind, DownloadCandidateKind.triosDeepLink);
    });

    test('a trios link pointing at a .version file still wins', () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([trilink('https://a.com/M.version', version: '1.0')]),
        remoteVersion: remote('https://vc.com/m.zip', version: '1.1'),
      );

      expect(candidates.first.kind, DownloadCandidateKind.triosDeepLink);
    });

    test('a trios link naming an older version loses to the version checker',
        () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([trilink('https://a.com/m.zip', version: '1.0')]),
        remoteVersion: remote('https://vc.com/m.zip', version: '1.1'),
      );

      expect(candidates.first.kind, DownloadCandidateKind.versionChecker);
      expect(candidates[1].kind, DownloadCandidateKind.triosDeepLink);
    });

    test('a trios link naming the same version still wins', () {
      final candidates = resolveDownloadCandidates(
        mod(),
        llmMod([trilink('https://a.com/m.zip', version: '1.1')]),
        remoteVersion: remote('https://vc.com/m.zip', version: '1.1'),
      );

      expect(candidates.first.kind, DownloadCandidateKind.triosDeepLink);
    });

    test('nothing changes when the version checker has no download link', () {
      final candidates = resolveDownloadCandidates(
        mod(directDownload: 'https://catalog.com/mod.zip'),
        null,
        remoteVersion: remote(null, version: '1.1'),
      );

      expect(candidates.single.kind, DownloadCandidateKind.catalogDirect);
    });
  });

  group('cleanModDisplayName', () {
    final cases = {
      '[0.98a] Red - the Oculian Armada (0.10.2-RC4) Mod':
          'Red - the Oculian Armada',
      'Scy V1.66rc3 (2023/03/19)': 'Scy',
      '[0.98a-RC5] Machina Void Shipyards v. 0.70a': 'Machina Void Shipyards',
      'Sardaukar [0.6.1a]': 'Sardaukar',
      'GraphicsLib 1.0.4': 'GraphicsLib',
      'LazyLib 2.2 (Updated)': 'LazyLib',
      '[0.8.1a] Degenerate Portrait Pack v1.1': 'Degenerate Portrait Pack',
      // Nothing to strip: an ampersand and a plain name both survive whole.
      '[0.98a] Azur Lane Vanilla Portrait Replacer & Extra Portraits':
          'Azur Lane Vanilla Portrait Replacer & Extra Portraits',
      'Nexerelin': 'Nexerelin',
      'Red': 'Red',
    };

    cases.forEach((raw, expected) {
      test('"$raw" -> "$expected"', () {
        expect(cleanModDisplayName(raw), expected);
      });
    });

    test('a name that is only decoration keeps its raw text', () {
      expect(cleanModDisplayName('[0.98a]'), '[0.98a]');
    });
  });

  group('modNamesMatch', () {
    test('matches once the decoration is gone', () {
      expect(modNamesMatch('GraphicsLib 1.0.4', 'GraphicsLib'), isTrue);
      expect(modNamesMatch('Sardaukar [0.6.1a]', 'sardaukar'), isTrue);
    });

    test('falls back to letters and numbers only', () {
      expect(modNamesMatch('Nexerelin', 'Nex-erelin!'), isTrue);
    });

    test('different mods do not match', () {
      expect(modNamesMatch('LazyLib', 'GraphicsLib'), isFalse);
    });
  });

  group('buildDownloadGroups', () {
    final armada = threadMod('Red - the Oculian Armada');
    final addon = threadMod(
      'Ocutek Pirates Addon',
      role: LlmModRole.addon,
      requires: ['Red - the Oculian Armada'],
    );

    test('the add-on leads its own dialog, the main mod follows', () {
      final groups = groupsFor([armada, addon], dialogMod: addon);

      expect(groups.first.modName, 'Ocutek Pirates Addon');
      expect(groups.first.isDialogMod, isTrue);
      expect(groups[1].modName, 'Red - the Oculian Armada');
      expect(groups[1].isDialogMod, isFalse);
      expect(groups[1].requiredByDialogMod, isTrue);
    });

    test('the main mod leads its own dialog', () {
      final groups = groupsFor([armada, addon], dialogMod: armada);

      expect(groups.first.isDialogMod, isTrue);
      expect(groups.first.modName, 'Red - the Oculian Armada');
      expect(groups[1].modName, 'Ocutek Pirates Addon');
      expect(groups[1].requiredByDialogMod, isFalse);
    });

    test('with no match the main mod leads and is not flagged as the dialog mod', () {
      final groups = groupsFor([addon, armada]);

      expect(groups.first.modName, 'Red - the Oculian Armada');
      expect(groups.first.isDialogMod, isFalse);
    });

    test('a required mod sorts above the rest of the thread', () {
      final other = threadMod('Some Portrait Pack', role: LlmModRole.separate);
      final groups = groupsFor([armada, other, addon], dialogMod: addon);

      expect(groups.map((g) => g.modName), [
        'Ocutek Pirates Addon',
        'Red - the Oculian Armada',
        'Some Portrait Pack',
      ]);
    });

    test('dependencies are built for the dialog mod, not just the main mod', () {
      final needy = threadMod(
        'Ocutek Pirates Addon',
        role: LlmModRole.addon,
        requires: ['GraphicsLib 1.0.4'],
      );
      final groups = groupsFor([armada, needy], dialogMod: needy);

      expect(groups.first.dependencies.single.name, 'GraphicsLib');
      expect(groups[1].dependencies, isEmpty);
    });

    test('a dependency with its own row is not also listed under the button', () {
      final groups = groupsFor([armada, addon], dialogMod: addon);

      expect(groups.first.dependencies, isEmpty);
    });

    test('the installed check is asked with the cleaned name', () {
      final needy = threadMod(
        'Ocutek Pirates Addon',
        role: LlmModRole.addon,
        requires: ['GraphicsLib 1.0.4'],
      );
      final groups = groupsFor(
        [needy],
        dialogMod: needy,
        installed: {'GraphicsLib'},
      );

      expect(groups.first.dependencies.single.installed, isTrue);
    });

    test('rows keep the raw name for downloads and records', () {
      final raw = threadMod('[0.98a] Red - the Oculian Armada (0.10.2-RC4) Mod');
      final groups = groupsFor([raw], dialogMod: raw);

      expect(groups.single.modName, 'Red - the Oculian Armada');
      expect(
        groups.single.rawModName,
        '[0.98a] Red - the Oculian Armada (0.10.2-RC4) Mod',
      );
    });

    test('a mod the thread only mentions gets no row', () {
      final mentioned = ForumLlmMod(
        name: 'Mentioned Only',
        role: LlmModRole.separate,
      );
      final groups = groupsFor([armada, mentioned], dialogMod: armada);

      expect(groups.map((g) => g.modName), ['Red - the Oculian Armada']);
    });
  });
}
