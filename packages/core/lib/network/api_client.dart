import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

const bool kIsWeb = bool.fromEnvironment('dart.library.js_util') || identical(0, 0.0);


class ApiResponse<T> {
  final bool isSuccess;
  final String? message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.isSuccess,
    this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin.startsWith('http')) {
          _baseUrl = '$origin/emptracker/backend/public/index.php/api';
        }
      } catch (_) {}
    }
  }

  String _baseUrl = AppConstants.apiBaseUrl;
  String? _authToken;

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers() {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  Future<ApiResponse<dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final res = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      return ApiResponse(isSuccess: false, message: e.toString(), statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final res = await http.post(
        uri,
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      return ApiResponse(isSuccess: false, message: e.toString(), statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final res = await http.put(
        uri,
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      return ApiResponse(isSuccess: false, message: e.toString(), statusCode: 500);
    }
  }

  Future<ApiResponse<dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final res = await http.delete(uri, headers: _headers()).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      return ApiResponse(isSuccess: false, message: e.toString(), statusCode: 500);
    }
  }

  ApiResponse<dynamic> _handleResponse(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResponse(
          isSuccess: true,
          message: decoded is Map ? decoded['message'] : null,
          data: decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded,
          statusCode: res.statusCode,
        );
      } else {
        final msg = decoded is Map && decoded.containsKey('message') ? decoded['message'] : 'Server error: ${res.statusCode}';
        return ApiResponse(
          isSuccess: false,
          message: msg.toString(),
          data: decoded,
          statusCode: res.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        isSuccess: res.statusCode >= 200 && res.statusCode < 300,
        message: res.body,
        statusCode: res.statusCode,
      );
    }
  }
}
