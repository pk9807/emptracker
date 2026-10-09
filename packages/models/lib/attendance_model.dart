import 'package:equatable/equatable.dart';

class AttendanceLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const AttendanceLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory AttendanceLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AttendanceLocation(latitude: 0.0, longitude: 0.0);
    return AttendanceLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String?,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class AttendanceModel extends Equatable {
  final String id;
  final String organizationId;
  final String employeeId;
  final String dateKey;
  final DateTime startTime;
  final AttendanceLocation startLocation;
  final DateTime? endTime;
  final AttendanceLocation? endLocation;
  final int workingDurationMinutes;
  final int totalVisitsCount;
  final double totalDistanceKm;
  final String status; // "WORKING" | "COMPLETED" | "HALF_DAY"

  const AttendanceModel({
    required this.id,
    required this.organizationId,
    required this.employeeId,
    required this.dateKey,
    required this.startTime,
    required this.startLocation,
    this.endTime,
    this.endLocation,
    this.workingDurationMinutes = 0,
    this.totalVisitsCount = 0,
    this.totalDistanceKm = 0.0,
    this.status = 'WORKING',
  });

  bool get isCompleted => status == 'COMPLETED';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'employeeId': employeeId,
      'dateKey': dateKey,
      'startTime': startTime.toIso8601String(),
      'startLocation': startLocation.toMap(),
      'endTime': endTime?.toIso8601String(),
      'endLocation': endLocation?.toMap(),
      'workingDurationMinutes': workingDurationMinutes,
      'totalVisitsCount': totalVisitsCount,
      'totalDistanceKm': totalDistanceKm,
      'status': status,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map,
      {String? documentId}) {
    final startLoc = map['startLocation'] != null
        ? AttendanceLocation.fromMap(map['startLocation'] as Map<String, dynamic>?)
        : AttendanceLocation(
            latitude: (map['check_in_lat'] as num?)?.toDouble() ?? 0.0,
            longitude: (map['check_in_lng'] as num?)?.toDouble() ?? 0.0,
            address: map['check_in_address'] as String?,
          );

    final endLoc = map['endLocation'] != null
        ? AttendanceLocation.fromMap(map['endLocation'] as Map<String, dynamic>?)
        : (map['check_out_lat'] != null
            ? AttendanceLocation(
                latitude: (map['check_out_lat'] as num?)?.toDouble() ?? 0.0,
                longitude: (map['check_out_lng'] as num?)?.toDouble() ?? 0.0,
                address: map['check_out_address'] as String?,
              )
            : null);

    return AttendanceModel(
      id: documentId ?? map['id']?.toString() ?? '',
      organizationId: (map['organizationId'] ?? map['organization_id'])?.toString() ?? 'org_1',
      employeeId: (map['employeeId'] ?? map['user_id'])?.toString() ?? '',
      dateKey: (map['dateKey'] ?? map['date'])?.toString() ?? '',
      startTime: map['startTime'] != null
          ? DateTime.tryParse(map['startTime'].toString()) ?? DateTime.now()
          : (map['check_in_time'] != null ? DateTime.tryParse(map['check_in_time'].toString()) ?? DateTime.now() : DateTime.now()),
      startLocation: startLoc,
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'].toString())
          : (map['check_out_time'] != null ? DateTime.tryParse(map['check_out_time'].toString()) : null),
      endLocation: endLoc,
      workingDurationMinutes: (map['workingDurationMinutes'] as num?)?.toInt() ?? 0,
      totalVisitsCount: (map['totalVisitsCount'] as num?)?.toInt() ?? 0,
      totalDistanceKm: ((map['totalDistanceKm'] ?? map['total_distance_km']) as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'WORKING',
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        employeeId,
        dateKey,
        startTime,
        startLocation,
        endTime,
        endLocation,
        workingDurationMinutes,
        totalVisitsCount,
        totalDistanceKm,
        status,
      ];
}
