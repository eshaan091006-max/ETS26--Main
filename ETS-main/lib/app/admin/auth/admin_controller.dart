import 'package:supabase_flutter/supabase_flutter.dart';

class AdminController {
  static Future<Map<String, dynamic>> loginAsAdmin(
    String username,
    String password,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('admins')
          .select()
          .eq('username', username)
          .eq('password', password);

      if (response.isNotEmpty) {
        final adminData = response.first;
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
