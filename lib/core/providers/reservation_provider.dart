import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../models/donation_model.dart';
import '../../services/json_donation_service.dart';
import '../../services/json_reservation_service.dart';
import 'notification_provider.dart';
import 'simple_auth_provider.dart';

class ReservationProvider with ChangeNotifier {
  final JsonDonationService _donationService = JsonDonationService();
  final JsonReservationService _reservationService = JsonReservationService();
  final NotificationProvider _notificationProvider = NotificationProvider();
  
  List<ReservationModel> _reservations = [];
  List<ReservationModel> _userReservations = [];
  bool _isLoading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  List<ReservationModel> get userReservations => _userReservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Checks if a donation is already reserved by a specific user
  bool isDonationReservedByUser(String donationId, String userId) {
    return _userReservations.any((reservation) => 
      reservation.donationId == donationId && 
      reservation.beneficiaryId == userId &&
      (reservation.status == ReservationStatus.pending || reservation.status == ReservationStatus.confirmed)
    );
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Don't notify here to avoid setState during build
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  /// Fetches all reservations
  Future<void> fetchReservations() async {
    try {
      _setLoading(true);
      _setError(null);

      _reservations = await _reservationService.getAllReservations();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error loading reservations: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Fetches reservations for a specific user
  Future<void> fetchUserReservations(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      _userReservations = await _reservationService.getUserReservations(userId);
      
      // Aussi mettre à jour la liste globale si elle est vide
      if (_reservations.isEmpty) {
        _reservations = await _reservationService.getAllReservations();
      }
      
      // Ensure user reservations are also in the global list
      for (final userReservation in _userReservations) {
        if (!_reservations.any((r) => r.id == userReservation.id)) {
          _reservations.add(userReservation);
        }
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error loading your reservations: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Fetches reservations for a donor's donations
  Future<void> fetchDonorReservations(String donorId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Get all reservations
      final allReservations = await _reservationService.getAllReservations();
      
      // Filter reservations for this donor
      _reservations = allReservations.where((reservation) => 
        reservation.donorId == donorId
      ).toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error loading reservations: $e');
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Creates a new reservation
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

      // Récupérer le nom réel du bénéficiaire
      final authProvider = SimpleAuthProvider();
      final beneficiary = await authProvider.getUserById(beneficiaryId);
      final beneficiaryName = beneficiary?.displayName ?? 'Utilisateur';

      // Create a new reservation
      final reservation = ReservationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        donationId: donationId,
        donorId: donation.donorId,
        beneficiaryId: beneficiaryId,
        beneficiaryName: beneficiaryName,
        donationTitle: donation.title,
        donationQuantity: donation.quantity,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
        donorName: donation.donorName,
        pickupAddress: donation.address,
        contactPhone: null, // No contact phone available
      );

      // Reserve the donation via JSON service
      await _donationService.reserveDonation(donationId, beneficiaryId);
      
      // Save the reservation via JSON service
      await _reservationService.addReservation(reservation);
      
      // Send notification to donor
      await _notificationProvider.sendNewReservationNotification(
        donorId: donation.donorId,
        donationTitle: donation.title,
        beneficiaryName: reservation.beneficiaryName,
        reservationId: reservation.id,
      );
      
      // Add reservation to local lists
      _reservations.add(reservation);
      _userReservations.add(reservation);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error creating reservation: $e');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
  
  /// Updates the status of a reservation
  Future<bool> updateReservationStatus(
    String reservationId,
    String newStatus,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      print('Updating reservation status $reservationId to $newStatus');
      
      // Charger les réservations actuelles
      await _reservationService.loadReservations();
      final reservations = await _reservationService.getAllReservations();
      
      // Trouver la réservation à mettre à jour
      final reservationIndex = reservations.indexWhere((r) => r.id == reservationId);
      if (reservationIndex == -1) {
        throw Exception('Reservation not found');
      }
      
      final reservation = reservations[reservationIndex];
      print('Reservation found: ${reservation.donationId}');
      
      // Si on annule la réservation, rendre le don disponible
      if (newStatus == 'cancelled') {
        print('Annulation de la réservation - libération du don ${reservation.donationId}');
        await _donationService.cancelReservation(reservation.donationId);
        
        // Supprimer la réservation du fichier JSON
        await _reservationService.deleteReservation(reservationId);
        print('Réservation supprimée du fichier JSON');
        
        // Mettre à jour les listes locales
        _reservations.removeWhere((r) => r.id == reservationId);
        _userReservations.removeWhere((r) => r.id == reservationId);
      } else {
        // Pour les autres statuts, mettre à jour la réservation
        final updatedReservation = reservation.copyWith(
          status: ReservationStatus.values.firstWhere(
            (status) => status.name == newStatus,
            orElse: () => ReservationStatus.pending,
          ),
          updatedAt: DateTime.now(),
        );
        
        await _reservationService.updateReservation(updatedReservation);
        
        // Mettre à jour les listes locales
        final localIndex = _reservations.indexWhere((r) => r.id == reservationId);
        if (localIndex != -1) {
          _reservations[localIndex] = updatedReservation;
        }
        
        final userIndex = _userReservations.indexWhere((r) => r.id == reservationId);
        if (userIndex != -1) {
          _userReservations[userIndex] = updatedReservation;
        }
      }
      
      _setLoading(false);
      notifyListeners();
      print('Status update completed successfully');
      return true;
    } catch (e) {
      print('Error updating status: $e');
      _setError('Error during update: $e');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Confirme une réservation (par le donateur)
  Future<bool> confirmReservation(String reservationId) async {
    try {
      final result = await updateReservationStatus(reservationId, ReservationStatus.confirmed.name);
      
      if (result) {
        // Envoyer une notification au bénéficiaire
        final reservation = _findReservationById(reservationId);
        if (reservation != null) {
          await _notificationProvider.sendReservationConfirmedNotification(
            reservation.beneficiaryId,
            reservationId,
          );
        }
      }
      
      return result;
    } catch (e) {
      _setError('Error during confirmation: $e');
      return false;
    }
  }

  /// Annule une réservation
  Future<bool> cancelReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, ReservationStatus.cancelled.name);
  }

  /// Refuse une réservation (pour les donateurs)
  Future<bool> rejectReservation(String reservationId) async {
    try {
      final result = await updateReservationStatus(reservationId, ReservationStatus.cancelled.name);
      
      if (result) {
        // Envoyer une notification au bénéficiaire
        final reservation = _findReservationById(reservationId);
        if (reservation != null) {
          await _notificationProvider.sendReservationCancelledNotification(
            reservation.beneficiaryId,
            reservationId,
          );
        }
      }
      
      return result;
    } catch (e) {
      _setError('Error during rejection: $e');
      return false;
    }
  }

  /// Marque une réservation comme terminée (don récupéré)
  Future<bool> completeReservation(String reservationId) async {
    try {
      _setLoading(true);
      _setError(null);

      // TODO: Implémenter avec le service JSON des réservations
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error during completion: $e');
      _setLoading(false);
      notifyListeners();
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
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error during deletion: $e');
      _setLoading(false);
      notifyListeners();
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
      notifyListeners();
      return null;
    } catch (e) {
      _setError('Error during retrieval: $e');
      _setLoading(false);
      notifyListeners();
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

      print('DEBUG: getReservationsWithDonations appelée pour userId: $userId');
      
      // Récupérer les réservations de l'utilisateur
      final userReservations = await _reservationService.getUserReservations(userId);
      print('DEBUG: Nombre de réservations trouvées: ${userReservations.length}');
      
      for (int i = 0; i < userReservations.length; i++) {
        final reservation = userReservations[i];
        print('DEBUG: Réservation $i - ID: ${reservation.id}, DonationID: ${reservation.donationId}, BeneficiaryID: ${reservation.beneficiaryId}');
      }
      
      // Pour chaque réservation, récupérer les détails du don
      final List<Map<String, dynamic>> result = [];
      
      for (final reservation in userReservations) {
        try {
          // Récupérer le don correspondant
          final donation = await _donationService.getDonationById(reservation.donationId);
          print('DEBUG: Don trouvé pour ${reservation.donationId}: ${donation != null}');
          
          if (donation != null) {
            result.add({
              'reservation': reservation,
              'donation': donation,
            });
          }
        } catch (e) {
          print('Error retrieving donation ${reservation.donationId}: $e');
          // Continuer avec les autres réservations même si une échoue
        }
      }
      
      print('DEBUG: Nombre de résultats finaux: ${result.length}');
      _setLoading(false);
      return result;
    } catch (e) {
      print('DEBUG: Error in getReservationsWithDonations: $e');
      _setError('Error loading: $e');
      _setLoading(false);
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      _setError('Error during search: $e');
      _setLoading(false);
      notifyListeners();
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