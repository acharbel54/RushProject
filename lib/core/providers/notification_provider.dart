import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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

  // Initialiser le provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      _setError(null);
      
      // Initialiser le service de notifications
      await _notificationService.initialize();
      
      // Charger les notifications existantes
      await fetchNotifications();
      
      // Écouter les nouvelles notifications
      _listenToNotifications();
      
      _isInitialized = true;
    } catch (e) {
      _setError('Erreur lors de l\'initialisation des notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger les notifications de l'utilisateur
  Future<void> fetchNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      _updateUnreadCount();
    } catch (e) {
      _setError('Erreur lors du chargement des notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Écouter les nouvelles notifications en temps réel
  void _listenToNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
        _updateUnreadCount();
        notifyListeners();
      },
      onError: (error) {
        _setError('Erreur lors de l\'écoute des notifications: $error');
      },
    );
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Mettre à jour localement
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

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead);
      
      for (final notification in unreadNotifications) {
        final docRef = _firestore.collection('notifications').doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }
      
      await batch.commit();
      
      // Mettre à jour localement
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

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Mettre à jour localement
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
    }
  }

  // Supprimer toutes les notifications
  Future<void> deleteAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      
      final batch = _firestore.batch();
      
      for (final notification in _notifications) {
        final docRef = _firestore.collection('notifications').doc(notification.id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      
      // Mettre à jour localement
      _notifications.clear();
      _updateUnreadCount();
    } catch (e) {
      _setError('Erreur lors de la suppression de toutes les notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Envoyer une notification à un utilisateur spécifique
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Sera généré par Firestore
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data ?? {},
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      _setError('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  // Envoyer une notification de nouvelle réservation
  Future<void> sendNewReservationNotification({
    required String donorId,
    required String donationTitle,
    required String beneficiaryName,
    required String reservationId,
  }) async {
    await sendNotificationToUser(
      userId: donorId,
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

  // Envoyer une notification de confirmation de réservation
  Future<void> sendReservationConfirmedNotification({
    required String beneficiaryId,
    required String donationTitle,
    required String donorName,
    required String reservationId,
  }) async {
    await sendNotificationToUser(
      userId: beneficiaryId,
      title: 'Réservation confirmée',
      body: '$donorName a confirmé votre réservation pour "$donationTitle"',
      type: NotificationType.reservationConfirmed,
      data: {
        'reservationId': reservationId,
        'donationTitle': donationTitle,
        'donorName': donorName,
      },
    );
  }

  // Envoyer une notification d'annulation de réservation
  Future<void> sendReservationCancelledNotification({
    required String userId,
    required String donationTitle,
    required String reason,
    required String reservationId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Réservation annulée',
      body: 'Votre réservation pour "$donationTitle" a été annulée. Raison: $reason',
      type: NotificationType.reservationCancelled,
      data: {
        'reservationId': reservationId,
        'donationTitle': donationTitle,
        'reason': reason,
      },
    );
  }

  // Envoyer une notification de nouveau don
  Future<void> sendNewDonationNotification({
    required String beneficiaryId,
    required String donationTitle,
    required String donorName,
    required String donationId,
  }) async {
    await sendNotificationToUser(
      userId: beneficiaryId,
      title: 'Nouveau don disponible',
      body: '$donorName a publié un nouveau don: "$donationTitle"',
      type: NotificationType.newDonation,
      data: {
        'donationId': donationId,
        'donationTitle': donationTitle,
        'donorName': donorName,
      },
    );
  }

  // Envoyer une notification d'expiration de don
  Future<void> sendDonationExpiringNotification({
    required String donorId,
    required String donationTitle,
    required String donationId,
    required int hoursUntilExpiry,
  }) async {
    await sendNotificationToUser(
      userId: donorId,
      title: 'Don bientôt expiré',
      body: 'Votre don "$donationTitle" expire dans $hoursUntilExpiry heures',
      type: NotificationType.donationExpiring,
      data: {
        'donationId': donationId,
        'donationTitle': donationTitle,
        'hoursUntilExpiry': hoursUntilExpiry,
      },
    );
  }

  // Obtenir le token FCM de l'appareil
  Future<String?> getDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      _setError('Erreur lors de l\'obtention du token: $e');
      return null;
    }
  }

  // Souscrire à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      _setError('Erreur lors de la souscription au topic: $e');
    }
  }

  // Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      _setError('Erreur lors du désabonnement du topic: $e');
    }
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

  // Envoyer une notification de test
  Future<void> sendTestNotification() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await sendNotificationToUser(
      userId: user.uid,
      title: 'Notification de test',
      body: 'Ceci est une notification de test pour vérifier que le système fonctionne correctement.',
      type: NotificationType.systemMessage,
    );
  }

  // Effacer toutes les notifications
  Future<void> clearAllNotifications() async {
    await deleteAllNotifications();
  }

  // Réinitialiser le provider
  void reset() {
    _notifications.clear();
    _isLoading = false;
    _error = null;
    _unreadCount = 0;
    _isInitialized = false;
    notifyListeners();
  }
}