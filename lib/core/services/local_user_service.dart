import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

class LocalUserService {
  static final LocalUserService _instance = LocalUserService._internal();
  factory LocalUserService() => _instance;
  LocalUserService._internal();

  final LocalStorageService _storage = LocalStorageService();
  
  // Collection name
  static const String _collection = 'users';

  // Initialiser le service
  Future<void> initialize() async {
    await _storage.initialize();
  }

  // Créer un profil utilisateur
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required UserRole userType,
    String? phone,
    String? photoUrl,
    String? address,
    double? latitude,
    double? longitude,
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
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      
      await _storage.add(_collection, userModel.toFirestore());
      
      if (kDebugMode) {
        print('Profil utilisateur créé localement: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création du profil: $e');
      }
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  // Créer un utilisateur (version simplifiée)
  Future<void> createUser(UserModel user) async {
    try {
      await _storage.add(_collection, user.toFirestore());
      
      if (kDebugMode) {
        print('Utilisateur créé localement: ${user.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création de l\'utilisateur: $e');
      }
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  // Obtenir un utilisateur par ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final users = await _storage.where(_collection, 'id', uid);
      
      if (users.isNotEmpty) {
        final userData = users.first;
        return UserModel.fromMap(userData);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération de l\'utilisateur: $e');
      }
      return null;
    }
  }

  // Obtenir un utilisateur par email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final users = await _storage.where(_collection, 'email', email);
      
      if (users.isNotEmpty) {
        final userData = users.first;
        return UserModel.fromMap(userData);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération de l\'utilisateur par email: $e');
      }
      return null;
    }
  }

  // Mettre à jour un utilisateur
  Future<void> updateUser(
    String uid, {
    String? displayName,
    String? phoneNumber,
    String? address,
    String? photoURL,
    UserRole? role,
    bool? isActive,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final users = await _storage.where(_collection, 'id', uid);
      
      if (users.isEmpty) {
        throw Exception('Utilisateur non trouvé: $uid');
      }
      
      final userData = users.first;
      final updateData = <String, dynamic>{};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (role != null) updateData['role'] = role.name;
      if (isActive != null) updateData['isActive'] = isActive;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      
      await _storage.update(_collection, userData['id'], updateData);
      
      if (kDebugMode) {
        print('Utilisateur mis à jour localement: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de l\'utilisateur: $e');
      }
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String uid) async {
    try {
      final users = await _storage.where(_collection, 'id', uid);
      
      if (users.isNotEmpty) {
        await _storage.delete(_collection, users.first['id']);
        
        if (kDebugMode) {
          print('Utilisateur supprimé localement: $uid');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression de l\'utilisateur: $e');
      }
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  // Obtenir tous les utilisateurs
  Future<List<UserModel>> getAllUsers() async {
    try {
      final usersData = await _storage.getAll(_collection);
      
      return usersData.map<UserModel>((userData) {
        return UserModel.fromMap(userData);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des utilisateurs: $e');
      }
      return [];
    }
  }

  // Obtenir les utilisateurs par rôle
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final users = await _storage.where(_collection, 'role', role.name);
      
      return users.map<UserModel>((userData) {
        return UserModel.fromMap(userData);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des utilisateurs par rôle: $e');
      }
      return [];
    }
  }

  // Obtenir les utilisateurs actifs
  Future<List<UserModel>> getActiveUsers() async {
    try {
      final users = await _storage.where(_collection, 'isActive', true);
      
      return users.map<UserModel>((userData) {
        return UserModel.fromMap(userData);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des utilisateurs actifs: $e');
      }
      return [];
    }
  }

  // Rechercher des utilisateurs par nom
  Future<List<UserModel>> searchUsersByName(String query) async {
    try {
      final allUsers = await _storage.getAll(_collection);
      
      final filteredUsers = allUsers.where((userData) {
        final displayName = userData['displayName']?.toString().toLowerCase() ?? '';
        return displayName.contains(query.toLowerCase());
      }).toList();
      
      return filteredUsers.map<UserModel>((userData) {
        return UserModel.fromMap(userData);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la recherche d\'utilisateurs: $e');
      }
      return [];
    }
  }

  // Vérifier si un utilisateur existe
  Future<bool> userExists(String uid) async {
    try {
      final users = await _storage.where(_collection, 'id', uid);
      return users.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification d\'existence: $e');
      }
      return false;
    }
  }

  // Vérifier si un email existe
  Future<bool> emailExists(String email) async {
    try {
      final users = await _storage.where(_collection, 'email', email);
      return users.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification d\'email: $e');
      }
      return false;
    }
  }

  // Obtenir le nombre d'utilisateurs
  Future<int> getUserCount() async {
    try {
      return await _storage.count(_collection);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du comptage des utilisateurs: $e');
      }
      return 0;
    }
  }

  // Obtenir les statistiques des utilisateurs
  Future<Map<String, int>> getUserStats() async {
    try {
      final allUsers = await _storage.getAll(_collection);
      
      final stats = <String, int>{
        'total': allUsers.length,
        'active': 0,
        'donateurs': 0,
        'beneficiaires': 0,
        'admins': 0,
      };
      
      for (final userData in allUsers) {
        if (userData['isActive'] == true) {
          stats['active'] = stats['active']! + 1;
        }
        
        final role = userData['role']?.toString();
        switch (role) {
          case 'donateur':
            stats['donateurs'] = stats['donateurs']! + 1;
            break;
          case 'beneficiaire':
            stats['beneficiaires'] = stats['beneficiaires']! + 1;
            break;
          case 'admin':
            stats['admins'] = stats['admins']! + 1;
            break;
        }
      }
      
      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du calcul des statistiques: $e');
      }
      return {
        'total': 0,
        'active': 0,
        'donateurs': 0,
        'beneficiaires': 0,
        'admins': 0,
      };
    }
  }

  // Vider tous les utilisateurs (pour les tests)
  Future<void> clearAllUsers() async {
    try {
      await _storage.clear(_collection);
      
      if (kDebugMode) {
        print('Tous les utilisateurs supprimés');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression des utilisateurs: $e');
      }
      throw Exception('Erreur lors de la suppression des utilisateurs: $e');
    }
  }
}