import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

class VisitLocationProof extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double distanceFromShop; // in meters

  const VisitLocationProof({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distanceFromShop,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'distanceFromShop': distanceFromShop,
    };
  }

  factory VisitLocationProof.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const VisitLocationProof(
        latitude: 0.0,
        longitude: 0.0,
        accuracy: 0.0,
        distanceFromShop: 0.0,
      );
    }
    return VisitLocationProof(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      distanceFromShop:
          (map['distanceFromShop'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props =>
      [latitude, longitude, accuracy, distanceFromShop];
}

class VisitWatermarkMetadata extends Equatable {
  final bool applied;
  final String? timestamp;
  final String? gpsText;

  const VisitWatermarkMetadata({
    this.applied = false,
    this.timestamp,
    this.gpsText,
  });

  Map<String, dynamic> toMap() {
    return {
      'applied': applied,
      'timestamp': timestamp,
      'gpsText': gpsText,
    };
  }

  factory VisitWatermarkMetadata.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const VisitWatermarkMetadata();
    return VisitWatermarkMetadata(
      applied: map['applied'] as bool? ?? false,
      timestamp: map['timestamp'] as String?,
      gpsText: map['gpsText'] as String?,
    );
  }

  @override
  List<Object?> get props => [applied, timestamp, gpsText];
}

class VisitModel extends Equatable {
  final String id;
  final String organizationId;
  final String employeeId;
  final String employeeName;
  final String shopId;
  final String shopName;
  final DateTime checkInTime;
  final VisitLocationProof checkInLocation;
  final DateTime? checkOutTime;
  final VisitLocationProof? checkOutLocation;
  final int durationMinutes;
  final String? photoUrl;
  final String? thumbnailUrl;
  final String? localPhotoPath;
  final VisitWatermarkMetadata watermarkData;
  final String? notes;
  final double? orderValue;
  final VisitStatus status;
  final bool isOfflineSynced;
  final DateTime? syncTimestamp;

  const VisitModel({
    required this.id,
    required this.organizationId,
    required this.employeeId,
    required this.employeeName,
    required this.shopId,
    required this.shopName,
    required this.checkInTime,
    required this.checkInLocation,
    this.checkOutTime,
    this.checkOutLocation,
    this.durationMinutes = 0,
    this.photoUrl,
    this.thumbnailUrl,
    this.localPhotoPath,
    this.watermarkData = const VisitWatermarkMetadata(),
    this.notes,
    this.orderValue,
    this.status = VisitStatus.checkedIn,
    this.isOfflineSynced = true,
    this.syncTimestamp,
  });

  bool get isCompleted => status == VisitStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'shopId': shopId,
      'shopName': shopName,
      'checkInTime': checkInTime.toIso8601String(),
      'checkInLocation': checkInLocation.toMap(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkOutLocation': checkOutLocation?.toMap(),
      'durationMinutes': durationMinutes,
      'photoUrl': photoUrl,
      'thumbnailUrl': thumbnailUrl,
      'localPhotoPath': localPhotoPath,
      'watermarkData': watermarkData.toMap(),
      'notes': notes,
      'orderValue': orderValue,
      'status': status.value,
      'isOfflineSynced': isOfflineSynced,
      'syncTimestamp': syncTimestamp?.toIso8601String(),
    };
  }

  factory VisitModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return VisitModel(
      id: documentId ?? map['id'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      checkInTime: map['checkInTime'] != null
          ? DateTime.tryParse(map['checkInTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      checkInLocation: VisitLocationProof.fromMap(
          map['checkInLocation'] as Map<String, dynamic>?),
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.tryParse(map['checkOutTime'].toString())
          : null,
      checkOutLocation: map['checkOutLocation'] != null
          ? VisitLocationProof.fromMap(
              map['checkOutLocation'] as Map<String, dynamic>?)
          : null,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      photoUrl: map['photoUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      localPhotoPath: map['localPhotoPath'] as String?,
      watermarkData: VisitWatermarkMetadata.fromMap(
          map['watermarkData'] as Map<String, dynamic>?),
      notes: map['notes'] as String?,
      orderValue: (map['orderValue'] as num?)?.toDouble(),
      status: VisitStatus.fromString(map['status'] as String?),
      isOfflineSynced: map['isOfflineSynced'] as bool? ?? true,
      syncTimestamp: map['syncTimestamp'] != null
          ? DateTime.tryParse(map['syncTimestamp'].toString())
          : null,
    );
  }

  VisitModel copyWith({
    String? id,
    String? organizationId,
    String? employeeId,
    String? employeeName,
    String? shopId,
    String? shopName,
    DateTime? checkInTime,
    VisitLocationProof? checkInLocation,
    DateTime? checkOutTime,
    VisitLocationProof? checkOutLocation,
    int? durationMinutes,
    String? photoUrl,
    String? thumbnailUrl,
    String? localPhotoPath,
    VisitWatermarkMetadata? watermarkData,
    String? notes,
    double? orderValue,
    VisitStatus? status,
    bool? isOfflineSynced,
    DateTime? syncTimestamp,
  }) {
    return VisitModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      photoUrl: photoUrl ?? this.photoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      watermarkData: watermarkData ?? this.watermarkData,
      notes: notes ?? this.notes,
      orderValue: orderValue ?? this.orderValue,
      status: status ?? this.status,
      isOfflineSynced: isOfflineSynced ?? this.isOfflineSynced,
      syncTimestamp: syncTimestamp ?? this.syncTimestamp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        employeeId,
        employeeName,
        shopId,
        shopName,
        checkInTime,
        checkInLocation,
        checkOutTime,
        checkOutLocation,
        durationMinutes,
        photoUrl,
        thumbnailUrl,
        localPhotoPath,
        watermarkData,
        notes,
        orderValue,
        status,
        isOfflineSynced,
        syncTimestamp,
      ];
}
