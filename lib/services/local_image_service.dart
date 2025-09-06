import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class LocalImageService {
  static const String _donationsImagesPath = 'assets/images/donations';
  static const Uuid _uuid = Uuid();

  /// Copie une image vers le dossier assets/images/donations/
  /// Retourne le chemin relatif de l'image copiée
  static Future<String> saveImageToAssets(File imageFile) async {
    try {
      // Générer un nom unique pour l'image
      final String extension = path.extension(imageFile.path);
      final String uniqueName = '${_uuid.v4()}$extension';
      final String destinationPath = '$_donationsImagesPath/$uniqueName';
      
      // Créer le répertoire de destination s'il n'existe pas
      final Directory destinationDir = Directory(_donationsImagesPath);
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }
      
      // Copier l'image vers le dossier assets
      final File destinationFile = File(destinationPath);
      await imageFile.copy(destinationFile.path);
      
      return destinationPath;
    } catch (e) {
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
  static Future<void> deleteImageFromAssets(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
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
  static Future<bool> imageExists(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtient la taille d'une image en octets
  static Future<int> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}