import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';
import 'lib/core/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST PROFIL BÉNÉFICIAIRE ===\n');
  
  final authService = SimpleAuthService();
  
  print('1. Test de connexion bénéficiaire...');
  
  // Tester la connexion
  final user = await authService.signIn(
    email: 'beneficiaire@test.com',
    password: '123456',
  );
  
  if (user != null) {
    print('✓ Connexion réussie!');
    print('\n2. Données utilisateur chargées:');
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
    print('\n3. Vérification des champs spécifiques:');
    print('- PreferredPickupZone null? ${user.preferredPickupZone == null}');
    print('- PreferredPickupZone value: "${user.preferredPickupZone}"');
    print('- DietaryPreferences null? ${user.dietaryPreferences == null}');
    print('- DietaryPreferences empty? ${user.dietaryPreferences?.isEmpty ?? true}');
    print('- DietaryPreferences value: ${user.dietaryPreferences}');
    print('- Allergies null? ${user.allergies == null}');
    print('- Allergies empty? ${user.allergies?.isEmpty ?? true}');
    print('- Allergies value: ${user.allergies}');
    
    // Test des conditions d'affichage
    print('\n4. Test des conditions d\'affichage:');
    print('- Role == UserRole.beneficiaire? ${user.role == UserRole.beneficiaire}');
    print('- Should show preferredPickupZone? ${user.preferredPickupZone != null}');
    print('- Should show dietaryPreferences? ${user.dietaryPreferences != null && user.dietaryPreferences!.isNotEmpty}');
    print('- Should show allergies? ${user.allergies != null && user.allergies!.isNotEmpty}');
    
  } else {
    print('✗ Échec de la connexion');
  }
  
  print('\n=== FIN TEST ===');
}