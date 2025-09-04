import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../services/firebase_service.dart';
import '../services/donation_service.dart';
import '../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:math' as math;

class DonationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DonationService _donationService = DonationService();
  final StorageService _storageService = StorageService();
  
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
          userLocation: GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
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
      
      // Upload des images si présentes
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (File image in images) {
          final imageUrl = await _storageService.uploadDonationImage(
            imageFile: image,
            donationId: donorId,
          );
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
      }
      
      // Créer le don
      final donation = DonationModel(
        id: '', // Sera généré par Firestore
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
      
      final donationId = await _donationService.createDonation(
        title: donation.title,
        description: donation.description,
        category: donation.category,
        quantity: donation.quantity,
        unit: donation.quantity.split(' ').length > 1 ? donation.quantity.split(' ')[1] : 'unité',
        expiryDate: donation.expirationDate,
        address: donation.address,
        location: GeoPoint(donation.latitude, donation.longitude),
        imageUrls: donation.imageUrls,
        notes: donation.notes,
      );
      
      // Créer l'objet donation avec l'ID généré
      final createdDonation = donation.copyWith(id: donationId);
      
      // Ajouter à la liste locale
      _userDonations.insert(0, createdDonation);
      _donations.insert(0, createdDonation);
      
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
      
      await _donationService.updateDonation(
        donationId: donation.id,
        title: donation.title,
        description: donation.description,
        category: donation.category,
        quantity: int.parse(donation.quantity.split(' ')[0]),
        unit: donation.quantity.split(' ').length > 1 ? donation.quantity.split(' ')[1] : 'unité',
        expiryDate: donation.expirationDate,
        address: donation.address,
        location: GeoPoint(donation.latitude, donation.longitude),
        imageUrls: donation.imageUrls,
        status: donation.status,
        notes: donation.notes,
      );
      
      final updatedDonation = donation;
      
      // Mettre à jour dans les listes locales
      _updateDonationInLists(updatedDonation);
      
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
      
      await _donationService.reserveDonation(donationId);
      
      // Si aucune exception n'est levée, l'opération a réussi
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
  
  // Nettoyer les données
  void clear() {
    _donations.clear();
    _userDonations.clear();
    _nearbyDonations.clear();
    _currentPosition = null;
    _selectedCategory = null;
    _clearError();
    notifyListeners();
  }
}