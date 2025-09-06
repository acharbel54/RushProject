import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../models/donation_model.dart';
import '../../services/json_donation_service.dart';
import '../../services/json_reservation_service.dart';

class ReservationProvider with ChangeNotifier {
  final JsonDonationService _donationService = JsonDonationService();
  final JsonReservationService _reservationService = JsonReservationService();
  
  List<ReservationModel> _reservations = [];
  List<ReservationModel> _userReservations = [];
  bool _isLoading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  List<ReservationModel> get userReservations => _userReservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Vérifie si un don est déjà réservé par un utilisateur spécifique
  bool isDonationReservedByUser(String donationId, String userId) {
    return _userReservations.any((reservation) => 
      reservation.donationId == donationId && 
      reservation.beneficiaryId == userId &&
      (reservation.status == ReservationStatus.pending || reservation.status == ReservationStatus.confirmed)
    );
  }
  
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

      _reservations = await _reservationService.getAllReservations();

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

      _userReservations = await _reservationService.getUserReservations(userId);
      // Aussi mettre à jour la liste globale si elle est vide
      if (_reservations.isEmpty) {
        _reservations = await _reservationService.getAllReservations();
      }

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

      // TODO: Implémenter avec le service JSON des réservations
      _reservations = [];

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
      final allDonations = await _donationService.getAllDonations();
      final donationList = allDonations.where((d) => d.id == donationId).toList();
      
      if (donationList.isEmpty) {
        _setError('Ce don n\'existe plus');
        _setLoading(false);
        return false;
      }
      
      final donation = donationList.first;
      if (donation.status != DonationStatus.disponible) {
        _setError('Ce don n\'est plus disponible');
        _setLoading(false);
        return false;
      }

      // Créer une nouvelle réservation
      final reservation = ReservationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        donationId: donationId,
        donorId: donation.donorId,
        beneficiaryId: beneficiaryId,
        beneficiaryName: 'Bénéficiaire', // TODO: Récupérer le vrai nom
        donationTitle: donation.title,
        donationQuantity: donation.quantity,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
        donorName: donation.donorName,
        pickupAddress: donation.address,
        contactPhone: null, // Pas de téléphone de contact disponible
      );

      // Réserver le don via le service JSON
      await _donationService.reserveDonation(donationId, beneficiaryId);
      
      // Sauvegarder la réservation via le service JSON
      await _reservationService.addReservation(reservation);
      
      // Ajouter la réservation aux listes locales
      _reservations.add(reservation);
      _userReservations.add(reservation);
      
      notifyListeners();
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

      // TODO: Implémenter avec le service JSON des réservations
      
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

      // TODO: Implémenter avec le service JSON des réservations
      
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

      // TODO: Implémenter avec le service JSON des réservations
      
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
      _setLoading(true);
      _setError(null);

      // TODO: Implémenter avec le service JSON des réservations
      
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Erreur lors de la récupération: $e');
      _setLoading(false);
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

      // TODO: Implémenter avec le service JSON des réservations
      final List<Map<String, dynamic>> result = [];
      
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

      // TODO: Implémenter avec le service JSON des réservations
      _reservations = [];

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