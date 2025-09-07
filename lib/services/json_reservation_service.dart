import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/models/reservation_model.dart';

class JsonReservationService {
  static const String _fileName = 'reservations.json';
  List<ReservationModel> _reservations = [];

  // Obtenir le chemin du fichier JSON
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${directory.path}/base_de_donnees');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return dbDir.path;
  }

  // Obtenir le fichier local
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  // Initialiser avec les données depuis le fichier du projet si le fichier sur le téléphone n'existe pas
  Future<void> _initializeWithProjectData() async {
    try {
      // Essayer de lire le fichier depuis le projet comme données initiales
      final projectFile = File('base_de_donnees/$_fileName');
      if (await projectFile.exists()) {
        final contents = await projectFile.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        _reservations = jsonData.map((json) => ReservationModel.fromJson(json)).toList();
        print('DEBUG: Données initiales chargées depuis le fichier projet: ${_reservations.length} réservations');
        
        // Sauvegarder ces données sur le téléphone
        await saveReservations();
        return;
      }
    } catch (e) {
      print('DEBUG: Erreur lors du chargement depuis le projet: $e');
    }
    
    // Si aucun fichier projet, initialiser avec une liste vide
    _reservations = [];
    print('DEBUG: Aucune donnée initiale trouvée, liste vide créée');
  }

  // Charger les réservations depuis le fichier JSON
  Future<void> loadReservations() async {
    try {
      final file = await _localFile;
      print('DEBUG: Chemin du fichier reservations.json: ${file.path}');
      print('DEBUG: Le fichier existe: ${await file.exists()}');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        print('DEBUG: Contenu du fichier (${contents.length} caractères)');
        
        final List<dynamic> jsonData = json.decode(contents);
        _reservations = jsonData.map((json) => ReservationModel.fromJson(json)).toList();
        print('DEBUG: Nombre de réservations chargées: ${_reservations.length}');
      } else {
        print('DEBUG: Fichier reservations.json n\'existe pas, initialisation avec données du projet');
        await _initializeWithProjectData();
      }
    } catch (e) {
      print('DEBUG: Erreur lors du chargement des réservations: $e');
      await _initializeWithProjectData();
    }
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
    
    // Ajouter un message d'historique automatiquement
    final reservationWithMessage = reservation.copyWith(
      historyMessage: 'Réservation créée le ${_formatDate(reservation.createdAt)} pour "${reservation.donationTitle}"'
    );
    
    _reservations.add(reservationWithMessage);
    await saveReservations();
  }
  
  // Méthode utilitaire pour formater la date
  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Mettre à jour une réservation
  Future<void> updateReservation(ReservationModel updatedReservation) async {
    await loadReservations();
    final index = _reservations.indexWhere((r) => r.id == updatedReservation.id);
    if (index != -1) {
      _reservations[index] = updatedReservation;
      await saveReservations();
      print('DEBUG JsonReservationService: Réservation ${updatedReservation.id} mise à jour');
    } else {
      print('DEBUG JsonReservationService: Réservation ${updatedReservation.id} non trouvée pour mise à jour');
    }
  }

  // Mettre à jour une réservation par ID (méthode legacy)
  Future<void> updateReservationById(String id, ReservationModel updatedReservation) async {
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