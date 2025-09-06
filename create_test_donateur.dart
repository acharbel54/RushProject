import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestDonateurScreen(),
    );
  }
}

class TestDonateurScreen extends StatefulWidget {
  @override
  _TestDonateurScreenState createState() => _TestDonateurScreenState();
}

class _TestDonateurScreenState extends State<TestDonateurScreen> {
  String status = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    createTestDonateur();
  }

  Future<void> createTestDonateur() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbDir = Directory('${directory.path}/base_de_donnees');
      
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      
      final userFile = File('${dbDir.path}/userinfo.json');
      
      List<dynamic> users = [];
      
      // Charger les utilisateurs existants
      if (await userFile.exists()) {
        final content = await userFile.readAsString();
        users = json.decode(content);
      }
      
      // Vérifier si un donateur existe déjà
      bool donateurExists = users.any((user) => user['role']?.toString().toLowerCase() == 'donateur');
      
      if (!donateurExists) {
        // Créer un utilisateur donateur de test
        final testDonateur = {
          'id': 'donateur_test_${DateTime.now().millisecondsSinceEpoch}',
          'email': 'donateur@test.com',
          'password': '123456',
          'displayName': 'Test Donateur',
          'role': 'donateur',
          'phoneNumber': '0123456789',
          'address': 'Adresse test',
          'createdAt': DateTime.now().toIso8601String(),
          'totalDonations': 0,
        };
        
        users.add(testDonateur);
        
        // Sauvegarder
        await userFile.writeAsString(json.encode(users));
        
        setState(() {
          status = 'Utilisateur donateur créé avec succès!\n\nEmail: donateur@test.com\nMot de passe: 123456\n\nVous pouvez maintenant vous connecter avec ces identifiants.';
        });
      } else {
        setState(() {
          status = 'Un utilisateur donateur existe déjà.\n\nUtilisateurs existants:';
          for (var user in users) {
            status += '\n- ${user['displayName']} (${user['email']}) - Rôle: ${user['role']}';
          }
        });
      }
      
    } catch (e) {
      setState(() {
        status = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Création Donateur Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            status,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}