import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/subscription.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/services/subscription_service.dart';
import 'package:lunara/widgets/trial_banner.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late MockSubscriptionService mockService;

  setUp(() {
    mockService = MockSubscriptionService();
  });

  testWidgets('TrialBanner is hidden when no subscription', (tester) async {
    when(() => mockService.getCurrentSubscription())
        .thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TrialBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Banner should not be visible
    expect(find.text('Premium Trial Active'), findsNothing);
    expect(find.text('Trial ending soon!'), findsNothing);
    expect(find.byType(TrialBanner), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('TrialBanner is hidden when trial is not active',
      (tester) async {
    // Free subscription (no trial)
    final subscription = Subscription(
      id: 'sub-1',
      userId: 'user-1',
      tier: 'free',
      status: 'active',
      startsAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockService.getCurrentSubscription())
        .thenAnswer((_) async => subscription);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TrialBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Banner should not be visible
    expect(find.text('Premium Trial Active'), findsNothing);
  });

  testWidgets('TrialBanner shows normal state when trial has > 6 hours',
      (tester) async {
    // Trial with 24 hours remaining
    final subscription = Subscription(
      id: 'sub-1',
      userId: 'user-1',
      tier: 'premium',
      status: 'trial',
      trialStartsAt: DateTime.now(),
      trialEndsAt: DateTime.now().add(const Duration(hours: 24)),
      startsAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockService.getCurrentSubscription())
        .thenAnswer((_) async => subscription);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TrialBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Normal state should be visible
    expect(find.text('Premium Trial Active'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);

    // Should show remaining time
    expect(find.textContaining('remaining'), findsOneWidget);

    // Urgent state should NOT be visible
    expect(find.text('Trial ending soon!'), findsNothing);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
  });

  testWidgets('TrialBanner shows urgent state when trial has ≤ 6 hours',
      (tester) async {
    // Trial with 5 hours remaining
    final subscription = Subscription(
      id: 'sub-1',
      userId: 'user-1',
      tier: 'premium',
      status: 'trial',
      trialStartsAt: DateTime.now().subtract(const Duration(hours: 43)),
      trialEndsAt: DateTime.now().add(const Duration(hours: 5)),
      startsAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockService.getCurrentSubscription())
        .thenAnswer((_) async => subscription);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TrialBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Urgent state should be visible
    expect(find.text('Trial ending soon!'), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);

    // Normal state should NOT be visible
    expect(find.text('Premium Trial Active'), findsNothing);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
  });

  testWidgets('TrialBanner upgrade button is tappable', (tester) async {
    final subscription = Subscription(
      id: 'sub-1',
      userId: 'user-1',
      tier: 'premium',
      status: 'trial',
      trialStartsAt: DateTime.now(),
      trialEndsAt: DateTime.now().add(const Duration(hours: 24)),
      startsAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockService.getCurrentSubscription())
        .thenAnswer((_) async => subscription);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TrialBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify upgrade button exists and is a FilledButton.tonal
    expect(find.text('Upgrade'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('TrialBanner displays trial remaining time', (tester) async {
    final subscription = Subscription(
      id: 'sub-1',
      userId: 'user-1',
      tier: 'premium',
      status: 'trial',
      trialStartsAt: DateTime.now(),
      trialEndsAt: DateTime.now().add(const Duration(hours: 12)),
      startsAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockService.getCurrentSubscription())
        .thenAnswer((_) async => subscription);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TrialBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should display remaining time in hours
    expect(find.textContaining('h remaining'), findsOneWidget);
  });

  testWidgets('TrialBanner is hidden on error', (tester) async {
    when(() => mockService.getCurrentSubscription())
        .thenThrow(Exception('Error'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TrialBanner(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Banner should not be visible on error
    expect(find.text('Premium Trial Active'), findsNothing);
    expect(find.text('Trial ending soon!'), findsNothing);
  });
}
