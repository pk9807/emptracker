import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

class LiveLocationModel extends Equatable {
  final String employeeId;
  final String organizationId;
  final String name;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final double altitude;
  final int battery;
  final String network;
  final bool isMockLocation;
  final DateTime updatedAt;

  const LiveLocationModel({
    required this.employeeId,
    required this.organizationId,
    required this.name,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed = 0.0,
    this.heading = 0.0,
    this.altitude = 0.0,
    required this.battery,
    this.network = 'CELLULAR',
    this.isMockLocation = false,
    required this.updatedAt,
  });

  TrackingLiveStatus get liveStatus => TrackingLiveStatus.compute(updatedAt);
  bool get isLive => liveStatus == TrackingLiveStatus.live;

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'organizationId': organizationId,
      'name': name,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'battery': battery,
      'network': network,
      'isMockLocation': isMockLocation,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LiveLocationModel.fromMap(Map<String, dynamic> map,
      {String? documentId}) {
    return LiveLocationModel(
      employeeId: documentId ?? map['employeeId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      battery: (map['battery'] as num?)?.toInt() ?? 100,
      network: map['network'] as String? ?? 'CELLULAR',
      isMockLocation: map['isMockLocation'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        employeeId,
        organizationId,
        name,
        photoUrl,
        latitude,
        longitude,
        accuracy,
        speed,
        heading,
        altitude,
        battery,
        network,
        isMockLocation,
        updatedAt,
      ];
}
