class Subscription {
  final String id;
  final String userId;
  final String tier;
  final String status;
  final DateTime? trialStartsAt;
  final DateTime? trialEndsAt;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final String? billingCycle;
  final String? paymentProvider;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    this.trialStartsAt,
    this.trialEndsAt,
    required this.startsAt,
    this.expiresAt,
    this.billingCycle,
    this.paymentProvider,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFree => tier == 'free';
  bool get isPremium => tier == 'premium';
  bool get isActive => status == 'active';
  bool get isTrial => status == 'trial';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  bool get isTrialActive =>
      isTrial &&
      trialEndsAt != null &&
      trialEndsAt!.isAfter(DateTime.now());

  bool get hasFullAccess => (isPremium && isActive) || isTrialActive;

  int get trialHoursRemaining {
    if (trialEndsAt == null) return 0;
    final remaining = trialEndsAt!.difference(DateTime.now()).inHours;
    return remaining > 0 ? remaining : 0;
  }

  String get trialRemainingDisplay {
    if (trialEndsAt == null) return '';
    final diff = trialEndsAt!.difference(DateTime.now());
    
    if (diff.isNegative) return 'Expired';
    
    if (diff.inHours >= 1) {
      return '${diff.inHours}h remaining';
    }
    
    return '${diff.inMinutes}m remaining';
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tier: json['tier'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      trialStartsAt: json['trial_starts_at'] != null
          ? DateTime.parse(json['trial_starts_at'] as String)
          : null,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'] as String)
          : null,
      startsAt: DateTime.parse(json['starts_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      billingCycle: json['billing_cycle'] as String?,
      paymentProvider: json['payment_provider'] as String?,
      transactionId: json['transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tier': tier,
      'status': status,
      'trial_starts_at': trialStartsAt?.toIso8601String(),
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'billing_cycle': billingCycle,
      'payment_provider': paymentProvider,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Subscription copyWith({
    String? tier,
    String? status,
    DateTime? trialStartsAt,
    DateTime? trialEndsAt,
    DateTime? expiresAt,
    String? billingCycle,
    String? paymentProvider,
    String? transactionId,
  }) {
    return Subscription(
      id: id,
      userId: userId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      trialStartsAt: trialStartsAt ?? this.trialStartsAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      startsAt: startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      billingCycle: billingCycle ?? this.billingCycle,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          tier == other.tier &&
          status == other.status &&
          trialStartsAt == other.trialStartsAt &&
          trialEndsAt == other.trialEndsAt &&
          startsAt == other.startsAt &&
          expiresAt == other.expiresAt &&
          billingCycle == other.billingCycle &&
          paymentProvider == other.paymentProvider &&
          transactionId == other.transactionId;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      tier.hashCode ^
      status.hashCode ^
      (trialStartsAt?.hashCode ?? 0) ^
      (trialEndsAt?.hashCode ?? 0) ^
      startsAt.hashCode ^
      (expiresAt?.hashCode ?? 0) ^
      (billingCycle?.hashCode ?? 0) ^
      (paymentProvider?.hashCode ?? 0) ^
      (transactionId?.hashCode ?? 0);

  @override
  String toString() {
    return 'Subscription('
        'id: $id, '
        'userId: $userId, '
        'tier: $tier, '
        'status: $status, '
        'hasFullAccess: $hasFullAccess'
        ')';
  }
}
