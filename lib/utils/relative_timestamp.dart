extension RelativeTimeExtension on DateTime {
  String relativeTimestamp() {
    final Duration difference = DateTime.now().difference(this);
    final bool isPast = difference.isNegative == false;
    final int seconds = difference.inSeconds.abs();
    final int minutes = difference.inMinutes.abs();
    final int hours = difference.inHours.abs();
    final int days = difference.inDays.abs();

    String timeString;
    String unit;

    if (seconds < 60) {
      unit = seconds == 1 ? 'second' : 'seconds';
      timeString = '$seconds $unit';
    } else if (minutes < 60) {
      unit = minutes == 1 ? 'minute' : 'minutes';
      timeString = '$minutes $unit';
    } else if (hours < 24) {
      unit = hours == 1 ? 'hour' : 'hours';
      timeString = '$hours $unit';
    } else if (days < 7) {
      unit = days == 1 ? 'day' : 'days';
      timeString = '$days $unit';
    } else if (days < 30) {
      final weeks = (days / 7).floor();
      unit = weeks == 1 ? 'week' : 'weeks';
      timeString = '$weeks $unit';
    } else if (days < 365) {
      final months = (days / 30).floor();
      unit = months == 1 ? 'month' : 'months';
      timeString = '$months $unit';
    } else {
      final years = (days / 365).floor();
      unit = years == 1 ? 'year' : 'years';
      timeString = '$years $unit';
    }

    return isPast ? '$timeString ago' : 'in $timeString';
  }
}
