import 'dart:convert';
import 'dart:io';

void main() async {
  // Simuler les données utilisateur comme dans l'app
  final users = [
    {
      'id': '1',
      'email': 'donateur@test.com',
      'firstName': 'Jean',
      'lastName': 'Donateur',
      'role': 'donateur',
      'password': 'test123'
    },
    {
      'id': '2', 
      'email': 'beneficiaire@test.com',
      'firstName': 'Marie',
      'lastName': 'Beneficiaire', 
      'role': 'beneficiaire',
      'password': 'test123'
    }
  ];

  print('=== Test des rôles utilisateur ===\n');
  
  for (var user in users) {
    print('Utilisateur: ${user['firstName']} ${user['lastName']}');
    print('Email: ${user['email']}');
    print('Rôle stocké: "${user['role']}"');
    print('Type du rôle: ${user['role'].runtimeType}');
    
    // Test des comparaisons comme dans l'app
    String role = user['role'] as String;
    print('role == "donateur": ${role == "donateur"}');
    print('role == "beneficiaire": ${role == "beneficiaire"}');
    
    // Test avec UserRole enum (simulation)
    print('Simulation enum:');
    if (role == 'donateur') {
      print('  -> UserRole.donateur détecté');
      print('  -> Devrait afficher 3 onglets: Dashboard, Mes dons, Profil');
    } else {
      print('  -> UserRole.beneficiaire détecté');
      print('  -> Devrait afficher 4 onglets: Dashboard, Map, Réservations, Profil');
    }
    print('---\n');
  }
}