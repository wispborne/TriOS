import 'dart:math';

extension Append on String {
  String prepend(String text) => text + this;

  String append(String text) => this + text;
}

extension ListExt<T> on List<T> {
  T random() {
    return this[Random().nextInt(length - 1)];
  }
}
