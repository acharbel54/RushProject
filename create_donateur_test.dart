import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('=== CRÉATION UTILISATEUR DONATEUR ===\n');
  
  try {
    // Obtenir le répertoire de l'application
    final appDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${appDir.path}/base_de_donnees');
    
    // Créer le répertoire s'il n'existe pas
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
      print('Répertoire créé: ${dataDir.path}');
    }
    
    final usersFile = File('${dataDir.path}/userinfo.json');
    
    // Charger les utilisateurs existants ou créer une liste vide
    List<dynamic> users = [];
    if (await usersFile.exists()) {
      final content = await usersFile.readAsString();
      users = json.decode(content);
      print('Utilisateurs existants trouvés: ${users.length}');
    }
    
    // Créer un utilisateur donateur
    final donateur = {
      'id': 'donateur_${DateTime.now().millisecondsSinceEpoch}',
      'email': 'donateur@test.com',
      'password': 'password123',
      'displayName': 'Test Donateur',
      'role': 'donateur',
      'phoneNumber': '0123456789',
      'address': 'Adresse test donateur',
      'createdAt': DateTime.now().toIso8601String(),
      'totalDonations': 0,
    };
    
    // Vérifier si l'utilisateur existe déjà
    bool exists = users.any((user) => user['email'] == donateur['email']);
    
    if (!exists) {
      users.add(donateur);
      
      // Sauvegarder dans le fichier
      await usersFile.writeAsString(json.encode(users));
      
      print('✅ Utilisateur donateur créé avec succès!');
      print('   Email: ${donateur['email']}');
      print('   Rôle: ${donateur['role']}');
      print('   Mot de passe: ${donateur['password']}');
    } else {
      print('⚠️  L\'utilisateur donateur existe déjà');
    }
    
    print('\n=== INSTRUCTIONS ===');
    print('1. Ouvrez l\'application sur l\'émulateur');
    print('2. Connectez-vous avec:');
    print('   - Email: donateur@test.com');
    print('   - Mot de passe: password123');
    print('3. Vérifiez que vous voyez 3 sections:');
    print('   - Accueil');
    print('   - Mes dons');
    print('   - Profil');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}