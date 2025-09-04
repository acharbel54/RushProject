import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Créer un profil utilisateur
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required UserRole userType,
    String? phone,
    String? photoUrl,
    String? address,
    GeoPoint? location,
  }) async {
    try {
      final userModel = UserModel(
        id: uid,
        email: email,
        displayName: name,
        role: userType,
        phoneNumber: phone,
        photoURL: photoUrl,
        address: address,
        latitude: location?.latitude,
        longitude: location?.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      
      await _usersCollection.doc(uid).set(userModel.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }
  
  // Créer un utilisateur avec un UserModel
  Future<void> createUser(UserModel userModel) async {
    try {
      await _usersCollection.doc(userModel.id).set(userModel.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  // Obtenir un utilisateur par ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }
  
  // Obtenir l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await getUserById(user.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur actuel: $e');
    }
  }
  
  // Stream de l'utilisateur actuel
  Stream<UserModel?> getCurrentUserStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _usersCollection
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromDocument(doc) : null);
    }
    return Stream.value(null);
  }
  
  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
    String? address,
    GeoPoint? location,
    bool? isVerified,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;
      if (address != null) updateData['address'] = address;
      if (location != null) updateData['location'] = location;
      if (isVerified != null) updateData['isVerified'] = isVerified;
      if (isActive != null) updateData['isActive'] = isActive;
      
      await _usersCollection.doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }
  
  // Mettre à jour l'utilisateur (méthode compatible avec AuthProvider)
  Future<void> updateUser(
    String uid, {
    String? displayName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      
      await _usersCollection.doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }
  
  // Supprimer un utilisateur
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }
  
  // Mettre à jour les statistiques de l'utilisateur
  Future<void> updateUserStats({
    required String uid,
    int? donationsCount,
    int? reservationsCount,
    double? rating,
    int? reviewsCount,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (donationsCount != null) {
        updateData['donationsCount'] = FieldValue.increment(donationsCount);
      }
      if (reservationsCount != null) {
        updateData['reservationsCount'] = FieldValue.increment(reservationsCount);
      }
      if (rating != null) updateData['rating'] = rating;
      if (reviewsCount != null) updateData['reviewsCount'] = reviewsCount;
      
      await _usersCollection.doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des statistiques: $e');
    }
  }
  
  // Incrémenter le nombre de dons
  Future<void> incrementDonationsCount(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'donationsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation des dons: $e');
    }
  }
  
  // Incrémenter le nombre de réservations
  Future<void> incrementReservationsCount(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'reservationsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation des réservations: $e');
    }
  }
  
  // Obtenir les utilisateurs par type
  Future<List<UserModel>> getUsersByType(UserRole userType) async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: userType.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }
  
  // Rechercher des utilisateurs par nom
  Future<List<UserModel>> searchUsersByName(String name) async {
    try {
      final querySnapshot = await _usersCollection
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThanOrEqualTo: name + '\uf8ff')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'utilisateurs: $e');
    }
  }
  
  // Obtenir les utilisateurs vérifiés
  Future<List<UserModel>> getVerifiedUsers() async {
    try {
      final querySnapshot = await _usersCollection
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs vérifiés: $e');
    }
  }
  
  // Obtenir les top donateurs
  Future<List<UserModel>> getTopDonors({int limit = 10}) async {
    try {
      final querySnapshot = await _usersCollection
          .where('userType', isEqualTo: 'donor')
          .where('isActive', isEqualTo: true)
          .orderBy('donationsCount', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des top donateurs: $e');
    }
  }
  
  // Vérifier si un utilisateur existe
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'utilisateur: $e');
    }
  }
  
  // Désactiver un utilisateur
  Future<void> deactivateUser(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la désactivation de l\'utilisateur: $e');
    }
  }
  
  // Réactiver un utilisateur
  Future<void> reactivateUser(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la réactivation de l\'utilisateur: $e');
    }
  }
  
  // Mettre à jour la note d'un utilisateur
  Future<void> updateUserRating(String uid, double newRating, int reviewsCount) async {
    try {
      await _usersCollection.doc(uid).update({
        'rating': newRating,
        'reviewsCount': reviewsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la note: $e');
    }
  }
  
  // Obtenir les statistiques globales des utilisateurs
  Future<Map<String, int>> getUsersStats() async {
    try {
      final totalUsers = await _usersCollection.count().get();
      final activeDonors = await _usersCollection
          .where('userType', isEqualTo: 'donor')
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      final activeBeneficiaries = await _usersCollection
          .where('userType', isEqualTo: 'beneficiary')
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      
      return {
        'total': totalUsers.count ?? 0,
        'donors': activeDonors.count ?? 0,
        'beneficiaries': activeBeneficiaries.count ?? 0,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}