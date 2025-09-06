import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../../services/json_donation_service.dart';
import '../services/simple_auth_service.dart';
import 'simple_auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../services/local_image_service.dart';

class DonationProvider with ChangeNotifier {
  final JsonDonationService _donationService = JsonDonationService();
  final SimpleAuthService _authService = SimpleAuthService();
  SimpleAuthProvider? _authProvider;
  
  List<DonationModel> _donations = [];
  List<DonationModel> _userDonations = [];
  List<DonationModel> _nearbyDonations = [];
  bool _isLoading = false;
  String? _error;
  String? _errorMessage;
  Position? _currentPosition;
  DonationCategory? _selectedCategory;
  double _maxDistance = 10.0;
  bool _showOnlyAvailable = false;
  
  // Getters
  List<DonationModel> get donations => _donations;
  List<DonationModel> get userDonations => _userDonations;
  List<DonationModel> get nearbyDonations => _nearbyDonations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;
  DonationCategory? get selectedCategory => _selectedCategory;
  double get maxDistance => _maxDistance;
  bool get showOnlyAvailable => _showOnlyAvailable;
  
  // Charger tous les dons
  Future<void> loadDonations() async {
    try {
      _setLoading(true);
      _clearError();
      
      _donations = await _donationService.getAvailableDonations();
      _applyFilters();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors du chargement des dons');
    }
  }
  
  // Charger les dons d'un utilisateur
  Future<void> loadUserDonations(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      _userDonations = await _donationService.getUserDonations(userId);
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors du chargement de vos dons');
    }
  }
  
  // Charger les dons à proximité
  Future<void> loadNearbyDonations() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Obtenir la position actuelle
      await _getCurrentLocation();
      
      if (_currentPosition != null) {
        _nearbyDonations = await _donationService.getNearbyDonations(
          userLatitude: _currentPosition!.latitude,
          userLongitude: _currentPosition!.longitude,
          radiusKm: _maxDistance,
        );
        
        if (_showOnlyAvailable) {
          _nearbyDonations = _nearbyDonations
              .where((d) => d.status == DonationStatus.disponible)
              .toList();
        }
        
        if (_selectedCategory != null) {
          _nearbyDonations = _nearbyDonations
              .where((d) => d.category == _selectedCategory)
              .toList();
        }
      }
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors du chargement des dons à proximité');
    }
  }
  
  // Créer un nouveau don
  Future<bool> createDonation({
    required String donorId,
    required String donorName,
    required String title,
    required String description,
    required String quantity,
    required DonationCategory category,
    required DateTime expirationDate,
    required String address,
    required double latitude,
    required double longitude,
    List<File>? images,
    String? notes,
    bool isUrgent = false,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Sauvegarder les images dans le dossier assets si elles sont fournies
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        try {
          imageUrls = await LocalImageService.saveImagesToAssets(images);
        } catch (e) {
          print('Erreur lors de la sauvegarde des images: $e');
          // Continuer sans les images en cas d'erreur
        }
      }
      
      // Créer le don
      final donation = DonationModel(
        id: '', // Sera généré par le service JSON
        donorId: donorId,
        donorName: donorName,
        title: title,
        description: description,
        quantity: quantity,
        category: category,
        expirationDate: expirationDate,
        address: address,
        latitude: latitude,
        longitude: longitude,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        notes: notes,
        isUrgent: isUrgent,
      );
      
      final donationId = await _donationService.addDonation(donation);
      
      // Créer l'objet donation avec l'ID généré
      final createdDonation = donation.copyWith(id: donationId);
      
      // Ajouter à la liste locale
      _userDonations.insert(0, createdDonation);
      _donations.insert(0, createdDonation);
      
      // Mettre à jour les statistiques du donateur
      await _updateDonorStats(donorId, createdDonation);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la création du don');
      return false;
    }
  }
  
  // Mettre à jour un don
  Future<bool> updateDonation(DonationModel donation) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _donationService.updateDonation(donation.id, donation);
      
      // Mettre à jour dans les listes locales
      _updateDonationInLists(donation);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la mise à jour du don');
      return false;
    }
  }
  
  // Supprimer un don
  Future<bool> deleteDonation(String donationId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _donationService.deleteDonation(donationId);
      
      // Supprimer des listes locales
      _donations.removeWhere((d) => d.id == donationId);
      _userDonations.removeWhere((d) => d.id == donationId);
      _nearbyDonations.removeWhere((d) => d.id == donationId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la suppression du don');
      return false;
    }
  }
  
  // Réserver un don
  Future<bool> reserveDonation(String donationId, String beneficiaryId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _donationService.reserveDonation(donationId, beneficiaryId);
      
      // Mettre à jour le statut local
      final donationIndex = _donations.indexWhere((d) => d.id == donationId);
      if (donationIndex != -1) {
        _donations[donationIndex] = _donations[donationIndex].copyWith(
          status: DonationStatus.reserve,
          reservedBy: beneficiaryId,
          reservedAt: DateTime.now(),
        );
        
        // Mettre à jour dans les autres listes
        _updateDonationInLists(_donations[donationIndex]);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la réservation du don');
      return false;
    }
  }
  
  // Obtenir la position actuelle
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés');
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }
      
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _setError('Erreur lors de l\'obtention de la localisation');
    }
  }
  
  // Appliquer les filtres
  void _applyFilters() {
    List<DonationModel> filtered = List.from(_donations);
    
    if (_showOnlyAvailable) {
      filtered = filtered.where((d) => d.status == DonationStatus.disponible).toList();
    }
    
    if (_selectedCategory != null) {
      filtered = filtered.where((d) => d.category == _selectedCategory).toList();
    }
    
    _donations = filtered;
  }
  
  // Mettre à jour un don dans toutes les listes
  void _updateDonationInLists(DonationModel updatedDonation) {
    // Mettre à jour dans _donations
    final donationIndex = _donations.indexWhere((d) => d.id == updatedDonation.id);
    if (donationIndex != -1) {
      _donations[donationIndex] = updatedDonation;
    }
    
    // Mettre à jour dans _userDonations
    final userDonationIndex = _userDonations.indexWhere((d) => d.id == updatedDonation.id);
    if (userDonationIndex != -1) {
      _userDonations[userDonationIndex] = updatedDonation;
    }
    
    // Mettre à jour dans _nearbyDonations
    final nearbyDonationIndex = _nearbyDonations.indexWhere((d) => d.id == updatedDonation.id);
    if (nearbyDonationIndex != -1) {
      _nearbyDonations[nearbyDonationIndex] = updatedDonation;
    }
    
    notifyListeners();
  }
  
  // Setters pour les filtres
  void setCategory(DonationCategory? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }
  
  void setMaxDistance(double distance) {
    _maxDistance = distance;
    notifyListeners();
  }
  
  void setShowOnlyAvailable(bool showOnly) {
    _showOnlyAvailable = showOnly;
    _applyFilters();
    notifyListeners();
  }
  
  // Méthodes utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Méthode pour compatibilité avec l'ancien code
  Future<void> fetchDonations() async {
    await loadDonations();
  }
  
  // Récupérer les dons d'un utilisateur
  Future<void> fetchUserDonations(String userId) async {
    await loadUserDonations(userId);
  }
  
  // Rechercher les dons par catégorie
  Future<void> searchDonationsByCategory(String category) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (category == 'Toutes') {
        _selectedCategory = null;
      } else {
        // Convertir la chaîne en enum DonationCategory si nécessaire
        _selectedCategory = DonationCategory.values.firstWhere(
          (cat) => cat.name == category.toLowerCase(),
          orElse: () => DonationCategory.autre,
        );
      }
      
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la recherche par catégorie: $e');
    }
  }
  
  // Définir le provider d'authentification
  void setAuthProvider(SimpleAuthProvider authProvider) {
    _authProvider = authProvider;
  }
  
  // Nettoyer les données
  void clear() {
    _donations.clear();
    _userDonations.clear();
    _nearbyDonations.clear();
    _currentPosition = null;
    _selectedCategory = null;
    _maxDistance = 10.0;
    _showOnlyAvailable = false;
    _clearError();
    notifyListeners();
  }
  
  // Mettre à jour les statistiques du donateur
  Future<void> _updateDonorStats(String donorId, DonationModel donation) async {
    try {
      // Obtenir l'utilisateur actuel pour récupérer ses statistiques
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.id != donorId) {
        return; // Ne mettre à jour que si c'est l'utilisateur actuel
      }
      
      // Calculer le poids du don (extraire le nombre de la quantité)
      double donationWeight = _extractWeightFromQuantity(donation.quantity);
      
      // Mettre à jour les statistiques via le provider si disponible, sinon directement
      if (_authProvider != null) {
        await _authProvider!.updateUserStats(
          userId: donorId,
          totalDonations: currentUser.totalDonations + 1,
          totalKgDonated: currentUser.totalKgDonated + donationWeight,
        );
      } else {
        await _authService.updateUserStats(
          userId: donorId,
          totalDonations: currentUser.totalDonations + 1,
          totalKgDonated: currentUser.totalKgDonated + donationWeight,
        );
      }
      
      if (kDebugMode) {
        print('Statistiques mises à jour pour le donateur $donorId: +1 don, +${donationWeight}kg');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour des statistiques: $e');
      }
    }
  }
  
  // Obtenir un don par ID
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      return await _donationService.getDonationById(donationId);
    } catch (e) {
      _setError('Erreur lors de la récupération du don: $e');
      if (kDebugMode) {
        print('Erreur getDonationById: $e');
      }
      return null;
    }
  }

  // Extraire le poids numérique de la quantité (ex: "2 kg" -> 2.0)
  double _extractWeightFromQuantity(String quantity) {
    try {
      // Rechercher les nombres dans la chaîne
      final RegExp numberRegex = RegExp(r'(\d+(?:\.\d+)?)');
      final match = numberRegex.firstMatch(quantity.toLowerCase());
      
      if (match != null) {
        double weight = double.parse(match.group(1)!);
        
        // Si la quantité contient "g" ou "gram", convertir en kg
        if (quantity.toLowerCase().contains('g') && !quantity.toLowerCase().contains('kg')) {
          weight = weight / 1000; // Convertir grammes en kg
        }
        
        return weight;
      }
      
      // Si aucun nombre trouvé, retourner une valeur par défaut
      return 1.0;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'extraction du poids: $e');
      }
      return 1.0; // Valeur par défaut
    }
  }
}