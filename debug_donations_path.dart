import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  try {
    // Obtenir le chemin utilisé par JsonDonationService
    final directory = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${directory.path}/base_de_donnees');
    final donationsFile = File('${dbDir.path}/donations.json');
    
    print('=== CHEMINS UTILISÉS PAR L\'APPLICATION ===');
    print('Documents directory: ${directory.path}');
    print('Database directory: ${dbDir.path}');
    print('Donations file: ${donationsFile.path}');
    print('');
    
    print('=== VÉRIFICATION DE L\'EXISTENCE ===');
    print('Database directory exists: ${await dbDir.exists()}');
    print('Donations file exists: ${await donationsFile.exists()}');
    print('');
    
    if (await donationsFile.exists()) {
      print('=== CONTENU DU FICHIER DONATIONS.JSON ===');
      final content = await donationsFile.readAsString();
      print('Taille du fichier: ${content.length} caractères');
      print('Contenu:');
      print(content);
    } else {
      print('Le fichier donations.json n\'existe pas dans le répertoire de l\'application.');
    }
    
    print('');
    print('=== COMPARAISON AVEC LE FICHIER DU PROJET ===');
    final projectFile = File('c:\\Users\\Dell\\Documents\\RushProject\\base_de_donnees\\donations.json');
    print('Project donations file exists: ${await projectFile.exists()}');
    
    if (await projectFile.exists()) {
      final projectContent = await projectFile.readAsString();
      print('Taille du fichier projet: ${projectContent.length} caractères');
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}