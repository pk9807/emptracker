import 'package:equatable/equatable.dart';

class OrganizationSettings extends Equatable {
  final bool requirePhotoProof;
  final bool requireWatermark;
  final double geofenceRadiusDefault;
  final int dutyTrackingIntervalMoving;
  final int dutyTrackingIntervalStationary;
  final int staleThresholdSeconds;
  final int offlineThresholdSeconds;

  const OrganizationSettings({
    this.requirePhotoProof = true,
    this.requireWatermark = true,
    this.geofenceRadiusDefault = 100.0,
    this.dutyTrackingIntervalMoving = 20,
    this.dutyTrackingIntervalStationary = 60,
    this.staleThresholdSeconds = 300,
    this.offlineThresholdSeconds = 900,
  });

  Map<String, dynamic> toMap() {
    return {
      'requirePhotoProof': requirePhotoProof,
      'requireWatermark': requireWatermark,
      'geofenceRadiusDefault': geofenceRadiusDefault,
      'dutyTrackingIntervalMoving': dutyTrackingIntervalMoving,
      'dutyTrackingIntervalStationary': dutyTrackingIntervalStationary,
      'staleThresholdSeconds': staleThresholdSeconds,
      'offlineThresholdSeconds': offlineThresholdSeconds,
    };
  }

  factory OrganizationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const OrganizationSettings();
    return OrganizationSettings(
      requirePhotoProof: map['requirePhotoProof'] as bool? ?? true,
      requireWatermark: map['requireWatermark'] as bool? ?? true,
      geofenceRadiusDefault:
          (map['geofenceRadiusDefault'] as num?)?.toDouble() ?? 100.0,
      dutyTrackingIntervalMoving:
          (map['dutyTrackingIntervalMoving'] as num?)?.toInt() ?? 20,
      dutyTrackingIntervalStationary:
          (map['dutyTrackingIntervalStationary'] as num?)?.toInt() ?? 60,
      staleThresholdSeconds:
          (map['staleThresholdSeconds'] as num?)?.toInt() ?? 300,
      offlineThresholdSeconds:
          (map['offlineThresholdSeconds'] as num?)?.toInt() ?? 900,
    );
  }

  @override
  List<Object?> get props => [
        requirePhotoProof,
        requireWatermark,
        geofenceRadiusDefault,
        dutyTrackingIntervalMoving,
        dutyTrackingIntervalStationary,
        staleThresholdSeconds,
        offlineThresholdSeconds,
      ];
}

class OrganizationModel extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final OrganizationSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    this.settings = const OrganizationSettings(),
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'logoUrl': logoUrl,
      'settings': settings.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OrganizationModel.fromMap(Map<String, dynamic> map,
      {String? documentId}) {
    return OrganizationModel(
      id: documentId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      settings: OrganizationSettings.fromMap(
          map['settings'] as Map<String, dynamic>?),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, code, logoUrl, settings, createdAt, updatedAt];
}
