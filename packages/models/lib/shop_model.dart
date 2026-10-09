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

  ShopModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? code,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    String? contactPerson,
    String? phone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
      id: documentId ?? map['id']?.toString() ?? '',
      organizationId: (map['organizationId'] ?? map['organization_id'])?.toString() ?? 'org_1',
      name: (map['name'])?.toString() ?? '',
      code: (map['code'] ?? map['qr_code'] ?? map['id'])?.toString() ?? '',
      address: (map['address'])?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      radius: (map['radius'] ?? map['geofence_radius_meters'] as num?)?.toDouble() ?? 100.0,
      contactPerson: (map['contactPerson'] ?? map['owner_name']) as String?,
      phone: (map['phone'])?.toString(),
      status: (map['status'])?.toString() ?? 'ACTIVE',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : (map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : (map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now()),
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
