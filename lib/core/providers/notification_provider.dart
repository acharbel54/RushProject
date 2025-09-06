import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../config/app_config.dart';

class NotificationProvider with ChangeNotifier {
  // Stockage local des notifications
  static final List<NotificationModel> _localNotifications = [];
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  bool _isInitialized = false;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get isInitialized => _isInitialized;

  // Initialiser le provider (version locale)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      
      // Charger les notifications locales
      await fetchNotifications();
      
      _isInitialized = true;
    } catch (e) {
      _setError('Erreur lors de l\'initialisation des notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger les notifications locales
  Future<void> fetchNotifications() async {
    try {
      _setLoading(true);
      _setError(null);

      // Utiliser les notifications locales
      _notifications = List.from(_localNotifications);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _updateUnreadCount();
    } catch (e) {
      _setError('Erreur lors du chargement des notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Marquer une notification comme lue (version locale)
  Future<void> markAsRead(String notificationId) async {
    try {
      // Mettre à jour dans le stockage local
      final localIndex = _localNotifications.indexWhere((n) => n.id == notificationId);
      if (localIndex != -1) {
        _localNotifications[localIndex] = _localNotifications[localIndex].copyWith(isRead: true);
      }

      // Mettre à jour dans la liste affichée
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors du marquage comme lu: $e');
    }
  }

  // Marquer toutes les notifications comme lues (version locale)
  Future<void> markAllAsRead() async {
    try {
      _setLoading(true);
      
      // Mettre à jour dans le stockage local
      for (int i = 0; i < _localNotifications.length; i++) {
        _localNotifications[i] = _localNotifications[i].copyWith(isRead: true);
      }
      
      // Mettre à jour dans la liste affichée
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _updateUnreadCount();
    } catch (e) {
      _setError('Erreur lors du marquage de toutes les notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer une notification (version locale)
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Supprimer du stockage local
      _localNotifications.removeWhere((n) => n.id == notificationId);
      
      // Mettre à jour la liste affichée
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
    }
  }

  // Supprimer toutes les notifications (version locale)
  Future<void> deleteAllNotifications() async {
    try {
      _setLoading(true);
      
      // Vider le stockage local
      _localNotifications.clear();
      
      // Mettre à jour la liste affichée
      _notifications.clear();
      _updateUnreadCount();
    } catch (e) {
      _setError('Erreur lors de la suppression de toutes les notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter une notification locale
  Future<void> addLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'local_user',
        title: title,
        body: body,
        type: type,
        data: data ?? {},
        isRead: false,
        createdAt: DateTime.now(),
      );

      // Ajouter au stockage local
      _localNotifications.add(notification);
      
      // Rafraîchir la liste
      await fetchNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de l\'ajout de la notification: $e');
    }
  }

  // Envoyer une notification de nouvelle réservation (version locale)
  Future<void> sendNewReservationNotification({
    required String donorId,
    required String donationTitle,
    required String beneficiaryName,
    required String reservationId,
  }) async {
    await addLocalNotification(
      title: 'Nouvelle réservation',
      body: '$beneficiaryName a réservé votre don "$donationTitle"',
      type: NotificationType.newReservation,
      data: {
        'reservationId': reservationId,
        'donationTitle': donationTitle,
        'beneficiaryName': beneficiaryName,
      },
    );
  }

  // Envoyer une notification de confirmation de réservation (version locale)
  Future<void> sendReservationConfirmedNotification(
    String beneficiaryId,
    String reservationId,
  ) async {
    await addLocalNotification(
      title: 'Réservation confirmée',
      body: 'Votre réservation a été confirmée par le donateur',
      type: NotificationType.reservationConfirmed,
      data: {
        'reservationId': reservationId,
      },
    );
  }

  // Envoyer une notification d'annulation de réservation (version locale)
  Future<void> sendReservationCancelledNotification(
    String beneficiaryId,
    String reservationId,
  ) async {
    await addLocalNotification(
      title: 'Réservation annulée',
      body: 'Votre réservation a été annulée par le donateur',
      type: NotificationType.reservationCancelled,
      data: {
        'reservationId': reservationId,
      },
    );
  }

  // Envoyer une notification de test (version locale)
  Future<void> sendTestNotification() async {
    await addLocalNotification(
      title: 'Notification de test',
      body: 'Ceci est une notification de test pour vérifier que le système fonctionne correctement.',
      type: NotificationType.systemMessage,
    );
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // Nettoyer les ressources
  @override
  void dispose() {
    super.dispose();
  }

  // Effacer toutes les notifications (version locale)
  Future<void> clearAllNotifications() async {
    await deleteAllNotifications();
  }

  // Réinitialiser le provider
  void reset() {
    _notifications.clear();
    _localNotifications.clear();
    _isLoading = false;
    _error = null;
    _unreadCount = 0;
    _isInitialized = false;
    notifyListeners();
  }
}