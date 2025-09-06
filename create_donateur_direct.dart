import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    // Créer le répertoire s'il n'existe pas
    final dbDir = Directory('base_de_donnees');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
      print('Répertoire base_de_donnees créé');
    }
    
    final userFile = File('base_de_donnees/userinfo.json');
    
    // Créer deux utilisateurs de test
    final users = [
      {
        'id': 'donateur_001',
        'email': 'donateur@test.com',
        'password': '123456',
        'displayName': 'Jean Donateur',
        'role': 'donateur',
        'phoneNumber': '0123456789',
        'address': '123 Rue du Don, Paris',
        'createdAt': DateTime.now().toIso8601String(),
        'totalDonations': 5,
      },
      {
        'id': 'beneficiaire_001',
        'email': 'beneficiaire@test.com',
        'password': '123456',
        'displayName': 'Marie Bénéficiaire',
        'role': 'beneficiaire',
        'phoneNumber': '0987654321',
        'address': '456 Avenue de l\'Aide, Lyon',
        'createdAt': DateTime.now().toIso8601String(),
        'totalDonations': 0,
      }
    ];
    
    // Sauvegarder dans le fichier JSON
    await userFile.writeAsString(json.encode(users));
    
    print('✅ Fichier userinfo.json créé avec succès!');
    print('📍 Emplacement: ${userFile.absolute.path}');
    print('👥 Utilisateurs créés:');
    print('   1. Donateur: donateur@test.com / 123456');
    print('   2. Bénéficiaire: beneficiaire@test.com / 123456');
    print('');
    print('🔍 Contenu du fichier:');
    print(json.encode(users));
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}