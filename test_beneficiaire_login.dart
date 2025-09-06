import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = SimpleAuthService();
  await authService.initialize();
  
  print('=== TEST DE CONNEXION BÉNÉFICIAIRE ===');
  
  // Afficher tous les utilisateurs disponibles
  final users = authService.getAllUsers();
  print('Utilisateurs disponibles:');
  for (var user in users) {
    print('- Email: ${user.email}, Mot de passe: ${user.password}, Rôle: ${user.role}');
  }
  
  // Test de connexion avec le bénéficiaire
  print('\n=== Test de connexion avec beneficiaire@test.com ===');
  
  final result = await authService.signIn(
    email: 'beneficiaire@test.com',
    password: '123456',
  );
  
  if (result != null) {
    print('✅ Connexion réussie!');
    print('Utilisateur connecté: ${result.displayName} (${result.role})');
    print('Préférences alimentaires: ${result.dietaryPreferences}');
    print('Allergies: ${result.allergies}');
    print('Zone de récupération: ${result.preferredPickupZone}');
  } else {
    print('❌ Échec de la connexion');
  }
  
  print('\n=== FIN DU TEST ===');
}