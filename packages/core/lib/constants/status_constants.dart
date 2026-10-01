enum UserRole {
  superAdmin('super_admin'),
  admin('admin'),
  manager('manager'),
  employee('employee');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? val) {
    return UserRole.values.firstWhere(
      (e) => e.value == val,
      orElse: () => UserRole.employee,
    );
  }
}

enum TrackingLiveStatus {
  live('LIVE'),
  recent('RECENT'),
  stale('STALE'),
  offline('OFFLINE');

  final String label;
  const TrackingLiveStatus(this.label);

  static TrackingLiveStatus compute(DateTime? lastUpdated, {DateTime? now}) {
    if (lastUpdated == null) return TrackingLiveStatus.offline;
    final currentTime = now ?? DateTime.now();
    final diffSec = currentTime.difference(lastUpdated).inSeconds;

    if (diffSec <= 60) return TrackingLiveStatus.live;
    if (diffSec <= 300) return TrackingLiveStatus.recent;
    if (diffSec <= 900) return TrackingLiveStatus.stale;
    return TrackingLiveStatus.offline;
  }
}

enum DutyStatus {
  active('DUTY_ACTIVE'),
  inactive('DUTY_INACTIVE'),
  paused('PAUSED');

  final String value;
  const DutyStatus(this.value);

  static DutyStatus fromString(String? val) {
    return DutyStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DutyStatus.inactive,
    );
  }
}

enum VisitStatus {
  checkedIn('CHECKED_IN'),
  completed('COMPLETED'),
  flagged('FLAGGED'),
  cancelled('CANCELLED');

  final String value;
  const VisitStatus(this.value);

  static VisitStatus fromString(String? val) {
    return VisitStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => VisitStatus.checkedIn,
    );
  }
}

enum AssignmentPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH'),
  urgent('URGENT');

  final String value;
  const AssignmentPriority(this.value);

  static AssignmentPriority fromString(String? val) {
    return AssignmentPriority.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AssignmentPriority.medium,
    );
  }
}
