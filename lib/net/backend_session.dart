import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Session state served by the web backend (`/api/session`).
///
/// The Pixiv token itself never reaches the browser; the backend keeps it and
/// injects it into the `/pixiv-api` proxy requests.
class BackendSession {
  static Map<String, dynamic>? data;

  static bool get authenticated => data?['authenticated'] == true;
  static bool get configured => data?['configured'] == true;
  static Map<String, dynamic>? get user {
    final value = data?['user'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Future<bool> load() async {
    if (!kIsWeb) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: '')).get('/api/session');
      final body = response.data;
      data = body is Map ? Map<String, dynamic>.from(body) : null;
    } catch (_) {
      data = null;
    }
    return authenticated;
  }

  static Future<void> logout() async {
    if (!kIsWeb) return;
    try {
      await Dio(BaseOptions(baseUrl: '')).post('/api/logout');
    } catch (_) {}
    data = null;
  }
}
