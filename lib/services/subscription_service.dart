import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lunara/models/subscription.dart';
import 'package:lunara/services/supabase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionPackage {
  final String identifier;
  final String title;
  final String description;
  final String price;
  final double priceAmount;
  final String billingCycle;
  final Package package;

  const SubscriptionPackage({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmount,
    required this.billingCycle,
    required this.package,
  });

  bool get isYearly => billingCycle == 'yearly';
  bool get isMonthly => billingCycle == 'monthly';
}

class SubscriptionService {
  static const _apiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: '',
  );
  static const _apiKeyIos = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: '',
  );
  static const _entitlementId = 'premium';

  final _supabase = SupabaseService().client;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> initialize() async {
    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? _apiKeyIos
        : _apiKeyAndroid;

    if (apiKey.isEmpty) {
      throw Exception('RevenueCat API key not configured');
    }

    final config = PurchasesConfiguration(apiKey);

    if (_userId != null) {
      config.appUserID = _userId;
    }

    await Purchases.configure(config);
  }

  Future<void> login(String userId) async {
    await Purchases.logIn(userId);
  }

  Future<void> logout() async {
    await Purchases.logOut();
  }

  Future<Subscription?> getCurrentSubscription() async {
    if (_userId == null) return null;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _mapCustomerInfoToSubscription(customerInfo);
    } catch (e) {
      return _getLocalSubscription();
    }
  }

  Future<List<SubscriptionPackage>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) return [];

      return current.availablePackages.map((pkg) {
        final billingCycle = _determineBillingCycle(pkg);
        return SubscriptionPackage(
          identifier: pkg.identifier,
          title: pkg.storeProduct.title,
          description: pkg.storeProduct.description,
          price: pkg.storeProduct.priceString,
          priceAmount: pkg.storeProduct.price,
          billingCycle: billingCycle,
          package: pkg,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Subscription?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final subscription = _mapCustomerInfoToSubscription(result);

      if (subscription != null && subscription.isPremium) {
        await _syncToSupabase(subscription);
      }

      return subscription;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return null;
      }
      rethrow;
    }
  }

  Future<Subscription?> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final subscription = _mapCustomerInfoToSubscription(customerInfo);

      if (subscription != null && subscription.isPremium) {
        await _syncToSupabase(subscription);
      }

      return subscription;
    } catch (e) {
      rethrow;
    }
  }

  Future<Subscription> startFreeTrial() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final trialEnd = now.add(const Duration(hours: 48));

    final data = await _supabase
        .from('subscriptions')
        .update({
          'tier': 'premium',
          'status': 'trial',
          'trial_starts_at': now.toIso8601String(),
          'trial_ends_at': trialEnd.toIso8601String(),
        })
        .eq('user_id', _userId!)
        .inFilter('status', ['active'])
        .select()
        .single();

    return Subscription.fromJson(data);
  }

  Future<void> cancelSubscription() async {
    if (_userId == null) return;

    await _supabase
        .from('subscriptions')
        .update({'status': 'cancelled'})
        .eq('user_id', _userId!)
        .inFilter('status', ['active', 'trial']);
  }

  Subscription? _mapCustomerInfoToSubscription(CustomerInfo info) {
    if (_userId == null) return null;

    final entitlement = info.entitlements.all[_entitlementId];

    if (entitlement == null || !entitlement.isActive) {
      return Subscription(
        id: '',
        userId: _userId!,
        tier: 'free',
        status: 'active',
        startsAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final isTrial = entitlement.periodType == PeriodType.trial;
    final productId = entitlement.productIdentifier;
    final billingCycle = productId.contains('yearly') ? 'yearly' : 'monthly';

    return Subscription(
      id: productId,
      userId: _userId!,
      tier: 'premium',
      status: isTrial ? 'trial' : 'active',
      trialStartsAt: isTrial
          ? DateTime.parse(entitlement.originalPurchaseDate)
          : null,
      trialEndsAt: isTrial && entitlement.expirationDate != null
          ? DateTime.parse(entitlement.expirationDate!)
          : null,
      startsAt: DateTime.parse(entitlement.originalPurchaseDate),
      expiresAt: entitlement.expirationDate != null
          ? DateTime.parse(entitlement.expirationDate!)
          : null,
      billingCycle: billingCycle,
      paymentProvider: 'revenuecat',
      transactionId: productId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<Subscription?> _getLocalSubscription() async {
    if (_userId == null) return null;

    final data = await _supabase
        .from('subscriptions')
        .select()
        .eq('user_id', _userId!)
        .inFilter('status', ['active', 'trial'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return Subscription.fromJson(data);
  }

  Future<void> _syncToSupabase(Subscription subscription) async {
    await _supabase.from('subscriptions').upsert(
      {
        'user_id': _userId!,
        'tier': subscription.tier,
        'status': subscription.status,
        'trial_starts_at': subscription.trialStartsAt?.toIso8601String(),
        'trial_ends_at': subscription.trialEndsAt?.toIso8601String(),
        'starts_at': subscription.startsAt.toIso8601String(),
        'expires_at': subscription.expiresAt?.toIso8601String(),
        'billing_cycle': subscription.billingCycle,
        'payment_provider': 'revenuecat',
        'transaction_id': subscription.transactionId,
      },
      onConflict: 'user_id',
    );
  }

  String _determineBillingCycle(Package package) {
    if (package.packageType == PackageType.annual) return 'yearly';
    if (package.packageType == PackageType.monthly) return 'monthly';

    final identifier = package.identifier.toLowerCase();
    if (identifier.contains('year') || identifier.contains('annual')) {
      return 'yearly';
    }
    if (identifier.contains('month')) return 'monthly';

    return 'monthly';
  }
}
