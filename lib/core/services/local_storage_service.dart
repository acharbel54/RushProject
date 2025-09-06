import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late Directory _appDir;
  bool _isInitialized = false;

  // Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _appDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory('${_appDir.path}/foodlink_data');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      _appDir = dataDir;
      _isInitialized = true;
      if (kDebugMode) {
        print('LocalStorageService initialisé: ${_appDir.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation du LocalStorageService: $e');
      }
      rethrow;
    }
  }

  // Obtenir le chemin d'un fichier de collection
  String _getCollectionPath(String collection) {
    return '${_appDir.path}/$collection.json';
  }

  // Lire une collection complète
  Future<List<Map<String, dynamic>>> _readCollection(String collection) async {
    await _ensureInitialized();
    
    final file = File(_getCollectionPath(collection));
    if (!await file.exists()) {
      return [];
    }
    
    try {
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la lecture de $collection: $e');
      }
      return [];
    }
  }

  // Écrire une collection complète
  Future<void> _writeCollection(String collection, List<Map<String, dynamic>> data) async {
    await _ensureInitialized();
    
    final file = File(_getCollectionPath(collection));
    try {
      await file.writeAsString(json.encode(data));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'écriture de $collection: $e');
      }
      rethrow;
    }
  }

  // Générer un ID unique
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  // Ajouter un document à une collection
  Future<String> add(String collection, Map<String, dynamic> data) async {
    final documents = await _readCollection(collection);
    final id = _generateId();
    
    final newDoc = {
      ...data,
      'id': id,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    documents.add(newDoc);
    await _writeCollection(collection, documents);
    
    if (kDebugMode) {
      print('Document ajouté à $collection avec ID: $id');
    }
    
    return id;
  }

  // Obtenir un document par ID
  Future<Map<String, dynamic>?> get(String collection, String documentId) async {
    final documents = await _readCollection(collection);
    
    try {
      return documents.firstWhere((doc) => doc['id'] == documentId);
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour un document
  Future<void> update(String collection, String documentId, Map<String, dynamic> data) async {
    final documents = await _readCollection(collection);
    final index = documents.indexWhere((doc) => doc['id'] == documentId);
    
    if (index == -1) {
      throw Exception('Document non trouvé: $documentId');
    }
    
    documents[index] = {
      ...documents[index],
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    await _writeCollection(collection, documents);
    
    if (kDebugMode) {
      print('Document mis à jour dans $collection: $documentId');
    }
  }

  // Supprimer un document
  Future<void> delete(String collection, String documentId) async {
    final documents = await _readCollection(collection);
    documents.removeWhere((doc) => doc['id'] == documentId);
    await _writeCollection(collection, documents);
    
    if (kDebugMode) {
      print('Document supprimé de $collection: $documentId');
    }
  }

  // Obtenir tous les documents d'une collection
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    return await _readCollection(collection);
  }

  // Requête simple avec filtre
  Future<List<Map<String, dynamic>>> where(
    String collection, 
    String field, 
    dynamic value
  ) async {
    final documents = await _readCollection(collection);
    return documents.where((doc) => doc[field] == value).toList();
  }

  // Requête avec plusieurs filtres
  Future<List<Map<String, dynamic>>> whereMultiple(
    String collection, 
    Map<String, dynamic> filters
  ) async {
    final documents = await _readCollection(collection);
    
    return documents.where((doc) {
      for (final entry in filters.entries) {
        if (doc[entry.key] != entry.value) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Vérifier si un document existe
  Future<bool> exists(String collection, String documentId) async {
    final doc = await get(collection, documentId);
    return doc != null;
  }

  // Compter les documents dans une collection
  Future<int> count(String collection) async {
    final documents = await _readCollection(collection);
    return documents.length;
  }

  // Vider une collection
  Future<void> clear(String collection) async {
    await _writeCollection(collection, []);
    
    if (kDebugMode) {
      print('Collection $collection vidée');
    }
  }

  // Vérifier l'initialisation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Obtenir les statistiques de stockage
  Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();
    
    final stats = <String, dynamic>{};
    final collections = ['users', 'donations', 'reservations', 'notifications', 'conversations', 'messages'];
    
    for (final collection in collections) {
      final count = await this.count(collection);
      stats[collection] = count;
    }
    
    return stats;
  }

  // Sauvegarder toutes les données
  Future<Map<String, dynamic>> exportAllData() async {
    await _ensureInitialized();
    
    final allData = <String, dynamic>{};
    final collections = ['users', 'donations', 'reservations', 'notifications', 'conversations', 'messages'];
    
    for (final collection in collections) {
      allData[collection] = await _readCollection(collection);
    }
    
    return allData;
  }

  // Restaurer toutes les données
  Future<void> importAllData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    for (final entry in data.entries) {
      if (entry.value is List) {
        await _writeCollection(entry.key, (entry.value as List).cast<Map<String, dynamic>>());
      }
    }
    
    if (kDebugMode) {
      print('Données importées avec succès');
    }
  }
}