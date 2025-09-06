import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/services/json_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = JsonAuthService();
  await authService.initialize();
  
  // Simuler une connexion avec Marie Bénéficiaire
  final result = await authService.login('beneficiaire@test.com', '123456');
  
  if (result['success']) {
    print('Connexion réussie: ${result['user'].fullName}');
    print('Utilisateur actuel: ${authService.currentUser?.fullName}');
  } else {
    print('Erreur de connexion: ${result['message']}');
  }
  
  exit(0);
}