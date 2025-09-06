import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = SimpleAuthService();
  await authService.initialize();
  
  print('=== TEST DE CONNEXION ===');
  
  // Afficher tous les utilisateurs disponibles
  final users = authService.getAllUsers();
  print('Utilisateurs disponibles:');
  for (var user in users) {
    print('- Email: ${user.email}, Rôle: ${user.role}');
  }
  
  // Test de connexion avec l'utilisateur existant
  if (users.isNotEmpty) {
    final testUser = users.first;
    print('\n=== Test de connexion avec ${testUser.email} ===');
    
    final result = await authService.signIn(
      email: testUser.email,
      password: testUser.password,
    );
    
    if (result != null) {
      print('✅ Connexion réussie!');
      print('Utilisateur connecté: ${result.displayName} (${result.role})');
    } else {
      print('❌ Échec de la connexion');
    }
  } else {
    print('Aucun utilisateur trouvé dans le fichier JSON');
  }
  
  print('\n=== FIN DU TEST ===');
}