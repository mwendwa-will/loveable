# Period Tracking Fix - Implementation Guide

## Problem Statement

When a user retroactively logs a period with a **different date** than originally onboarded, the system:
1. Overwrites `users.last_period_start` 
2. Loses the original onboarding date
3. Recalculates predictions using the new (incorrect) anchor
4. Breaks cycle tracking accuracy

## Solution: Separate Onboarding Period from Logged Periods

### Step 1: Database Migration

```sql
-- Add new column to preserve original onboarding period
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS onboarding_period_start DATE;

-- Migrate existing data (set onboarding date to last_period_start if not set)
UPDATE public.users
SET onboarding_period_start = 
  CASE 
    WHEN last_period_start IS NOT NULL THEN last_period_start::DATE
    ELSE NULL
  END
WHERE onboarding_period_start IS NULL;

-- Comment for clarity
COMMENT ON COLUMN public.users.onboarding_period_start IS 
  'The period date provided during onboarding - preserved for historical accuracy and predictions';

COMMENT ON COLUMN public.users.last_period_start IS 
  'The most recent logged period start date - updated when user logs a period';
```

### Step 2: Update Onboarding Screen

**File**: [lib/screens/onboarding/onboarding_screen.dart](lib/screens/onboarding/onboarding_screen.dart#L210-L250)

```dart
// BEFORE
await supabaseService.saveUserData(
  username: username,
  firstName: firstName,
  lastName: lastName,
  dateOfBirth: _dateOfBirth,
  averageCycleLength: _averageCycleLength,
  averagePeriodLength: _averagePeriodLength,
  lastPeriodStart: _lastPeriodStart,
  notificationsEnabled: _notificationsEnabled,
);

// AFTER
await supabaseService.saveUserData(
  username: username,
  firstName: firstName,
  lastName: lastName,
  dateOfBirth: _dateOfBirth,
  averageCycleLength: _averageCycleLength,
  averagePeriodLength: _averagePeriodLength,
  lastPeriodStart: _lastPeriodStart,
  onboardingPeriodStart: _lastPeriodStart,  // ← NEW: Store as onboarding date too
  notificationsEnabled: _notificationsEnabled,
);
```

### Step 3: Update SupabaseService.saveUserData()

**File**: [lib/services/supabase_service.dart](lib/services/supabase_service.dart#L240-L280)

Find the `saveUserData()` method and add the parameter:

```dart
// BEFORE
Future<void> saveUserData({
  required String username,
  String? firstName,
  String? lastName,
  DateTime? dateOfBirth,
  int? averageCycleLength,
  int? averagePeriodLength,
  DateTime? lastPeriodStart,
  bool? notificationsEnabled,
}) async {

// AFTER
Future<void> saveUserData({
  required String username,
  String? firstName,
  String? lastName,
  DateTime? dateOfBirth,
  int? averageCycleLength,
  int? averagePeriodLength,
  DateTime? lastPeriodStart,
  DateTime? onboardingPeriodStart,  // ← NEW parameter
  bool? notificationsEnabled,
}) async {
```

Then in the update call:

```dart
// BEFORE
final userData = {
  'username': username,
  'first_name': firstName,
  'last_name': lastName,
  'date_of_birth': dateOfBirth?.toIso8601String(),
  'average_cycle_length': averageCycleLength,
  'average_period_length': averagePeriodLength,
  'last_period_start': lastPeriodStart?.toIso8601String(),
  'notifications_enabled': notificationsEnabled,
  'has_completed_onboarding': true,
};

// AFTER
final userData = {
  'username': username,
  'first_name': firstName,
  'last_name': lastName,
  'date_of_birth': dateOfBirth?.toIso8601String(),
  'average_cycle_length': averageCycleLength,
  'average_period_length': averagePeriodLength,
  'last_period_start': lastPeriodStart?.toIso8601String(),
  'onboarding_period_start': onboardingPeriodStart?.toIso8601String(),  // ← NEW
  'notifications_enabled': notificationsEnabled,
  'has_completed_onboarding': true,
};
```

### Step 4: Update SupabaseService.startPeriod()

**File**: [lib/services/supabase_service.dart](lib/services/supabase_service.dart#L448-L530)

**CRITICAL CHANGE**: Don't overwrite `last_period_start` if it's before an existing period

```dart
Future<Period> startPeriod({
  required DateTime startDate,
  FlowIntensity? intensity,
}) async {
  final user = currentUser;
  if (user == null) throw AuthException.sessionExpired();

  // ... existing code for auto-closing old periods ...

  // STEP 1: Record prediction accuracy if this is not the first period
  try {
    final userData = await getUserData();
    
    if (userData == null) {
      debugPrint('⚠️ User data not found');
    } else {
      final onboardingPeriodStart = userData['onboarding_period_start'] != null
          ? DateTime.parse(userData['onboarding_period_start']!)
          : null;

      if (onboardingPeriodStart != null) {
        final completedPeriods = await getCompletedPeriods(limit: 100);
        final cycleNumber = completedPeriods.length + 1;

        await CycleAnalyzer.recordPredictionAccuracy(
          userId: user.id,
          cycleNumber: cycleNumber,
          actualDate: startDate,
        );
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error recording prediction accuracy: $e');
  }

  // STEP 2: Create new period
  final data = {
    'user_id': user.id,
    'start_date': startDate.toIso8601String(),
    'flow_intensity': intensity?.name ?? FlowIntensity.medium.name,
  };

  final response = await client
      .from('periods')
      .insert(data)
      .select()
      .single();

  // STEP 3: Update last_period_start ONLY if this is the most recent period
  // ✅ CHANGE: Get current last_period_start and compare
  final userData = await getUserData();
  final currentLastPeriod = userData?['last_period_start'] != null
      ? DateTime.parse(userData!['last_period_start']!)
      : null;

  if (currentLastPeriod == null || startDate.isAfter(currentLastPeriod)) {
    // ✅ Only update if this is the most recent period
    await updateUserData({'last_period_start': startDate.toIso8601String()});
    debugPrint('✅ Updated last_period_start to: $startDate');
  } else if (startDate.isBefore(currentLastPeriod)) {
    // ⚠️ User logged a period earlier than the most recent one
    debugPrint('⚠️ Retroactive period logged: $startDate (before current: $currentLastPeriod)');
    // Don't update last_period_start - keep most recent as the anchor
  }

  // STEP 4: RECALCULATE all predictions based on new data
  try {
    await CycleAnalyzer.recalculateAfterPeriodStart(user.id);
    debugPrint('✅ Period started, predictions recalculated');
  } catch (e) {
    debugPrint('⚠️ Error recalculating predictions: $e');
  }

  return Period.fromJson(response);
}
```

### Step 5: Update CycleAnalyzer.generateInitialPredictions()

**File**: [lib/services/cycle_analyzer.dart](lib/services/cycle_analyzer.dart#L10-L47)

Use `onboarding_period_start` instead of `last_period_start` for initial prediction:

```dart
static Future<void> generateInitialPredictions(String userId) async {
  try {
    final userData = await _supabase.getUserData();
    
    if (userData == null) {
      debugPrint('⚠️ User data not found');
      return;
    }
    
    // ✅ Use onboarding_period_start as the anchor for initial prediction
    final periodStartDate = userData['onboarding_period_start'] != null
        ? DateTime.parse(userData['onboarding_period_start']!)
        : DateTime.parse(userData['last_period_start']!);  // Fallback for old data
        
    final cycleLength = userData['cycle_length'] as int;

    // Calculate first prediction using self-reported cycle length
    final nextPeriodDate = periodStartDate.add(Duration(days: cycleLength));

    // Store prediction with 50% confidence
    await _supabase.updateUserData({
      'next_period_predicted': nextPeriodDate.toIso8601String(),
      'prediction_confidence': 0.50,
      'prediction_method': 'self_reported',
      'average_cycle_length': cycleLength.toDouble(),
    });

    await _logPrediction(
      userId: userId,
      cycleNumber: 1,
      predictedDate: nextPeriodDate,
      confidence: 0.50,
      method: 'self_reported',
    );

    debugPrint(
        '✅ Initial prediction: ${nextPeriodDate.toLocal()} (${cycleLength}d cycle)');
  } catch (e) {
    debugPrint('❌ Error generating initial predictions: $e');
  }
}
```

### Step 6: Update CycleAnalyzer.recalculateAfterPeriodStart()

**File**: [lib/services/cycle_analyzer.dart](lib/services/cycle_analyzer.dart#L51-L113)

No changes needed! This already works correctly since it uses the `periods` table which contains all logged periods in order.

---

## Migration Path for Existing Users

For users who already onboarded before this fix:

```sql
-- Existing data: onboarding_period_start is already set from last_period_start
-- No action needed - the fallback in generateInitialPredictions() handles it

-- For users who have logged retroactive periods:
-- Their onboarding_period_start preserves the original onboarded date
-- Their predictions will recalculate correctly based on all periods

-- Verification query:
SELECT 
  id,
  username,
  onboarding_period_start,
  last_period_start,
  (SELECT COUNT(*) FROM periods WHERE user_id = users.id) as period_count
FROM users
WHERE has_completed_onboarding = true
LIMIT 10;
```

---

## Testing Checklist

### Test 1: New User Onboarding
- [ ] User onboards with period date = Dec 28
- [ ] Verify: `onboarding_period_start` = Dec 28
- [ ] Verify: `last_period_start` = Dec 28
- [ ] Verify: Prediction = Jan 27 (Dec 28 + 30)

### Test 2: Log Same Period (Today)
- [ ] User logs period for today
- [ ] Verify: `last_period_start` updated to today
- [ ] Verify: `onboarding_period_start` unchanged
- [ ] Verify: Prediction recalculated

### Test 3: Retroactive Period (Earlier)
- [ ] User logs period for Dec 25 (before onboarded Dec 28)
- [ ] Verify: Period created in periods table for Dec 25
- [ ] Verify: `onboarding_period_start` = Dec 28 (unchanged!)
- [ ] Verify: `last_period_start` = Dec 28 or Dec 25 (whichever is most recent)
- [ ] Verify: Prediction uses both periods for calculation

### Test 4: Retroactive Period (Later)
- [ ] User logs period for Jan 5 (after some earlier date)
- [ ] Verify: `last_period_start` updates to Jan 5
- [ ] Verify: `onboarding_period_start` unchanged
- [ ] Verify: Prediction recalculates

### Test 5: Existing Users
- [ ] User with data before this change
- [ ] Verify: `onboarding_period_start` populated from migration
- [ ] Verify: App continues to work

---

## Files Modified Summary

| File | Changes | Lines |
|------|---------|-------|
| `lib/screens/onboarding/onboarding_screen.dart` | Pass `onboardingPeriodStart` to `saveUserData()` | +1 |
| `lib/services/supabase_service.dart` | Add param, store column, conditional update in `startPeriod()` | +15 |
| `lib/services/cycle_analyzer.dart` | Use `onboarding_period_start` for initial prediction | +2 |
| Database migration | Add column, migrate data | ~10 lines |

**Total Effort**: ~4 hours
**Risk Level**: Low (backward compatible)
**Testing Time**: ~2 hours

---

## Rollback Plan

If something goes wrong:

1. Add `onboarding_period_start` to migration revert list
2. Code changes are backward compatible
3. `onboarding_period_start` defaults to NULL (uses `last_period_start` as fallback)
4. No data is lost (column can be dropped safely)

