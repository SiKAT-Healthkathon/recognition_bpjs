import 'package:bpjs_recognition/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserServices {
  static SupabaseClient client = Supabase.instance.client;

  static Future<UserModel?> getUserData({required String nik}) async {
    try {
      // update status checkin

      final response =
          await client.from('users').select().eq('nik', nik).maybeSingle();

      if (response == null) {
        return null;
      }
      UserModel user = UserModel.fromJson(response);
      if (user.checkInAt == null) {
        await client
            .from('users')
            .update({'check_in_at': DateTime.now().toIso8601String()}).eq(
          'nik',
          user.nik,
        );
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }
}
