import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  
  // Dossiers de stockage
  static const String donationsFolder = 'donations';
  static const String profilesFolder = 'profiles';
  static const String tempFolder = 'temp';
  
  // Upload d'une image pour un don
  Future<String> uploadDonationImage({
    required File imageFile,
    required String donationId,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}_${path.basename(imageFile.path)}';
      final String filePath = '$donationsFolder/$donationId/$fileName';
      
      final Reference ref = _storage.ref().child(filePath);
      
      // Métadonnées pour optimiser le stockage
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(imageFile.path),
        customMetadata: {
          'donationId': donationId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      
      // Attendre la fin de l'upload
      final TaskSnapshot snapshot = await uploadTask;
      
      // Obtenir l'URL de téléchargement
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }
  
  // Upload de plusieurs images pour un don
  Future<List<String>> uploadDonationImages({
    required List<File> imageFiles,
    required String donationId,
    Function(int, int)? onProgress,
  }) async {
    try {
      final List<String> downloadUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final String url = await uploadDonationImage(
          imageFile: imageFiles[i],
          donationId: donationId,
        );
        downloadUrls.add(url);
        
        // Callback de progression
        onProgress?.call(i + 1, imageFiles.length);
      }
      
      return downloadUrls;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload des images: $e');
    }
  }
  
  // Upload d'une image de profil
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final String fileName = 'profile_${_uuid.v4()}_${path.basename(imageFile.path)}';
      final String filePath = '$profilesFolder/$userId/$fileName';
      
      final Reference ref = _storage.ref().child(filePath);
      
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(imageFile.path),
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'profile',
        },
      );
      
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image de profil: $e');
    }
  }
  
  // Upload depuis des bytes (pour les images prises avec la caméra)
  Future<String> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String fileName,
    required String folder,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final String uniqueFileName = '${_uuid.v4()}_$fileName';
      final String filePath = '$folder/$uniqueFileName';
      
      final Reference ref = _storage.ref().child(filePath);
      
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentTypeFromExtension(fileName),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          ...?customMetadata,
        },
      );
      
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de l\'upload depuis bytes: $e');
    }
  }
  
  // Supprimer une image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }
  
  // Supprimer plusieurs images
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      final List<Future<void>> deleteTasks = imageUrls
          .map((url) => deleteImage(url))
          .toList();
      
      await Future.wait(deleteTasks);
    } catch (e) {
      throw Exception('Erreur lors de la suppression des images: $e');
    }
  }
  
  // Supprimer toutes les images d'un don
  Future<void> deleteDonationImages(String donationId) async {
    try {
      final Reference donationRef = _storage.ref().child('$donationsFolder/$donationId');
      final ListResult result = await donationRef.listAll();
      
      final List<Future<void>> deleteTasks = result.items
          .map((ref) => ref.delete())
          .toList();
      
      await Future.wait(deleteTasks);
    } catch (e) {
      throw Exception('Erreur lors de la suppression des images du don: $e');
    }
  }
  
  // Supprimer l'ancienne image de profil
  Future<void> deleteOldProfileImage(String userId, String currentImageUrl) async {
    try {
      final Reference userProfileRef = _storage.ref().child('$profilesFolder/$userId');
      final ListResult result = await userProfileRef.listAll();
      
      for (final Reference ref in result.items) {
        final String url = await ref.getDownloadURL();
        if (url != currentImageUrl) {
          await ref.delete();
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'ancienne image de profil: $e');
    }
  }
  
  // Obtenir les métadonnées d'un fichier
  Future<FullMetadata> getFileMetadata(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des métadonnées: $e');
    }
  }
  
  // Obtenir la taille d'un fichier
  Future<int> getFileSize(String imageUrl) async {
    try {
      final FullMetadata metadata = await getFileMetadata(imageUrl);
      return metadata.size ?? 0;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la taille du fichier: $e');
    }
  }
  
  // Lister les fichiers d'un dossier
  Future<List<String>> listFiles(String folderPath) async {
    try {
      final Reference ref = _storage.ref().child(folderPath);
      final ListResult result = await ref.listAll();
      
      final List<String> urls = [];
      for (final Reference fileRef in result.items) {
        final String url = await fileRef.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Erreur lors de la liste des fichiers: $e');
    }
  }
  
  // Compresser et redimensionner une image avant upload
  Future<File> compressImage(File imageFile, {int quality = 85, int maxWidth = 1024}) async {
    try {
      // Note: Cette méthode nécessiterait une bibliothèque comme image_picker ou flutter_image_compress
      // Pour l'instant, on retourne le fichier original
      // Dans une implémentation complète, on utiliserait:
      // - flutter_image_compress pour la compression
      // - image package pour le redimensionnement
      
      return imageFile;
    } catch (e) {
      throw Exception('Erreur lors de la compression de l\'image: $e');
    }
  }
  
  // Valider le type de fichier
  bool isValidImageFile(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    const List<String> validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return validExtensions.contains(extension);
  }
  
  // Valider la taille du fichier (en bytes)
  bool isValidFileSize(File file, {int maxSizeInMB = 10}) {
    final int fileSizeInBytes = file.lengthSync();
    final int maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSizeInBytes <= maxSizeInBytes;
  }
  
  // Obtenir le type de contenu basé sur l'extension
  String _getContentType(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
  
  String _getContentTypeFromExtension(String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
  
  // Nettoyer les fichiers temporaires anciens
  Future<void> cleanupTempFiles({int maxAgeInHours = 24}) async {
    try {
      final Reference tempRef = _storage.ref().child(tempFolder);
      final ListResult result = await tempRef.listAll();
      
      final DateTime cutoffTime = DateTime.now().subtract(Duration(hours: maxAgeInHours));
      
      for (final Reference ref in result.items) {
        try {
          final FullMetadata metadata = await ref.getMetadata();
          if (metadata.timeCreated != null && metadata.timeCreated!.isBefore(cutoffTime)) {
            await ref.delete();
          }
        } catch (e) {
          // Ignorer les erreurs pour les fichiers individuels
          continue;
        }
      }
    } catch (e) {
      throw Exception('Erreur lors du nettoyage des fichiers temporaires: $e');
    }
  }
  
  // Obtenir l'utilisation du stockage pour un utilisateur
  Future<Map<String, dynamic>> getUserStorageUsage(String userId) async {
    try {
      int totalSize = 0;
      int fileCount = 0;
      
      // Vérifier les images de profil
      final Reference profileRef = _storage.ref().child('$profilesFolder/$userId');
      try {
        final ListResult profileResult = await profileRef.listAll();
        for (final Reference ref in profileResult.items) {
          final FullMetadata metadata = await ref.getMetadata();
          totalSize += metadata.size ?? 0;
          fileCount++;
        }
      } catch (e) {
        // Dossier n'existe pas encore
      }
      
      return {
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'fileCount': fileCount,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul de l\'utilisation du stockage: $e');
    }
  }
}