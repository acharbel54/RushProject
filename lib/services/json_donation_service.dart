import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/models/donation_model.dart';

class JsonDonationService {
  static final JsonDonationService _instance = JsonDonationService._internal();
  factory JsonDonationService() => _instance;
  JsonDonationService._internal();

  List<DonationModel> _donations = [];

  List<DonationModel> get donations => _donations;

  // Obtenir le chemin du fichier JSON
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${directory.path}/base_de_donnees');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return dbDir.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/donations.json');
  }

  // Charger les donations depuis le fichier JSON
  Future<void> loadDonations() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        _donations = jsonData.map((json) => DonationModel.fromJson(json)).toList();
        
        // Ajouter des images de test aux donations existantes
        for (int i = 0; i < _donations.length; i++) {
          if (_donations[i].imageUrls.isEmpty) {
            List<String> testImages = [
              'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
              'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?w=400',
              'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
              'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400'
            ];
            _donations[i] = _donations[i].copyWith(
              imageUrls: [testImages[i % testImages.length]]
            );
          }
        }
        
        // Sauvegarder les modifications
        await saveDonations();
      }
    } catch (e) {
      print('Erreur lors du chargement des donations: $e');
      _donations = [];
    }
  }

  // Sauvegarder les donations dans le fichier JSON
  Future<void> saveDonations() async {
    try {
      final file = await _localFile;
      // Créer le répertoire s'il n'existe pas
      await file.parent.create(recursive: true);
      final jsonData = _donations.map((donation) => donation.toJson()).toList();
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      print('Erreur lors de la sauvegarde des donations: $e');
    }
  }

  // Ajouter une nouvelle donation
  Future<String> addDonation(DonationModel donation) async {
    try {
      await loadDonations();
      
      // Générer un ID unique
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newDonation = donation.copyWith(id: id);
      
      _donations.add(newDonation);
      await saveDonations();
      
      return id;
    } catch (e) {
      print('Erreur lors de l\'ajout de la donation: $e');
      rethrow;
    }
  }

  // Obtenir toutes les donations
  Future<List<DonationModel>> getAllDonations() async {
    await loadDonations();
    return _donations;
  }

  // Obtenir les donations d'un donateur spécifique
  Future<List<DonationModel>> getDonationsByDonor(String donorId) async {
    await loadDonations();
    return _donations.where((donation) => donation.donorId == donorId).toList();
  }

  // Mettre à jour une donation
  Future<void> updateDonation(String id, DonationModel updatedDonation) async {
    try {
      await loadDonations();
      
      final index = _donations.indexWhere((donation) => donation.id == id);
      if (index != -1) {
        _donations[index] = updatedDonation.copyWith(id: id, updatedAt: DateTime.now());
        await saveDonations();
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la donation: $e');
      rethrow;
    }
  }

  // Supprimer une donation
  Future<void> deleteDonation(String id) async {
    try {
      await loadDonations();
      
      _donations.removeWhere((donation) => donation.id == id);
      await saveDonations();
    } catch (e) {
      print('Erreur lors de la suppression de la donation: $e');
      rethrow;
    }
  }

  // Réserver une donation
  Future<void> reserveDonation(String id, String userId) async {
    try {
      await loadDonations();
      
      final index = _donations.indexWhere((donation) => donation.id == id);
      if (index != -1) {
        _donations[index] = _donations[index].copyWith(
          status: DonationStatus.reserve,
          reservedBy: userId,
          reservedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveDonations();
      }
    } catch (e) {
      print('Erreur lors de la réservation de la donation: $e');
      rethrow;
    }
  }

  // Annuler la réservation d'une donation
  Future<void> cancelReservation(String id) async {
    try {
      await loadDonations();
      
      final index = _donations.indexWhere((donation) => donation.id == id);
      if (index != -1) {
        _donations[index] = _donations[index].copyWith(
          status: DonationStatus.disponible,
          reservedBy: null,
          reservedAt: null,
          updatedAt: DateTime.now(),
        );
        await saveDonations();
      }
    } catch (e) {
      print('Erreur lors de l\'annulation de la réservation: $e');
      rethrow;
    }
  }

  // Marquer une donation comme récupérée
  Future<void> markAsCollected(String id) async {
    try {
      await loadDonations();
      
      final index = _donations.indexWhere((donation) => donation.id == id);
      if (index != -1) {
        _donations[index] = _donations[index].copyWith(
          status: DonationStatus.recupere,
          updatedAt: DateTime.now(),
        );
        await saveDonations();
      }
    } catch (e) {
      print('Erreur lors du marquage comme récupéré: $e');
      rethrow;
    }
  }

  // Obtenir les donations disponibles
  Future<List<DonationModel>> getAvailableDonations() async {
    await loadDonations();
    return _donations.where((donation) => 
      donation.status == DonationStatus.disponible && 
      !donation.isExpired
    ).toList();
  }

  // Obtenir les donations réservées par un utilisateur
  Future<List<DonationModel>> getReservedDonations(String userId) async {
    await loadDonations();
    return _donations.where((donation) => 
      donation.reservedBy == userId && 
      donation.status == DonationStatus.reserve
    ).toList();
  }

  // Obtenir les donations d'un utilisateur spécifique
  Future<List<DonationModel>> getUserDonations(String userId) async {
    await loadDonations();
    return _donations.where((donation) => donation.donorId == userId).toList();
  }

  // Obtenir les donations à proximité (simulation simple)
  Future<List<DonationModel>> getNearbyDonations({
    required double userLatitude,
    required double userLongitude,
    required double radiusKm,
  }) async {
    await loadDonations();
    // Pour l'instant, on retourne toutes les donations disponibles
    // Dans une vraie implémentation, on calculerait la distance
    return getAvailableDonations();
  }

  // Obtenir une donation par ID
  Future<DonationModel?> getDonationById(String donationId) async {
    await loadDonations();
    print('DEBUG: Recherche donation avec ID: $donationId');
    print('DEBUG: Nombre de donations chargées: ${_donations.length}');
    for (var donation in _donations) {
      print('DEBUG: Donation ID disponible: ${donation.id}, imageUrls: ${donation.imageUrls}');
    }
    try {
      final result = _donations.firstWhere((donation) => donation.id == donationId);
      print('DEBUG: Donation trouvée: ${result.title}, imageUrls: ${result.imageUrls}');
      return result;
    } catch (e) {
      print('DEBUG: Aucune donation trouvée avec l\'ID: $donationId');
      return null;
    }
  }
}