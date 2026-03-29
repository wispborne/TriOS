import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../trios/constants.dart';
import '../utils/extensions.dart';

final changelogProvider = AsyncNotifierProvider<ChangelogNotifier, String>(
  ChangelogNotifier.new,
);

class ChangelogNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() => _fetchChangelog();

  Future<String> _fetchChangelog() async {
    final httpClient = ref.read(triOSHttpClient);
    try {
      final releasesResponse = await httpClient.get(
        Constants.changelogReleasesApiUrl,
        allowSelfSignedCertificates: true,
      );

      if (releasesResponse.statusCode == 200) {
        var data = releasesResponse.data;
        if (data is String) {
          data = jsonDecode(data);
        }

        final releases = data as List<dynamic>;
        if (releases.isNotEmpty) {
          final branch =
              releases.first['target_commitish'] as String? ?? 'main';
          final branchUrl = Constants.changelogUrlForBranch(branch);
          return await _fetchMarkdownFromUrl(branchUrl, httpClient);
        }
      }
    } catch (e) {
      Fimber.i(
        'Failed to resolve changelog branch from releases API, '
        'falling back to main: $e',
      );
    }

    return _fetchMarkdownFromUrl(Constants.changelogFallbackUrl, httpClient);
  }

  Future<String> _fetchMarkdownFromUrl(
    String url,
    TriOSHttpClient httpClient,
  ) async {
    final response = await httpClient.get(
      url,
      allowSelfSignedCertificates: true,
    );
    if (response.statusCode == 200) {
      var data = response.data;

      if (data is List<int>) {
        data = utf8.decode(data);
      }

      final String body = data;
      return body;
    } else {
      throw Exception('Failed to load Markdown content');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchChangelog);
  }
}

class TriOSChangelogViewer extends ConsumerStatefulWidget {
  final Version? lastestVersionToShow;

  const TriOSChangelogViewer({super.key, required this.lastestVersionToShow});

  @override
  ConsumerState<TriOSChangelogViewer> createState() =>
      _TriOSChangelogViewerState();
}

class _TriOSChangelogViewerState extends ConsumerState<TriOSChangelogViewer> {
  String? _selectedVersion;

  static final _versionHeaderPattern = RegExp(r'^# \d');

  static List<String> _parseVersionHeaders(String content) {
    return content
        .split('\n')
        .where((line) => _versionHeaderPattern.hasMatch(line.trim()))
        .map((line) => line.substring(2).trim())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final changelogAsync = ref.watch(changelogProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 12,
            right: 24,
            bottom: 0,
          ),
          child: Row(
            children: [
              SvgImageIcon(
                "assets/images/icon-bullhorn-variant.svg",
                width: 36,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                "Changelog",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 24),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Refresh changelog",
                onPressed: () {
                  ref.read(changelogProvider.notifier).refresh();
                },
              ),
            ],
          ),
        ),
        changelogAsync.whenOrNull(
              data: (content) {
                final baseContent = widget.lastestVersionToShow == null
                    ? content
                    : content.skipLinesWhile(
                        (line) => !line.contains(
                          widget.lastestVersionToShow!.toStringFromParts(),
                        ),
                      );
                final versions = _parseVersionHeaders(baseContent);
                if (versions.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: .symmetric(horizontal: 12),
                    child: Row(
                      spacing: 8,
                      children: [
                        for (final version in versions)
                          ActionChip(
                            label: Text(version),
                            backgroundColor: _selectedVersion == version
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            onPressed: () {
                              setState(() {
                                _selectedVersion = _selectedVersion == version
                                    ? null
                                    : version;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ) ??
            const SizedBox.shrink(),
        Expanded(
          child: changelogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (content) {
              var text = widget.lastestVersionToShow == null
                  ? content
                  : content.skipLinesWhile(
                      (line) => !line.contains(
                        widget.lastestVersionToShow!.toStringFromParts(),
                      ),
                    );
              if (_selectedVersion != null) {
                text = text.skipLinesWhile(
                  (line) => !line.startsWith('# $_selectedVersion'),
                );
              }
              return Markdown(data: text);
            },
          ),
        ),
      ],
    );
  }
}

void showTriOSChangelogDialog(
  BuildContext context, {
  required Version? lastestVersionToShow,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: SizedBox(
          width: 600,
          height: 1200,
          child: TriOSChangelogViewer(
            lastestVersionToShow: lastestVersionToShow,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}
