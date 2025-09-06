import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== CRÉATION DES DONATIONS PAR DÉFAUT ===\n');
  
  try {
    // Utiliser le répertoire Documents directement
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    final systemDbDir = Directory('$userHome/Documents/base_de_donnees');
    
    // Créer le répertoire s'il n'existe pas
    if (!await systemDbDir.exists()) {
      await systemDbDir.create(recursive: true);
      print('Répertoire créé: ${systemDbDir.path}');
    }
    
    final donationsFile = File('${systemDbDir.path}/donations.json');
    
    // Charger les donations existantes ou créer une liste vide
    List<dynamic> donations = [];
    if (await donationsFile.exists()) {
      final content = await donationsFile.readAsString();
      donations = json.decode(content);
      print('Donations existantes trouvées: ${donations.length}');
    }
    
    // Créer 5 donations par défaut pour Jean Donateur
    final defaultDonations = [
      {
        "id": "donation_001",
        "donorId": "donateur_001",
        "donorName": "Jean Donateur",
        "title": "Légumes frais du jardin",
        "description": "Courgettes, tomates et aubergines fraîches du potager",
        "quantity": "3 kg",
        "category": "fruits_legumes",
        "expirationDate": "2025-01-15T23:59:59.000Z",
        "address": "123 Rue du Don, Paris",
        "latitude": 48.8566,
        "longitude": 2.3522,
        "imageUrls": [],
        "status": "disponible",
        "createdAt": "2025-01-05T10:00:00.000Z",
        "updatedAt": "2025-01-05T10:00:00.000Z",
        "notes": "Légumes bio, récoltés ce matin",
        "isUrgent": false
      },
      {
        "id": "donation_002",
        "donorId": "donateur_001",
        "donorName": "Jean Donateur",
        "title": "Pain de boulangerie",
        "description": "Baguettes et pains de campagne de la veille",
        "quantity": "8 pains",
        "category": "boulangerie",
        "expirationDate": "2025-01-08T23:59:59.000Z",
        "address": "123 Rue du Don, Paris",
        "latitude": 48.8566,
        "longitude": 2.3522,
        "imageUrls": [],
        "status": "disponible",
        "createdAt": "2025-01-04T16:30:00.000Z",
        "updatedAt": "2025-01-04T16:30:00.000Z",
        "notes": "Pain encore frais, parfait pour le petit-déjeuner",
        "isUrgent": true
      },
      {
        "id": "donation_003",
        "donorId": "donateur_001",
        "donorName": "Jean Donateur",
        "title": "Produits laitiers",
        "description": "Yaourts, fromage blanc et lait frais",
        "quantity": "12 yaourts + 2L lait",
        "category": "produits_laitiers",
        "expirationDate": "2025-01-12T23:59:59.000Z",
        "address": "123 Rue du Don, Paris",
        "latitude": 48.8566,
        "longitude": 2.3522,
        "imageUrls": [],
        "status": "disponible",
        "createdAt": "2025-01-03T14:15:00.000Z",
        "updatedAt": "2025-01-03T14:15:00.000Z",
        "notes": "Produits bio, dates de péremption encore bonnes",
        "isUrgent": false
      },
      {
        "id": "donation_004",
        "donorId": "donateur_001",
        "donorName": "Jean Donateur",
        "title": "Plats cuisinés maison",
        "description": "Ratatouille et gratin de légumes faits maison",
        "quantity": "4 portions",
        "category": "plats_prepares",
        "expirationDate": "2025-01-10T23:59:59.000Z",
        "address": "123 Rue du Don, Paris",
        "latitude": 48.8566,
        "longitude": 2.3522,
        "imageUrls": [],
        "status": "disponible",
        "createdAt": "2025-01-02T19:45:00.000Z",
        "updatedAt": "2025-01-02T19:45:00.000Z",
        "notes": "Plats végétariens, à réchauffer",
        "isUrgent": false
      },
      {
        "id": "donation_005",
        "donorId": "donateur_001",
        "donorName": "Jean Donateur",
        "title": "Fruits de saison",
        "description": "Pommes, poires et oranges fraîches",
        "quantity": "2 kg",
        "category": "fruits_legumes",
        "expirationDate": "2025-01-20T23:59:59.000Z",
        "address": "123 Rue du Don, Paris",
        "latitude": 48.8566,
        "longitude": 2.3522,
        "imageUrls": [],
        "status": "disponible",
        "createdAt": "2025-01-01T11:20:00.000Z",
        "updatedAt": "2025-01-01T11:20:00.000Z",
        "notes": "Fruits de qualité, parfaits pour les enfants",
        "isUrgent": false
      }
    ];
    
    // Ajouter les donations qui n'existent pas déjà
    int addedCount = 0;
    for (final donation in defaultDonations) {
      bool exists = donations.any((d) => d['id'] == donation['id']);
      if (!exists) {
        donations.add(donation);
        addedCount++;
        print('✅ Donation ajoutée: ${donation['title']}');
      } else {
        print('⚠️  Donation déjà existante: ${donation['title']}');
      }
    }
    
    // Sauvegarder dans le fichier
    await donationsFile.writeAsString(json.encode(donations));
    
    print('\n🎉 SUCCÈS!');
    print('📁 Fichier: ${donationsFile.path}');
    print('📊 Total donations: ${donations.length}');
    print('➕ Nouvelles donations ajoutées: $addedCount');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}