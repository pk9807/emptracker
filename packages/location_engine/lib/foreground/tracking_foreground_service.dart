import 'dart:async';

class TrackingForegroundService {
  bool _isRunning = false;
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  bool get isRunning => _isRunning;
  Stream<bool> get isRunningStream => _statusController.stream;

  Future<void> startService({
    required String employeeName,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    _isRunning = true;
    _statusController.add(true);
  }

  Future<void> stopService() async {
    _isRunning = false;
    _statusController.add(false);
  }
}
