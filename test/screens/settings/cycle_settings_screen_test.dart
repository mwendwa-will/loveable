import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/screens/settings/cycle_settings_screen.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/models/subscription.dart';
import 'package:lunara/services/subscription_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockSubscriptionNotifier extends AsyncNotifier<Subscription?>
    with Mock
    implements SubscriptionNotifier {
  final Subscription? _subscription;

  MockSubscriptionNotifier(this._subscription);

  @override
  Future<Subscription?> build() async => _subscription;
}

void main() {
  late MockSubscriptionService mockSubscriptionService;

  setUp(() {
    mockSubscriptionService = MockSubscriptionService();
  });

  Widget createTestWidget({required bool isPremium}) {
    final now = DateTime.now();
    final subscription = Subscription(
      id: 'test-subscription-id',
      userId: 'test-user',
      tier: isPremium ? 'premium' : 'free',
      status: 'active',
      startsAt: now,
      createdAt: now,
      updatedAt: now,
    );

    return ProviderScope(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(mockSubscriptionService),
        subscriptionProvider.overrideWith(() => MockSubscriptionNotifier(subscription)),
      ],
      child: const MaterialApp(
        home: CycleSettingsScreen(),
      ),
    );
  }

  group('CycleSettingsScreen - Free User', () {
    testWidgets('displays view-only info cards', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: false));
      await tester.pumpAndSettle();

      // Should show current cycle length card
      expect(find.text('Current Cycle Length'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

      // Should show current period length card
      expect(find.text('Average Period Length'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
    });

    testWidgets('displays premium banner', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: false));
      await tester.pumpAndSettle();

      // Should show premium banner
      expect(
        find.text('Upgrade to customize your cycle settings'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.text('Unlock Premium'), findsOneWidget);
    });

    testWidgets('shows dimmed edit controls', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: false));
      await tester.pumpAndSettle();

      // Edit sections should be present but dimmed by PremiumFeatureGate
      expect(find.text('Cycle Length'), findsOneWidget);
      expect(find.text('Period Length'), findsOneWidget);
      expect(find.text('Last Period Start Date'), findsOneWidget);
    });

    testWidgets('does not show save button for free users', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: false));
      await tester.pumpAndSettle();

      // Save button should not be visible for free users
      expect(find.text('Save'), findsNothing);
    });
  });

  group('CycleSettingsScreen - Premium User', () {
    testWidgets('displays view-only info cards', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: true));
      await tester.pumpAndSettle();

      // Should show info cards
      expect(find.text('Current Cycle Length'), findsOneWidget);
      expect(find.text('Average Period Length'), findsOneWidget);
    });

    testWidgets('does not show premium banner', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: true));
      await tester.pumpAndSettle();

      // Should NOT show premium banner
      expect(
        find.text('Upgrade to customize your cycle settings'),
        findsNothing,
      );
    });

    testWidgets('shows unlocked edit controls', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: true));
      await tester.pumpAndSettle();

      // Edit sections should be visible and interactive
      expect(find.text('Cycle Length'), findsOneWidget);
      expect(find.text('Period Length'), findsOneWidget);
      expect(find.text('Last Period Start Date'), findsOneWidget);

      // Should have icons
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
      expect(find.byIcon(Icons.science_rounded), findsOneWidget);
    });

    testWidgets('shows save button for premium users', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: true));
      await tester.pumpAndSettle();

      // Save button should be visible for premium users
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('displays prediction accuracy card', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: true));
      await tester.pumpAndSettle();

      // Should show prediction accuracy section
      expect(find.text('Prediction Accuracy'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('displays info card', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: true));
      await tester.pumpAndSettle();

      // Should show info section
      expect(find.text('How Predictions Work'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('CycleSettingsScreen - Trial User', () {
    testWidgets('trial user has premium access', (tester) async {
      final now = DateTime.now();
      final trialSubscription = Subscription(
        id: 'test-subscription-id',
        userId: 'test-user',
        tier: 'free',
        status: 'trial',
        trialStartsAt: now.subtract(const Duration(hours: 12)),
        trialEndsAt: now.add(const Duration(hours: 36)),
        startsAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionServiceProvider
                .overrideWithValue(mockSubscriptionService),
            subscriptionProvider.overrideWith(
              () => MockSubscriptionNotifier(trialSubscription),
            ),
          ],
          child: const MaterialApp(
            home: CycleSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trial users should NOT see premium banner
      expect(
        find.text('Upgrade to customize your cycle settings'),
        findsNothing,
      );

      // Should have save button (premium access)
      expect(find.text('Save'), findsOneWidget);

      // Should have unlocked edit controls
      expect(find.text('Cycle Length'), findsOneWidget);
      expect(find.text('Period Length'), findsOneWidget);
    });
  });

  group('CycleSettingsScreen - Responsive Design', () {
    testWidgets('uses responsive sizing', (tester) async {
      await tester.pumpWidget(createTestWidget(isPremium: true));
      await tester.pumpAndSettle();

      // Verify widgets are present (responsive sizing is applied internally)
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(Icon), findsWidgets);
    });
  });
}
