import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: JsonViewer(),
    );
  }
}

class JsonViewer extends StatefulWidget {
  @override
  _JsonViewerState createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  String content = 'Chargement...';

  @override
  void initState() {
    super.initState();
    loadJsonContent();
  }

  Future<void> loadJsonContent() async {
    try {
      print('=== DEBUT VERIFICATION USERINFO.JSON ===');
      
      final directory = await getApplicationDocumentsDirectory();
      print('Répertoire app: ${directory.path}');
      
      final dbDir = Directory('${directory.path}/base_de_donnees');
      final userFile = File('${dbDir.path}/userinfo.json');
      
      print('Chemin fichier: ${userFile.path}');
      
      if (await userFile.exists()) {
        print('✓ FICHIER USERINFO.JSON TROUVE!');
        
        final fileContent = await userFile.readAsString();
        print('CONTENU BRUT DU FICHIER:');
        print(fileContent);
        
        try {
          final jsonData = json.decode(fileContent) as List;
          print('NOMBRE D\'UTILISATEURS: ${jsonData.length}');
          
          for (int i = 0; i < jsonData.length; i++) {
            final user = jsonData[i];
            print('--- UTILISATEUR ${i + 1} ---');
            print('Prénom: ${user['prenom']}');
            print('Nom: ${user['nom']}');
            print('Email: ${user['email']}');
            print('Rôle: ${user['role']}');
            print('Date: ${user['dateCreation']}');
          }
          
          setState(() {
            content = 'Fichier trouvé avec ${jsonData.length} utilisateur(s). Voir les logs pour les détails.';
          });
        } catch (e) {
          print('ERREUR JSON: $e');
          setState(() {
            content = 'Erreur de décodage JSON: $e';
          });
        }
      } else {
        print('✗ FICHIER USERINFO.JSON NON TROUVE');
        print('Dossier existe: ${await dbDir.exists()}');
        setState(() {
          content = 'Fichier userinfo.json non trouvé';
        });
      }
      
      print('=== FIN VERIFICATION ===');
    } catch (e) {
      print('ERREUR GENERALE: $e');
      setState(() {
        content = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vérification JSON')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            content,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}