import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class User {
  final String id;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      firstName: json['firstName'] ?? json['fullName']?.split(' ')[0] ?? '',
      lastName: json['lastName'] ?? json['fullName']?.split(' ').skip(1).join(' ') ?? '',
      role: json['role'] ?? 'Donateur',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class JsonAuthService {
  static final JsonAuthService _instance = JsonAuthService._internal();
  factory JsonAuthService() => _instance;
  JsonAuthService._internal();

  User? _currentUser;
  List<User> _users = [];

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Initialiser le service et charger l'utilisateur actuel
  Future<void> initialize() async {
    await loadUsers();
    await _loadCurrentUser();
  }

  // Obtenir le chemin du fichier JSON
  Future<String> get _localPath async {
    // Utiliser le répertoire base_de_donnees du projet
    return 'base_de_donnees';
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/userinfo.json');
  }

  Future<File> get _currentUserFile async {
    final path = await _localPath;
    return File('$path/current_user.json');
  }

  // Sauvegarder l'utilisateur actuel
  Future<void> _saveCurrentUser() async {
    try {
      final file = await _currentUserFile;
      if (_currentUser != null) {
        await file.writeAsString(json.encode(_currentUser!.toJson()));
      } else {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'utilisateur actuel: $e');
    }
  }

  // Charger l'utilisateur actuel
  Future<void> _loadCurrentUser() async {
    try {
      final file = await _currentUserFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final userData = json.decode(contents);
        _currentUser = User.fromJson(userData);
        print('Utilisateur actuel chargé: ${_currentUser?.fullName}');
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'utilisateur actuel: $e');
      _currentUser = null;
    }
  }

  // Charger les utilisateurs depuis le fichier JSON
  Future<void> loadUsers() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        _users = jsonData.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur lors du chargement des utilisateurs: $e');
      _users = [];
    }
  }

  // Sauvegarder les utilisateurs dans le fichier JSON
  Future<void> saveUsers() async {
    try {
      final file = await _localFile;
      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);
      final jsonData = _users.map((user) => user.toJson()).toList();
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      print('Erreur lors de la sauvegarde des utilisateurs: $e');
    }
  }

  // Pas de hachage pour le prototype
  String _hashPassword(String password) {
    return password; // Stockage direct pour le prototype
  }

  // Registration
  Future<Map<String, dynamic>> register(String email, String password, String firstName, String lastName, String role) async {
    try {
      await loadUsers();
      
      // Check if email already exists
      if (_users.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
        return {
          'success': false,
          'message': 'This email is already in use'
        };
      }

      // Create a new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email.toLowerCase(),
        password: _hashPassword(password),
        firstName: firstName,
        lastName: lastName,
        role: role,
        createdAt: DateTime.now(),
      );

      _users.add(newUser);
      await saveUsers();
      
      _currentUser = newUser;
      await _saveCurrentUser();
      
      return {
        'success': true,
        'message': 'Registration successful',
        'user': newUser
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration error: $e'
      };
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await loadUsers();
      
      // Find the user
      final user = _users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Verify password
      if (user.password != _hashPassword(password)) {
        return {
          'success': false,
          'message': 'Incorrect password'
        };
      }

      _currentUser = user;
      await _saveCurrentUser();
      
      return {
        'success': true,
        'message': 'Login successful',
        'user': user
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Incorrect email or password'
      };
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    await _saveCurrentUser();
  }

  // Obtenir tous les utilisateurs (pour debug)
  Future<List<User>> getAllUsers() async {
    await loadUsers();
    return _users;
  }
}