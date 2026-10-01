import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

class AssignmentModel extends Equatable {
  final String id;
  final String organizationId;
  final String employeeId;
  final String shopId;
  final AssignmentPriority priority;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // "PENDING" | "VISITED" | "MISSED" | "CANCELLED"
  final String? assignedBy;

  const AssignmentModel({
    required this.id,
    required this.organizationId,
    required this.employeeId,
    required this.shopId,
    this.priority = AssignmentPriority.medium,
    required this.startDate,
    required this.endDate,
    this.status = 'PENDING',
    this.assignedBy,
  });

  bool get isVisited => status == 'VISITED';
  bool get isPending => status == 'PENDING';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'employeeId': employeeId,
      'shopId': shopId,
      'priority': priority.value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'assignedBy': assignedBy,
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map,
      {String? documentId}) {
    return AssignmentModel(
      id: documentId ?? map['id'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      priority: AssignmentPriority.fromString(map['priority'] as String?),
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] as String? ?? 'PENDING',
      assignedBy: map['assignedBy'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        employeeId,
        shopId,
        priority,
        startDate,
        endDate,
        status,
        assignedBy,
      ];
}
