import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'lib/core/services/simple_auth_service.dart';

void main() async {
  print('=== ANALYSE DE LA GESTION DE SESSION ===\n');
  
  // 1. Vérifier le service d'authentification
  final authService = SimpleAuthService();
  await authService.initialize();
  
  print('1. État du service d\'authentification:');
  print('   - Utilisateur actuel en mémoire: ${authService.currentUser?.email ?? "AUCUN"} ');
  print('   - Authentifié: ${authService.isAuthenticated}');
  
  // 2. Vérifier le fichier des utilisateurs
  final appDir = await getApplicationDocumentsDirectory();
  final usersFile = File('${appDir.path}/base_de_donnees/userinfo.json');
  
  print('\n2. Fichier des utilisateurs:');
  print('   - Chemin: ${usersFile.path}');
  print('   - Existe: ${await usersFile.exists()}');
  
  if (await usersFile.exists()) {
    final content = await usersFile.readAsString();
    print('   - Contenu: $content');
    
    // Compter les utilisateurs
    final users = authService.getAllUsers();
    print('   - Nombre d\'utilisateurs: ${users.length}');
    
    for (var user in users) {
      print('     * ${user.email} (${user.role.toString().split('.').last})');
    }
  }
  
  print('\n=== PROBLÈME IDENTIFIÉ ===');
  print('Le service SimpleAuthService ne persiste PAS la session utilisateur.');
  print('La variable _currentUser est stockée uniquement en mémoire.');
  print('Au redémarrage de l\'app, _currentUser = null même si des utilisateurs existent.');
  print('\nSOLUTION NÉCESSAIRE:');
  print('- Ajouter une méthode pour sauvegarder la session (ex: SharedPreferences)');
  print('- Restaurer automatiquement la session au démarrage');
  print('- Ou implémenter un système de "Remember me"');
}