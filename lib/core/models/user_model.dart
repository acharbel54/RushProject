import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { donateur, beneficiaire, admin }

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? phoneNumber;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final int totalDonations;
  final int totalReservations;
  final double totalKgDonated;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.phoneNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.totalDonations = 0,
    this.totalReservations = 0,
    this.totalKgDonated = 0.0,
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'phoneNumber': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'totalDonations': totalDonations,
      'totalReservations': totalReservations,
      'totalKgDonated': totalKgDonated,
    };
  }

  // Méthode pour Firestore
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  // Création depuis Map Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.beneficiaire,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isActive: map['isActive'] ?? true,
      totalDonations: map['totalDonations'] ?? 0,
      totalReservations: map['totalReservations'] ?? 0,
      totalKgDonated: (map['totalKgDonated'] ?? 0.0).toDouble(),
    );
  }

  // Création depuis DocumentSnapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  // Copie avec modifications
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
    int? totalDonations,
    int? totalReservations,
    double? totalKgDonated,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      totalDonations: totalDonations ?? this.totalDonations,
      totalReservations: totalReservations ?? this.totalReservations,
      totalKgDonated: totalKgDonated ?? this.totalKgDonated,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: $role)';
  }
}