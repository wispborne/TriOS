import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: SelectionArea(
        child: Column(
          spacing: 16,
          children: [
            Text(
              "${context.appName} is a mod manager, launcher, and toolkit."
              "\nIt's written in Dart/Flutter.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                _title("Forum Thread", textTheme),
                _link(Constants.triosForumThread, textTheme),
              ],
            ),
            Column(
              children: [
                _title("Source Code", textTheme),
                _link("https://github.com/wispborne/TriOS", textTheme),
              ],
            ),
            Column(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                Center(child: _title("Privacy Policy", textTheme)),
                _line(
                  "• If you choose to allow it, device information (e.g. OS and screen resolution), mod list, and ${context.appName} errors will be collected and uploaded to servers managed by Sentry.io. The information is associated with a randomly generated id and is used to fix bugs. Example of collected data: https://i.imgur.com/k9E6zxO.png.",
                  textTheme,
                  linkify: true,
                ),
                _line(
                  "• If you do not choose to allow this, ${context.appName} only uses the internet for obvious things like version checker updates, mod updates, downloading the Mod Catalog files, etc.",
                  textTheme,
                ),
                _line(
                  "• No personal information is collected at any time. I don't know who you are, where you are, what your username is, etc.",
                  textTheme,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                Center(child: _title("AI Disclosure", textTheme)),
                _line(
                  "• AI is used to help generate the Mod Catalog (which is a text file downloaded and displayed by TriOS) by sending the HTML content of forum pages."
                  " This is used for processing that would be very difficult without AI, such as:",
                  textTheme,
                ),
                _subLine(
                  "Detecting and extracting multiple mods on a single forum page.",
                  textTheme,
                ),
                _subLine("Changelogs on the forum page.", textTheme),
                _subLine(
                  "Detecting and categorizing a wider range of download links. Links that don't exist on the forum page are ignored (hallucination prevention).",
                  textTheme,
                ),
                _subLine("Generating summaries of mods.", textTheme),
                _line("• AI is used to help write TriOS.", textTheme),
                _line(
                  "• AI is not sent mod content except that which is sent automatically while using it for coding.",
                  textTheme,
                ),
                _line(
                  "• TriOS itself does not use or contact any AI service.",
                  textTheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text, TextTheme textTheme) => Text(
    text,
    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );

  Widget _link(String url, TextTheme textTheme) => Linkify(
    text: url,
    style: textTheme.labelLarge,
    linkifiers: const [UrlLinkifier()],
    onOpen: (link) {
      OpenFilex.open(link.url);
    },
  );

  Widget _line(String text, TextTheme textTheme, {bool linkify = false}) =>
      linkify
      ? _link(text, textTheme)
      : Text(text, style: textTheme.labelLarge);

  Widget _subLine(String text, TextTheme textTheme) =>
      Text("\t\t\t\t- $text", style: textTheme.labelMedium);
}
