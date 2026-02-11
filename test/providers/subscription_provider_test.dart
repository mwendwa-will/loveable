import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/subscription.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/services/subscription_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockPackage extends Mock implements Package {}

void main() {
  late MockSubscriptionService mockService;

  setUp(() {
    mockService = MockSubscriptionService();
  });

  group('PremiumFeature enum', () {
    test('has all expected features', () {
      expect(PremiumFeature.values.length, 6);
      expect(PremiumFeature.values, contains(PremiumFeature.editCycleSettings));
      expect(PremiumFeature.values, contains(PremiumFeature.unlimitedHistory));
      expect(PremiumFeature.values, contains(PremiumFeature.advancedInsights));
      expect(PremiumFeature.values, contains(PremiumFeature.exportReports));
      expect(
          PremiumFeature.values, contains(PremiumFeature.customAffirmations));
      expect(PremiumFeature.values, contains(PremiumFeature.adFree));
    });
  });

  group('subscriptionServiceProvider', () {
    test('creates SubscriptionService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(subscriptionServiceProvider);
      expect(service, isA<SubscriptionService>());
    });
  });

  group('subscriptionProvider', () {
    test('loads subscription on build', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = await container.read(subscriptionProvider.future);
      expect(asyncValue, subscription);
      verify(() => mockService.getCurrentSubscription()).called(1);
    });

    test('purchase calls service and updates state', () async {
      final mockPackage = MockPackage();
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
          .thenAnswer((_) async => null);
      when(() => mockService.purchasePackage(mockPackage))
          .thenAnswer((_) async => subscription);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(subscriptionProvider.future);

      // Trigger purchase
      await container
          .read(subscriptionProvider.notifier)
          .purchase(mockPackage);

      final result = container.read(subscriptionProvider).value;
      expect(result, subscription);
      verify(() => mockService.purchasePackage(mockPackage)).called(1);
    });

    test('startFreeTrial calls service and updates state', () async {
      final subscription = Subscription(
        id: 'sub-1',
        userId: 'user-1',
        tier: 'premium',
        status: 'trial',
        trialStartsAt: DateTime.now(),
        trialEndsAt: DateTime.now().add(const Duration(hours: 48)),
        startsAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockService.getCurrentSubscription())
          .thenAnswer((_) async => null);
      when(() => mockService.startFreeTrial())
          .thenAnswer((_) async => subscription);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(subscriptionProvider.future);

      // Start trial
      await container.read(subscriptionProvider.notifier).startFreeTrial();

      final result = container.read(subscriptionProvider).value;
      expect(result, subscription);
      verify(() => mockService.startFreeTrial()).called(1);
    });

    test('restore calls service and updates state', () async {
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
          .thenAnswer((_) async => null);
      when(() => mockService.restorePurchases())
          .thenAnswer((_) async => subscription);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(subscriptionProvider.future);

      // Restore
      await container.read(subscriptionProvider.notifier).restore();

      final result = container.read(subscriptionProvider).value;
      expect(result, subscription);
      verify(() => mockService.restorePurchases()).called(1);
    });

    test('refresh reloads subscription from service', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Initial load
      await container.read(subscriptionProvider.future);

      // Refresh
      await container.read(subscriptionProvider.notifier).refresh();

      final result = container.read(subscriptionProvider).value;
      expect(result, subscription);
      // Called twice: once for build, once for refresh
      verify(() => mockService.getCurrentSubscription()).called(2);
    });
  });

  group('offeringsProvider', () {
    test('returns list of subscription packages', () async {
      final packages = [
        SubscriptionPackage(
          identifier: 'monthly',
          title: 'Monthly',
          description: 'Monthly subscription',
          price: '\$4.99',
          priceAmount: 4.99,
          billingCycle: 'monthly',
          package: MockPackage(),
        ),
        SubscriptionPackage(
          identifier: 'yearly',
          title: 'Yearly',
          description: 'Yearly subscription',
          price: '\$39.99',
          priceAmount: 39.99,
          billingCycle: 'yearly',
          package: MockPackage(),
        ),
      ];

      when(() => mockService.getOfferings()).thenAnswer((_) async => packages);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(offeringsProvider.future);
      expect(result, packages);
      expect(result.length, 2);
      verify(() => mockService.getOfferings()).called(1);
    });

    test('returns empty list when no offerings available', () async {
      when(() => mockService.getOfferings()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(offeringsProvider.future);
      expect(result, isEmpty);
    });
  });

  group('featureGateProvider', () {
    test('returns true when user has full access', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final hasFeature = container
          .read(featureGateProvider(PremiumFeature.editCycleSettings));
      expect(hasFeature, true);
    });

    test('returns false when user does not have access', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final hasFeature = container
          .read(featureGateProvider(PremiumFeature.editCycleSettings));
      expect(hasFeature, false);
    });

    test('returns false when subscription is null', () async {
      when(() => mockService.getCurrentSubscription())
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final hasFeature = container
          .read(featureGateProvider(PremiumFeature.editCycleSettings));
      expect(hasFeature, false);
    });

    test('returns true for active trial', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final hasFeature =
          container.read(featureGateProvider(PremiumFeature.unlimitedHistory));
      expect(hasFeature, true);
    });
  });

  group('isPremiumProvider', () {
    test('returns true for premium subscription', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final isPremium = container.read(isPremiumProvider);
      expect(isPremium, true);
    });

    test('returns false for free subscription', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final isPremium = container.read(isPremiumProvider);
      expect(isPremium, false);
    });
  });

  group('trialHoursRemainingProvider', () {
    test('returns correct hours remaining in trial', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final hoursRemaining = container.read(trialHoursRemainingProvider);
      expect(hoursRemaining, greaterThan(0));
      expect(hoursRemaining, lessThanOrEqualTo(24));
    });

    test('returns 0 when subscription is null', () async {
      when(() => mockService.getCurrentSubscription())
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final hoursRemaining = container.read(trialHoursRemainingProvider);
      expect(hoursRemaining, 0);
    });
  });

  group('trialRemainingDisplayProvider', () {
    test('returns correct display string for active trial', () async {
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

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final display = container.read(trialRemainingDisplayProvider);
      expect(display, isNotEmpty);
      expect(display, matches(RegExp(r'\d+h remaining')));
    });

    test('returns empty string when subscription is null', () async {
      when(() => mockService.getCurrentSubscription())
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for subscription to load
      await container.read(subscriptionProvider.future);

      final display = container.read(trialRemainingDisplayProvider);
      expect(display, '');
    });
  });
}
