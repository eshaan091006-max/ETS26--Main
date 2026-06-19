import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/hash_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContingentController {
  static Future<Map<String, dynamic>> loginAsContingent(
    String username,
    String password,
  ) async {
    try {
      final hashedPassword = HashUtil.hashPassword(password);
      final response = await Supabase.instance.client.rpc(
        'login_contingent_rpc',
        params: {
          'input_code': username,
          'input_password': hashedPassword,
        },
      ) as List<dynamic>;

      if (response.isNotEmpty) {
        final contingentData = Map<String, dynamic>.from(response.first);
        
        // Set the custom JWT session for Supabase
        if (contingentData.containsKey('token') && contingentData['token'] != null) {
          await Supabase.instance.client.auth.setSession(contingentData['token']);
        }

        return {
          "success": true,
          "message": 'Contingent Login Successful for $username!',
          "contingent": Contingent.fromJson(contingentData),
        };
      } else {
        return {"success": false, "message": "Invalid Contingent Credentials!"};
      }
    } catch (e) {
      return {"success": false, "message": "Login failed: $e"};
    }
  }
}
