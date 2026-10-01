import 'dart:convert';
import 'package:models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String _userKey = 'cached_user_profile';
  static const String _employeeKey = 'cached_employee_profile';
  static const String _attendanceKey = 'cached_today_attendance';
  static const String _shopsKey = 'cached_assigned_shops';
  static const String _visitsKey = 'cached_offline_visits';

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveEmployee(EmployeeModel emp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employeeKey, jsonEncode(emp.toMap()));
  }

  Future<EmployeeModel?> getEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_employeeKey);
    if (raw == null) return null;
    return EmployeeModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveTodayAttendance(AttendanceModel attendance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attendanceKey, jsonEncode(attendance.toMap()));
  }

  Future<AttendanceModel?> getTodayAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attendanceKey);
    if (raw == null) return null;
    return AttendanceModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveShops(List<ShopModel> shops) async {
    final prefs = await SharedPreferences.getInstance();
    final list = shops.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(_shopsKey, list);
  }

  Future<List<ShopModel>> getShops() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_shopsKey) ?? [];
    return list
        .map((s) => ShopModel.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveVisit(VisitModel visit) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_visitsKey) ?? [];
    list.add(jsonEncode(visit.toMap()));
    await prefs.setStringList(_visitsKey, list);
  }

  Future<List<VisitModel>> getOfflineVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_visitsKey) ?? [];
    return list
        .map((s) => VisitModel.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
