import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String getDateKey(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String formatSecondsAgo(DateTime dt, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(dt);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return formatDate(dt);
  }
}
