// Removed Firebase import for JSON storage

enum DonationStatus { disponible, reserve, recupere, expire }
enum DonationType { fruits, legumes, pain, produits_laitiers, viande, autre }

class Donation {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final DonationType type;
  final double quantity;
  final String unit;
  final DateTime expirationDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DonationStatus status;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String address;
  final String? reservedBy;
  final DateTime? reservedAt;
  final String? notes;
  final bool isActive;

  Donation({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
    required this.createdAt,
    this.updatedAt,
    required this.status,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.reservedBy,
    this.reservedAt,
    this.notes,
    this.isActive = true,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] ?? '',
      donorId: json['donorId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: DonationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DonationType.autre,
      ),
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      expirationDate: DateTime.parse(json['expirationDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      status: DonationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DonationStatus.disponible,
      ),
      imageUrl: json['imageUrl'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      reservedBy: json['reservedBy'],
      reservedAt: json['reservedAt'] != null
          ? DateTime.parse(json['reservedAt'])
          : null,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': expirationDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'reservedBy': reservedBy,
      'reservedAt': reservedAt?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
    };
  }

  Donation copyWith({
    String? id,
    String? donorId,
    String? title,
    String? description,
    DonationType? type,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DonationStatus? status,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? reservedBy,
    DateTime? reservedAt,
    String? notes,
    bool? isActive,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      reservedBy: reservedBy ?? this.reservedBy,
      reservedAt: reservedAt ?? this.reservedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expirationDate);
  bool get isReserved => status == DonationStatus.reserve;
  bool get isAvailable => status == DonationStatus.disponible && !isExpired;
}