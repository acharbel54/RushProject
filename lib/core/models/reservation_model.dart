import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus { pending, confirmed, completed, cancelled }

class ReservationModel {
  final String id;
  final String donationId;
  final String donorId;
  final String beneficiaryId;
  final String beneficiaryName;
  final String donationTitle;
  final String donationQuantity;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final String? notes;
  final String? cancellationReason;
  final String donorName;
  final String pickupAddress;
  final DateTime? scheduledPickupTime;
  final String? contactPhone;

  ReservationModel({
    required this.id,
    required this.donationId,
    required this.donorId,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.donationTitle,
    required this.donationQuantity,
    this.status = ReservationStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.completedAt,
    this.notes,
    this.cancellationReason,
    required this.donorName,
    required this.pickupAddress,
    this.scheduledPickupTime,
    this.contactPhone,
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donationId': donationId,
      'donorId': donorId,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'donationTitle': donationTitle,
      'donationQuantity': donationQuantity,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'donorName': donorName,
      'pickupAddress': pickupAddress,
      'scheduledPickupTime': scheduledPickupTime != null 
          ? Timestamp.fromDate(scheduledPickupTime!) 
          : null,
      'contactPhone': contactPhone,
    };
  }

  // Création depuis Map Firestore
  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      id: map['id'] ?? '',
      donationId: map['donationId'] ?? '',
      donorId: map['donorId'] ?? '',
      beneficiaryId: map['beneficiaryId'] ?? '',
      beneficiaryName: map['beneficiaryName'] ?? '',
      donationTitle: map['donationTitle'] ?? '',
      donationQuantity: map['donationQuantity'] ?? '',
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
      cancellationReason: map['cancellationReason'],
      donorName: map['donorName'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      scheduledPickupTime: map['scheduledPickupTime'] != null
          ? (map['scheduledPickupTime'] as Timestamp).toDate()
          : null,
      contactPhone: map['contactPhone'],
    );
  }

  // Création depuis DocumentSnapshot
  factory ReservationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel.fromMap(data);
  }

  // Copie avec modifications
  ReservationModel copyWith({
    String? id,
    String? donationId,
    String? donorId,
    String? beneficiaryId,
    String? beneficiaryName,
    String? donationTitle,
    String? donationQuantity,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    String? notes,
    String? cancellationReason,
    String? donorName,
    String? pickupAddress,
    DateTime? scheduledPickupTime,
    String? contactPhone,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      donationId: donationId ?? this.donationId,
      donorId: donorId ?? this.donorId,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      donationTitle: donationTitle ?? this.donationTitle,
      donationQuantity: donationQuantity ?? this.donationQuantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      donorName: donorName ?? this.donorName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      scheduledPickupTime: scheduledPickupTime ?? this.scheduledPickupTime,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  // Vérifier si la réservation est active
  bool get isActive => status == ReservationStatus.pending || status == ReservationStatus.confirmed;

  // Obtenir la couleur du statut
  String get statusDisplayText {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.completed:
        return 'Récupérée';
      case ReservationStatus.cancelled:
        return 'Annulée';
    }
  }

  @override
  String toString() {
    return 'ReservationModel(id: $id, donationTitle: $donationTitle, status: $status)';
  }
}