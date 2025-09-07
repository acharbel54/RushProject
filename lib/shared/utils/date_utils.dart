import 'package:intl/intl.dart';

class AppDateUtils {
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  static String formatDate(DateTime dateTime, {String? format}) {
    final formatter = DateFormat(format ?? 'dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  static String formatDateTime(DateTime dateTime, {String? format}) {
    final formatter = DateFormat(format ?? 'dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  static String formatTime(DateTime dateTime, {String? format}) {
    final formatter = DateFormat(format ?? 'HH:mm');
    return formatter.format(dateTime);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  static String getDateLabel(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      return formatDate(date);
    }
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  static bool isExpired(DateTime expiryDate) {
    return expiryDate.isBefore(DateTime.now());
  }

  static bool isExpiringSoon(DateTime expiryDate, {int daysThreshold = 2}) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= daysThreshold && difference >= 0;
  }

  static String getExpirationStatus(DateTime expiryDate) {
    if (isExpired(expiryDate)) {
      return 'Expired';
    } else if (isExpiringSoon(expiryDate)) {
      final daysLeft = daysBetween(DateTime.now(), expiryDate);
      if (daysLeft == 0) {
        return 'Expires today';
      } else if (daysLeft == 1) {
        return 'Expires tomorrow';
      } else {
        return 'Expires in $daysLeft days';
      }
    } else {
      final daysLeft = daysBetween(DateTime.now(), expiryDate);
      if (daysLeft < 7) {
        return 'Expires in $daysLeft days';
      } else if (daysLeft < 30) {
        final weeks = (daysLeft / 7).floor();
        return weeks == 1 ? 'Expires in 1 week' : 'Expires in $weeks weeks';
      } else {
        final months = (daysLeft / 30).floor();
        return months == 1 ? 'Expires in 1 month' : 'Expires in $months months';
      }
    }
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  static DateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  static List<DateTime> getDaysInMonth(DateTime date) {
    final firstDay = startOfMonth(date);
    final lastDay = endOfMonth(date);
    final days = <DateTime>[];
    
    for (var day = firstDay; day.isBefore(lastDay) || isSameDay(day, lastDay); day = day.add(const Duration(days: 1))) {
      days.add(day);
    }
    
    return days;
  }

  static String getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  static String getDayName(int weekday) {
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return dayNames[weekday - 1];
  }

  static String getShortDayName(int weekday) {
    const shortDayNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return shortDayNames[weekday - 1];
  }
}