import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

void main() async {
  try {
    // Obtenir le chemin exact comme dans JsonAuthService
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/users.json';
    
    print('=== RECHERCHE DU FICHIER USERS.JSON ===');
    print('Chemin attendu: $filePath');
    print('');
    
    // Vérifier si le fichier existe
    final file = File(filePath);
    if (await file.exists()) {
      print('✅ FICHIER TROUVÉ!');
      print('Taille: ${await file.length()} bytes');
      print('');
      
      // Lire et afficher le contenu
      final contents = await file.readAsString();
      print('📄 CONTENU DU FICHIER:');
      
      try {
        final jsonData = json.decode(contents);
        final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
        print(prettyJson);
        
        if (jsonData is List) {
          print('');
          print('📊 STATISTIQUES:');
          print('Nombre d\'utilisateurs: ${jsonData.length}');
        }
      } catch (e) {
        print('Contenu brut:');
        print(contents);
        print('⚠️  Erreur de parsing JSON: $e');
      }
    } else {
      print('❌ FICHIER NON TROUVÉ');
      print('');
      print('🔍 RECHERCHE DANS D\'AUTRES EMPLACEMENTS...');
      
      // Vérifier d'autres emplacements possibles
      final possiblePaths = [
        'C:\\Users\\Dell\\Documents\\users.json',
        '${Directory.current.path}\\users.json',
        '${Platform.environment['USERPROFILE']}\\AppData\\Roaming\\com.example.foodlink\\users.json',
        '${Platform.environment['USERPROFILE']}\\AppData\\Local\\com.example.foodlink\\users.json',
      ];
      
      for (String path in possiblePaths) {
        final testFile = File(path);
        if (await testFile.exists()) {
          print('✅ Trouvé dans: $path');
          final size = await testFile.length();
          print('   Taille: $size bytes');
        } else {
          print('❌ Pas dans: $path');
        }
      }
    }
    
    print('');
    print('💡 CONSEILS:');
    print('- Le fichier est créé seulement après la première inscription réussie');
    print('- Vérifiez que l\'inscription s\'est bien déroulée sans erreur');
    print('- Le fichier peut être dans un dossier système caché');
    
  } catch (e) {
    print('❌ ERREUR: $e');
  }
}