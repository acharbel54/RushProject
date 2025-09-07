import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalImageService {
  static const Uuid _uuid = Uuid();

  /// Obtient le chemin du dossier assets dans base_de_donnees
  static Future<String> get _assetsPath async {
    final directory = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${directory.path}/base_de_donnees');
    final assetsDir = Directory('${dbDir.path}/assets');
    
    // Create directories if they don't exist
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    
    return assetsDir.path;
  }

  /// Copie une image vers le dossier assets dans base_de_donnees
  /// Retourne le chemin relatif de l'image copiée
  static Future<String> saveImageToAssets(File imageFile) async {
    try {
      print('🖼️ Début sauvegarde image: ${imageFile.path}');
      
      // Obtenir le chemin du dossier assets
      final assetsPath = await _assetsPath;
      print('📁 Dossier assets: $assetsPath');
      
      // Générer un nom unique pour l'image
      final String extension = path.extension(imageFile.path);
      final String uniqueName = '${_uuid.v4()}$extension';
      final String destinationPath = '$assetsPath/$uniqueName';
      
      print('💾 Destination: $destinationPath');
      
      // Copier l'image vers le dossier assets
      final File destinationFile = File(destinationPath);
      await imageFile.copy(destinationFile.path);
      
      // Retourner le chemin relatif pour stockage dans la base de données
      final String relativePath = 'assets/$uniqueName';
      print('✅ Image sauvegardée avec succès: $relativePath');
      
      return relativePath;
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de l\'image: $e');
      throw Exception('Erreur lors de la sauvegarde de l\'image: $e');
    }
  }

  /// Copie plusieurs images vers le dossier assets
  /// Retourne la liste des chemins relatifs des images copiées
  static Future<List<String>> saveImagesToAssets(List<File> imageFiles) async {
    try {
      final List<String> imagePaths = [];
      
      for (File imageFile in imageFiles) {
        final String imagePath = await saveImageToAssets(imageFile);
        imagePaths.add(imagePath);
      }
      
      return imagePaths;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des images: $e');
    }
  }

  /// Supprime une image du dossier assets
  static Future<void> deleteImageFromAssets(String relativePath) async {
    try {
      print('🗑️ Suppression image: $relativePath');
      
      // Convertir le chemin relatif en chemin absolu
      final assetsPath = await _assetsPath;
      final String fileName = relativePath.replaceFirst('assets/', '');
      final String fullPath = '$assetsPath/$fileName';
      
      final File imageFile = File(fullPath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        print('✅ Image supprimée avec succès: $relativePath');
      } else {
        print('⚠️ Image non trouvée: $fullPath');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'image: $e');
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }

  /// Supprime plusieurs images du dossier assets
  static Future<void> deleteImagesFromAssets(List<String> imagePaths) async {
    try {
      for (String imagePath in imagePaths) {
        await deleteImageFromAssets(imagePath);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression des images: $e');
    }
  }

  /// Vérifie si une image existe dans le dossier assets
  static Future<bool> imageExists(String relativePath) async {
    try {
      // Convertir le chemin relatif en chemin absolu
      final assetsPath = await _assetsPath;
      final String fileName = relativePath.replaceFirst('assets/', '');
      final String fullPath = '$assetsPath/$fileName';
      
      final File imageFile = File(fullPath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtient la taille d'une image en octets
  static Future<int> getImageSize(String relativePath) async {
    try {
      // Convertir le chemin relatif en chemin absolu
      final assetsPath = await _assetsPath;
      final String fileName = relativePath.replaceFirst('assets/', '');
      final String fullPath = '$assetsPath/$fileName';
      
      final File imageFile = File(fullPath);
      if (await imageFile.exists()) {
        return await imageFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Obtient le chemin absolu d'une image à partir de son chemin relatif
  static Future<String> getAbsolutePath(String relativePath) async {
    final assetsPath = await _assetsPath;
    final String fileName = relativePath.replaceFirst('assets/', '');
    return '$assetsPath/$fileName';
  }
}