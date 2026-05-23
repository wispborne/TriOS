/// Time units for clamping [relativeTimestamp] output.
enum TimeUnit { seconds, minutes, hours, days, weeks, months, years }

extension RelativeTimeExtension on DateTime {
  /// Human-readable relative time, e.g. "5 minutes ago", "in 3 days".
  ///
  /// [minUnit] — smallest unit to display. Anything below is shown as
  /// "less than a minute ago" (or whichever unit [minUnit] is).
  /// [maxUnit] — largest unit to display. Anything above is clamped.
  String relativeTimestamp({
    TimeUnit minUnit = TimeUnit.seconds,
    TimeUnit maxUnit = TimeUnit.years,
  }) {
    final Duration difference = DateTime.now().difference(this);
    final bool isPast = difference.isNegative == false;
    final int seconds = difference.inSeconds.abs();
    final int minutes = difference.inMinutes.abs();
    final int hours = difference.inHours.abs();
    final int days = difference.inDays.abs();

    String timeString;
    String unit;

    if (seconds < 60 &&
        minUnit.index <= TimeUnit.seconds.index &&
        maxUnit.index >= TimeUnit.seconds.index) {
      unit = seconds == 1 ? 'second' : 'seconds';
      timeString = '$seconds $unit';
    } else if (minutes < 60 && maxUnit.index >= TimeUnit.minutes.index) {
      // Clamp up: if below minUnit, show the minUnit value.
      final m = minutes < 1 ? 1 : minutes;
      unit = m == 1 ? 'minute' : 'minutes';
      timeString = '$m $unit';
    } else if (hours < 24 && maxUnit.index >= TimeUnit.hours.index) {
      unit = hours == 1 ? 'hour' : 'hours';
      timeString = '$hours $unit';
    } else if (days < 7 && maxUnit.index >= TimeUnit.days.index) {
      unit = days == 1 ? 'day' : 'days';
      timeString = '$days $unit';
    } else if (days < 30 && maxUnit.index >= TimeUnit.weeks.index) {
      final weeks = (days / 7).floor();
      unit = weeks == 1 ? 'week' : 'weeks';
      timeString = '$weeks $unit';
    } else if (days < 365 && maxUnit.index >= TimeUnit.months.index) {
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

  /// Compact age string relative to now: `"5s"`, `"3m"`, `"2h"`, `"4d"`.
  /// Always uses the largest unit that fits, no sign.
  String ageCompact() {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

extension CompactDurationExtension on Duration {
  /// Compact duration string: `"5s"`, `"3m"`, `"2h"`, `"4d"`.
  /// Always uses the largest unit that fits.
  String toCompactString() {
    if (inDays >= 1) return '${inDays}d';
    if (inHours >= 1) return '${inHours}h';
    if (inMinutes >= 1) return '${inMinutes}m';
    return '${inSeconds}s';
  }
}
