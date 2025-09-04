import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newReservation,
  reservationConfirmed,
  reservationCancelled,
  reservationCompleted,
  newDonation,
  donationExpiring,
  donationExpired,
  donationUpdated,
  systemMessage,
  reminder,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  // Créer depuis Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseNotificationType(data['type']),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  // Créer depuis Map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseNotificationType(map['type']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      readAt: map['readAt'] != null
          ? (map['readAt'] is Timestamp
              ? (map['readAt'] as Timestamp).toDate()
              : DateTime.parse(map['readAt']))
          : null,
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Convertir en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Marquer comme lu
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  // Obtenir l'icône selon le type
  String get iconName {
    switch (type) {
      case NotificationType.newReservation:
        return 'bookmark_add';
      case NotificationType.reservationConfirmed:
        return 'check_circle';
      case NotificationType.reservationCancelled:
        return 'cancel';
      case NotificationType.reservationCompleted:
        return 'task_alt';
      case NotificationType.newDonation:
        return 'restaurant';
      case NotificationType.donationExpiring:
        return 'schedule';
      case NotificationType.donationExpired:
        return 'expired';
      case NotificationType.donationUpdated:
        return 'edit';
      case NotificationType.systemMessage:
        return 'info';
      case NotificationType.reminder:
        return 'notifications';
    }
  }

  // Obtenir la couleur selon le type
  String get colorHex {
    switch (type) {
      case NotificationType.newReservation:
        return '#4CAF50'; // Vert
      case NotificationType.reservationConfirmed:
        return '#2196F3'; // Bleu
      case NotificationType.reservationCancelled:
        return '#F44336'; // Rouge
      case NotificationType.reservationCompleted:
        return '#4CAF50'; // Vert
      case NotificationType.newDonation:
        return '#FF9800'; // Orange
      case NotificationType.donationExpiring:
        return '#FF5722'; // Orange foncé
      case NotificationType.donationExpired:
        return '#9E9E9E'; // Gris
      case NotificationType.donationUpdated:
        return '#2196F3'; // Bleu
      case NotificationType.systemMessage:
        return '#607D8B'; // Bleu gris
      case NotificationType.reminder:
        return '#9C27B0'; // Violet
    }
  }

  // Obtenir le temps relatif
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  // Vérifier si la notification est récente (moins de 24h)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  // Vérifier si la notification est importante
  bool get isImportant {
    switch (type) {
      case NotificationType.newReservation:
      case NotificationType.reservationConfirmed:
      case NotificationType.reservationCancelled:
      case NotificationType.donationExpiring:
        return true;
      default:
        return false;
    }
  }

  // Obtenir le titre formaté avec emoji
  String get formattedTitle {
    switch (type) {
      case NotificationType.newReservation:
        return '📋 $title';
      case NotificationType.reservationConfirmed:
        return '✅ $title';
      case NotificationType.reservationCancelled:
        return '❌ $title';
      case NotificationType.reservationCompleted:
        return '🎉 $title';
      case NotificationType.newDonation:
        return '🍽️ $title';
      case NotificationType.donationExpiring:
        return '⏰ $title';
      case NotificationType.donationExpired:
        return '⏰ $title';
      case NotificationType.donationUpdated:
        return '✏️ $title';
      case NotificationType.systemMessage:
        return 'ℹ️ $title';
      case NotificationType.reminder:
        return '🔔 $title';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.isRead == isRead &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        body.hashCode ^
        type.hashCode ^
        isRead.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead, createdAt: $createdAt)';
  }

  // Méthode utilitaire pour parser le type de notification
  static NotificationType _parseNotificationType(dynamic typeValue) {
    if (typeValue is String) {
      try {
        return NotificationType.values.firstWhere(
          (type) => type.name == typeValue,
        );
      } catch (e) {
        return NotificationType.systemMessage;
      }
    }
    return NotificationType.systemMessage;
  }

  // Créer une notification de test
  static NotificationModel createTest({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'test_user',
      title: title ?? 'Notification de test',
      body: body ?? 'Ceci est une notification de test',
      type: type ?? NotificationType.systemMessage,
      data: {'test': true},
      isRead: isRead ?? false,
      createdAt: DateTime.now(),
    );
  }
}