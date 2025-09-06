import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/models/reservation_model.dart';

class JsonReservationService {
  static const String _fileName = 'reservations.json';
  List<ReservationModel> _reservations = [];

  // Obtenir le fichier local
  Future<File> get _localFile async {
    // Utiliser le fichier de test dans le dossier du projet
    return File('base_de_donnees/$_fileName');
  }

  // Initialiser avec les données de test depuis les assets
  Future<void> _initializeWithTestData() async {
    try {
      // Essayer de lire le fichier depuis les assets du projet
      final projectFile = File('base_de_donnees/$_fileName');
      if (await projectFile.exists()) {
        final contents = await projectFile.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        _reservations = jsonData.map((json) => ReservationModel.fromJson(json)).toList();
        print('DEBUG: Données chargées depuis le fichier projet: ${_reservations.length} réservations');
        return;
      }
    } catch (e) {
      print('DEBUG: Erreur lors du chargement depuis le projet: $e');
    }
    
    // Fallback: créer une réservation de test
    final testReservation = ReservationModel(
      id: 'test-reservation-001',
      donationId: 'donation_001',
      donorId: 'donateur_001',
      beneficiaryId: 'beneficiaire_001',
      beneficiaryName: 'Bénéficiaire Test',
      donationTitle: 'Don de test',
      donationQuantity: 1,
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      donorName: 'Donateur Test',
      pickupAddress: 'Adresse de test',
    );
    
    _reservations = [testReservation];
    print('DEBUG: Données de test créées avec 1 réservation');
  }

  // Charger les réservations depuis le fichier JSON
  Future<void> loadReservations() async {
    print('DEBUG loadReservations: Début du chargement');
    await _initializeWithTestData();
    print('DEBUG loadReservations: Fin du chargement, ${_reservations.length} réservations');
  }

  // Sauvegarder les réservations dans le fichier JSON
  Future<void> saveReservations() async {
    try {
      final file = await _localFile;
      // Créer le répertoire s'il n'existe pas
      await file.parent.create(recursive: true);
      final jsonData = _reservations.map((reservation) => reservation.toJson()).toList();
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      print('Erreur lors de la sauvegarde des réservations: $e');
    }
  }

  // Obtenir toutes les réservations
  Future<List<ReservationModel>> getAllReservations() async {
    await loadReservations();
    return List.from(_reservations);
  }

  // Obtenir les réservations d'un utilisateur
  Future<List<ReservationModel>> getUserReservations(String userId) async {
    await loadReservations();
    print('DEBUG JsonReservationService: Total réservations chargées: ${_reservations.length}');
    print('DEBUG JsonReservationService: Recherche pour userId: $userId');
    
    for (int i = 0; i < _reservations.length; i++) {
      final reservation = _reservations[i];
      print('DEBUG JsonReservationService: Réservation $i - BeneficiaryID: ${reservation.beneficiaryId}');
    }
    
    final userReservations = _reservations.where((r) => r.beneficiaryId == userId).toList();
    print('DEBUG JsonReservationService: Réservations trouvées pour $userId: ${userReservations.length}');
    
    return userReservations;
  }

  // Ajouter une nouvelle réservation
  Future<void> addReservation(ReservationModel reservation) async {
    await loadReservations();
    _reservations.add(reservation);
    await saveReservations();
  }

  // Mettre à jour une réservation
  Future<void> updateReservation(String id, ReservationModel updatedReservation) async {
    await loadReservations();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reservations[index] = updatedReservation;
      await saveReservations();
    }
  }

  // Supprimer une réservation
  Future<void> deleteReservation(String id) async {
    await loadReservations();
    _reservations.removeWhere((r) => r.id == id);
    await saveReservations();
  }

  // Obtenir une réservation par ID
  Future<ReservationModel?> getReservationById(String id) async {
    await loadReservations();
    try {
      return _reservations.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // Vérifier si un don a une réservation active
  Future<bool> hasDonationActiveReservation(String donationId) async {
    await loadReservations();
    return _reservations.any((r) => 
      r.donationId == donationId && 
      (r.status == ReservationStatus.pending || r.status == ReservationStatus.confirmed)
    );
  }

  // Obtenir les réservations par statut
  Future<List<ReservationModel>> getReservationsByStatus(ReservationStatus status) async {
    await loadReservations();
    return _reservations.where((r) => r.status == status).toList();
  }
}