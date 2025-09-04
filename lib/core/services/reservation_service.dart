import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference
  CollectionReference get _reservationsCollection => _firestore.collection('reservations');
  
  // Créer une réservation
  Future<String> createReservation({
    required String donationId,
    required String donorId,
    required String donationTitle,
    required String donationDescription,
    required String donorName,
    required String pickupAddress,
    required DateTime scheduledPickupTime,
    String? contactPhone,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      final reservationModel = ReservationModel(
        id: '', // Sera généré par Firestore
        donationId: donationId,
        userId: user.uid,
        donorId: donorId,
        donationTitle: donationTitle,
        donationDescription: donationDescription,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        donorName: donorName,
        pickupAddress: pickupAddress,
        scheduledPickupTime: scheduledPickupTime,
        contactPhone: contactPhone,
        notes: notes,
      );
      
      final docRef = await _reservationsCollection.add(reservationModel.toFirestore());
      
      // Mettre à jour l'ID du document
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }
  
  // Obtenir une réservation par ID
  Future<ReservationModel?> getReservationById(String reservationId) async {
    try {
      final doc = await _reservationsCollection.doc(reservationId).get();
      if (doc.exists) {
        return ReservationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la réservation: $e');
    }
  }
  
  // Obtenir les réservations d'un utilisateur (bénéficiaire)
  Future<List<ReservationModel>> getUserReservations(String userId) async {
    try {
      final querySnapshot = await _reservationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations de l\'utilisateur: $e');
    }
  }
  
  // Obtenir les réservations d'un donateur
  Future<List<ReservationModel>> getDonorReservations(String donorId) async {
    try {
      final querySnapshot = await _reservationsCollection
          .where('donorId', isEqualTo: donorId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations du donateur: $e');
    }
  }
  
  // Obtenir les réservations par statut
  Future<List<ReservationModel>> getReservationsByStatus(
    ReservationStatus status, {
    String? userId,
    String? donorId,
  }) async {
    try {
      Query query = _reservationsCollection
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true);
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      if (donorId != null) {
        query = query.where('donorId', isEqualTo: donorId);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations par statut: $e');
    }
  }
  
  // Obtenir les réservations par don
  Future<List<ReservationModel>> getReservationsByDonation(String donationId) async {
    try {
      final querySnapshot = await _reservationsCollection
          .where('donationId', isEqualTo: donationId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations par don: $e');
    }
  }
  
  // Obtenir les réservations dans une plage de dates
  Future<List<ReservationModel>> getReservationsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    String? donorId,
  }) async {
    try {
      Query query = _reservationsCollection
          .where('scheduledPickupTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scheduledPickupTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('scheduledPickupTime');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      if (donorId != null) {
        query = query.where('donorId', isEqualTo: donorId);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations par date: $e');
    }
  }
  
  // Confirmer une réservation
  Future<void> confirmReservation(String reservationId) async {
    try {
      await _reservationsCollection.doc(reservationId).update({
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la confirmation de la réservation: $e');
    }
  }
  
  // Compléter une réservation
  Future<void> completeReservation(String reservationId) async {
    try {
      await _reservationsCollection.doc(reservationId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la finalisation de la réservation: $e');
    }
  }
  
  // Annuler une réservation
  Future<void> cancelReservation(String reservationId, String reason) async {
    try {
      await _reservationsCollection.doc(reservationId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la réservation: $e');
    }
  }
  
  // Mettre à jour une réservation
  Future<void> updateReservation({
    required String reservationId,
    DateTime? scheduledPickupTime,
    String? contactPhone,
    String? notes,
    ReservationStatus? status,
    String? cancellationReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (scheduledPickupTime != null) {
        updateData['scheduledPickupTime'] = Timestamp.fromDate(scheduledPickupTime);
      }
      if (contactPhone != null) updateData['contactPhone'] = contactPhone;
      if (notes != null) updateData['notes'] = notes;
      if (status != null) updateData['status'] = status.toString().split('.').last;
      if (cancellationReason != null) updateData['cancellationReason'] = cancellationReason;
      
      await _reservationsCollection.doc(reservationId).update(updateData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la réservation: $e');
    }
  }
  
  // Supprimer une réservation
  Future<void> deleteReservation(String reservationId) async {
    try {
      await _reservationsCollection.doc(reservationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la réservation: $e');
    }
  }
  
  // Obtenir les réservations actives (pending + confirmed)
  Future<List<ReservationModel>> getActiveReservations({
    String? userId,
    String? donorId,
  }) async {
    try {
      Query query = _reservationsCollection
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('scheduledPickupTime');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      if (donorId != null) {
        query = query.where('donorId', isEqualTo: donorId);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations actives: $e');
    }
  }
  
  // Obtenir les réservations du jour
  Future<List<ReservationModel>> getTodayReservations({
    String? userId,
    String? donorId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      return await getReservationsByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
        userId: userId,
        donorId: donorId,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations du jour: $e');
    }
  }
  
  // Obtenir les réservations de la semaine
  Future<List<ReservationModel>> getWeekReservations({
    String? userId,
    String? donorId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      return await getReservationsByDateRange(
        startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        endDate: endOfWeek,
        userId: userId,
        donorId: donorId,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations de la semaine: $e');
    }
  }
  
  // Vérifier si un don a déjà une réservation active
  Future<bool> hasDonationActiveReservation(String donationId) async {
    try {
      final querySnapshot = await _reservationsCollection
          .where('donationId', isEqualTo: donationId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de la réservation: $e');
    }
  }
  
  // Obtenir les statistiques des réservations
  Future<Map<String, int>> getReservationsStats() async {
    try {
      final totalReservations = await _reservationsCollection.count().get();
      final pendingReservations = await _reservationsCollection
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      final confirmedReservations = await _reservationsCollection
          .where('status', isEqualTo: 'confirmed')
          .count()
          .get();
      final completedReservations = await _reservationsCollection
          .where('status', isEqualTo: 'completed')
          .count()
          .get();
      final cancelledReservations = await _reservationsCollection
          .where('status', isEqualTo: 'cancelled')
          .count()
          .get();
      
      return {
        'total': totalReservations.count,
        'pending': pendingReservations.count,
        'confirmed': confirmedReservations.count,
        'completed': completedReservations.count,
        'cancelled': cancelledReservations.count,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
  
  // Stream des réservations d'un utilisateur
  Stream<List<ReservationModel>> getUserReservationsStream(String userId) {
    return _reservationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    });
  }
  
  // Stream des réservations d'un donateur
  Stream<List<ReservationModel>> getDonorReservationsStream(String donorId) {
    return _reservationsCollection
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    });
  }
  
  // Stream des réservations actives
  Stream<List<ReservationModel>> getActiveReservationsStream({
    String? userId,
    String? donorId,
  }) {
    Query query = _reservationsCollection
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('scheduledPickupTime');
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    if (donorId != null) {
      query = query.where('donorId', isEqualTo: donorId);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    });
  }
}