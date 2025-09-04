import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Référence à une collection
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  // Référence à un document
  DocumentReference document(String path) {
    return _firestore.doc(path);
  }

  // Créer un document avec un ID auto-généré
  Future<DocumentReference> create(String collection, Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création du document: $e');
      }
      rethrow;
    }
  }

  // Créer ou mettre à jour un document avec un ID spécifique
  Future<void> set(String collection, String documentId, Map<String, dynamic> data, {bool merge = false}) async {
    try {
      await _firestore.collection(collection).doc(documentId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: merge));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la définition du document: $e');
      }
      rethrow;
    }
  }

  // Mettre à jour un document
  Future<void> update(String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(documentId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du document: $e');
      }
      rethrow;
    }
  }

  // Supprimer un document
  Future<void> delete(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du document: $e');
      }
      rethrow;
    }
  }

  // Récupérer un document par ID
  Future<DocumentSnapshot> getDocument(String collection, String documentId) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération du document: $e');
      }
      rethrow;
    }
  }

  // Récupérer une collection avec des filtres optionnels
  Future<QuerySnapshot> getCollection(
    String collection, {
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Appliquer les filtres
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(filter.field, isEqualTo: filter.isEqualTo, isNotEqualTo: filter.isNotEqualTo,
              isLessThan: filter.isLessThan, isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
              isGreaterThan: filter.isGreaterThan, isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
              arrayContains: filter.arrayContains, arrayContainsAny: filter.arrayContainsAny,
              whereIn: filter.whereIn, whereNotIn: filter.whereNotIn, isNull: filter.isNull);
        }
      }

      // Appliquer l'ordre
      if (orderBy != null) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      // Appliquer la limite
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération de la collection: $e');
      }
      rethrow;
    }
  }

  // Écouter les changements d'un document
  Stream<DocumentSnapshot> listenToDocument(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  // Écouter les changements d'une collection
  Stream<QuerySnapshot> listenToCollection(
    String collection, {
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Appliquer les filtres
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(filter.field, isEqualTo: filter.isEqualTo, isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan, isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan, isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains, arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn, whereNotIn: filter.whereNotIn, isNull: filter.isNull);
      }
    }

    // Appliquer l'ordre
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    // Appliquer la limite
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Exécuter une transaction
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) updateFunction) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'exécution de la transaction: $e');
      }
      rethrow;
    }
  }

  // Exécuter un batch
  WriteBatch batch() {
    return _firestore.batch();
  }

  // Incrémenter une valeur numérique
  Future<void> increment(String collection, String documentId, String field, num value) async {
    try {
      await _firestore.collection(collection).doc(documentId).update({
        field: FieldValue.increment(value),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'incrémentation: $e');
      }
      rethrow;
    }
  }

  // Ajouter un élément à un array
  Future<void> arrayUnion(String collection, String documentId, String field, List<dynamic> elements) async {
    try {
      await _firestore.collection(collection).doc(documentId).update({
        field: FieldValue.arrayUnion(elements),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'ajout à l\'array: $e');
      }
      rethrow;
    }
  }

  // Supprimer un élément d'un array
  Future<void> arrayRemove(String collection, String documentId, String field, List<dynamic> elements) async {
    try {
      await _firestore.collection(collection).doc(documentId).update({
        field: FieldValue.arrayRemove(elements),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression de l\'array: $e');
      }
      rethrow;
    }
  }
}

// Classes utilitaires pour les requêtes
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

class QueryOrder {
  final String field;
  final bool descending;

  QueryOrder(this.field, {this.descending = false});
}