import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lovely/services/supabase_service.dart';

// 1. Create a tiny fake SupabaseClient that only exposes `auth`.
class FakeSupabaseClient implements SupabaseClient {
  @override
  final GoTrueClient auth;
  FakeSupabaseClient(this.auth);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SupabaseService with mock', () {
    late SupabaseClient mockClient;
    late FakeGoTrueClient mockAuth;
    late SupabaseService service;

    setUp(() {
      mockAuth = FakeGoTrueClient();
      mockClient = FakeSupabaseClient(mockAuth);
      // Inject the fake client into the service for testing
      service = SupabaseService.forTest(mockClient);
    });

    test('calls getUser on the mock client', () async {
      // Arrange: set up mock behavior
      // Act
      final user = service.currentUser;

      // Assert
      expect(user, isNull);
    });
  });
}
