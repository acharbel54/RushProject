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

  // Obtenir le chemin du fichier JSON
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${directory.path}/base_de_donnees');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return dbDir.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/userinfo.json');
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
      // Créer le répertoire s'il n'existe pas
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

  // Inscription
  Future<Map<String, dynamic>> register(String email, String password, String firstName, String lastName, String role) async {
    try {
      await loadUsers();
      
      // Vérifier si l'email existe déjà
      if (_users.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
        return {
          'success': false,
          'message': 'Cet email est déjà utilisé'
        };
      }

      // Créer un nouvel utilisateur
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
      
      return {
        'success': true,
        'message': 'Inscription réussie',
        'user': newUser
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de l\'inscription: $e'
      };
    }
  }

  // Connexion
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await loadUsers();
      
      // Chercher l'utilisateur
      final user = _users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Utilisateur non trouvé'),
      );

      // Vérifier le mot de passe
      if (user.password != _hashPassword(password)) {
        return {
          'success': false,
          'message': 'Mot de passe incorrect'
        };
      }

      _currentUser = user;
      
      return {
        'success': true,
        'message': 'Connexion réussie',
        'user': user
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Email ou mot de passe incorrect'
      };
    }
  }

  // Déconnexion
  void logout() {
    _currentUser = null;
  }

  // Obtenir tous les utilisateurs (pour debug)
  Future<List<User>> getAllUsers() async {
    await loadUsers();
    return _users;
  }
}