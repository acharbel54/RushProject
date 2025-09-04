import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: DonationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => DonationType.autre,
      ),
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      expirationDate: (data['expirationDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      status: DonationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => DonationStatus.disponible,
      ),
      imageUrl: data['imageUrl'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      reservedBy: data['reservedBy'],
      reservedAt: data['reservedAt'] != null
          ? (data['reservedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'reservedBy': reservedBy,
      'reservedAt': reservedAt != null ? Timestamp.fromDate(reservedAt!) : null,
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