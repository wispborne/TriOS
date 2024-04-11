import 'dart:math';

import 'package:flutter/material.dart';

extension Append on String {
  String prepend(String text) => text + this;
  String append(String text) => this + text;
}

extension ListExt<T> on List<T> {
  T random() {
    return this[Random().nextInt(length - 1)];
  }
}

Future<void> showMyDialog(BuildContext context, {Widget? title, List<Widget>? body}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: SelectionArea(
              child: ListBody(
                children: body ?? [],
              )),
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

Future<void> showAlertDialog(BuildContext context, {String? title, String? content}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: SingleChildScrollView(
          child: SelectionArea(
              child: ListBody(
                children: [Text(content ?? "")],
              )),
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