// Removed Firebase import for JSON storage

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

  // Conversion vers Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'title': title,
      'description': description,
      'quantity': quantity,
      'category': category.name,
      'expirationDate': expirationDate.toIso8601String(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'reservedBy': reservedBy,
      'reservedAt': reservedAt?.toIso8601String(),
      'notes': notes,
      'isUrgent': isUrgent,
    };
  }

  // Création depuis Map JSON
  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'] ?? '',
      donorId: json['donorId'] ?? '',
      donorName: json['donorName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? '',
      category: DonationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DonationCategory.autre,
      ),
      expirationDate: DateTime.parse(json['expirationDate']),
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      status: DonationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DonationStatus.disponible,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      reservedBy: json['reservedBy'],
      reservedAt: json['reservedAt'] != null
          ? DateTime.parse(json['reservedAt'])
          : null,
      notes: json['notes'],
      isUrgent: json['isUrgent'] ?? false,
    );
  }

  // Méthode pour compatibilité (alias de fromJson)
  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel.fromJson(map);
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