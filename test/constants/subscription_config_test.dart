import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/constants/subscription_config.dart';

void main() {
  group('TierLimits', () {
    test('isUnlimited returns true when historyMonths is -1', () {
      const limits = TierLimits(historyMonths: -1);
      expect(limits.isUnlimited, true);
    });

    test('isUnlimited returns false when historyMonths is not -1', () {
      const limits = TierLimits(historyMonths: 3);
      expect(limits.isUnlimited, false);
    });

    test('stores historyMonths correctly', () {
      const limits = TierLimits(historyMonths: 6);
      expect(limits.historyMonths, 6);
    });
  });

  group('TierDetails', () {
    test('stores all properties correctly', () {
      const details = TierDetails(
        name: 'Test',
        monthlyPrice: 9.99,
        yearlyPrice: 99.99,
        features: ['Feature 1', 'Feature 2'],
        limits: TierLimits(historyMonths: 12),
      );

      expect(details.name, 'Test');
      expect(details.monthlyPrice, 9.99);
      expect(details.yearlyPrice, 99.99);
      expect(details.features, ['Feature 1', 'Feature 2']);
      expect(details.limits.historyMonths, 12);
    });

    test('yearlyMonthlyEquivalent calculates correctly', () {
      const details = TierDetails(
        name: 'Test',
        monthlyPrice: 10.0,
        yearlyPrice: 96.0,
        features: [],
        limits: TierLimits(historyMonths: -1),
      );

      expect(details.yearlyMonthlyEquivalent, 8.0);
    });

    test('yearlySavingsPercent calculates correctly', () {
      const details = TierDetails(
        name: 'Test',
        monthlyPrice: 10.0,
        yearlyPrice: 100.0,
        features: [],
        limits: TierLimits(historyMonths: -1),
      );

      // Monthly total: 10 * 12 = 120
      // Yearly price: 100
      // Savings: 20
      // Percent: (20/120) * 100 = 16.666...%
      expect(details.yearlySavingsPercent, closeTo(16.67, 0.01));
    });

    test('yearlySavingsPercent returns 0 for free tier', () {
      const details = TierDetails(
        name: 'Free',
        monthlyPrice: 0,
        yearlyPrice: 0,
        features: [],
        limits: TierLimits(historyMonths: 3),
      );

      expect(details.yearlySavingsPercent, 0);
    });

    test('yearlySavingsPercent handles no savings correctly', () {
      const details = TierDetails(
        name: 'Test',
        monthlyPrice: 10.0,
        yearlyPrice: 120.0,
        features: [],
        limits: TierLimits(historyMonths: -1),
      );

      expect(details.yearlySavingsPercent, 0);
    });
  });

  group('freeTier', () {
    test('has correct name', () {
      expect(freeTier.name, 'Free');
    });

    test('has zero prices', () {
      expect(freeTier.monthlyPrice, 0);
      expect(freeTier.yearlyPrice, 0);
    });

    test('has 3 months history limit', () {
      expect(freeTier.limits.historyMonths, 3);
      expect(freeTier.limits.isUnlimited, false);
    });

    test('has correct features', () {
      expect(freeTier.features.length, 5);
      expect(freeTier.features, contains('Basic cycle tracking'));
      expect(freeTier.features, contains('Simple period predictions'));
      expect(freeTier.features, contains('3 months history'));
      expect(freeTier.features, contains('Daily affirmation'));
      expect(freeTier.features, contains('Basic symptom logging'));
    });

    test('yearlyMonthlyEquivalent is 0', () {
      expect(freeTier.yearlyMonthlyEquivalent, 0);
    });

    test('yearlySavingsPercent is 0', () {
      expect(freeTier.yearlySavingsPercent, 0);
    });
  });

  group('premiumTier', () {
    test('has correct name', () {
      expect(premiumTier.name, 'Premium');
    });

    test('has correct prices', () {
      expect(premiumTier.monthlyPrice, 4.99);
      expect(premiumTier.yearlyPrice, 39.99);
    });

    test('has unlimited history', () {
      expect(premiumTier.limits.historyMonths, -1);
      expect(premiumTier.limits.isUnlimited, true);
    });

    test('has correct features', () {
      expect(premiumTier.features.length, 8);
      expect(premiumTier.features, contains('Everything in Free'));
      expect(premiumTier.features, contains('Edit cycle settings'));
      expect(premiumTier.features, contains('Unlimited history'));
      expect(premiumTier.features, contains('Advanced cycle insights'));
      expect(premiumTier.features, contains('Mood & symptom trends'));
      expect(premiumTier.features, contains('Export health reports'));
      expect(premiumTier.features, contains('Custom affirmations'));
      expect(premiumTier.features, contains('Ad-free experience'));
    });

    test('yearlyMonthlyEquivalent calculates correctly', () {
      // 39.99 / 12 = 3.3325
      expect(premiumTier.yearlyMonthlyEquivalent, closeTo(3.33, 0.01));
    });

    test('yearlySavingsPercent calculates correctly', () {
      // Monthly total: 4.99 * 12 = 59.88
      // Yearly price: 39.99
      // Savings: 19.89
      // Percent: (19.89/59.88) * 100 = 33.216...%
      expect(premiumTier.yearlySavingsPercent, closeTo(33.22, 0.01));
    });
  });
}
