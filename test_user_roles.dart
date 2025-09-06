import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';
import 'lib/core/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = SimpleAuthService();
  await authService.initialize();
  
  print('=== TEST DES RÔLES UTILISATEUR ===');
  
  // Afficher tous les utilisateurs disponibles
  final users = authService.getAllUsers();
  print('Utilisateurs disponibles:');
  for (var user in users) {
    print('- Email: ${user.email}');
    print('  Rôle: ${user.role}');
    print('  Type de rôle: ${user.role.runtimeType}');
    print('  Est donateur: ${user.role == UserRole.donateur}');
    print('  Est bénéficiaire: ${user.role == UserRole.beneficiaire}');
    print('---');
  }
  
  // Test de connexion avec le premier utilisateur donateur
  final donorUser = users.where((u) => u.role == UserRole.donateur).firstOrNull;
  if (donorUser != null) {
    print('\n=== Test de connexion donateur ===');
    print('Tentative de connexion avec: ${donorUser.email}');
    
    final result = await authService.signIn(
      email: donorUser.email,
      password: donorUser.password,
    );
    
    if (result != null) {
      print('✅ Connexion réussie!');
      print('Utilisateur connecté: ${result.displayName}');
      print('Rôle: ${result.role}');
      print('Est donateur: ${result.role == UserRole.donateur}');
    } else {
      print('❌ Échec de la connexion');
    }
  } else {
    print('\n❌ Aucun utilisateur donateur trouvé');
  }
  
  print('\n=== FIN DU TEST ===');
}