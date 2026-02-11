import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User, Session;
import 'package:lunara/services/supabase_service.dart';

/// Test helpers for registering platform channel mocks and creating
/// simple fake `User`/`Session` objects for tests.

void registerDefaultTestChannelMocks() {
  // path_provider mock
  const MethodChannel pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  // Use dynamic call to avoid analyzer issues in environments where the
  // test API isn't available at analysis time.
  (pathProvider as dynamic).setMockMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'getApplicationSupportDirectory':
      case 'getApplicationDocumentsDirectory':
      case 'getTemporaryDirectory':
        return Directory.systemTemp.path;
      default:
        return null;
    }
  });

  // flutter_secure_storage mock
  const MethodChannel secureStorage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> store = <String, String>{};
  (secureStorage as dynamic).setMockMethodCallHandler((MethodCall call) async {
    final args = call.arguments as Map<dynamic, dynamic>?;
    switch (call.method) {
      case 'read':
        return store[args?['key'] as String];
      case 'write':
        store[args?['key'] as String] = args?['value'] as String;
        return null;
      case 'delete':
        store.remove(args?['key'] as String);
        return null;
      case 'readAll':
        return store;
      case 'deleteAll':
        store.clear();
        return null;
      default:
        return null;
    }
  });
}

/// Create a minimal fake `User` object compatible with `supabase_flutter`'s
/// `User` shape used in the app. Tests typically only read `id`, `email`,
/// and `createdAt`.
dynamic createFakeUser({String? id, String? email}) {
  final Map<String, dynamic> data = {
    'id': id ?? 'test-user-id',
    'email': email ?? 'test@example.com',
    'created_at': DateTime.now().toIso8601String(),
    'email_confirmed_at': DateTime.now().toIso8601String(),
    'aud': 'authenticated',
    'app_metadata': {'provider': 'email'},
    'user_metadata': {'test_meta': true},
    'phone': null,
  };

  return User.fromJson(data);
}

/// Create a minimal fake `Session` object. The app often reads `.user` and
/// `.accessToken` at most. Produces a `Session` constructed from JSON.
dynamic createFakeSession({dynamic user}) {
  final u = user ?? createFakeUser();
  final Map<String, dynamic> data = {
    'access_token': 'fake-access-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    'refresh_token': 'fake-refresh-token',
    'user': u.toJson(),
  };
  return (Session.fromJson(data) as dynamic);
}

/// Convenience: register mocks and set a fake authenticated session
/// on `SupabaseService` so tests see an authenticated user by default.
void bootstrapTestAuth({String? userId, String? email}) {
  registerDefaultTestChannelMocks();
  final user = createFakeUser(id: userId, email: email);
  final session = createFakeSession(user: user);
  SupabaseService.setTestAuth(user: user, session: session);
}

/// Clear the test auth (simulate signed out)
void clearTestAuth() {
  SupabaseService.setTestAuth(user: null, session: null);
}
