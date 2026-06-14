import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:malhar_ets/shared/models/contingent.dart';

class SessionManager {
  static const String _keyUserType = 'user_type'; // 'admin' or 'contingent'
  static const String _keyAdminUsername = 'admin_username';
  static const String _keyAdminIsVolunteer = 'admin_is_volunteer';
  static const String _keyContingentJson = 'contingent_json';

  // Save Admin Session
  static Future<void> saveAdminSession(String username, bool isVolunteer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserType, 'admin');
    await prefs.setString(_keyAdminUsername, username);
    await prefs.setBool(_keyAdminIsVolunteer, isVolunteer);
  }

  // Save Contingent Session
  static Future<void> saveContingentSession(Contingent contingent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserType, 'contingent');
    await prefs.setString(_keyContingentJson, jsonEncode(contingent.toJson()));
  }

  // Clear Session (Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyAdminUsername);
    await prefs.remove(_keyAdminIsVolunteer);
    await prefs.remove(_keyContingentJson);
  }

  // Get Session Details
  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userType = prefs.getString(_keyUserType);
    if (userType == null) return null;

    if (userType == 'admin') {
      final username = prefs.getString(_keyAdminUsername);
      final isVolunteer = prefs.getBool(_keyAdminIsVolunteer) ?? false;
      if (username != null) {
        return {
          'type': 'admin',
          'username': username,
          'is_volunteer': isVolunteer,
        };
      }
    } else if (userType == 'contingent') {
      final contingentJson = prefs.getString(_keyContingentJson);
      if (contingentJson != null) {
        try {
          final contingent = Contingent.fromJson(jsonDecode(contingentJson));
          return {
            'type': 'contingent',
            'contingent': contingent,
          };
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }
}
