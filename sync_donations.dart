import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== SYNCHRONISATION DES DONATIONS ===\n');
  
  try {
    // 1. Lire le fichier donations.json du projet
    final projectFile = File('base_de_donnees/donations.json');
    if (!await projectFile.exists()) {
      print('❌ Fichier donations.json du projet introuvable');
      return;
    }
    
    final projectContent = await projectFile.readAsString();
    final projectDonations = json.decode(projectContent);
    print('📁 Fichier projet trouvé avec \${projectDonations.length} don(s)');
    
    // 2. Utiliser le répertoire Documents directement
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    final systemDbDir = Directory('\$userHome/Documents/base_de_donnees');
    
    // Créer le répertoire s'il n'existe pas
    if (!await systemDbDir.exists()) {
      await systemDbDir.create(recursive: true);
      print('📂 Répertoire système créé: \${systemDbDir.path}');
    }
    
    final systemFile = File('\${systemDbDir.path}/donations.json');
    
    // 3. Vérifier s'il y a déjà des donations dans le système
    List<dynamic> systemDonations = [];
    if (await systemFile.exists()) {
      final systemContent = await systemFile.readAsString();
      systemDonations = json.decode(systemContent);
      print('💾 Fichier système existant avec \${systemDonations.length} don(s)');
    }
    
    // 4. Fusionner les donations (éviter les doublons par ID)
    final allDonations = <String, dynamic>{};
    
    // Ajouter les donations système existantes
    for (var donation in systemDonations) {
      allDonations[donation['id']] = donation;
    }
    
    // Ajouter les donations du projet (écrase les doublons)
    for (var donation in projectDonations) {
      allDonations[donation['id']] = donation;
    }
    
    // 5. Sauvegarder dans le fichier système
    final finalDonations = allDonations.values.toList();
    await systemFile.writeAsString(json.encode(finalDonations));
    
    print('\n✅ Synchronisation terminée!');
    print('📍 Emplacement système: \${systemFile.path}');
    print('📊 Total des donations: \${finalDonations.length}');
    
    // 6. Afficher le contenu pour vérification
    print('\n🔍 Contenu synchronisé:');
    for (var donation in finalDonations) {
      print('   - \${donation['title']} (ID: \${donation['id']})');
    }
    
    print('\n💡 Redémarrez l\'application pour voir les changements!');
    
  } catch (e) {
    print('❌ Erreur: \$e');
  }
}