import 'package:equatable/equatable.dart';

class DeviceModel extends Equatable {
  final String id;
  final String employeeId;
  final String organizationId;
  final String deviceName;
  final String platform;
  final String appVersion;
  final int battery;
  final String? fcmToken;
  final DateTime lastSeen;
  final bool isActive;

  const DeviceModel({
    required this.id,
    required this.employeeId,
    required this.organizationId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    required this.battery,
    this.fcmToken,
    required this.lastSeen,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'organizationId': organizationId,
      'deviceName': deviceName,
      'platform': platform,
      'appVersion': appVersion,
      'battery': battery,
      'fcmToken': fcmToken,
      'lastSeen': lastSeen.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return DeviceModel(
      id: documentId ?? map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      platform: map['platform'] as String? ?? 'Android',
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      battery: (map['battery'] as num?)?.toInt() ?? 100,
      fcmToken: map['fcmToken'] as String?,
      lastSeen: map['lastSeen'] != null
          ? DateTime.tryParse(map['lastSeen'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        organizationId,
        deviceName,
        platform,
        appVersion,
        battery,
        fcmToken,
        lastSeen,
        isActive,
      ];
}
