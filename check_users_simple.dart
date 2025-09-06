import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    // Essayer différents chemins possibles
    List<String> possiblePaths = [
      'base_de_donnees/userinfo.json',
      'userinfo.json',
      'lib/base_de_donnees/userinfo.json'
    ];
    
    File? userFile;
    
    for (String path in possiblePaths) {
      File file = File(path);
      if (await file.exists()) {
        userFile = file;
        print('Fichier trouvé: $path');
        break;
      }
    }
    
    if (userFile == null) {
      print('Aucun fichier userinfo.json trouvé dans les chemins suivants:');
      for (String path in possiblePaths) {
        print('- $path');
      }
      return;
    }
    
    String content = await userFile.readAsString();
    List<dynamic> users = json.decode(content);
    
    print('\n=== UTILISATEURS TROUVÉS (${users.length}) ===');
    
    for (int i = 0; i < users.length; i++) {
      var user = users[i];
      print('\nUtilisateur ${i + 1}:');
      print('  Email: ${user['email']}');
      print('  Nom: ${user['displayName'] ?? user['name'] ?? 'N/A'}');
      print('  Rôle: ${user['role']}');
      print('  Rôle (type): ${user['role'].runtimeType}');
      print('  Rôle (lowercase): ${user['role']?.toString().toLowerCase()}');
      
      // Vérifier la correspondance avec les rôles attendus
      String roleStr = user['role']?.toString().toLowerCase() ?? '';
      if (roleStr == 'donateur') {
        print('  ✓ Rôle DONATEUR détecté correctement');
      } else if (roleStr == 'beneficiaire') {
        print('  ✓ Rôle BENEFICIAIRE détecté correctement');
      } else if (roleStr == 'admin') {
        print('  ✓ Rôle ADMIN détecté correctement');
      } else {
        print('  ⚠️  Rôle INCONNU: "$roleStr"');
      }
    }
    
    print('\n=== ANALYSE DES RÔLES ===');
    Map<String, int> roleCount = {};
    for (var user in users) {
      String role = user['role']?.toString().toLowerCase() ?? 'undefined';
      roleCount[role] = (roleCount[role] ?? 0) + 1;
    }
    
    roleCount.forEach((role, count) {
      print('$role: $count utilisateur(s)');
    });
    
  } catch (e) {
    print('Erreur: $e');
  }
}