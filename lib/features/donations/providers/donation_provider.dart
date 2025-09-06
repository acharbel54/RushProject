import 'package:flutter/foundation.dart';
import '../../../core/models/donation_model.dart';
import '../../../services/json_donation_service.dart';

class DonationProvider with ChangeNotifier {
  final JsonDonationService _donationService = JsonDonationService();
  
  List<DonationModel> _donations = [];
  List<DonationModel> _userDonations = [];
  bool _isLoading = false;
  String? _error;

  List<DonationModel> get donations => _donations;
  List<DonationModel> get userDonations => _userDonations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Récupérer tous les dons disponibles
  Future<void> fetchDonations() async {
    _setLoading(true);
    try {
      _donations = await _donationService.getAvailableDonations();
      
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des dons: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _setLoading(false);
    }
  }

  // Récupérer les dons d'un utilisateur spécifique
  Future<void> fetchUserDonations(String userId) async {
    _setLoading(true);
    try {
      _userDonations = await _donationService.getUserDonations(userId);
      
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement de vos dons: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _setLoading(false);
    }
  }

  // Créer un nouveau don
  Future<bool> createDonation(DonationModel donation) async {
    _setLoading(true);
    try {
      await _donationService.addDonation(donation);
      
      // Rafraîchir la liste des dons
      await fetchDonations();
      await fetchUserDonations(donation.donorId);
      
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erreur lors de la création du don: $e';
      if (kDebugMode) {
        print(_error);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour un don
  Future<bool> updateDonation(String donationId, Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      // Récupérer la donation existante
      final existingDonation = await _donationService.getDonationById(donationId);
      if (existingDonation == null) {
        throw Exception('Donation non trouvée');
      }
      
      // Créer une nouvelle donation avec les mises à jour
      final updatedDonation = existingDonation.copyWith(
        status: updates['status'] != null ? DonationStatus.values.firstWhere(
          (e) => e.toString().split('.').last == updates['status'],
          orElse: () => existingDonation.status,
        ) : null,
        updatedAt: DateTime.now(),
      );
      
      await _donationService.updateDonation(donationId, updatedDonation);
      
      // Rafraîchir les listes
      await fetchDonations();
      
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du don: $e';
      if (kDebugMode) {
        print(_error);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un don
  Future<bool> deleteDonation(String donationId) async {
    _setLoading(true);
    try {
      await _donationService.deleteDonation(donationId);
      
      // Rafraîchir les listes
      await fetchDonations();
      
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression du don: $e';
      if (kDebugMode) {
        print(_error);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Réserver un don
  Future<bool> reserveDonation(String donationId, String userId) async {
    _setLoading(true);
    try {
      await _donationService.reserveDonation(donationId, userId);
      
      // Rafraîchir les listes
      await fetchDonations();
      
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erreur lors de la réservation du don: $e';
      if (kDebugMode) {
        print(_error);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Annuler une réservation
  Future<bool> cancelReservation(String donationId) async {
    _setLoading(true);
    try {
      // Récupérer la donation existante
      final existingDonation = await _donationService.getDonationById(donationId);
      if (existingDonation == null) {
        throw Exception('Donation non trouvée');
      }
      
      // Créer une nouvelle donation avec les mises à jour
      final updatedDonation = existingDonation.copyWith(
        status: DonationStatus.disponible,
        reservedBy: null,
        reservedAt: null,
        updatedAt: DateTime.now(),
      );
      
      await _donationService.updateDonation(donationId, updatedDonation);
      
      // Rafraîchir les listes
      await fetchDonations();
      
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'annulation de la réservation: $e';
      if (kDebugMode) {
        print(_error);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Marquer un don comme récupéré
  Future<bool> markAsCollected(String donationId) async {
    _setLoading(true);
    try {
      // Récupérer la donation existante
      final existingDonation = await _donationService.getDonationById(donationId);
      if (existingDonation == null) {
        throw Exception('Donation non trouvée');
      }
      
      // Créer une nouvelle donation avec les mises à jour
      final updatedDonation = existingDonation.copyWith(
        status: DonationStatus.recupere,
        updatedAt: DateTime.now(),
      );
      
      await _donationService.updateDonation(donationId, updatedDonation);
      
      // Rafraîchir les listes
      await fetchDonations();
      
      _error = null;
      return true;
    } catch (e) {
      _error = 'Erreur lors du marquage comme récupéré: $e';
      if (kDebugMode) {
        print(_error);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Rechercher des dons par critères
  Future<void> searchDonations({
    String? query,
    DonationCategory? type,
    double? maxDistance,
    double? userLat,
    double? userLng,
  }) async {
    _setLoading(true);
    try {
      // Récupérer toutes les donations disponibles
      List<DonationModel> results = await _donationService.getAllDonations();
      
      // Filtrer par statut disponible
      results = results.where((donation) => donation.status == DonationStatus.disponible).toList();

      // Filtrer par catégorie si fournie
      if (type != null) {
        results = results.where((donation) => donation.category == type).toList();
      }

      // Filtrer par texte de recherche si fourni
      if (query != null && query.isNotEmpty) {
        results = results.where((donation) {
          return donation.title.toLowerCase().contains(query.toLowerCase()) ||
                 donation.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      // TODO: Filtrer par distance si les coordonnées sont fournies
      // if (maxDistance != null && userLat != null && userLng != null) {
      //   results = results.where((donation) {
      //     double distance = calculateDistance(userLat, userLng, donation.latitude, donation.longitude);
      //     return distance <= maxDistance;
      //   }).toList();
      // }

      _donations = results;
      _error = null;
    } catch (e) {
      _error = 'Erreur lors de la recherche: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _setLoading(false);
    }
  }

  // Obtenir un don par ID
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      return await _donationService.getDonationById(donationId);
    } catch (e) {
      _error = 'Erreur lors de la récupération du don: $e';
      if (kDebugMode) {
        print(_error);
      }
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}