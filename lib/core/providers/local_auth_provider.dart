import 'package:flutter/material.dart';
import 'package:foodlink/core/models/user_model.dart';
import '../services/local_auth_service.dart';
import '../services/local_user_service.dart';

class LocalAuthProvider extends ChangeNotifier {
  final LocalAuthService _authService = LocalAuthService();
  final LocalUserService _userService = LocalUserService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isDonor => _currentUser?.role == UserRole.donateur;
  bool get isBeneficiary => _currentUser?.role == UserRole.beneficiaire;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  
  LocalAuthProvider() {
    _initializeAuth();
  }
  
  // Initialiser l'authentification locale
  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();
      await _userService.initialize();
      
      // Vérifier si un utilisateur est déjà connecté
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser.uid);
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de l\'authentification locale: $e');
    }
  }
  
  // Vérifier l'état d'authentification
  Future<void> checkAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }
  
  // Charger les données utilisateur depuis le stockage local
  Future<void> _loadUserData(String uid) async {
    try {
      _currentUser = await _userService.getUserById(uid);
      if (_currentUser == null) {
        _errorMessage = 'Profil utilisateur non trouvé. Veuillez vous reconnecter.';
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des données utilisateur: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Inscription avec email et mot de passe
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('Début de l\'inscription locale pour: $email');
      
      // Vérifier si l'email existe déjà
      final existingUser = await _userService.getUserByEmail(email);
      if (existingUser != null) {
        throw LocalAuthException(
          'email-already-in-use',
          'Cet email est déjà utilisé',
        );
      }
      
      // Créer le compte d'authentification local
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      
      print('Compte d\'authentification local créé avec succès pour UID: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        try {
          // Créer le profil utilisateur dans le stockage local
          final userModel = UserModel(
            id: userCredential.user!.uid,
            email: email,
            displayName: displayName,
            role: role,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
            phoneNumber: phoneNumber,
            address: address,
          );
          
          print('Création du profil utilisateur local pour UID: ${userCredential.user!.uid}');
          print('Données utilisateur: ${userModel.toFirestore()}');
          
          // Créer le profil utilisateur
          await _userService.createUser(userModel);
          
          print('Profil utilisateur créé avec succès dans le stockage local');
          
          // Utiliser directement le modèle créé
          _currentUser = userModel;
          print('Inscription locale terminée avec succès pour: $email');
          _setLoading(false);
          return true;
        } catch (userServiceError) {
          print('Erreur lors de la création du profil utilisateur: $userServiceError');
          // Supprimer le compte d'authentification si la création du profil échoue
          try {
            await _authService.deleteAccount();
            print('Compte d\'authentification supprimé après échec de création du profil');
          } catch (deleteError) {
            print('Erreur lors de la suppression du compte d\'authentification: $deleteError');
          }
          throw Exception('Erreur lors de la création du profil utilisateur: $userServiceError');
        }
      } else {
        throw Exception('Aucun utilisateur créé par le service d\'authentification local');
      }
    } catch (e) {
      print('Erreur complète lors de l\'inscription locale: $e');
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    }
  }
  
  // Inscription avec email et mot de passe (version sans timeout)
  Future<bool> signUpWithEmailNoTimeout({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
    String? address,
  }) async {
    // Pour le stockage local, pas de différence avec la version normale
    return signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      phoneNumber: phoneNumber,
      address: address,
    );
  }
  
  // Connexion avec email et mot de passe
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
        print('Connexion locale réussie pour: $email');
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } on LocalAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur de connexion: ${e.toString()}');
      return false;
    }
  }
  
  // Connexion avec Google (non supportée en local)
  Future<bool> signInWithGoogle() async {
    _setError('La connexion Google n\'est pas supportée en mode local');
    return false;
  }
  
  // Déconnexion
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la déconnexion');
    }
  }
  
  // Réinitialiser le mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.resetPassword(email);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    }
  }
  
  // Mettre à jour le profil utilisateur
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (_currentUser != null) {
        await _userService.updateUser(
          _currentUser!.id,
          displayName: name,
          phoneNumber: phone,
          address: address,
        );
        
        // Recharger les données utilisateur
        await _loadUserData(_currentUser!.id);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    }
  }
  
  // Mettre à jour le profil utilisateur (ancienne méthode)
  Future<bool> updateUserProfileOld(UserModel updatedUser) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _userService.updateUser(
        updatedUser.id,
        displayName: updatedUser.displayName,
        phoneNumber: updatedUser.phoneNumber,
        address: updatedUser.address,
      );
      _currentUser = updatedUser;
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la mise à jour du profil');
      return false;
    }
  }
  
  // Supprimer le compte utilisateur
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();
      
      if (_currentUser != null) {
        await _userService.deleteUser(_currentUser!.id);
      await _authService.deleteAccount();
        _currentUser = null;
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    }
  }
  
  // Méthodes utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  String _getErrorMessage(dynamic error) {
    // Gestion spéciale pour les erreurs d'authentification locale
    if (error is LocalAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'weak-password':
          return 'Le mot de passe est trop faible';
        case 'invalid-email':
          return 'Email invalide';
        case 'invalid-credential':
          return 'Identifiants invalides';
        case 'too-many-requests':
          return 'Trop de tentatives. Veuillez réessayer plus tard';
        default:
          return 'Erreur d\'authentification: ${error.message ?? error.code}';
      }
    }
    
    // Gestion des erreurs génériques
    if (error is Exception) {
      return 'Erreur: ${error.toString().replaceAll('Exception: ', '')}';
    }
    
    // Gestion des erreurs de type string
    if (error is String) {
      return error;
    }
    
    return 'Une erreur inattendue s\'est produite';
  }
  
  // Méthodes utilitaires pour les tests
  Future<void> clearAllData() async {
    try {
      await _userService.clearAllUsers();
      await _authService.clearAllAuthData();
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la suppression des données: ${e.toString()}');
    }
  }
  
  // Obtenir les statistiques des utilisateurs
  Future<Map<String, int>> getUserStats() async {
    try {
      return await _userService.getUserStats();
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {
        'total': 0,
        'active': 0,
        'donateurs': 0,
        'beneficiaires': 0,
        'admins': 0,
      };
    }
  }
  
  // Obtenir tous les utilisateurs (pour l'admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      return await _userService.getAllUsers();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }
  
  // Rechercher des utilisateurs
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _userService.searchUsersByName(query);
    } catch (e) {
      print('Erreur lors de la recherche d\'utilisateurs: $e');
      return [];
    }
  }
}