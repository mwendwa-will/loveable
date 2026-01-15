// ignore_for_file: file_names

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_helpers.dart';

/// Test initializer that runs before other tests to initialize Supabase.
/// Named with leading zeros so test runner runs it early.
void main() {
  setUpAll(() async {
    // Register platform-channel mocks and test auth helpers early
    bootstrapTestAuth();

    await Supabase.initialize(
      url: 'http://localhost',
      anonKey: 'test-anon-key',
    );
  });

  test('test init - supabase instance available', () {
    expect(Supabase.instance, isNotNull);
  });
}
