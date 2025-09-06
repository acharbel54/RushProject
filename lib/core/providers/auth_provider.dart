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
  

  
  // Vérifier l'état d'authentification
  Future<void> checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }
  
  // Initialiser l'authentification
  void _initializeAuth() {
    // Écouter les changements d'état d'authentification de manière plus simple
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
      }
      // Ne pas charger automatiquement les données pour éviter les boucles
    });
  }
  
  // Charger les données utilisateur depuis Firestore
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
  
  // Inscription avec email et mot de passe (version avec timeout)
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
    String? address,
  }) async {
    return _signUpWithEmailInternal(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      phoneNumber: phoneNumber,
      address: address,
      useTimeout: true,
    );
  }

  // Inscription avec email et mot de passe (version sans timeout pour connexions lentes)
  Future<bool> signUpWithEmailNoTimeout({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
    String? address,
  }) async {
    return _signUpWithEmailInternal(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      phoneNumber: phoneNumber,
      address: address,
      useTimeout: false,
    );
  }

  // Méthode interne pour l'inscription
  Future<bool> _signUpWithEmailInternal({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
    String? address,
    required bool useTimeout,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      print('Début de l\'inscription pour: $email');
      
      // Vérification basique de la connectivité
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        print('Test de connectivité réussi');
      } catch (e) {
        print('Problème de connectivité détecté: $e');
        throw Exception('Problème de connectivité réseau détecté. Vérifiez votre connexion internet.');
      }
      
      // Créer le compte Firebase Auth
      final Future<UserCredential> authFuture = _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      
      final userCredential = useTimeout 
        ? await authFuture.timeout(
            const Duration(minutes: 3),
            onTimeout: () => throw Exception('Timeout lors de la création du compte Firebase Auth - Vérifiez votre connexion internet et réessayez'),
          )
        : await authFuture;
      
      print('Compte Firebase Auth créé avec succès pour UID: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        try {
          // Créer le profil utilisateur dans Firestore
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
          
          print('Création du document utilisateur dans Firestore pour UID: ${userCredential.user!.uid}');
          print('Données utilisateur: ${userModel.toFirestore()}');
          
          // Créer le document Firestore
          final Future<void> firestoreFuture = _userService.createUser(userModel);
          
          if (useTimeout) {
            await firestoreFuture.timeout(
              const Duration(minutes: 2),
              onTimeout: () => throw Exception('Timeout lors de la création du document Firestore - Vérifiez votre connexion internet et réessayez'),
            );
          } else {
            await firestoreFuture;
          }
          
          print('Document utilisateur créé avec succès dans Firestore');
          
          // Utiliser directement le modèle créé sans relecture
          _currentUser = userModel;
          print('Inscription terminée avec succès pour: $email');
          _setLoading(false);
          return true;
        } catch (firestoreError) {
          // Si la création du document Firestore échoue, supprimer le compte Firebase Auth
          print('Erreur lors de la création du document Firestore: $firestoreError');
          try {
            await userCredential.user!.delete();
            print('Compte Firebase Auth supprimé après échec Firestore');
          } catch (deleteError) {
            print('Erreur lors de la suppression du compte Firebase Auth: $deleteError');
          }
          throw Exception('Erreur lors de la création du profil utilisateur: $firestoreError');
        }
      } else {
        throw Exception('Aucun utilisateur créé par Firebase Auth');
      }
    } catch (e) {
      print('Erreur complète lors de l\'inscription: $e');
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
        print('Connexion réussie pour: $email');
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
          return 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
        case 'timeout':
          return 'La requête a expiré. Vérifiez votre connexion internet et réessayez.';
        default:
          return 'Erreur d\'authentification: ${error.message ?? error.code}';
      }
    }
    
    // Gestion des erreurs de timeout personnalisées
    if (error.toString().contains('Timeout')) {
      return 'La connexion a expiré. Vérifiez votre connexion internet et réessayez.';
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