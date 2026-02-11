import 'package:lunara/services/supabase_service.dart';

class EntitlementsService {
  final _client = SupabaseService().client;

  Future<List<Map<String, dynamic>>> fetchEntitlements({String? userId}) async {
    final uid = userId ?? SupabaseService().currentUser?.id;
    if (uid == null) return [];

    final resp = await _client
        .from('entitlements')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    if (resp == null) return [];

    // When using Supabase Dart client, `.select()` returns List<dynamic>
    return List<Map<String, dynamic>>.from(resp as List<dynamic>);
  }
}
