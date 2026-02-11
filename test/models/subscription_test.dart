import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models/subscription.dart';

void main() {
  group('Subscription Model', () {
    late DateTime now;
    late DateTime past;
    late DateTime future;

    setUp(() {
      now = DateTime.now();
      past = now.subtract(const Duration(days: 1));
      future = now.add(const Duration(hours: 24));
    });

    group('Constructor and Basic Properties', () {
      test('creates subscription with all required fields', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.id, 'sub-123');
        expect(subscription.userId, 'user-456');
        expect(subscription.tier, 'premium');
        expect(subscription.status, 'active');
        expect(subscription.startsAt, now);
        expect(subscription.createdAt, now);
        expect(subscription.updatedAt, now);
      });

      test('handles optional fields correctly', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
          trialStartsAt: past,
          trialEndsAt: future,
          expiresAt: future,
          billingCycle: 'monthly',
          paymentProvider: 'revenuecat',
          transactionId: 'txn-789',
        );

        expect(subscription.trialStartsAt, past);
        expect(subscription.trialEndsAt, future);
        expect(subscription.expiresAt, future);
        expect(subscription.billingCycle, 'monthly');
        expect(subscription.paymentProvider, 'revenuecat');
        expect(subscription.transactionId, 'txn-789');
      });
    });

    group('Tier Getters', () {
      test('isFree returns true for free tier', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'free',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isFree, true);
        expect(subscription.isPremium, false);
      });

      test('isPremium returns true for premium tier', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isPremium, true);
        expect(subscription.isFree, false);
      });
    });

    group('Status Getters', () {
      test('isActive returns true for active status', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isActive, true);
        expect(subscription.isTrial, false);
        expect(subscription.isExpired, false);
        expect(subscription.isCancelled, false);
      });

      test('isTrial returns true for trial status', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isTrial, true);
        expect(subscription.isActive, false);
      });

      test('isExpired returns true for expired status', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'free',
          status: 'expired',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isExpired, true);
        expect(subscription.isActive, false);
      });

      test('isCancelled returns true for cancelled status', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'cancelled',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isCancelled, true);
        expect(subscription.isActive, false);
      });
    });

    group('Trial Active Logic', () {
      test('isTrialActive returns true when trial is active and not expired', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past,
          trialEndsAt: future,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isTrialActive, true);
      });

      test('isTrialActive returns false when trial has expired', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past.subtract(const Duration(days: 3)),
          trialEndsAt: past,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isTrialActive, false);
      });

      test('isTrialActive returns false when status is not trial', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          trialStartsAt: past,
          trialEndsAt: future,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isTrialActive, false);
      });

      test('isTrialActive returns false when trialEndsAt is null', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.isTrialActive, false);
      });
    });

    group('Full Access Logic', () {
      test('hasFullAccess returns true for active premium subscription', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.hasFullAccess, true);
      });

      test('hasFullAccess returns true for active trial', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past,
          trialEndsAt: future,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.hasFullAccess, true);
      });

      test('hasFullAccess returns false for free subscription', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'free',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.hasFullAccess, false);
      });

      test('hasFullAccess returns false for expired subscription', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'expired',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.hasFullAccess, false);
      });

      test('hasFullAccess returns false for cancelled subscription', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'cancelled',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.hasFullAccess, false);
      });

      test('hasFullAccess returns false for expired trial', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past.subtract(const Duration(days: 3)),
          trialEndsAt: past,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.hasFullAccess, false);
      });
    });

    group('Trial Hours Remaining', () {
      test('returns correct hours when trial is active', () {
        final trialEnd = now.add(const Duration(hours: 36));
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past,
          trialEndsAt: trialEnd,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialHoursRemaining, inInclusiveRange(35, 36));
      });

      test('returns 0 when trial has expired', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past.subtract(const Duration(days: 3)),
          trialEndsAt: past,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialHoursRemaining, 0);
      });

      test('returns 0 when trialEndsAt is null', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialHoursRemaining, 0);
      });

      test('returns correct hours for trial ending in less than 1 hour', () {
        final trialEnd = now.add(const Duration(minutes: 30));
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past,
          trialEndsAt: trialEnd,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialHoursRemaining, 0);
      });
    });

    group('Trial Remaining Display', () {
      test('returns hours display when more than 1 hour remaining', () {
        final trialEnd = now.add(const Duration(hours: 23));
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past,
          trialEndsAt: trialEnd,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialRemainingDisplay, matches(r'^(22|23)h remaining$'));
      });

      test('returns minutes display when less than 1 hour remaining', () {
        final trialEnd = now.add(const Duration(minutes: 45));
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past,
          trialEndsAt: trialEnd,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialRemainingDisplay, contains('m remaining'));
        expect(subscription.trialRemainingDisplay, contains(RegExp(r'4[4-5]')));
      });

      test('returns "Expired" when trial has expired', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past.subtract(const Duration(days: 3)),
          trialEndsAt: past,
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialRemainingDisplay, 'Expired');
      });

      test('returns empty string when trialEndsAt is null', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(subscription.trialRemainingDisplay, '');
      });
    });

    group('JSON Serialization', () {
      test('fromJson creates subscription from valid JSON', () {
        final json = {
          'id': 'sub-123',
          'user_id': 'user-456',
          'tier': 'premium',
          'status': 'active',
          'trial_starts_at': past.toIso8601String(),
          'trial_ends_at': future.toIso8601String(),
          'starts_at': now.toIso8601String(),
          'expires_at': future.toIso8601String(),
          'billing_cycle': 'monthly',
          'payment_provider': 'revenuecat',
          'transaction_id': 'txn-789',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.id, 'sub-123');
        expect(subscription.userId, 'user-456');
        expect(subscription.tier, 'premium');
        expect(subscription.status, 'active');
        expect(subscription.billingCycle, 'monthly');
        expect(subscription.paymentProvider, 'revenuecat');
        expect(subscription.transactionId, 'txn-789');
      });

      test('fromJson handles null optional fields', () {
        final json = {
          'id': 'sub-123',
          'user_id': 'user-456',
          'tier': 'free',
          'status': 'active',
          'starts_at': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.trialStartsAt, null);
        expect(subscription.trialEndsAt, null);
        expect(subscription.expiresAt, null);
        expect(subscription.billingCycle, null);
        expect(subscription.paymentProvider, null);
        expect(subscription.transactionId, null);
      });

      test('fromJson uses defaults for missing tier and status', () {
        final json = {
          'id': 'sub-123',
          'user_id': 'user-456',
          'starts_at': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.tier, 'free');
        expect(subscription.status, 'active');
      });

      test('toJson creates valid JSON map', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          trialStartsAt: past,
          trialEndsAt: future,
          startsAt: now,
          expiresAt: future,
          billingCycle: 'yearly',
          paymentProvider: 'revenuecat',
          transactionId: 'txn-789',
          createdAt: now,
          updatedAt: now,
        );

        final json = subscription.toJson();

        expect(json['id'], 'sub-123');
        expect(json['user_id'], 'user-456');
        expect(json['tier'], 'premium');
        expect(json['status'], 'active');
        expect(json['trial_starts_at'], past.toIso8601String());
        expect(json['trial_ends_at'], future.toIso8601String());
        expect(json['starts_at'], now.toIso8601String());
        expect(json['expires_at'], future.toIso8601String());
        expect(json['billing_cycle'], 'yearly');
        expect(json['payment_provider'], 'revenuecat');
        expect(json['transaction_id'], 'txn-789');
        expect(json['created_at'], now.toIso8601String());
        expect(json['updated_at'], now.toIso8601String());
      });

      test('toJson handles null optional fields', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'free',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final json = subscription.toJson();

        expect(json['trial_starts_at'], null);
        expect(json['trial_ends_at'], null);
        expect(json['expires_at'], null);
        expect(json['billing_cycle'], null);
        expect(json['payment_provider'], null);
        expect(json['transaction_id'], null);
      });

      test('roundtrip serialization preserves data', () {
        final original = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          trialStartsAt: past,
          trialEndsAt: future,
          startsAt: now,
          expiresAt: future,
          billingCycle: 'monthly',
          paymentProvider: 'revenuecat',
          transactionId: 'txn-789',
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final deserialized = Subscription.fromJson(json);

        expect(deserialized.id, original.id);
        expect(deserialized.userId, original.userId);
        expect(deserialized.tier, original.tier);
        expect(deserialized.status, original.status);
        expect(deserialized.billingCycle, original.billingCycle);
        expect(deserialized.paymentProvider, original.paymentProvider);
        expect(deserialized.transactionId, original.transactionId);
      });
    });

    group('CopyWith', () {
      test('copyWith creates new instance with updated tier', () {
        final original = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'free',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(tier: 'premium');

        expect(updated.tier, 'premium');
        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
        expect(updated.status, original.status);
      });

      test('copyWith creates new instance with updated status', () {
        final original = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(status: 'cancelled');

        expect(updated.status, 'cancelled');
        expect(updated.tier, original.tier);
      });

      test('copyWith updates trial dates', () {
        final original = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'trial',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          trialStartsAt: past,
          trialEndsAt: future,
        );

        expect(updated.trialStartsAt, past);
        expect(updated.trialEndsAt, future);
      });

      test('copyWith updates multiple fields', () {
        final original = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'free',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          tier: 'premium',
          status: 'trial',
          billingCycle: 'yearly',
          paymentProvider: 'revenuecat',
          transactionId: 'txn-789',
        );

        expect(updated.tier, 'premium');
        expect(updated.status, 'trial');
        expect(updated.billingCycle, 'yearly');
        expect(updated.paymentProvider, 'revenuecat');
        expect(updated.transactionId, 'txn-789');
      });

      test('copyWith preserves unchanged fields', () {
        final original = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          billingCycle: 'monthly',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(tier: 'free');

        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
        expect(updated.status, original.status);
        expect(updated.billingCycle, original.billingCycle);
        expect(updated.startsAt, original.startsAt);
        expect(updated.createdAt, original.createdAt);
      });

      test('copyWith updates updatedAt timestamp', () {
        final original = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: past,
        );

        final updated = original.copyWith(tier: 'free');

        expect(updated.updatedAt.isAfter(original.updatedAt), true);
      });
    });

    group('Equality and HashCode', () {
      test('two subscriptions with same values are equal', () {
        final sub1 = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final sub2 = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(sub1 == sub2, true);
        expect(sub1.hashCode == sub2.hashCode, true);
      });

      test('two subscriptions with different ids are not equal', () {
        final sub1 = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final sub2 = Subscription(
          id: 'sub-456',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(sub1 == sub2, false);
      });

      test('subscriptions with different tiers are not equal', () {
        final sub1 = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'free',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final sub2 = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(sub1 == sub2, false);
      });
    });

    group('ToString', () {
      test('toString returns readable string representation', () {
        final subscription = Subscription(
          id: 'sub-123',
          userId: 'user-456',
          tier: 'premium',
          status: 'active',
          startsAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final string = subscription.toString();

        expect(string, contains('sub-123'));
        expect(string, contains('user-456'));
        expect(string, contains('premium'));
        expect(string, contains('active'));
        expect(string, contains('hasFullAccess: true'));
      });
    });
  });
}
