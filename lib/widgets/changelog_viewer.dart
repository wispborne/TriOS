import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:trios/widgets/svg_image_icon.dart';

import '../trios/constants.dart';
import '../utils/extensions.dart';

class ChangelogViewer extends StatefulWidget {
  final String url;
  final bool showUnreleasedVersions;

  const ChangelogViewer(
      {super.key, required this.url, required this.showUnreleasedVersions});

  @override
  State<ChangelogViewer> createState() => _ChangelogViewerState();
}

class _ChangelogViewerState extends State<ChangelogViewer> {
  late Future<String> _markdownContent;

  @override
  void initState() {
    super.initState();
    _markdownContent = fetchMarkdown(widget.url);
  }

  Future<String> fetchMarkdown(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
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
          final text = widget.showUnreleasedVersions
              ? snapshot.data
              : snapshot.data
                  ?.skipLinesWhile((line) => !line.contains(Constants.version));

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
    {required bool showUnreleasedVersions}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: SizedBox(
          width: 600,
          height: 1200,
          child: ChangelogViewer(
              url: Constants.changelogUrl,
              showUnreleasedVersions: showUnreleasedVersions),
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
