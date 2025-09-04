import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';
import '../models/donation_model.dart';

class ReservationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ReservationModel> _reservations = [];
  List<ReservationModel> _userReservations = [];
  bool _isLoading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  List<ReservationModel> get userReservations => _userReservations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// Récupère toutes les réservations
  Future<void> fetchReservations() async {
    try {
      _setLoading(true);
      _setError(null);

      final querySnapshot = await _firestore
          .collection('reservations')
          .orderBy('createdAt', descending: true)
          .get();

      _reservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromDocument(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des réservations: $e');
      _setLoading(false);
    }
  }

  /// Récupère les réservations d'un utilisateur spécifique
  Future<void> fetchUserReservations(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final querySnapshot = await _firestore
          .collection('reservations')
          .where('beneficiaryId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userReservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromDocument(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement de vos réservations: $e');
      _setLoading(false);
    }
  }

  /// Récupère les réservations pour les dons d'un donateur
  Future<void> fetchDonorReservations(String donorId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Récupérer d'abord les IDs des dons du donateur
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: donorId)
          .get();

      final donationIds = donationsSnapshot.docs.map((doc) => doc.id).toList();

      if (donationIds.isEmpty) {
        _reservations = [];
        _setLoading(false);
        return;
      }

      // Récupérer les réservations pour ces dons
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('donationId', whereIn: donationIds)
          .orderBy('createdAt', descending: true)
          .get();

      _reservations = reservationsSnapshot.docs
          .map((doc) => ReservationModel.fromDocument(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des réservations: $e');
      _setLoading(false);
    }
  }
  
  /// Crée une nouvelle réservation
  Future<bool> createReservation({
    required String donationId,
    required String beneficiaryId,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Vérifier que le don existe et est disponible
      final donationDoc = await _firestore
          .collection('donations')
          .doc(donationId)
          .get();

      if (!donationDoc.exists) {
        _setError('Ce don n\'existe plus');
        _setLoading(false);
        return false;
      }

      final donation = DonationModel.fromDocument(donationDoc);
      if (donation.status != DonationStatus.disponible) {
        _setError('Ce don n\'est plus disponible');
        _setLoading(false);
        return false;
      }

      // Vérifier qu'il n'y a pas déjà une réservation active pour ce don
      final existingReservation = await _firestore
          .collection('reservations')
          .where('donationId', isEqualTo: donationId)
          .where('status', whereIn: [ReservationStatus.pending.name, ReservationStatus.confirmed.name])
          .get();

      if (existingReservation.docs.isNotEmpty) {
        _setError('Ce don est déjà réservé');
        _setLoading(false);
        return false;
      }

      // Créer la réservation
      final reservation = ReservationModel(
        id: '', // Sera généré par Firestore
        donationId: donationId,
        donorId: donation.donorId,
        beneficiaryId: beneficiaryId,
        beneficiaryName: '', // À récupérer depuis le profil utilisateur
        donationTitle: donation.title,
        donationQuantity: donation.quantity,
        status: ReservationStatus.pending,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        donorName: donation.donorName,
        pickupAddress: donation.address,
      );

      final docRef = await _firestore
          .collection('reservations')
          .add(reservation.toMap());

      // Mettre à jour le statut du don
      await _firestore
          .collection('donations')
          .doc(donationId)
          .update({
        'status': DonationStatus.reserve.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ajouter la réservation à la liste locale
      final newReservation = reservation.copyWith(id: docRef.id);
      _userReservations.insert(0, newReservation);
      _reservations.insert(0, newReservation);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de la création de la réservation: $e');
      _setLoading(false);
      return false;
    }
  }
  
  /// Met à jour le statut d'une réservation
  Future<bool> updateReservationStatus(
    String reservationId,
    String newStatus,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour localement
      _updateReservationInLists(reservationId, {'status': newStatus});

      // Si la réservation est annulée, remettre le don comme disponible
      if (newStatus == ReservationStatus.cancelled.name) {
        final reservation = _findReservationById(reservationId);
        if (reservation != null) {
          await _firestore
              .collection('donations')
              .doc(reservation.donationId)
              .update({
            'status': DonationStatus.disponible.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Confirme une réservation (par le donateur)
  Future<bool> confirmReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, ReservationStatus.confirmed.name);
  }

  /// Annule une réservation
  Future<bool> cancelReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, ReservationStatus.cancelled.name);
  }

  /// Marque une réservation comme terminée (don récupéré)
  Future<bool> completeReservation(String reservationId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Mettre à jour la réservation
      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update({
        'status': ReservationStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le don comme récupéré
      final reservation = _findReservationById(reservationId);
      if (reservation != null) {
        await _firestore
            .collection('donations')
            .doc(reservation.donationId)
            .update({
          'status': DonationStatus.recupere.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Mettre à jour localement
      _updateReservationInLists(reservationId, {
        'status': ReservationStatus.completed.name,
        'completedAt': DateTime.now(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de la finalisation: $e');
      _setLoading(false);
      return false;
    }
  }
  
  /// Supprime une réservation
  Future<bool> deleteReservation(String reservationId) async {
    try {
      _setLoading(true);
      _setError(null);

      final reservation = _findReservationById(reservationId);
      if (reservation == null) {
        _setError('Réservation introuvable');
        _setLoading(false);
        return false;
      }

      // Supprimer la réservation
      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .delete();

      // Si la réservation était active, remettre le don comme disponible
      if (reservation.status == ReservationStatus.pending || reservation.status == ReservationStatus.confirmed) {
        await _firestore
            .collection('donations')
            .doc(reservation.donationId)
            .update({
          'status': DonationStatus.disponible.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Supprimer localement
      _reservations.removeWhere((r) => r.id == reservationId);
      _userReservations.removeWhere((r) => r.id == reservationId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Récupère une réservation par son ID
  Future<ReservationModel?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore
          .collection('reservations')
          .doc(reservationId)
          .get();

      if (doc.exists) {
        return ReservationModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      _setError('Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// Récupère les réservations avec les détails des dons
  Future<List<Map<String, dynamic>>> getReservationsWithDonations(
    String userId,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('beneficiaryId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> result = [];

      for (final reservationDoc in reservationsSnapshot.docs) {
        final reservation = ReservationModel.fromDocument(reservationDoc);
        
        // Récupérer les détails du don
        final donationDoc = await _firestore
            .collection('donations')
            .doc(reservation.donationId)
            .get();

        if (donationDoc.exists) {
          final donation = DonationModel.fromDocument(donationDoc);
          result.add({
            'reservation': reservation,
            'donation': donation,
          });
        }
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Erreur lors du chargement: $e');
      _setLoading(false);
      return [];
    }
  }

  /// Recherche des réservations par statut
  Future<void> fetchReservationsByStatus(String status) async {
    try {
      _setLoading(true);
      _setError(null);

      final querySnapshot = await _firestore
          .collection('reservations')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      _reservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromDocument(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      _setLoading(false);
    }
  }
  
  /// Méthodes utilitaires privées
  ReservationModel? _findReservationById(String id) {
    try {
      return _reservations.firstWhere((r) => r.id == id);
    } catch (e) {
      try {
        return _userReservations.firstWhere((r) => r.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  void _updateReservationInLists(String id, Map<String, dynamic> updates) {
    // Mettre à jour dans _reservations
    final reservationIndex = _reservations.indexWhere((r) => r.id == id);
    if (reservationIndex != -1) {
      final reservation = _reservations[reservationIndex];
      _reservations[reservationIndex] = _updateReservation(reservation, updates);
    }

    // Mettre à jour dans _userReservations
    final userReservationIndex = _userReservations.indexWhere((r) => r.id == id);
    if (userReservationIndex != -1) {
      final reservation = _userReservations[userReservationIndex];
      _userReservations[userReservationIndex] = _updateReservation(reservation, updates);
    }

    notifyListeners();
  }

  ReservationModel _updateReservation(ReservationModel reservation, Map<String, dynamic> updates) {
    ReservationStatus? newStatus;
    if (updates['status'] != null) {
      if (updates['status'] is String) {
        newStatus = ReservationStatus.values.firstWhere(
          (status) => status.name == updates['status'],
          orElse: () => reservation.status,
        );
      } else {
        newStatus = updates['status'];
      }
    }
    
    return reservation.copyWith(
      status: newStatus ?? reservation.status,
      notes: updates['notes'] ?? reservation.notes,
      completedAt: updates['completedAt'] ?? reservation.completedAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Nettoie les données locales
  void clearData() {
    _reservations.clear();
    _userReservations.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Obtient les statistiques des réservations pour un utilisateur
  Map<String, int> getUserReservationStats(String userId) {
    final userReservations = _userReservations.where(
      (r) => r.beneficiaryId == userId,
    ).toList();

    return {
      'total': userReservations.length,
      'pending': userReservations.where((r) => r.status == ReservationStatus.pending).length,
      'confirmed': userReservations.where((r) => r.status == ReservationStatus.confirmed).length,
      'completed': userReservations.where((r) => r.status == ReservationStatus.completed).length,
      'cancelled': userReservations.where((r) => r.status == ReservationStatus.cancelled).length,
    };
  }
}