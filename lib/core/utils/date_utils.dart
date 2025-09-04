import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy à HH:mm');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');
  static final DateFormat _fullDateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');

  /// Formate une date au format dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formate une heure au format HH:mm
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Formate une date et heure au format dd/MM/yyyy à HH:mm
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Formate une date au format court (dd MMM)
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Formate une date au format complet (Lundi 15 janvier 2024)
  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// Retourne le temps relatif (il y a X minutes/heures/jours)
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Retourne le temps restant jusqu'à une date
  static String getTimeUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return 'Expiré';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min restantes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h restantes';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''} restant${difference.inDays > 1 ? 's' : ''}';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks semaine${weeks > 1 ? 's' : ''} restante${weeks > 1 ? 's' : ''}';
    }
  }

  /// Vérifie si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Vérifie si une date est hier
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Vérifie si une date est demain
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  /// Retourne le début de la journée (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Retourne la fin de la journée (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Ajoute des jours ouvrables à une date
  static DateTime addBusinessDays(DateTime date, int days) {
    DateTime result = date;
    int addedDays = 0;
    
    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }
    
    return result;
  }

  /// Calcule l'âge en années
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Retourne une liste des 7 derniers jours
  static List<DateTime> getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) => 
        startOfDay(now.subtract(Duration(days: index)))
    ).reversed.toList();
  }

  /// Retourne une liste des 30 derniers jours
  static List<DateTime> getLast30Days() {
    final now = DateTime.now();
    return List.generate(30, (index) => 
        startOfDay(now.subtract(Duration(days: index)))
    ).reversed.toList();
  }

  /// Formate une durée en texte lisible
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${duration.inSeconds} seconde${duration.inSeconds > 1 ? 's' : ''}';
    }
  }
}