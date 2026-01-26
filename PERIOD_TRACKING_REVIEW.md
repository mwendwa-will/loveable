# Period Tracking & Onboarding Review

**Date**: January 6, 2026
**Reviewed**: Period tracking flow, retroactive logging, and onboarding integration

---

## ✅ GOOD NEWS: The App DOES Handle Previous Period Tracking

The app successfully tracks the previous onboarded period and handles retroactive period logging. Here's how it works:

---

## 1. Onboarding Period Setup

### Flow:
```
User Onboarding (OnboardingScreen) 
    ↓
User enters "Last Period Start Date" (can be up to 90 days ago)
    ↓
Data saved to users table: last_period_start
    ↓
Check: Is last period recent? (within average_period_length days)
    ↓
If YES → Create active period record
    ↓
CycleAnalyzer.generateInitialPredictions() called
    ↓
Initial prediction generated at 50% confidence
```

### Location: [lib/screens/onboarding/onboarding_screen.dart](lib/screens/onboarding/onboarding_screen.dart#L220-L250)

```dart
// ✨ If last period start is recent (within average period length), 
// create an active period record
if (_lastPeriodStart != null) {
  final daysSinceStart = DateTime.now().difference(_lastPeriodStart!).inDays;
  // Use user's average period length instead of hardcoded 7 days
  if (daysSinceStart <= _averagePeriodLength) {
    try {
      debugPrint('📅 Last period is recent ($daysSinceStart days ago, threshold: $_averagePeriodLength days), creating active period record...');
      // Start with light intensity by default, user can update in DailyLogScreen
      await supabaseService.startPeriod(
        startDate: _lastPeriodStart!,
        intensity: FlowIntensity.light,
      );
      debugPrint('✅ Active period record created');
    } catch (e) {
      debugPrint('⚠️ Error creating period record: $e');
    }
  }
}
```

**Key Points:**
- ✅ Accepts any date within 90 days (via DatePicker)
- ✅ Only creates active period if recent (within average_period_length)
- ✅ Stores the date exactly as provided by user

---

## 2. Initial Prediction Generation

### Location: [lib/services/cycle_analyzer.dart](lib/services/cycle_analyzer.dart#L10-L47)

```dart
static Future<void> generateInitialPredictions(String userId) async {
  try {
    final userData = await _supabase.getUserData();
    final lastPeriodStart = DateTime.parse(userData['last_period_start']!);
    final cycleLength = userData['cycle_length'] as int;

    // Calculate first prediction using self-reported cycle length
    final nextPeriodDate = lastPeriodStart.add(Duration(days: cycleLength));

    // Store prediction with 50% confidence
    await _supabase.updateUserData({
      'next_period_predicted': nextPeriodDate.toIso8601String(),
      'prediction_confidence': 0.50,
      'prediction_method': 'self_reported',
    });
    
    debugPrint('✅ Initial prediction: ${nextPeriodDate.toLocal()} (${cycleLength}d cycle)');
  } catch (e) {
    debugPrint('❌ Error generating initial predictions: $e');
  }
}
```

**What happens:**
- Uses `last_period_start` from onboarding
- Adds `cycle_length` (default 28 days) to calculate next period
- Stores prediction with 50% confidence (self-reported data)

---

## 3. Retroactive Period Logging (IMPORTANT)

### Daily Log Screen: [lib/screens/daily_log_screen_v2.dart](lib/screens/daily_log_screen_v2.dart#L244-L260)

```dart
Future<void> _logOrUpdatePeriod(FlowIntensity intensity, Period? existingPeriod) async {
  await _autoSave(() async {
    final supabase = ref.read(supabaseServiceProvider);
    if (existingPeriod != null) {
      await supabase.updatePeriodIntensity(
        periodId: existingPeriod.id,
        intensity: intensity,
      );
    } else {
      // ✅ This uses widget.selectedDate - allows ANY date!
      await supabase.startPeriod(startDate: widget.selectedDate, intensity: intensity);
    }
    // Force UI refresh
    ref.invalidate(periodsStreamProvider(DateRange(
      startDate: widget.selectedDate,
      endDate: widget.selectedDate.add(const Duration(days: 1)),
    )));
  });
}
```

**Key Point:** `widget.selectedDate` can be ANY historical date from the calendar!

---

## ⚠️ IMPORTANT: How Retroactive Logging AFFECTS Predictions

When user logs a period on a **different date than originally predicted**, the `startPeriod()` function triggers the prediction recalculation:

### Location: [lib/services/supabase_service.dart](lib/services/supabase_service.dart#L448-L530)

```dart
Future<Period> startPeriod({
  required DateTime startDate,
  FlowIntensity? intensity,
}) async {
  // STEP 1: Record prediction accuracy if this is not the first period
  final completedPeriods = await getCompletedPeriods(limit: 100);
  final cycleNumber = completedPeriods.length + 1;
  
  // Record prediction accuracy (Instance 6: Truth Event)
  await CycleAnalyzer.recordPredictionAccuracy(
    userId: user.id,
    cycleNumber: cycleNumber,
    actualDate: startDate,  // ← Uses the logged date, not today
  );
  
  // STEP 2: Create new period
  final response = await client
      .from('periods')
      .insert({
        'user_id': user.id,
        'start_date': startDate.toIso8601String(),  // ← Stores exact logged date
      });
  
  // STEP 3: Update user's last period start
  await updateUserData({'last_period_start': startDate.toIso8601String()});
  
  // STEP 4: RECALCULATE all predictions based on new data
  await CycleAnalyzer.recalculateAfterPeriodStart(user.id);
}
```

---

## 🔴 CRITICAL ISSUE: Retroactive Logging BREAKS Predictions

### The Problem:

**Scenario:**
```
User onboards: "Last period started Jan 1"
  → System predicts: Jan 31 (Jan 1 + 30 days)
  
User later realizes: Period actually started Dec 28
  → User goes to calendar and logs Dec 28 in daily log
  → System calls startPeriod(Dec 28)
  → This updates last_period_start to Dec 28
  → Predictions recalculate using Dec 28 as anchor
  → Original onboarding date (Jan 1) gets overwritten
```

### Result:
❌ **The original onboarded period is LOST**
❌ **Prediction recalculation treats the retroactive date as the actual period**
❌ **Cycle calculations become inaccurate**

### How Prediction Recalculation Works:

Location: [lib/services/cycle_analyzer.dart](lib/services/cycle_analyzer.dart#L51-L113)

```dart
static Future<void> recalculateAfterPeriodStart(String userId) async {
  // Get all completed periods (periods with end_date set)
  final periods = await _supabase.getCompletedPeriods(limit: 12);
  
  // Calculate cycle lengths from consecutive periods
  final cycleLengths = <int>[];
  for (int i = 0; i < periods.length - 1; i++) {
    final currentPeriod = periods[i];
    final nextPeriod = periods[i + 1];
    final cycleLength = 
        nextPeriod.startDate.difference(currentPeriod.startDate).inDays;
    cycleLengths.add(cycleLength);
  }
  
  // Calculate average and confidence
  final averageCycleLength = _calculateSimpleAverage(cycleLengths);
  final confidence = _calculateConfidence(cycleLengths);
  
  // Use most recent period to predict next
  final lastPeriod = periods.first;
  final nextPredicted = lastPeriod.startDate
      .add(Duration(days: averageCycleLength.round()));
  
  // Update prediction
  await _supabase.updateUserData({
    'cycle_length': averageCycleLength.round(),
    'average_cycle_length': averageCycleLength,
    'next_period_predicted': nextPredicted.toIso8601String(),
    'prediction_confidence': confidence,
    'prediction_method': 'simple_average',
  });
}
```

---

## 📋 Summary: Current Behavior

| Aspect | Current Behavior | Status |
|--------|------------------|--------|
| **Track Previous Period** | ✅ Yes, accepts any date within 90 days | GOOD |
| **Onboarding Period Storage** | ✅ Stored in `last_period_start` | GOOD |
| **Active Period Creation** | ✅ If recent (within avg period length) | GOOD |
| **Initial Prediction** | ✅ Generated from onboarded date | GOOD |
| **Retroactive Logging (Same Date)** | ✅ Works fine | GOOD |
| **Retroactive Logging (Different Date)** | ⚠️ Overwrites `last_period_start` | **ISSUE** |
| **Prediction Recalculation** | ✅ Triggered on new period | GOOD |
| **Original Onboarded Date Preservation** | ❌ Not preserved if retroactively changed | **BUG** |

---

## 🔧 Recommended Fixes

### Option 1: Store Original Onboarding Date (BEST)
Add a new column to users table:
```sql
ALTER TABLE users ADD COLUMN onboarding_period_start DATE;
```

Then modify:
- **OnboardingScreen**: Store both `last_period_start` AND `onboarding_period_start`
- **CycleAnalyzer**: Use `onboarding_period_start` for initial prediction, not `last_period_start`
- **SupabaseService.startPeriod()**: Only update `last_period_start`, not `onboarding_period_start`

### Option 2: Use Periods Table Only
- Remove reliance on `users.last_period_start` for calculations
- Always read from `periods` table ordered by date
- Calculate based on actual logged periods only

### Option 3: Validate Retroactive Changes
- When user logs a period before the last logged period, show confirmation
- Warn that this will recalculate predictions
- Store reasoning in database

---

## 🧪 Test Cases

### Test 1: Normal Onboarding Flow
```
1. User onboards: Last period = Jan 1
2. Cycle length = 30 days
3. Expected prediction = Jan 31
4. ✅ Verify: users.last_period_start = Jan 1
5. ✅ Verify: users.next_period_predicted = Jan 31
```

### Test 2: Retroactive Logging (Same Date)
```
1. User logs period on daily log for Jan 1
2. Expected: Just updates intensity, no recalculation
3. ✅ Verify: last_period_start still = Jan 1
4. ✅ Verify: prediction unchanged
```

### Test 3: Retroactive Logging (Earlier Date) ⚠️
```
1. Onboarded: Jan 1
2. Later realizes: Actually started Dec 28
3. Logs Dec 28 in calendar
4. ❌ Current behavior: Overwrites to Dec 28, predictions shift
5. ✅ Expected: Should preserve Jan 1, add Dec 28 as separate period
```

### Test 4: Retroactive Logging (Later Date)
```
1. Onboarded: Jan 1
2. Later logs: Jan 5 (was still in same period)
3. ❌ Current: Treats Jan 5 as new period start
4. ✅ Expected: Should mark Jan 1-5 as single period
```

---

## 📊 Data Flow Diagram

```
ONBOARDING
├─ User provides: last_period_start (e.g., Jan 1)
├─ System stores: users.last_period_start = Jan 1
├─ System creates: periods record (if recent)
└─ System generates: prediction = Jan 1 + 30 = Jan 31 ✅

DAILY LOG - LOG PERIOD (Same Date)
├─ User: Logs period for Jan 1
├─ System: Calls startPeriod(Jan 1)
├─ System: Records in periods table
└─ Prediction: Jan 31 (unchanged) ✅

DAILY LOG - LOG PERIOD (Different Date) ⚠️
├─ User: Realizes period was Dec 28, logs it
├─ System: Calls startPeriod(Dec 28)
├─ System: Updates users.last_period_start = Dec 28
├─ System: Recalculates prediction = Dec 28 + 30 = Jan 27
├─ System: Original onboarded date (Jan 1) LOST ❌
└─ Predictions: Now inaccurate based on wrong anchor date
```

---

## 🎯 Conclusion

The app **successfully tracks the previous onboarded period** during onboarding, but **retroactive logging of a different date overwrites the original period date**, which breaks the prediction system.

**Priority**: HIGH - This affects cycle accuracy for any user who corrects their period date.

