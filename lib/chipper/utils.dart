import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/about/about_page.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/widgets/trios_app_icon.dart';

extension Append on String {
  String prepend(String text) => text + this;

  String append(String text) => this + text;
}

extension ListExt<T> on List<T> {
  T random() {
    return this[Random().nextInt(length - 1)];
  }
}

Future<void> showMyDialog(
  BuildContext context, {
  Widget? title,
  List<Widget>? body,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: SelectionArea(child: ListBody(children: body ?? [])),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showAlertDialog(
  BuildContext context, {
  String? title,
  String? content,
  Widget? widget,
}) async {
  assert(content != null || widget != null);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: SingleChildScrollView(
          child: SelectionArea(
            child: ListBody(
              children: [
                widget ??
                    Linkify(
                      text: content ?? "",
                      onOpen: (link) {
                        OpenFilex.open(link.url);
                      },
                    ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showTriOSAboutDialog(BuildContext context) async {
  return
    showAboutDialog(
      context: context,
      applicationIcon: const TriOSAppIcon(),
      applicationName: Constants.appTitle,
      applicationVersion:
      "A Starsector toolkit\nby Wisp",
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          child: const AboutPage(),
        ),
      ],
    );
}