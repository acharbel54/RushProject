import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    // Chemin relatif dans le projet
    final file = File('users.json');
    
    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> users = json.decode(contents);
      
      print('=== UTILISATEURS ENREGISTRÉS ===');
      print('Nombre d\'utilisateurs: ${users.length}');
      print('');
      
      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        print('Utilisateur ${i + 1}:');
        print('  ID: ${user['id']}');
        print('  Email: ${user['email']}');
        print('  Nom: ${user['fullName']}');
        print('  Rôle: ${user['role']}');
        print('  Mot de passe: ${user['password']}');
        print('  Créé le: ${user['createdAt']}');
        print('');
      }
    } else {
      print('Aucun fichier users.json trouvé dans le répertoire du projet.');
      print('Vérifiez si une inscription a été effectuée.');
    }
  } catch (e) {
    print('Erreur lors de la lecture du fichier: $e');
  }
}