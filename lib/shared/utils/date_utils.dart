import 'package:intl/intl.dart';

class AppDateUtils {
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'il y a 1 jour';
      } else if (difference.inDays < 7) {
        return 'il y a ${difference.inDays} jours';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? 'il y a 1 semaine' : 'il y a $weeks semaines';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? 'il y a 1 mois' : 'il y a $months mois';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? 'il y a 1 an' : 'il y a $years ans';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? 'il y a 1 heure'
          : 'il y a ${difference.inHours} heures';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? 'il y a 1 minute'
          : 'il y a ${difference.inMinutes} minutes';
    } else {
      return 'à l\'instant';
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
      return 'Aujourd\'hui';
    } else if (isYesterday(date)) {
      return 'Hier';
    } else if (isTomorrow(date)) {
      return 'Demain';
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
      return 'Expiré';
    } else if (isExpiringSoon(expiryDate)) {
      final daysLeft = daysBetween(DateTime.now(), expiryDate);
      if (daysLeft == 0) {
        return 'Expire aujourd\'hui';
      } else if (daysLeft == 1) {
        return 'Expire demain';
      } else {
        return 'Expire dans $daysLeft jours';
      }
    } else {
      final daysLeft = daysBetween(DateTime.now(), expiryDate);
      if (daysLeft < 7) {
        return 'Expire dans $daysLeft jours';
      } else if (daysLeft < 30) {
        final weeks = (daysLeft / 7).floor();
        return weeks == 1 ? 'Expire dans 1 semaine' : 'Expire dans $weeks semaines';
      } else {
        final months = (daysLeft / 30).floor();
        return months == 1 ? 'Expire dans 1 mois' : 'Expire dans $months mois';
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
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return monthNames[month - 1];
  }

  static String getDayName(int weekday) {
    const dayNames = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return dayNames[weekday - 1];
  }

  static String getShortDayName(int weekday) {
    const shortDayNames = [
      'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
    ];
    return shortDayNames[weekday - 1];
  }
}