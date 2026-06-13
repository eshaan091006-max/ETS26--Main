import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:malhar_ets/constants/supabase/credentials.dart';

void main() {
  testWidgets('Query Admins', (WidgetTester tester) async {
    await Supabase.initialize(
      url: SupabaseCredentials.url,
      anonKey: SupabaseCredentials.anonKey,
    );
    final client = Supabase.instance.client;
    try {
      final response = await client.from('admins').select();
      print("ADMINS_RESULT: $response");
    } catch (e) {
      print("Error querying admins: $e");
    }
  });
}
