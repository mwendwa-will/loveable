import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_helpers.dart';

/// Test initializer that runs before other tests to initialize Supabase.
/// This prevents tests from failing with "You must initialize the supabase instance"
/// when code calls `Supabase.instance`.
void main() {
  setUpAll(() async {
    // Use safe dummy values for tests. These do not contact a network by themselves;
    // they only initialize the Supabase client instance used by the app code.
    await Supabase.initialize(
      url: 'http://localhost',
      anonKey: 'test-anon-key',
    );

    // Register platform mocks and set a fake authenticated session
    // for tests (registers path_provider and secure storage mocks).
    bootstrapTestAuth(userId: 'test-user-1', email: 'test@example.com');
  });

  // A simple test to make sure the initializer file is executed by the test runner.
  test('test init - supabase instance available', () {
    expect(Supabase.instance, isNotNull);
  });
}

// No local fake user class needed; helpers produce real `User`/`Session` objects.
