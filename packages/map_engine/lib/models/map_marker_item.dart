import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

enum MarkerType { employee, shop, office, visitStop }

class MapMarkerItem extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final double latitude;
  final double longitude;
  final MarkerType type;
  final TrackingLiveStatus? liveStatus;
  final int? battery;
  final dynamic originalData;

  const MapMarkerItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.liveStatus,
    this.battery,
    this.originalData,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        latitude,
        longitude,
        type,
        liveStatus,
        battery,
      ];
}
