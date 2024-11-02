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

      return user;
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> checkIn({required String nik}) async {
    try {
      final response = await client
          .from('reservations')
          .select('check_in_at, status, tanggal')
          .eq('nik', nik)
          .eq('status', 'Belum Datang')
          .order('tanggal', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        throw Exception(
            'Failed to fetch check-in time. Please try again later.');
      }

      final lastCheckInAt = response['check_in_at'] as String?;
      if (lastCheckInAt != null) {
        DateTime lastCheckInDateTime = DateTime.parse(lastCheckInAt);
        DateTime currentDateTime = DateTime.now();

        if (currentDateTime
            .isBefore(lastCheckInDateTime.add(const Duration(hours: 2)))) {
          return false;
        }
      }

      await client.from('reservations').update({
        'check_in_at': DateTime.now().toIso8601String(),
        'status': 'Check In'
      }).eq('nik', nik);

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
