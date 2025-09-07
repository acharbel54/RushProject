import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

// Modèle simple pour l'utilisateur
class SimpleUser {
  final String id;
  final String email;
  final String password;
  final String displayName;
  final UserRole role;
  final String? phoneNumber;
  final String? address;
  final DateTime createdAt;
  final int totalDonations;
  final int totalReservations;
  final double totalKgDonated;
  final List<String>? dietaryPreferences;
  final List<String>? allergies;
  final String? preferredPickupZone;

  SimpleUser({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.address,
    required this.createdAt,
    this.totalDonations = 0,
    this.totalReservations = 0,
    this.totalKgDonated = 0.0,
    this.dietaryPreferences,
    this.allergies,
    this.preferredPickupZone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'displayName': displayName,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'totalDonations': totalDonations,
      'totalReservations': totalReservations,
      'totalKgDonated': totalKgDonated,
      'dietaryPreferences': dietaryPreferences,
      'allergies': allergies,
      'preferredPickupZone': preferredPickupZone,
    };
  }

  factory SimpleUser.fromJson(Map<String, dynamic> json) {
    // Conversion plus robuste du rôle
    UserRole role;
    String roleString = json['role']?.toString().toLowerCase() ?? 'beneficiaire';
    
    switch (roleString) {
      case 'donateur':
        role = UserRole.donateur;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      case 'beneficiaire':
      default:
        role = UserRole.beneficiaire;
        break;
    }
    
    return SimpleUser(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      displayName: json['displayName'] ?? json['fullName'] ?? json['firstName'] ?? '',
      role: role,
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      createdAt: DateTime.parse(json['createdAt']),
      totalDonations: json['totalDonations'] ?? 0,
      totalReservations: json['totalReservations'] ?? 0,
      totalKgDonated: (json['totalKgDonated'] ?? 0.0).toDouble(),
      dietaryPreferences: json['dietaryPreferences']?.cast<String>(),
      allergies: json['allergies']?.cast<String>(),
      preferredPickupZone: json['preferredPickupZone'],
    );
  }
}

class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  SimpleUser? _currentUser;
  List<SimpleUser> _users = [];
  late File _usersFile;
  bool _isInitialized = false;

  SimpleUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Obtenir le répertoire des documents de l'application
      final directory = await getApplicationDocumentsDirectory();
      _usersFile = File('${directory.path}/userinfo.json');
      
      // Créer le fichier avec les données par défaut s'il n'existe pas
      if (!await _usersFile.exists()) {
        await _createDefaultUsers();
      }
      
      await _loadUsers();
      await _loadCurrentUser(); // Charger l'utilisateur actuel depuis current_user.json
      _isInitialized = true;
      
      if (kDebugMode) {
        print('SimpleAuthService initialized with ${_users.length} users');
        print('Current user: ${_currentUser?.email ?? "None"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation: $e');
      }
      rethrow;
    }
  }

  // Charger les utilisateurs depuis le fichier JSON
  Future<void> _loadUsers() async {
    try {
      if (await _usersFile.exists()) {
        final content = await _usersFile.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _users = jsonList.map((json) => SimpleUser.fromJson(json)).toList();
      } else {
        _users = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des utilisateurs: $e');
      }
      _users = [];
    }
  }

  // Créer les utilisateurs par défaut
  Future<void> _createDefaultUsers() async {
    try {
      final defaultUsers = [
        {
          "phoneNumber": "0123456789",
          "id": "donateur_001",
          "displayName": "Jean Donateur",
          "totalDonations": 5,
          "createdAt": "2025-09-06T00:18:50.114Z",
          "password": "123456",
          "role": "donateur",
          "address": "123 Rue du Don, Paris",
          "email": "donateur@test.com"
        },
        {
          "phoneNumber": "0987654321",
          "id": "beneficiaire_001",
          "displayName": "Marie Bénéficiaire",
          "totalDonations": 0,
          "totalReservations": 3,
          "createdAt": "2025-09-06T00:18:50.122Z",
          "password": "123456",
          "role": "beneficiaire",
          "address": "456 Avenue de l'Aide, Lyon",
          "email": "beneficiaire@test.com",
          "preferredPickupZone": "Lyon Centre",
          "dietaryPreferences": ["Végétarien", "Sans gluten"],
          "allergies": ["Arachides", "Lait"]
        }
      ];
      
      final content = json.encode(defaultUsers);
      await _usersFile.writeAsString(content);
      
      if (kDebugMode) {
        print('Fichier userinfo.json créé avec les utilisateurs par défaut');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création des utilisateurs par défaut: $e');
      }
      rethrow;
    }
  }

  // Sauvegarder les utilisateurs dans le fichier JSON
  Future<void> _saveUsers() async {
    try {
      final jsonList = _users.map((user) => user.toJson()).toList();
      final content = json.encode(jsonList);
      await _usersFile.writeAsString(content);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde: $e');
      }
      rethrow;
    }
  }

  // Charger l'utilisateur actuel depuis current_user.json
  Future<void> _loadCurrentUser() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final currentUserFile = File('${directory.path}/current_user.json');
      
      if (await currentUserFile.exists()) {
        final content = await currentUserFile.readAsString();
        final userData = json.decode(content);
        
        // Convertir les données JSON en SimpleUser
        final user = SimpleUser(
          id: userData['id'],
          email: userData['email'],
          password: userData['password'],
          displayName: '${userData['firstName']} ${userData['lastName']}',
          role: _parseUserRole(userData['role']),
          createdAt: DateTime.parse(userData['createdAt']),
        );
        
        _currentUser = user;
        
        if (kDebugMode) {
          print('Utilisateur actuel chargé: ${user.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement de l\'utilisateur actuel: $e');
      }
      _currentUser = null;
    }
  }

  // Sauvegarder l'utilisateur actuel dans current_user.json
  Future<void> _saveCurrentUser() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final currentUserFile = File('${directory.path}/current_user.json');
      
      if (_currentUser != null) {
        // Convertir SimpleUser en format compatible avec current_user.json
        final userData = {
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'password': _currentUser!.password,
          'firstName': _currentUser!.displayName.split(' ').first,
          'lastName': _currentUser!.displayName.split(' ').skip(1).join(' '),
          'role': _currentUser!.role.toString().split('.').last,
          'createdAt': _currentUser!.createdAt.toIso8601String(),
        };
        
        await currentUserFile.writeAsString(json.encode(userData));
        
        if (kDebugMode) {
          print('Utilisateur actuel sauvegardé: ${_currentUser!.email}');
        }
      } else {
        // Supprimer le fichier si aucun utilisateur connecté
        if (await currentUserFile.exists()) {
          await currentUserFile.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde de l\'utilisateur actuel: $e');
      }
    }
  }

  // Parser le rôle utilisateur depuis une chaîne
  UserRole _parseUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'donateur':
        return UserRole.donateur;
      case 'beneficiaire':
        return UserRole.beneficiaire;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.beneficiaire;
    }
  }

  // Inscription
  Future<SimpleUser?> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      // Vérifier si l'email existe déjà
      final existingUser = _users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw StateError('Not found'),
      );
      
      if (kDebugMode) {
        print('Email déjà utilisé: $email');
      }
      return null; // Email déjà utilisé
    } catch (e) {
      // L'utilisateur n'existe pas, on peut créer le compte
    }

    try {
      final newUser = SimpleUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        password: password, // Stockage en clair pour le prototype
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
        address: address,
        createdAt: DateTime.now(),
      );

      _users.add(newUser);
      await _saveUsers();
      _currentUser = newUser;

      if (kDebugMode) {
        print('Utilisateur créé: ${newUser.email}');
      }

      return newUser;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'inscription: $e');
      }
      return null;
    }
  }

  // Connexion
  Future<SimpleUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = _users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase() && user.password == password,
        orElse: () => throw StateError('Not found'),
      );

      _currentUser = user;
      await _saveCurrentUser(); // Sauvegarder la session
      
      if (kDebugMode) {
        print('Connexion réussie: ${user.email}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Échec de connexion pour: $email');
      }
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    _currentUser = null;
    await _saveCurrentUser(); // Supprimer la session sauvegardée
    
    if (kDebugMode) {
      print('Déconnexion réussie');
    }
  }

  // Obtenir tous les utilisateurs (pour debug)
  List<SimpleUser> getAllUsers() {
    return List.from(_users);
  }

  // Obtenir un utilisateur par ID
  Future<SimpleUser?> getUserById(String userId) async {
    try {
      await initialize();
      return _users.firstWhere(
        (user) => user.id == userId,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Utilisateur non trouvé avec ID: $userId');
      }
      return null;
    }
  }

  // Supprimer un utilisateur
  Future<bool> deleteUser(String userId) async {
    try {
      _users.removeWhere((user) => user.id == userId);
      await _saveUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour les statistiques utilisateur
  Future<SimpleUser?> updateUserStats({
    String? userId,
    int? totalDonations,
    int? totalReservations,
    double? totalKgDonated,
  }) async {
    try {
      final targetUserId = userId ?? _currentUser?.id;
      if (targetUserId == null) return null;

      final userIndex = _users.indexWhere((user) => user.id == targetUserId);
      if (userIndex == -1) return null;

      final currentUser = _users[userIndex];
      
      // Créer un nouvel utilisateur avec les statistiques mises à jour
      final updatedUser = SimpleUser(
        id: currentUser.id,
        email: currentUser.email,
        password: currentUser.password,
        displayName: currentUser.displayName,
        role: currentUser.role,
        phoneNumber: currentUser.phoneNumber,
        address: currentUser.address,
        createdAt: currentUser.createdAt,
        totalDonations: totalDonations ?? currentUser.totalDonations,
         totalReservations: totalReservations ?? currentUser.totalReservations,
         totalKgDonated: totalKgDonated ?? currentUser.totalKgDonated,
         dietaryPreferences: currentUser.dietaryPreferences,
        allergies: currentUser.allergies,
        preferredPickupZone: currentUser.preferredPickupZone,
      );

      // Mettre à jour dans la liste
      _users[userIndex] = updatedUser;
      await _saveUsers();
      
      // Si c'est l'utilisateur actuel, mettre à jour la référence
      if (targetUserId == _currentUser?.id) {
        _currentUser = updatedUser;
      }

      if (kDebugMode) {
        print('Statistiques mises à jour pour: ${updatedUser.email}');
      }

      return updatedUser;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour des statistiques: $e');
      }
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  Future<SimpleUser?> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? address,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    String? preferredPickupZone,
  }) async {
    if (_currentUser == null) return null;

    try {
      // Créer un nouvel utilisateur avec les informations mises à jour
      final updatedUser = SimpleUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        password: _currentUser!.password,
        displayName: displayName ?? _currentUser!.displayName,
        role: _currentUser!.role,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        address: address ?? _currentUser!.address,
        createdAt: _currentUser!.createdAt,
        totalDonations: _currentUser!.totalDonations,
        totalReservations: _currentUser!.totalReservations,
        totalKgDonated: _currentUser!.totalKgDonated,
        dietaryPreferences: dietaryPreferences ?? _currentUser!.dietaryPreferences,
        allergies: allergies ?? _currentUser!.allergies,
        preferredPickupZone: preferredPickupZone ?? _currentUser!.preferredPickupZone,
      );

      // Mettre à jour dans la liste
      final index = _users.indexWhere((user) => user.id == _currentUser!.id);
      if (index != -1) {
        _users[index] = updatedUser;
        await _saveUsers();
        _currentUser = updatedUser;

        if (kDebugMode) {
          print('Profil mis à jour pour: ${updatedUser.email}');
        }

        return updatedUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du profil: $e');
      }
    }
    return null;
  }
}