import 'dart:io';
import 'dart:math' show cos, sin, atan2, sqrt, pi;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/donation_model.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference
  CollectionReference get _donationsCollection => _firestore.collection('donations');
  
  // Créer un don
  Future<String> createDonation({
    required String title,
    required String description,
    required DonationCategory category,
    required String quantity,
    required String unit,
    required DateTime expiryDate,
    required String address,
    required GeoPoint location,
    String? contactPhone,
    List<String>? imageUrls,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      final donationModel = DonationModel(
        id: '', // Sera généré par Firestore
        donorId: user.uid,
        donorName: user.displayName ?? 'Donateur anonyme',
        title: title,
        description: description,
        quantity: quantity,
        category: category,
        expirationDate: expiryDate,
        address: address,
        latitude: location?.latitude ?? 0.0,
        longitude: location?.longitude ?? 0.0,
        imageUrls: imageUrls ?? [],
        status: DonationStatus.disponible,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notes,
      );
      
      final docRef = await _donationsCollection.add(donationModel.toMap());
      
      // Mettre à jour l'ID du document
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du don: $e');
    }
  }
  
  // Obtenir un don par ID
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      final doc = await _donationsCollection.doc(donationId).get();
      if (doc.exists) {
        return DonationModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du don: $e');
    }
  }
  
  // Obtenir tous les dons disponibles
  Future<List<DonationModel>> getAvailableDonations({
    int? limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _donationsCollection
          .where('status', isEqualTo: 'available')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => DonationModel.fromDocument(doc))
          .toList().cast<DonationModel>();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dons: $e');
    }
  }
  
  // Obtenir les dons d'un utilisateur
  Future<List<DonationModel>> getUserDonations(String userId) async {
    try {
      final querySnapshot = await _donationsCollection
          .where('donorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => DonationModel.fromDocument(doc))
          .toList().cast<DonationModel>();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dons de l\'utilisateur: $e');
    }
  }
  
  // Obtenir les dons par catégorie
  Future<List<DonationModel>> getDonationsByCategory(
    DonationCategory category, {
    int? limit,
  }) async {
    try {
      Query query = _donationsCollection
          .where('category', isEqualTo: category.toString().split('.').last)
          .where('status', isEqualTo: 'available')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => DonationModel.fromDocument(doc))
          .toList().cast<DonationModel>();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dons par catégorie: $e');
    }
  }
  
  // Obtenir les dons à proximité
  Future<List<DonationModel>> getNearbyDonations({
    required GeoPoint userLocation,
    required double radiusKm,
    int? limit,
  }) async {
    try {
      // Calculer les limites géographiques approximatives
      final lat = userLocation.latitude;
      final lng = userLocation.longitude;
      
      // Approximation: 1 degré ≈ 111 km
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * cos(lat * pi / 180));
      
      final minLat = lat - latDelta;
      final maxLat = lat + latDelta;
      final minLng = lng - lngDelta;
      final maxLng = lng + lngDelta;
      
      Query query = _donationsCollection
          .where('status', isEqualTo: 'available')
          .where('isActive', isEqualTo: true)
          .where('location', isGreaterThan: GeoPoint(minLat, minLng))
          .where('location', isLessThan: GeoPoint(maxLat, maxLng))
          .orderBy('location')
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit * 2); // Récupérer plus pour filtrer ensuite
      }
      
      final querySnapshot = await query.get();
      
      // Filtrer par distance exacte et trier par distance
      final donations = querySnapshot.docs
          .map((doc) => DonationModel.fromDocument(doc))
          .where((donation) {
            final distance = _calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              donation.latitude,
              donation.longitude,
            );
            return distance <= radiusKm;
          })
          .toList();
      
      // Trier par distance
      donations.sort((a, b) {
        final distanceA = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
      
      return limit != null ? donations.take(limit).toList().cast<DonationModel>() : donations.cast<DonationModel>();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des dons à proximité: $e');
    }
  }
  
  // Rechercher des dons
  Future<List<DonationModel>> searchDonations({
    required String searchTerm,
    DonationCategory? category,
    int? limit,
  }) async {
    try {
      Query query = _donationsCollection
          .where('status', isEqualTo: 'available')
          .where('isActive', isEqualTo: true);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }
      
      // Recherche par titre (approximative)
      query = query
          .where('title', isGreaterThanOrEqualTo: searchTerm)
          .where('title', isLessThanOrEqualTo: searchTerm + '\uf8ff');
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => DonationModel.fromDocument(doc))
          .toList().cast<DonationModel>();
    } catch (e) {
      throw Exception('Erreur lors de la recherche de dons: $e');
    }
  }
  
  // Mettre à jour un don
  Future<void> updateDonation({
    required String donationId,
    String? title,
    String? description,
    DonationCategory? category,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    String? address,
    GeoPoint? location,
    String? contactPhone,
    List<String>? imageUrls,
    DonationStatus? status,
    String? notes,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category.toString().split('.').last;
      if (quantity != null) updateData['quantity'] = quantity;
      if (unit != null) updateData['unit'] = unit;
      if (expiryDate != null) updateData['expiryDate'] = Timestamp.fromDate(expiryDate);
      if (address != null) updateData['address'] = address;
      if (location != null) updateData['location'] = location;
      if (contactPhone != null) updateData['contactPhone'] = contactPhone;
      if (imageUrls != null) updateData['imageUrls'] = imageUrls;
      if (status != null) updateData['status'] = status.toString().split('.').last;
      if (notes != null) updateData['notes'] = notes;
      if (isActive != null) updateData['isActive'] = isActive;
      
      await _donationsCollection.doc(donationId).update(updateData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du don: $e');
    }
  }
  
  // Réserver un don
  Future<void> reserveDonation(String donationId) async {
    try {
      await _donationsCollection.doc(donationId).update({
        'status': 'reserved',
        'reservationsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la réservation du don: $e');
    }
  }
  
  // Annuler la réservation d'un don
  Future<void> cancelReservation(String donationId) async {
    try {
      await _donationsCollection.doc(donationId).update({
        'status': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la réservation: $e');
    }
  }
  
  // Marquer un don comme collecté
  Future<void> markAsCollected(String donationId) async {
    try {
      await _donationsCollection.doc(donationId).update({
        'status': 'collected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors du marquage comme collecté: $e');
    }
  }
  
  // Incrémenter le nombre de vues
  Future<void> incrementViewsCount(String donationId) async {
    try {
      await _donationsCollection.doc(donationId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation des vues: $e');
    }
  }
  
  // Supprimer un don
  Future<void> deleteDonation(String donationId) async {
    try {
      await _donationsCollection.doc(donationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du don: $e');
    }
  }
  
  // Désactiver un don
  Future<void> deactivateDonation(String donationId) async {
    try {
      await _donationsCollection.doc(donationId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la désactivation du don: $e');
    }
  }
  
  // Obtenir les statistiques des dons
  Future<Map<String, int>> getDonationsStats() async {
    try {
      final totalDonations = await _donationsCollection.count().get();
      final availableDonations = await _donationsCollection
          .where('status', isEqualTo: 'available')
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      final reservedDonations = await _donationsCollection
          .where('status', isEqualTo: 'reserved')
          .count()
          .get();
      final collectedDonations = await _donationsCollection
          .where('status', isEqualTo: 'collected')
          .count()
          .get();
      
      return {
        'total': totalDonations.count ?? 0,
        'available': availableDonations.count ?? 0,
        'reserved': reservedDonations.count ?? 0,
        'collected': collectedDonations.count ?? 0,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
  
  // Stream des dons disponibles
  Stream<List<DonationModel>> getAvailableDonationsStream({int? limit}) {
    Query query = _donationsCollection
        .where('status', isEqualTo: 'available')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DonationModel.fromDocument(doc))
          .toList().cast<DonationModel>();
    });
  }
  
  // Calculer la distance entre deux points géographiques
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}