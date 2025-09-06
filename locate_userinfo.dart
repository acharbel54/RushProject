import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

void main() async {
  try {
    // Obtenir le répertoire de documents de l'application
    final directory = await getApplicationDocumentsDirectory();
    print('Répertoire de l\'application: ${directory.path}');
    
    // Chemin vers le dossier base_de_donnees
    final dbDir = Directory('${directory.path}/base_de_donnees');
    print('Dossier base_de_donnees: ${dbDir.path}');
    
    if (await dbDir.exists()) {
      print('✓ Le dossier base_de_donnees existe');
      
      // Chemin vers le fichier userinfo.json
      final userFile = File('${dbDir.path}/userinfo.json');
      print('Fichier userinfo.json: ${userFile.path}');
      
      if (await userFile.exists()) {
        print('✓ Le fichier userinfo.json existe');
        
        // Lire et afficher le contenu
        final content = await userFile.readAsString();
        print('Contenu du fichier:');
        print(content);
        
        // Décoder et afficher de manière formatée
        try {
          final jsonData = json.decode(content);
          print('\nDonnées formatées:');
          for (var user in jsonData) {
            print('- Utilisateur: ${user['prenom']} ${user['nom']} (${user['email']})');
          }
        } catch (e) {
          print('Erreur lors du décodage JSON: $e');
        }
      } else {
        print('✗ Le fichier userinfo.json n\'existe pas encore');
      }
    } else {
      print('✗ Le dossier base_de_donnees n\'existe pas encore');
    }
    
    // Lister tous les fichiers dans le répertoire de l'application
    print('\nContenu du répertoire de l\'application:');
    await for (var entity in directory.list(recursive: true)) {
      print('- ${entity.path}');
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}