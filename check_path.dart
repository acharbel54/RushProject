import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  try {
    // Utiliser la même méthode que JsonAuthService
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/users.json';
    
    print('Chemin du fichier users.json:');
    print(filePath);
    
    // Vérifier si le fichier existe
    final file = File(filePath);
    if (await file.exists()) {
      print('\nLe fichier existe!');
      final contents = await file.readAsString();
      print('\nContenu du fichier:');
      print(contents);
    } else {
      print('\nLe fichier n\'existe pas encore.');
      print('Il sera créé lors de la première inscription.');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}