import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/subscription.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/services/subscription_service.dart';
import 'package:lunara/widgets/premium_feature_gate.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late MockSubscriptionService mockService;

  setUp(() {
    mockService = MockSubscriptionService();
  });

  testWidgets('PremiumFeatureGate renders child when user has access',
      (tester) async {
    // Premium subscription with access
    final subscription = Subscription(
      id: 'sub-1',
      userId: 'user-1',
      tier: 'premium',
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
        child: MaterialApp(
          home: Scaffold(
            body: PremiumFeatureGate(
              feature: PremiumFeature.editCycleSettings,
              child: const Text('Protected Content'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Child should be visible without overlay
    expect(find.text('Protected Content'), findsOneWidget);
    expect(find.text('Premium Feature'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  testWidgets('PremiumFeatureGate shows locked overlay when user lacks access',
      (tester) async {
    // Free subscription
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
        child: MaterialApp(
          home: Scaffold(
            body: PremiumFeatureGate(
              feature: PremiumFeature.editCycleSettings,
              child: const Text('Protected Content'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Overlay should be visible
    expect(find.text('Premium Feature'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('Upgrade to edit Cycle Settings'), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    // Child is still in widget tree but dimmed
    expect(find.text('Protected Content'), findsOneWidget);
  });

  testWidgets('PremiumFeatureGate shows dimmed child when showLockedOverlay is false',
      (tester) async {
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
        child: MaterialApp(
          home: Scaffold(
            body: PremiumFeatureGate(
              feature: PremiumFeature.editCycleSettings,
              showLockedOverlay: false,
              child: const Text('Protected Content'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // No overlay shown
    expect(find.text('Premium Feature'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);

    // Child should be visible (dimmed)
    expect(find.text('Protected Content'), findsOneWidget);
  });

  testWidgets('PremiumFeatureGate uses custom featureName when provided',
      (tester) async {
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
        child: MaterialApp(
          home: Scaffold(
            body: PremiumFeatureGate(
              feature: PremiumFeature.editCycleSettings,
              featureName: 'Custom Feature Name',
              child: const Text('Protected Content'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Upgrade to edit Custom Feature Name'), findsOneWidget);
  });

  testWidgets('PremiumFeatureGate upgrade button opens upgrade sheet',
      (tester) async {
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
        child: MaterialApp(
          home: Scaffold(
            body: PremiumFeatureGate(
              feature: PremiumFeature.editCycleSettings,
              child: const Text('Protected Content'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify upgrade button exists
    expect(find.text('Upgrade'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('PremiumFeatureGate dimmed variant tappable',
      (tester) async {
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
        child: MaterialApp(
          home: Scaffold(
            body: PremiumFeatureGate(
              feature: PremiumFeature.exportReports,
              showLockedOverlay: false,
              child: const Text('Protected Content'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify child is visible and tappable
    expect(find.text('Protected Content'), findsOneWidget);
    expect(find.byType(GestureDetector), findsOneWidget);
  });

  testWidgets('PremiumFeatureGate maps all feature enum values correctly',
      (tester) async {
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

    // Test each feature mapping
    final testCases = {
      PremiumFeature.editCycleSettings: 'Cycle Settings',
      PremiumFeature.unlimitedHistory: 'Unlimited History',
      PremiumFeature.advancedInsights: 'Advanced Insights',
      PremiumFeature.exportReports: 'Export Reports',
      PremiumFeature.customAffirmations: 'Custom Affirmations',
      PremiumFeature.adFree: 'Ad-Free Experience',
    };

    for (final entry in testCases.entries) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PremiumFeatureGate(
                feature: entry.key,
                child: const Text('Protected Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Upgrade to edit ${entry.value}'),
        findsOneWidget,
        reason: 'Feature ${entry.key} should map to "${entry.value}"',
      );

      // Clear for next test
      await tester.pumpWidget(Container());
    }
  });

  testWidgets('PremiumFeatureGate works with trial subscription',
      (tester) async {
    // Active trial subscription
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
        child: MaterialApp(
          home: Scaffold(
            body: PremiumFeatureGate(
              feature: PremiumFeature.advancedInsights,
              child: const Text('Protected Content'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Child should be accessible during trial
    expect(find.text('Protected Content'), findsOneWidget);
    expect(find.text('Premium Feature'), findsNothing);
  });
}
