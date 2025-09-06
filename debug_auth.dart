import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'services/json_auth_service.dart';

void main() {
  runApp(DebugAuthApp());
}

class DebugAuthApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DebugAuthScreen(),
    );
  }
}

class DebugAuthScreen extends StatefulWidget {
  @override
  _DebugAuthScreenState createState() => _DebugAuthScreenState();
}

class _DebugAuthScreenState extends State<DebugAuthScreen> {
  final JsonAuthService _authService = JsonAuthService();
  String _debugInfo = 'Initialisation...';
  
  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }
  
  Future<void> _runDebugTests() async {
    setState(() {
      _debugInfo = '🔍 DÉMARRAGE DES TESTS DE DÉBOGAGE\n\n';
    });
    
    try {
      // Test 1: Vérifier le chemin du fichier
      setState(() {
        _debugInfo += '📁 Test 1: Vérification du chemin...\n';
      });
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/users.json');
      final path = file.path;
      
      setState(() {
        _debugInfo += '   Chemin: $path\n';
        _debugInfo += '   Existe: ${await file.exists()}\n\n';
      });
      
      // Test 2: Charger les utilisateurs existants
      setState(() {
        _debugInfo += '👥 Test 2: Chargement des utilisateurs...\n';
      });
      
      await _authService.loadUsers();
      final users = await _authService.getAllUsers();
      
      setState(() {
        _debugInfo += '   Nombre d\'utilisateurs: ${users.length}\n';
        for (var user in users) {
          _debugInfo += '   - ${user.firstName} ${user.lastName} (${user.email})\n';
        }
        _debugInfo += '\n';
      });
      
      // Test 3: Créer un utilisateur de test
      setState(() {
        _debugInfo += '➕ Test 3: Création d\'un utilisateur de test...\n';
      });
      
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final result = await _authService.register(
        firstName: 'Test',
        lastName: 'User',
        email: testEmail,
        password: 'password123',
        role: 'Donateur',
      );
      
      setState(() {
        _debugInfo += '   Résultat: ${result ? "✅ Succès" : "❌ Échec"}\n';
      });
      
      // Test 4: Vérifier si le fichier existe maintenant
      setState(() {
        _debugInfo += '\n📄 Test 4: Vérification du fichier après création...\n';
      });
      
      final fileExists = await file.exists();
      setState(() {
        _debugInfo += '   Fichier existe: ${fileExists ? "✅ Oui" : "❌ Non"}\n';
      });
      
      if (fileExists) {
        final content = await file.readAsString();
        setState(() {
          _debugInfo += '   Taille: ${content.length} caractères\n';
          _debugInfo += '   Contenu: $content\n';
        });
      }
      
      setState(() {
        _debugInfo += '\n🎉 TESTS TERMINÉS!';
      });
      
    } catch (e, stackTrace) {
      setState(() {
        _debugInfo += '\n❌ ERREUR: $e\n';
        _debugInfo += 'Stack trace: $stackTrace';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Auth Service'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            _debugInfo,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runDebugTests,
        child: Icon(Icons.refresh),
        tooltip: 'Relancer les tests',
      ),
    );
  }
}