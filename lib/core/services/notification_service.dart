import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialiser le service de notifications
  Future<void> initialize() async {
    try {
      // Demander les permissions
      await _requestPermissions();
      
      // Initialiser les notifications locales
      // await _initializeLocalNotifications();
      
      // Configurer les handlers de messages
      _configureMessageHandlers();
      
      // Obtenir et sauvegarder le token FCM
      await _saveDeviceToken();
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation des notifications: $e');
    }
  }
  
  // Demander les permissions de notification
  Future<void> _requestPermissions() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw Exception('Permissions de notification refusées');
    }
  }
  
  // Initialiser les notifications locales
  /*Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }*/
  
  // Configurer les handlers de messages
  void _configureMessageHandlers() {
    // Message reçu quand l'app est en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Message reçu quand l'app est en background et que l'utilisateur tape sur la notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Vérifier si l'app a été ouverte depuis une notification
    _checkInitialMessage();
  }
  
  // Sauvegarder le token FCM de l'appareil
  Future<void> _saveDeviceToken() async {
    try {
      final String? token = await _messaging.getToken();
      final User? user = _auth.currentUser;
      
      if (token != null && user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
      
      // Écouter les changements de token
      _messaging.onTokenRefresh.listen((newToken) {
        _updateDeviceToken(newToken);
      });
    } catch (e) {
      // Ignorer les erreurs de token pour ne pas bloquer l'app
      print('Erreur lors de la sauvegarde du token: $e');
    }
  }
  
  // Mettre à jour le token FCM
  Future<void> _updateDeviceToken(String newToken) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du token: $e');
    }
  }
  
  // Gérer les messages en foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      await _showLocalNotification(
        title: message.notification?.title ?? 'Nouvelle notification',
        body: message.notification?.body ?? '',
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification: $e');
    }
  }
  
  // Gérer les messages en background
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      // Naviguer vers l'écran approprié selon le type de notification
      _handleNotificationNavigation(message.data);
    } catch (e) {
      print('Erreur lors de la gestion du message background: $e');
    }
  }
  
  // Vérifier le message initial (app ouverte depuis une notification)
  Future<void> _checkInitialMessage() async {
    try {
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationNavigation(initialMessage.data);
      }
    } catch (e) {
      print('Erreur lors de la vérification du message initial: $e');
    }
  }
  
  // Afficher une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    /*const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'foodlink_channel',
      'FoodLink Notifications',
      channelDescription: 'Notifications pour l\'application FoodLink',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );*/
    
    /*await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );*/
  }
  
  // Gérer le tap sur une notification
  /*void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      print('Erreur lors de la gestion du tap sur notification: $e');
    }
  }*/
  
  // Gérer la navigation selon le type de notification
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? id = data['id'];
    
    switch (type) {
      case 'new_reservation':
        // Naviguer vers les détails de la réservation
        break;
      case 'reservation_confirmed':
        // Naviguer vers les réservations confirmées
        break;
      case 'reservation_cancelled':
        // Naviguer vers les réservations annulées
        break;
      case 'new_donation':
        // Naviguer vers les détails du don
        break;
      case 'donation_expired':
        // Naviguer vers les dons expirés
        break;
      default:
        // Naviguer vers l'écran principal
        break;
    }
  }
  
  // Envoyer une notification de nouvelle réservation
  Future<void> sendNewReservationNotification({
    required String donorId,
    required String donationTitle,
    required String beneficiaryName,
    required String reservationId,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: donorId,
        title: 'Nouvelle réservation',
        body: '$beneficiaryName a réservé votre don "$donationTitle"',
        data: {
          'type': 'new_reservation',
          'id': reservationId,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification de réservation: $e');
    }
  }
  
  // Envoyer une notification de confirmation de réservation
  Future<void> sendReservationConfirmedNotification({
    required String beneficiaryId,
    required String donationTitle,
    required String donorName,
    required String reservationId,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: beneficiaryId,
        title: 'Réservation confirmée',
        body: '$donorName a confirmé votre réservation pour "$donationTitle"',
        data: {
          'type': 'reservation_confirmed',
          'id': reservationId,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification de confirmation: $e');
    }
  }
  
  // Envoyer une notification d'annulation de réservation
  Future<void> sendReservationCancelledNotification({
    required String userId,
    required String donationTitle,
    required String reason,
    required String reservationId,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: userId,
        title: 'Réservation annulée',
        body: 'Votre réservation pour "$donationTitle" a été annulée. Raison: $reason',
        data: {
          'type': 'reservation_cancelled',
          'id': reservationId,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification d\'annulation: $e');
    }
  }
  
  // Envoyer une notification de nouveau don à proximité
  Future<void> sendNewDonationNearbyNotification({
    required List<String> userIds,
    required String donationTitle,
    required String donationId,
    required double distance,
  }) async {
    try {
      for (final String userId in userIds) {
        await _sendNotificationToUser(
          userId: userId,
          title: 'Nouveau don à proximité',
          body: '"$donationTitle" est disponible à ${distance.toStringAsFixed(1)} km de vous',
          data: {
            'type': 'new_donation',
            'id': donationId,
          },
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi des notifications de proximité: $e');
    }
  }
  
  // Envoyer une notification de don expirant bientôt
  Future<void> sendDonationExpiringNotification({
    required String donorId,
    required String donationTitle,
    required String donationId,
    required int hoursUntilExpiry,
  }) async {
    try {
      await _sendNotificationToUser(
        userId: donorId,
        title: 'Don expirant bientôt',
        body: 'Votre don "$donationTitle" expire dans $hoursUntilExpiry heures',
        data: {
          'type': 'donation_expiring',
          'id': donationId,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification d\'expiration: $e');
    }
  }
  
  // Envoyer une notification à un utilisateur spécifique
  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Récupérer les tokens FCM de l'utilisateur
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return;
      
      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic>? fcmTokens = userData['fcmTokens'];
      
      if (fcmTokens == null || fcmTokens.isEmpty) return;
      
      // Envoyer la notification à tous les tokens de l'utilisateur
      for (final dynamic token in fcmTokens) {
        if (token is String) {
          await _sendPushNotification(
            token: token,
            title: title,
            body: body,
            data: data,
          );
        }
      }
      
      // Sauvegarder la notification dans Firestore pour l'historique
      await _saveNotificationToHistory(
        userId: userId,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification à l\'utilisateur: $e');
    }
  }
  
  // Envoyer une notification push via FCM
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Note: Dans une implémentation complète, on utiliserait l'API REST de FCM
      // ou Firebase Admin SDK côté serveur pour envoyer les notifications
      // Ici, on simule l'envoi
      
      print('Notification envoyée à $token: $title - $body');
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification push: $e');
    }
  }
  
  // Sauvegarder la notification dans l'historique
  Future<void> _saveNotificationToHistory({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde de la notification: $e');
    }
  }
  
  // Obtenir l'historique des notifications d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des notifications: $e');
    }
  }
  
  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors du marquage de la notification: $e');
    }
  }
  
  // Marquer toutes les notifications comme lues
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final WriteBatch batch = _firestore.batch();
      
      for (final DocumentSnapshot doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du marquage de toutes les notifications: $e');
    }
  }
  
  // Obtenir le nombre de notifications non lues
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final AggregateQuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Erreur lors du comptage des notifications non lues: $e');
    }
  }
  
  // Nettoyer les anciennes notifications
  Future<void> cleanupOldNotifications({int maxAgeInDays = 30}) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      
      final QuerySnapshot querySnapshot = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      final WriteBatch batch = _firestore.batch();
      
      for (final DocumentSnapshot doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du nettoyage des notifications: $e');
    }
  }
}

// Handler pour les messages en background (doit être une fonction top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Message reçu en background: ${message.messageId}');
}