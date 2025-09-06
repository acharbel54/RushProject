import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';
import 'lib/core/models/user_model.dart';

void main() async {
  print('=== Test de connexion bénéficiaire ===');
  
  // Créer le service d'authentification
  final authService = SimpleAuthService();
  
  try {
    // Tenter de se connecter avec un bénéficiaire
    final result = await authService.signInWithEmailAndPassword(
      'marie.beneficiaire@example.com',
      'password123'
    );
    
    if (result.success && result.user != null) {
      final user = result.user!;
      print('✅ Connexion réussie!');
      print('Nom: ${user.displayName}');
      print('Email: ${user.email}');
      print('Rôle: ${user.role}');
      print('Téléphone: ${user.phoneNumber}');
      print('Adresse: ${user.address}');
      print('Zone préférée: ${user.preferredPickupZone}');
      print('Préférences alimentaires: ${user.dietaryPreferences}');
      print('Allergies: ${user.allergies}');
      print('Total réservations: ${user.totalReservations}');
      print('Date de création: ${user.createdAt}');
      
      // Vérifier si les champs spécifiques aux bénéficiaires sont présents
      if (user.role == UserRole.beneficiaire) {
        print('\n=== Vérification des champs bénéficiaire ===');
        print('Zone préférée renseignée: ${user.preferredPickupZone != null}');
        print('Préférences alimentaires renseignées: ${user.dietaryPreferences != null && user.dietaryPreferences!.isNotEmpty}');
        print('Allergies renseignées: ${user.allergies != null && user.allergies!.isNotEmpty}');
        print('Total réservations défini: ${user.totalReservations != null}');
        
        if (user.preferredPickupZone == null && 
            (user.dietaryPreferences == null || user.dietaryPreferences!.isEmpty) &&
            (user.allergies == null || user.allergies!.isEmpty)) {
          print('⚠️  PROBLÈME: Aucun champ spécifique aux bénéficiaires n\'est renseigné!');
        } else {
          print('✅ Les champs spécifiques aux bénéficiaires sont correctement renseignés.');
        }
      }
      
    } else {
      print('❌ Échec de la connexion: ${result.errorMessage}');
    }
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
  
  print('\n=== Fin du test ===');
}