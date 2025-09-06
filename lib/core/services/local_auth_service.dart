import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

// Modèle pour l'utilisateur local
class LocalUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime lastSignIn;

  LocalUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    required this.createdAt,
    required this.lastSignIn,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSignIn': lastSignIn.toIso8601String(),
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      emailVerified: map['emailVerified'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      lastSignIn: DateTime.parse(map['lastSignIn']),
    );
  }
}

// Modèle pour les credentials
class LocalUserCredential {
  final LocalUser? user;
  
  LocalUserCredential({this.user});
}

// Exception personnalisée pour l'auth locale
class LocalAuthException implements Exception {
  final String code;
  final String message;
  
  LocalAuthException(this.code, this.message);
  
  @override
  String toString() => 'LocalAuthException: $code - $message';
}

class LocalAuthService {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  final LocalStorageService _storage = LocalStorageService();
  LocalUser? _currentUser;
  
  // Stream controller pour les changements d'état
  final List<Function(LocalUser?)> _authStateListeners = [];

  // Obtenir l'utilisateur actuel
  LocalUser? get currentUser => _currentUser;

  // Ajouter un listener pour les changements d'état
  void addAuthStateListener(Function(LocalUser?) listener) {
    _authStateListeners.add(listener);
  }

  // Supprimer un listener
  void removeAuthStateListener(Function(LocalUser?) listener) {
    _authStateListeners.remove(listener);
  }

  // Notifier les listeners
  void _notifyAuthStateChange() {
    for (final listener in _authStateListeners) {
      listener(_currentUser);
    }
  }

  // Initialiser le service
  Future<void> initialize() async {
    await _storage.initialize();
    await _loadCurrentUser();
  }

  // Charger l'utilisateur actuel depuis le stockage
  Future<void> _loadCurrentUser() async {
    try {
      final sessions = await _storage.getAll('auth_sessions');
      if (sessions.isNotEmpty) {
        final activeSession = sessions.firstWhere(
          (session) => session['isActive'] == true,
          orElse: () => {},
        );
        
        if (activeSession.isNotEmpty) {
          final userData = await _storage.get('auth_users', activeSession['userId']);
          if (userData != null) {
            _currentUser = LocalUser.fromMap(userData);
            if (kDebugMode) {
              print('Utilisateur chargé: ${_currentUser!.email}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement de l\'utilisateur: $e');
      }
    }
  }

  // Hacher un mot de passe
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'foodlink_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Générer un UID unique
  String _generateUid() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Inscription avec email et mot de passe
  Future<LocalUserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Début inscription locale pour: $email');
      }

      // Vérifier si l'email existe déjà
      final existingUsers = await _storage.where('auth_users', 'email', email);
      if (existingUsers.isNotEmpty) {
        throw LocalAuthException('email-already-in-use', 'Cet email est déjà utilisé');
      }

      // Valider l'email
      if (!_isValidEmail(email)) {
        throw LocalAuthException('invalid-email', 'Email invalide');
      }

      // Valider le mot de passe
      if (password.length < 6) {
        throw LocalAuthException('weak-password', 'Le mot de passe doit contenir au moins 6 caractères');
      }

      // Créer l'utilisateur
      final uid = _generateUid();
      final now = DateTime.now();
      
      final user = LocalUser(
        uid: uid,
        email: email,
        emailVerified: true, // Pas de vérification email en local
        createdAt: now,
        lastSignIn: now,
      );

      // Sauvegarder l'utilisateur
      await _storage.add('auth_users', {
        ...user.toMap(),
        'passwordHash': _hashPassword(password),
      });

      // Créer une session active
      await _createSession(uid);
      
      _currentUser = user;
      _notifyAuthStateChange();

      if (kDebugMode) {
        print('Inscription locale réussie pour: $email avec UID: $uid');
      }

      return LocalUserCredential(user: user);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'inscription locale: $e');
      }
      rethrow;
    }
  }

  // Connexion avec email et mot de passe
  Future<LocalUserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Début connexion locale pour: $email');
      }

      // Chercher l'utilisateur
      final users = await _storage.where('auth_users', 'email', email);
      if (users.isEmpty) {
        throw LocalAuthException('user-not-found', 'Aucun utilisateur trouvé avec cet email');
      }

      final userData = users.first;
      final storedHash = userData['passwordHash'];
      final inputHash = _hashPassword(password);

      if (storedHash != inputHash) {
        throw LocalAuthException('wrong-password', 'Mot de passe incorrect');
      }

      // Mettre à jour la dernière connexion
      await _storage.update('auth_users', userData['id'], {
        'lastSignIn': DateTime.now().toIso8601String(),
      });

      // Créer une session active
      await _createSession(userData['uid']);
      
      _currentUser = LocalUser.fromMap(userData);
      _notifyAuthStateChange();

      if (kDebugMode) {
        print('Connexion locale réussie pour: $email');
      }

      return LocalUserCredential(user: _currentUser);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la connexion locale: $e');
      }
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      // Désactiver toutes les sessions
      final sessions = await _storage.getAll('auth_sessions');
      for (final session in sessions) {
        if (session['isActive'] == true) {
          await _storage.update('auth_sessions', session['id'], {
            'isActive': false,
            'signOutAt': DateTime.now().toIso8601String(),
          });
        }
      }

      _currentUser = null;
      _notifyAuthStateChange();

      if (kDebugMode) {
        print('Déconnexion locale réussie');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la déconnexion locale: $e');
      }
      rethrow;
    }
  }

  // Créer une session active
  Future<void> _createSession(String userId) async {
    // Désactiver les anciennes sessions
    final sessions = await _storage.getAll('auth_sessions');
    for (final session in sessions) {
      if (session['userId'] == userId && session['isActive'] == true) {
        await _storage.update('auth_sessions', session['id'], {
          'isActive': false,
        });
      }
    }

    // Créer une nouvelle session
    await _storage.add('auth_sessions', {
      'userId': userId,
      'isActive': true,
      'signInAt': DateTime.now().toIso8601String(),
    });
  }

  // Valider un email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Réinitialiser le mot de passe (simulation)
  Future<void> resetPassword(String email) async {
    try {
      final users = await _storage.where('auth_users', 'email', email);
      if (users.isEmpty) {
        throw LocalAuthException('user-not-found', 'Aucun utilisateur trouvé avec cet email');
      }

      // En mode local, on simule l'envoi d'email
      if (kDebugMode) {
        print('Email de réinitialisation simulé envoyé à: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la réinitialisation: $e');
      }
      rethrow;
    }
  }

  // Mettre à jour l'email
  Future<void> updateEmail(String newEmail) async {
    if (_currentUser == null) {
      throw LocalAuthException('no-current-user', 'Aucun utilisateur connecté');
    }

    try {
      // Vérifier si le nouvel email existe déjà
      final existingUsers = await _storage.where('auth_users', 'email', newEmail);
      if (existingUsers.any((user) => user['uid'] != _currentUser!.uid)) {
        throw LocalAuthException('email-already-in-use', 'Cet email est déjà utilisé');
      }

      // Mettre à jour l'email
      final users = await _storage.where('auth_users', 'uid', _currentUser!.uid);
      if (users.isNotEmpty) {
        await _storage.update('auth_users', users.first['id'], {
          'email': newEmail,
        });

        _currentUser = LocalUser(
          uid: _currentUser!.uid,
          email: newEmail,
          displayName: _currentUser!.displayName,
          photoURL: _currentUser!.photoURL,
          emailVerified: _currentUser!.emailVerified,
          createdAt: _currentUser!.createdAt,
          lastSignIn: _currentUser!.lastSignIn,
        );
        
        _notifyAuthStateChange();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de l\'email: $e');
      }
      rethrow;
    }
  }

  // Mettre à jour le mot de passe
  Future<void> updatePassword(String newPassword) async {
    if (_currentUser == null) {
      throw LocalAuthException('no-current-user', 'Aucun utilisateur connecté');
    }

    try {
      if (newPassword.length < 6) {
        throw LocalAuthException('weak-password', 'Le mot de passe doit contenir au moins 6 caractères');
      }

      final users = await _storage.where('auth_users', 'uid', _currentUser!.uid);
      if (users.isNotEmpty) {
        await _storage.update('auth_users', users.first['id'], {
          'passwordHash': _hashPassword(newPassword),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du mot de passe: $e');
      }
      rethrow;
    }
  }

  // Supprimer le compte
  Future<void> deleteAccount() async {
    if (_currentUser == null) {
      throw LocalAuthException('no-current-user', 'Aucun utilisateur connecté');
    }

    try {
      // Supprimer l'utilisateur
      final users = await _storage.where('auth_users', 'uid', _currentUser!.uid);
      if (users.isNotEmpty) {
        await _storage.delete('auth_users', users.first['id']);
      }

      // Supprimer les sessions
      final sessions = await _storage.where('auth_sessions', 'userId', _currentUser!.uid);
      for (final session in sessions) {
        await _storage.delete('auth_sessions', session['id']);
      }

      _currentUser = null;
      _notifyAuthStateChange();

      if (kDebugMode) {
        print('Compte supprimé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du compte: $e');
      }
      rethrow;
    }
  }

  // Obtenir tous les utilisateurs (pour debug)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _storage.getAll('auth_users');
  }

  // Vider toutes les données d'authentification
  Future<void> clearAllAuthData() async {
    await _storage.clear('auth_users');
    await _storage.clear('auth_sessions');
    _currentUser = null;
    _notifyAuthStateChange();
    
    if (kDebugMode) {
      print('Toutes les données d\'authentification supprimées');
    }
  }
}