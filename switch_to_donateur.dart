import 'dart:convert';
import 'dart:io';

void main() async {
  // Chemin vers le fichier current_user.json
  final file = File('base_de_donnees/current_user.json');
  
  // Données du donateur
  final donateurData = {
    "id": "donateur_001",
    "email": "donateur@test.com",
    "password": "123456",
    "firstName": "Jean",
    "lastName": "Donateur",
    "role": "donateur",
    "createdAt": "2025-09-06T00:18:50.114Z"
  };
  
  // Écrire les données dans le fichier
  await file.writeAsString(jsonEncode(donateurData));
  
  print('✅ Utilisateur changé vers donateur');
  print('📧 Email: donateur@test.com');
  print('🔑 Mot de passe: 123456');
  print('👤 Rôle: donateur');
  print('');
  print('Vous pouvez maintenant redémarrer l\'application pour voir l\'onglet "Mes dons" et le bouton de suppression.');
}