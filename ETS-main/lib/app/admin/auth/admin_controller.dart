import 'package:supabase_flutter/supabase_flutter.dart';

class AdminController {
  static Future<Map<String, dynamic>> loginAsAdmin(
    String username,
    String password,
  ) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'login_admin_rpc',
        params: {
          'input_username': username,
          'input_password': password,
        },
      ) as List<dynamic>;

      if (response.isNotEmpty) {
        final adminData = Map<String, dynamic>.from(response.first);
        return {
          "success": true,
          "message": 'Admin Login Successful for $username!',
          "is_volunteer": adminData['is_volunteer'] ?? false,
        };
      } else {
        return {"success": false, "message": "Invalid Admin Credentials!"};
      }
    } catch (e) {
      return {"success": false, "message": "Login failed: $e"};
    }
  }
}
