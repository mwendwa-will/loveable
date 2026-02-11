/// Subscription tier configuration and limits.
///
/// Defines Free and Premium tier details, pricing, and feature limits.
library;

/// Tier limits configuration
class TierLimits {
  /// Number of months of history available (-1 = unlimited)
  final int historyMonths;

  const TierLimits({
    required this.historyMonths,
  });

  /// Whether this tier has unlimited history
  bool get isUnlimited => historyMonths == -1;
}

/// Tier details configuration
class TierDetails {
  /// Tier name (e.g., "Free", "Premium")
  final String name;

  /// Monthly subscription price in USD
  final double monthlyPrice;

  /// Yearly subscription price in USD
  final double yearlyPrice;

  /// List of features included in this tier
  final List<String> features;

  /// Usage limits for this tier
  final TierLimits limits;

  const TierDetails({
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.limits,
  });

  /// Monthly equivalent price when paying yearly
  double get yearlyMonthlyEquivalent => yearlyPrice / 12;

  /// Savings percentage when choosing yearly over monthly
  double get yearlySavingsPercent {
    if (monthlyPrice == 0) return 0;
    final yearlyTotal = monthlyPrice * 12;
    final savings = yearlyTotal - yearlyPrice;
    return (savings / yearlyTotal) * 100;
  }
}

/// Free tier configuration
const freeTier = TierDetails(
  name: 'Free',
  monthlyPrice: 0,
  yearlyPrice: 0,
  features: [
    'Basic cycle tracking',
    'Simple period predictions',
    '3 months history',
    'Daily affirmation',
    'Basic symptom logging',
  ],
  limits: TierLimits(historyMonths: 3),
);

/// Premium tier configuration
const premiumTier = TierDetails(
  name: 'Premium',
  monthlyPrice: 4.99,
  yearlyPrice: 39.99,
  features: [
    'Everything in Free',
    'Edit cycle settings',
    'Unlimited history',
    'Advanced cycle insights',
    'Mood & symptom trends',
    'Export health reports',
    'Custom affirmations',
    'Ad-free experience',
  ],
  limits: TierLimits(historyMonths: -1),
);
