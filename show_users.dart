import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  try {
    // Obtenir le répertoire des documents de l'application
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/users.json';
    final file = File(filePath);
    
    print('Chemin du fichier: $filePath');
    
    if (await file.exists()) {
      final contents = await file.readAsString();
      print('\n=== Contenu du fichier users.json ===');
      
      // Parser et afficher de manière formatée
      final List<dynamic> users = json.decode(contents);
      
      if (users.isEmpty) {
        print('Aucun utilisateur trouvé.');
      } else {
        print('Nombre d\'utilisateurs: ${users.length}\n');
        
        for (int i = 0; i < users.length; i++) {
          final user = users[i];
          print('--- Utilisateur ${i + 1} ---');
          print('ID: ${user['id']}');
          print('Email: ${user['email']}');
          print('Prénom: ${user['firstName'] ?? 'Non défini'}');
          print('Nom: ${user['lastName'] ?? 'Non défini'}');
          print('Nom complet: ${user['fullName'] ?? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'}');
          print('Rôle: ${user['role']}');
          print('Mot de passe: ${user['password']}');
          print('Créé le: ${user['createdAt']}');
          print('');
        }
      }
    } else {
      print('Le fichier users.json n\'existe pas encore.');
      print('Veuillez d\'abord créer un compte dans l\'application.');
    }
  } catch (e) {
    print('Erreur lors de la lecture du fichier: $e');
  }
}