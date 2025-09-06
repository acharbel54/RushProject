import 'package:flutter/material.dart';
import '../services/simple_auth_service.dart';
import '../models/user_model.dart';

class SimpleAuthProvider extends ChangeNotifier {
  final SimpleAuthService _authService = SimpleAuthService();
  
  SimpleUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  SimpleUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isDonor => _currentUser?.role == UserRole.donateur;
  bool get isBeneficiary => _currentUser?.role == UserRole.beneficiaire;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  
  SimpleAuthProvider() {
    _initializeAuth();
  }
  
  // Initialiser l'authentification
  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();
      _currentUser = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    }
  }
  
  // Inscription
  Future<bool> signUp({
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
      
      final user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phoneNumber: phoneNumber,
        address: address,
      );
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _setError('Cet email est déjà utilisé');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de l\'inscription: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // Connexion
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _setError('Email ou mot de passe incorrect');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la connexion: $e');
      _setLoading(false);
      return false;
    }
  }
  
  // Déconnexion
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
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
  
  // Obtenir tous les utilisateurs (pour debug)
  List<SimpleUser> getAllUsers() {
    return _authService.getAllUsers();
  }

  // Mettre à jour le profil utilisateur
  Future<bool> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? address,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    String? preferredPickupZone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authService.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        address: address,
        dietaryPreferences: dietaryPreferences,
        allergies: allergies,
        preferredPickupZone: preferredPickupZone,
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      } else {
        _setError('Erreur lors de la mise à jour du profil');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}