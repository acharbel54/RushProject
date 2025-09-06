import 'dart:convert';
import 'dart:io';
import '../core/models/reservation_model.dart';

class JsonReservationService {
  static const String _fileName = 'reservations.json';
  List<ReservationModel> _reservations = [];

  // Obtenir le fichier local
  Future<File> get _localFile async {
    // Utiliser le fichier de test dans le dossier du projet
    return File('base_de_donnees/$_fileName');
  }

  // Charger les réservations depuis le fichier JSON
  Future<void> loadReservations() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        _reservations = jsonData.map((json) => ReservationModel.fromJson(json)).toList();
      } else {
        _reservations = [];
      }
    } catch (e) {
      print('Erreur lors du chargement des réservations: $e');
      _reservations = [];
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
    return _reservations.where((r) => r.beneficiaryId == userId).toList();
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