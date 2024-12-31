import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: SelectionArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text(
              "TriOS is a mod manager, launcher, and toolkit."
              "\nIt's written in Dart/Flutter.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text("Source Code",
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Linkify(
              text: "https://github.com/wispborne/TriOS",
              style: textTheme.labelLarge,
              linkifiers: const [UrlLinkifier()],
              onOpen: (link) {
                OpenFilex.open(link.url);
              },
            ),
            const SizedBox(height: 24),
            Text("Privacy Policy",
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Linkify(
              text:
                  "- If you choose to allow it, device information (e.g. OS and screen resolution), mod list, and TriOS errors will be collected and uploaded to servers managed by Sentry.io. The information is associated with a randomly generated id and is used to fix bugs. Example of collected data: https://i.imgur.com/k9E6zxO.png."
                  "\n- If you do not choose to allow this, TriOS only uses the internet for obvious things like version checker updates, mod updates, etc."
                  "\n- No personal information is collected at any time. I don't know who you are, where you are, what your username is, etc.",
              style: textTheme.labelLarge,
              linkifiers: const [UrlLinkifier()],
              onOpen: (link) {
                OpenFilex.open(link.url);
              },
            ),
          ],
        ),
      ),
    );
  }
}
