import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
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
      final appDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory('${appDir.path}/base_de_donnees');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      
      _usersFile = File('${dataDir.path}/userinfo.json');
      await _loadUsers();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('SimpleAuthService initialisé avec ${_users.length} utilisateurs');
        print('Fichier utilisé: ${_usersFile.path}');
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
    if (kDebugMode) {
      print('Utilisateur déconnecté');
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