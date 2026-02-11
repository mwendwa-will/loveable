import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/services/entitlements_service.dart';

final entitlementsProvider = NotifierProvider<EntitlementsNotifier, List<Map<String, dynamic>>>(() {
  return EntitlementsNotifier();
});

class EntitlementsNotifier extends Notifier<List<Map<String, dynamic>>> {
  final EntitlementsService _service = EntitlementsService();

  @override
  List<Map<String, dynamic>> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    try {
      final items = await _service.fetchEntitlements();
      state = items;
    } catch (_) {
      // keep existing state on error
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  bool get isPremium {
    if (state.isEmpty) return false;
    return state.any((e) => e['is_active'] == true);
  }
}
