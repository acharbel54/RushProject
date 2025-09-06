import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  try {
    // Obtenir le répertoire des documents
    final appDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${appDir.path}/base_de_donnees');
    final usersFile = File('${dataDir.path}/userinfo.json');
    
    print('Chemin du fichier: ${usersFile.path}');
    print('Le fichier existe: ${await usersFile.exists()}');
    
    if (await usersFile.exists()) {
      final content = await usersFile.readAsString();
      print('Contenu du fichier:');
      print(content);
      
      try {
        final List<dynamic> jsonList = json.decode(content);
        print('\nNombre d\'utilisateurs trouvés: ${jsonList.length}');
        
        for (int i = 0; i < jsonList.length; i++) {
          final user = jsonList[i];
          print('Utilisateur ${i + 1}:');
          print('  Email: ${user['email']}');
          print('  Nom: ${user['displayName']}');
          print('  Rôle: ${user['role']}');
        }
      } catch (e) {
        print('Erreur lors du parsing JSON: $e');
      }
    } else {
      print('Le fichier userinfo.json n\'existe pas encore.');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}