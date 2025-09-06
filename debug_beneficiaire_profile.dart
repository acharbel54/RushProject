import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';
import 'lib/core/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== DEBUG PROFIL BÉNÉFICIAIRE ===');
  
  // Initialiser le service d'authentification
  final authService = SimpleAuthService();
  await authService.initialize();
  
  print('\n1. Vérification du fichier userinfo.json...');
  
  // Vérifier le contenu du fichier
  try {
    final documentsDir = Directory('${Platform.environment['USERPROFILE']}\\Documents');
    final file = File('${documentsDir.path}\\base_de_donnees\\userinfo.json');
    
    if (await file.exists()) {
      print('✓ Fichier trouvé: ${file.path}');
      final content = await file.readAsString();
      final List<dynamic> users = json.decode(content);
      
      print('\n2. Utilisateurs dans le fichier:');
      for (var userData in users) {
        print('- ID: ${userData['id']}');
        print('  Email: ${userData['email']}');
        print('  Role: ${userData['role']}');
        print('  DisplayName: ${userData['displayName']}');
        
        if (userData['role'] == 'beneficiaire') {
          print('  === DONNÉES BÉNÉFICIAIRE ===');
          print('  Phone: ${userData['phoneNumber']}');
          print('  Address: ${userData['address']}');
          print('  PreferredPickupZone: ${userData['preferredPickupZone']}');
          print('  DietaryPreferences: ${userData['dietaryPreferences']}');
          print('  Allergies: ${userData['allergies']}');
          print('  TotalReservations: ${userData['totalReservations']}');
        }
        print('');
      }
    } else {
      print('✗ Fichier non trouvé: ${file.path}');
    }
  } catch (e) {
    print('✗ Erreur lecture fichier: $e');
  }
  
  print('\n3. Test de connexion bénéficiaire...');
  
  // Tester la connexion
  final user = await authService.signIn(
    email: 'beneficiaire@test.com',
    password: '123456',
  );
  
  if (user != null) {
    print('✓ Connexion réussie!');
    print('\n4. Données utilisateur chargées:');
    print('- ID: ${user.id}');
    print('- Email: ${user.email}');
    print('- DisplayName: ${user.displayName}');
    print('- Role: ${user.role}');
    print('- Phone: ${user.phoneNumber}');
    print('- Address: ${user.address}');
    print('- PreferredPickupZone: ${user.preferredPickupZone}');
    print('- DietaryPreferences: ${user.dietaryPreferences}');
    print('- Allergies: ${user.allergies}');
    print('- TotalReservations: ${user.totalReservations}');
    print('- CreatedAt: ${user.createdAt}');
    
    // Vérifier les champs spécifiques
    print('\n5. Vérification des champs spécifiques:');
    print('- PreferredPickupZone null? ${user.preferredPickupZone == null}');
    print('- DietaryPreferences null? ${user.dietaryPreferences == null}');
    print('- DietaryPreferences empty? ${user.dietaryPreferences?.isEmpty ?? true}');
    print('- Allergies null? ${user.allergies == null}');
    print('- Allergies empty? ${user.allergies?.isEmpty ?? true}');
    
  } else {
    print('✗ Échec de la connexion');
  }
  
  print('\n=== FIN DEBUG ===');
}