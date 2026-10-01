import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

class EmployeeModel extends Equatable {
  final String id;
  final String userId;
  final String organizationId;
  final String name;
  final String employeeCode;
  final String phone;
  final String email;
  final String? photoUrl;
  final String designation;
  final String department;
  final bool active;
  final DutyStatus trackingStatus;
  final Map<String, dynamic>? lastLocation;
  final DateTime? lastLocationAt;
  final String? deviceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmployeeModel({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.name,
    required this.employeeCode,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.designation,
    required this.department,
    this.active = true,
    this.trackingStatus = DutyStatus.inactive,
    this.lastLocation,
    this.lastLocationAt,
    this.deviceId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isWorking => trackingStatus == DutyStatus.active;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'name': name,
      'employeeCode': employeeCode,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'designation': designation,
      'department': department,
      'active': active,
      'trackingStatus': trackingStatus.value,
      'lastLocation': lastLocation,
      'lastLocationAt': lastLocationAt?.toIso8601String(),
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map,
      {String? documentId}) {
    return EmployeeModel(
      id: documentId ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      employeeCode: map['employeeCode'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      designation: map['designation'] as String? ?? '',
      department: map['department'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      trackingStatus: DutyStatus.fromString(map['trackingStatus'] as String?),
      lastLocation: map['lastLocation'] as Map<String, dynamic>?,
      lastLocationAt: map['lastLocationAt'] != null
          ? DateTime.tryParse(map['lastLocationAt'].toString())
          : null,
      deviceId: map['deviceId'] as String?,
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
        userId,
        organizationId,
        name,
        employeeCode,
        phone,
        email,
        photoUrl,
        designation,
        department,
        active,
        trackingStatus,
        lastLocation,
        lastLocationAt,
        deviceId,
        createdAt,
        updatedAt,
      ];
}
