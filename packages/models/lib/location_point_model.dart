import 'package:equatable/equatable.dart';

class LocationPointModel extends Equatable {
  final String id;
  final String employeeId;
  final String organizationId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final double altitude;
  final int battery;
  final String dateKey;
  final bool isMocked;
  final bool isSuspicious;
  final DateTime timestamp;
  final DateTime createdAt;

  const LocationPointModel({
    required this.id,
    required this.employeeId,
    required this.organizationId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed = 0.0,
    this.heading = 0.0,
    this.altitude = 0.0,
    required this.battery,
    required this.dateKey,
    this.isMocked = false,
    this.isSuspicious = false,
    required this.timestamp,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'organizationId': organizationId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'battery': battery,
      'dateKey': dateKey,
      'isMocked': isMocked,
      'isSuspicious': isSuspicious,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LocationPointModel.fromMap(Map<String, dynamic> map,
      {String? documentId}) {
    return LocationPointModel(
      id: documentId ?? map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      battery: (map['battery'] as num?)?.toInt() ?? 100,
      dateKey: map['dateKey'] as String? ?? '',
      isMocked: map['isMocked'] as bool? ?? false,
      isSuspicious: map['isSuspicious'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        organizationId,
        latitude,
        longitude,
        accuracy,
        speed,
        heading,
        altitude,
        battery,
        dateKey,
        isMocked,
        isSuspicious,
        timestamp,
        createdAt,
      ];
}
