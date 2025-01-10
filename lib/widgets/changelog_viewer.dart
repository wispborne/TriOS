import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../trios/constants.dart';
import '../trios/providers.dart';
import '../utils/extensions.dart';

class TriOSChangelogViewer extends ConsumerStatefulWidget {
  final String url;
  final Version? lastestVersionToShow;

  const TriOSChangelogViewer(
      {super.key, required this.url, required this.lastestVersionToShow});

  @override
  ConsumerState<TriOSChangelogViewer> createState() => _TriOSChangelogViewerState();
}

class _TriOSChangelogViewerState extends ConsumerState<TriOSChangelogViewer> {
  late Future<String> _markdownContent;

  @override
  void initState() {
    super.initState();
    final httpClient = ref.read(triOSHttpClient);
    _markdownContent = fetchMarkdown(widget.url, httpClient);
  }

  Future<String> fetchMarkdown(String url, TriOSHttpClient httpClient) async {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _markdownContent,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final text = widget.lastestVersionToShow == null
              ? snapshot.data
              : snapshot.data
                  ?.skipLinesWhile((line) => !line.contains(widget.lastestVersionToShow!.toStringFromParts()));

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
                child: Row(children: [
                  SvgImageIcon(
                    "assets/images/icon-bullhorn-variant.svg",
                    width: 36,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Changelog",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 24),
                  ),
                ]),
              ),
              Expanded(child: Markdown(data: text ?? '')),
            ],
          );
        }
      },
    );
  }
}

showTriOSChangelogDialog(BuildContext context,
    {required Version? lastestVersionToShow}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: SizedBox(
          width: 600,
          height: 1200,
          child: TriOSChangelogViewer(
              url: Constants.changelogUrl,
              lastestVersionToShow: lastestVersionToShow),
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
