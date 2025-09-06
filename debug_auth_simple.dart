import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== DEBUG AUTHENTIFICATION SIMPLE ===');
  
  // Vérifier le chemin du fichier
  final appDir = await getApplicationDocumentsDirectory();
  final dataDir = Directory('${appDir.path}/base_de_donnees');
  final usersFile = File('${dataDir.path}/userinfo.json');
  
  print('Chemin du fichier: ${usersFile.path}');
  print('Le fichier existe: ${await usersFile.exists()}');
  
  if (await usersFile.exists()) {
    final content = await usersFile.readAsString();
    print('Contenu du fichier:');
    print(content);
  }
  
  // Initialiser le service
  final authService = SimpleAuthService();
  await authService.initialize();
  
  // Afficher tous les utilisateurs chargés
  final users = authService.getAllUsers();
  print('\n=== UTILISATEURS CHARGÉS (${users.length}) ===');
  for (var user in users) {
    print('- ID: ${user.id}');
    print('  Email: ${user.email}');
    print('  Mot de passe: ${user.password}');
    print('  Rôle: ${user.role}');
    print('  Nom: ${user.displayName}');
    print('');
  }
  
  // Test de connexion spécifique
  print('=== TEST DE CONNEXION ===');
  final result = await authService.signIn(
    email: 'beneficiaire@test.com',
    password: '123456',
  );
  
  if (result != null) {
    print('✅ Connexion réussie!');
    print('Utilisateur: ${result.displayName} (${result.role})');
  } else {
    print('❌ Échec de la connexion');
    
    // Test avec chaque utilisateur pour voir lequel fonctionne
    print('\n=== TEST AVEC CHAQUE UTILISATEUR ===');
    for (var user in users) {
      final testResult = await authService.signIn(
        email: user.email,
        password: user.password,
      );
      print('Test ${user.email}: ${testResult != null ? "✅" : "❌"}');
    }
  }
  
  print('\n=== FIN DU DEBUG ===');
}