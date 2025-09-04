import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/donation.dart';
import '../../../core/services/firestore_service.dart';

class DonationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Donation> _donations = [];
  List<Donation> _userDonations = [];
  bool _isLoading = false;
  String? _error;

  List<Donation> get donations => _donations;
  List<Donation> get userDonations => _userDonations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Récupérer tous les dons disponibles
  Future<void> fetchDonations() async {
    _setLoading(true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'disponible')
          .orderBy('createdAt', descending: true)
          .get();

      _donations = querySnapshot.docs
          .map((doc) => Donation.fromFirestore(doc))
          .toList();
      
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
      final querySnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userDonations = querySnapshot.docs
          .map((doc) => Donation.fromFirestore(doc))
          .toList();
      
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
  Future<bool> createDonation(Donation donation) async {
    _setLoading(true);
    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .add(donation.toFirestore());
      
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
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
      
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
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      
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
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'status': 'reserve',
        'reservedBy': userId,
        'reservedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
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
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'status': 'disponible',
        'reservedBy': null,
        'reservedAt': null,
        'updatedAt': Timestamp.now(),
      });
      
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
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'status': 'recupere',
        'updatedAt': Timestamp.now(),
      });
      
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
    DonationType? type,
    double? maxDistance,
    double? userLat,
    double? userLng,
  }) async {
    _setLoading(true);
    try {
      Query queryRef = FirebaseFirestore.instance
          .collection('donations')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'disponible');

      if (type != null) {
        queryRef = queryRef.where('type', isEqualTo: type.toString().split('.').last);
      }

      final querySnapshot = await queryRef
          .orderBy('createdAt', descending: true)
          .get();

      List<Donation> results = querySnapshot.docs
          .map((doc) => Donation.fromFirestore(doc))
          .toList();

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
  Future<Donation?> getDonationById(String donationId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .get();
      
      if (doc.exists) {
        return Donation.fromFirestore(doc);
      }
      return null;
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