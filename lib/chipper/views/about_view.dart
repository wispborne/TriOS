import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../chipper_home.dart';

void showChipperAboutDialog(BuildContext context, ThemeData theme) {
  showAboutDialog(
    context: context,
    applicationName: chipperTitleAndVersion,
    applicationVersion: "$chipperSubtitle\nby Wisp",
    applicationIcon: Image.asset(
      "assets/images/chipper/icon.png",
      width: 72,
      height: 72,
    ),
    children: [
      Column(
        children: [
          Text("What's it do?", style: theme.textTheme.titleLarge),
          SizedBox.fromSize(size: const Size.fromHeight(5)),
          const Text(
            "Chipper pulls useful information out of the log for easier viewing.\n\nThe first part of troubleshooting Starsector issues is looking through a log file for errors and/or outdated mods.",
          ),
          SizedBox.fromSize(size: const Size.fromHeight(20)),
          Text(
            "\nWhat do you do with my logs?",
            style: theme.textTheme.titleLarge,
          ),
          SizedBox.fromSize(size: const Size.fromHeight(5)),
          const Text(
            "Nothing; I can't see them. Everything is done on your browser. Neither the file nor any part of it are ever sent over the Internet.\n\nI do not collect any analytics except for what Cloudflare, the hosting provider, collects by default, which is all anonymous.",
          ),
          SizedBox.fromSize(size: const Size.fromHeight(30)),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "\nCreated using Flutter, by Google "),
                TextSpan(
                  text: "so it'll probably get discontinued next year.",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Linkify(
            text: "Source Code: https://github.com/wispborne/chipper",
            linkifiers: const [UrlLinkifier()],
            onOpen: (link) => launchUrl(Uri.parse(link.url)),
          ),
        ],
      ),
    ],
  );
}
