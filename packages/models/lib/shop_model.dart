import 'package:equatable/equatable.dart';

class ShopModel extends Equatable {
  final String id;
  final String organizationId;
  final String name;
  final String code;
  final String address;
  final double latitude;
  final double longitude;
  final double radius; // geofence radius in meters
  final String? contactPerson;
  final String? phone;
  final String status; // "ACTIVE" | "INACTIVE"
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    this.contactPerson,
    this.phone,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'ACTIVE';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'code': code,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'contactPerson': contactPerson,
      'phone': phone,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ShopModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ShopModel(
      id: documentId ?? map['id'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      radius: (map['radius'] as num?)?.toDouble() ?? 100.0,
      contactPerson: map['contactPerson'] as String?,
      phone: map['phone'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        name,
        code,
        address,
        latitude,
        longitude,
        radius,
        contactPerson,
        phone,
        status,
        createdAt,
        updatedAt,
      ];
}
