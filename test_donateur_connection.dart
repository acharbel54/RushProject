import 'dart:io';
import 'package:flutter/foundation.dart';
import 'lib/core/services/simple_auth_service.dart';
import 'lib/core/models/user_model.dart';

void main() async {
  print('=== TEST CONNEXION DONATEUR ===\n');
  
  final authService = SimpleAuthService();
  await authService.initialize();
  
  // 1. Créer un utilisateur donateur de test
  print('1. Création d\'un utilisateur donateur...');
  final donateur = await authService.signUp(
    email: 'donateur@test.com',
    password: 'password123',
    displayName: 'Test Donateur',
    role: UserRole.donateur,
    phoneNumber: '0123456789',
    address: 'Adresse test',
  );
  
  if (donateur != null) {
    print('   ✅ Donateur créé: ${donateur.email} (${donateur.role.toString().split('.').last})');
  } else {
    print('   ❌ Échec de création du donateur');
    return;
  }
  
  // 2. Vérifier l'état de connexion
  print('\n2. État de connexion:');
  print('   - Utilisateur connecté: ${authService.currentUser?.email ?? "AUCUN"}');
  print('   - Rôle: ${authService.currentUser?.role.toString().split('.').last ?? "AUCUN"}');
  print('   - Authentifié: ${authService.isAuthenticated}');
  
  // 3. Simuler une déconnexion puis reconnexion
  print('\n3. Test déconnexion/reconnexion...');
  await authService.signOut();
  print('   - Après déconnexion: ${authService.currentUser?.email ?? "AUCUN"}');
  
  final reconnected = await authService.signIn(
    email: 'donateur@test.com',
    password: 'password123',
  );
  
  if (reconnected != null) {
    print('   ✅ Reconnexion réussie: ${reconnected.email} (${reconnected.role.toString().split('.').last})');
  } else {
    print('   ❌ Échec de reconnexion');
  }
  
  print('\n=== RÉSULTAT ===');
  print('Le donateur est maintenant connecté et devrait voir 3 sections:');
  print('1. Accueil');
  print('2. Mes dons');
  print('3. Profil');
  print('\nLancez l\'application maintenant pour tester la navigation !');
}