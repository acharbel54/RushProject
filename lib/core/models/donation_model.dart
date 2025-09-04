import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationStatus { disponible, reserve, recupere, expire }

enum DonationCategory {
  fruits,
  legumes,
  produits_laitiers,
  viande,
  poisson,
  cereales,
  conserves,
  boulangerie,
  autre
}

class DonationModel {
  final String id;
  final String donorId;
  final String donorName;
  final String title;
  final String description;
  final String quantity;
  final DonationCategory category;
  final DateTime expirationDate;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final DonationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reservedBy;
  final DateTime? reservedAt;
  final String? notes;
  final bool isUrgent;

  DonationModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.title,
    required this.description,
    required this.quantity,
    required this.category,
    required this.expirationDate,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrls = const [],
    this.status = DonationStatus.disponible,
    required this.createdAt,
    this.updatedAt,
    this.reservedBy,
    this.reservedAt,
    this.notes,
    this.isUrgent = false,
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'title': title,
      'description': description,
      'quantity': quantity,
      'category': category.name,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'reservedBy': reservedBy,
      'reservedAt': reservedAt != null ? Timestamp.fromDate(reservedAt!) : null,
      'notes': notes,
      'isUrgent': isUrgent,
    };
  }

  // Création depuis Map Firestore
  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      id: map['id'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? '',
      category: DonationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => DonationCategory.autre,
      ),
      expirationDate: (map['expirationDate'] as Timestamp).toDate(),
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: DonationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DonationStatus.disponible,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      reservedBy: map['reservedBy'],
      reservedAt: map['reservedAt'] != null
          ? (map['reservedAt'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
      isUrgent: map['isUrgent'] ?? false,
    );
  }

  // Création depuis DocumentSnapshot
  factory DonationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationModel.fromMap(data);
  }

  // Copie avec modifications
  DonationModel copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? title,
    String? description,
    String? quantity,
    DonationCategory? category,
    DateTime? expirationDate,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    DonationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reservedBy,
    DateTime? reservedAt,
    String? notes,
    bool? isUrgent,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      expirationDate: expirationDate ?? this.expirationDate,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reservedBy: reservedBy ?? this.reservedBy,
      reservedAt: reservedAt ?? this.reservedAt,
      notes: notes ?? this.notes,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  // Vérifier si le don est expiré
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  // Obtenir le temps restant avant expiration
  Duration get timeUntilExpiration => expirationDate.difference(DateTime.now());

  @override
  String toString() {
    return 'DonationModel(id: $id, title: $title, status: $status)';
  }
}