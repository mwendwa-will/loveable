import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/models/subscription.dart';
import 'package:lunara/services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Premium features available for subscription
enum PremiumFeature {
  editCycleSettings,
  unlimitedHistory,
  advancedInsights,
  exportReports,
  customAffirmations,
  adFree,
}

/// Provides the SubscriptionService instance
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Manages the current subscription state
final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(
  SubscriptionNotifier.new,
);

/// Provides available subscription packages
final offeringsProvider = FutureProvider<List<SubscriptionPackage>>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return await service.getOfferings();
});

/// Checks if a specific premium feature is available
final featureGateProvider =
    Provider.family<bool, PremiumFeature>((ref, feature) {
  final subscription = ref.watch(subscriptionProvider).value;
  return subscription?.hasFullAccess ?? false;
});

/// Checks if user has premium access
final isPremiumProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider).value;
  return subscription?.hasFullAccess ?? false;
});

/// Returns remaining hours in trial
final trialHoursRemainingProvider = Provider<int>((ref) {
  final subscription = ref.watch(subscriptionProvider).value;
  return subscription?.trialHoursRemaining ?? 0;
});

/// Returns human-readable trial remaining display
final trialRemainingDisplayProvider = Provider<String>((ref) {
  final subscription = ref.watch(subscriptionProvider).value;
  return subscription?.trialRemainingDisplay ?? '';
});

/// Notifier for subscription state management
class SubscriptionNotifier extends AsyncNotifier<Subscription?> {
  @override
  Future<Subscription?> build() async {
    final service = ref.watch(subscriptionServiceProvider);
    return await service.getCurrentSubscription();
  }

  /// Purchase a subscription package
  Future<void> purchase(Package package) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(subscriptionServiceProvider);
      return await service.purchasePackage(package);
    });
  }

  /// Start the 48-hour free trial
  Future<void> startFreeTrial() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(subscriptionServiceProvider);
      return await service.startFreeTrial();
    });
  }

  /// Restore previous purchases
  Future<void> restore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(subscriptionServiceProvider);
      return await service.restorePurchases();
    });
  }

  /// Refresh subscription from source
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(subscriptionServiceProvider);
      return await service.getCurrentSubscription();
    });
  }
}
