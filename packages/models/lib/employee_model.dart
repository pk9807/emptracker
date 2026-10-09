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

  EmployeeModel copyWith({
    String? id,
    String? userId,
    String? organizationId,
    String? name,
    String? employeeCode,
    String? phone,
    String? email,
    String? photoUrl,
    String? designation,
    String? department,
    bool? active,
    DutyStatus? trackingStatus,
    Map<String, dynamic>? lastLocation,
    DateTime? lastLocationAt,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      employeeCode: employeeCode ?? this.employeeCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      active: active ?? this.active,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      lastLocation: lastLocation ?? this.lastLocation,
      lastLocationAt: lastLocationAt ?? this.lastLocationAt,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
    final rawId = documentId ?? map['id']?.toString() ?? '';
    final rawUserId = (map['userId'] ?? map['user_id'] ?? map['id'])?.toString() ?? '';
    final rawOrgId = (map['organizationId'] ?? map['organization_id'])?.toString() ?? 'org_1';
    final rawCode = (map['employeeCode'] ?? map['employee_code'])?.toString() ?? '';
    final rawName = (map['name'])?.toString() ?? '';
    final rawPhone = (map['phone'])?.toString() ?? '';
    final rawEmail = (map['email'])?.toString() ?? '';
    final rawPhoto = (map['photoUrl'] ?? map['avatar']) as String?;
    final rawDesig = (map['designation'])?.toString() ?? 'Field Officer';
    final rawDept = (map['department'])?.toString() ?? 'Operations';
    final rawActive = map['active'] as bool? ?? map['is_active'] as bool? ?? true;
    final isOnDuty = map['is_on_duty'] == true || map['trackingStatus'] == 'ACTIVE' || map['status'] == 'ON_DUTY';

    return EmployeeModel(
      id: rawId,
      userId: rawUserId,
      organizationId: rawOrgId,
      name: rawName,
      employeeCode: rawCode,
      phone: rawPhone,
      email: rawEmail,
      photoUrl: rawPhoto,
      designation: rawDesig,
      department: rawDept,
      active: rawActive,
      trackingStatus: isOnDuty ? DutyStatus.active : DutyStatus.inactive,
      lastLocation: map['lastLocation'] as Map<String, dynamic>? ?? map['live_location'] as Map<String, dynamic>?,
      lastLocationAt: map['lastLocationAt'] != null
          ? DateTime.tryParse(map['lastLocationAt'].toString())
          : (map['live_location'] != null && map['live_location']['last_ping_at'] != null)
              ? DateTime.tryParse(map['live_location']['last_ping_at'].toString())
              : null,
      deviceId: map['deviceId']?.toString(),
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
