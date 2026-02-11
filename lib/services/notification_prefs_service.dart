import 'package:lunara/services/supabase_service.dart';

class NotificationPrefsService {
  static final NotificationPrefsService _instance = NotificationPrefsService._internal();
  factory NotificationPrefsService({SupabaseService? supabase}) => _instance;
  NotificationPrefsService._internal({SupabaseService? supabase}) : _supabase = supabase ?? SupabaseService();

  final SupabaseService _supabase;

  Future<Map<String, dynamic>?> getNotificationPreferencesData() => _supabase.getNotificationPreferencesData();

  Future<void> saveNotificationPreferencesData(Map<String, dynamic> data) => _supabase.saveNotificationPreferencesData(data);
}
