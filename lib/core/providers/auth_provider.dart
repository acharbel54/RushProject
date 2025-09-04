import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodlink/core/models/user_model.dart';
import 'package:foodlink/core/services/auth_service.dart';
import 'package:foodlink/core/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
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
  
  AuthProvider() {
    _initializeAuth();
  }
  
  // Charger les données de l'utilisateur actuel
  Future<void> _loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        _currentUser = await _userService.getUserById(user.uid);
        notifyListeners();
      } catch (e) {
        _setError('Erreur lors du chargement des données utilisateur');
      }
    }
  }
  
  // Vérifier l'état d'authentification
  Future<void> checkAuthState() async {
    await _loadCurrentUser();
  }
  
  // Initialiser l'authentification
  void _initializeAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }
  
  // Charger les données utilisateur depuis Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      print('Tentative de chargement des données utilisateur pour UID: $uid');
      _currentUser = await _userService.getUserById(uid);
      if (_currentUser != null) {
        print('Données utilisateur chargées avec succès: ${_currentUser!.email}');
      } else {
        print('Aucun document utilisateur trouvé pour UID: $uid');
        _errorMessage = 'Profil utilisateur non trouvé. Veuillez vous reconnecter.';
      }
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
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
      
      // Créer le compte Firebase Auth
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Créer le profil utilisateur dans Firestore
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          createdAt: DateTime.now(),
          phoneNumber: phoneNumber,
          address: address,
        );
        
        await _userService.createUser(userModel);
        _currentUser = userModel;
        
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    }
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
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur de connexion: ${e.toString()}');
      return false;
    }
  }
  
  // Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential?.user != null) {
        final user = userCredential!.user!;
        
        // Vérifier si l'utilisateur existe déjà
        UserModel? existingUser = await _userService.getUserById(user.uid);
        
        if (existingUser == null) {
          // Créer un nouveau profil utilisateur
          final userModel = UserModel(
            id: user.uid,
            email: user.email!,
            displayName: user.displayName,
            photoURL: user.photoURL,
            role: UserRole.beneficiaire, // Par défaut
            createdAt: DateTime.now(),
          );
          
          await _userService.createUser(userModel);
          _currentUser = userModel;
        } else {
          _currentUser = existingUser;
        }
        
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur de connexion Google: ${e.toString()}');
      return false;
    }
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
  
  // Mettre à jour le profil utilisateur (ancienne méthode)
  Future<bool> updateUserProfileOld(UserModel updatedUser) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _userService.updateUser(updatedUser.id, 
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
        await _loadCurrentUser();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(_getErrorMessage(e));
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
    // Gestion spéciale pour les erreurs Firebase sur le web
    if (error is FirebaseAuthException) {
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
        case 'network-request-failed':
          return 'Erreur de connexion réseau';
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
}