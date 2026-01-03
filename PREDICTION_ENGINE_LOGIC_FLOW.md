# Prediction Engine: Logic Flow & Decision Points

This document maps out every decision point in Lovely's prediction engine, following a new user named Maya through her first cycles. Each "Instance" represents a critical moment where the app's algorithm makes a calculation or updates its knowledge.

---

## The Journey: Maya's First 30 Days

### Instance 1: The Birth of the Profile (Initialization)

**WHEN**: User taps "Get Started" button on welcome screen  
**TRIGGER**: First app launch after signup

#### The Action
```dart
// lib/screens/onboarding/onboarding_screen.dart
Future<void> _initializeNewUser() async {
  final userId = await SupabaseService().getCurrentUserId();
  
  // Create user profile with default values
  await SupabaseService().createUserProfile(UserProfile(
    id: userId,
    cycleLength: 28,        // Generic Template: Global Constant
    periodLength: 5,        // Generic Template: Global Constant
    lastPeriodStart: null,  // Unknown - will be set in onboarding
    hasCompletedOnboarding: false,
    createdAt: DateTime.now(),
  ));
}
```

#### The Logic
- **Global Constants**: `CYCLE_LENGTH = 28`, `PERIOD_LENGTH = 5`
- **State**: `UNINITIALIZED` (no personal data yet)
- **Prediction Capability**: `NONE` (cannot predict without anchor date)

#### The Result
- Database entry created with user_id
- Profile exists but is "blank slate"
- App is ready to receive Maya's first data point

#### Database State
```sql
-- users table (after initialization)
| user_id | cycle_length | period_length | last_period_start | has_completed_onboarding |
|---------|--------------|---------------|-------------------|--------------------------|
| maya123 | 28           | 5             | NULL              | FALSE                    |
```

---

### Instance 2: The Onboarding Input (The Anchor)

**WHEN**: User completes onboarding (Page 3: "When did your last period start?")  
**TRIGGER**: User selects date and taps "Continue"

#### The Action
```dart
// lib/screens/onboarding/onboarding_screen.dart (Page 3)
Future<void> _saveOnboardingData() async {
  final lastPeriodStart = _selectedDate; // January 1st, 2026
  
  // Save anchor date to database
  await SupabaseService().saveUserData({
    'last_period_start': lastPeriodStart.toIso8601String(),
    'cycle_length': _selectedCycleLength ?? 30, // Maya's self-reported
    'period_length': _selectedPeriodLength ?? 5,
    'has_completed_onboarding': true,
  });
  
  // Create first period record
  await SupabaseService().startPeriod(lastPeriodStart);
}
```

#### The Logic
```dart
// Calculate current cycle day
final today = DateTime.now(); // January 2nd, 2026
final daysSinceStart = today.difference(lastPeriodStart).inDays;
final currentCycleDay = daysSinceStart + 1; // Day 2

// Determine period status
final isCurrentlyOnPeriod = currentCycleDay <= periodLength; // true (Day 2 < 5)
```

#### The Result
- **Anchor Date Established**: January 1st is now the reference point
- **Current Cycle Day**: `Day 2`
- **Period Status**: `ACTIVE` (currently menstruating)
- **UI Updates**:
  - Home screen shows "Day 2 of your cycle"
  - Period color (red) appears on calendar for Jan 1-2
  - "Log Period" button shows active state

#### Database State
```sql
-- users table (after onboarding)
| user_id | cycle_length | period_length | last_period_start | has_completed_onboarding |
|---------|--------------|---------------|-------------------|--------------------------|
| maya123 | 30           | 5             | 2026-01-01        | TRUE                     |

-- periods table (auto-created)
| id  | user_id | start_date | end_date | is_predicted |
|-----|---------|------------|----------|--------------|
| p1  | maya123 | 2026-01-01 | NULL     | FALSE        |
```

---

### Instance 3: The First Forecast (The Extrapolation)

**WHEN**: Immediately after anchor date is saved  
**TRIGGER**: Automatic - runs in `saveUserData()` callback

#### The Action
```dart
// lib/services/cycle_analyzer.dart (NEW - to be created)
class CycleAnalyzer {
  static Future<void> generateInitialPredictions(String userId) async {
    final userData = await SupabaseService().getUserData();
    final lastPeriodStart = DateTime.parse(userData['last_period_start']);
    final cycleLength = userData['cycle_length'] as int; // 30 days
    
    // Calculate first prediction
    final nextPeriodDate = lastPeriodStart.add(Duration(days: cycleLength));
    
    // Store prediction
    await SupabaseService().updateUserData({
      'next_period_predicted': nextPeriodDate.toIso8601String(),
      'prediction_confidence': 0.5, // 50% - based on self-report, not data
    });
    
    // Generate predicted periods for calendar (next 3 cycles)
    final predictions = <PredictedPeriod>[];
    for (int i = 1; i <= 3; i++) {
      final predictedStart = lastPeriodStart.add(Duration(days: cycleLength * i));
      predictions.add(PredictedPeriod(
        startDate: predictedStart,
        cycleNumber: i,
        confidence: 0.5,
      ));
    }
    
    return predictions;
  }
}
```

#### The Logic
**Simple Arithmetic Projection**:
```
Anchor Date:     January 1st, 2026
Cycle Length:    30 days (self-reported)
Calculation:     Jan 1 + 30 days = January 31st
```

**Repeat for 3 cycles**:
- Cycle 2: January 31st + 30 = March 2nd
- Cycle 3: March 2nd + 30 = April 1st

#### The Result
- **Calendar View**: Shows pink predicted periods on Jan 31, Mar 2, Apr 1
- **Home Screen**: "Your next period is expected around Jan 31"
- **Confidence Level**: `50%` (low - based on guess, not actual data)

#### Database State
```sql
-- users table (prediction added)
| user_id | cycle_length | last_period_start | next_period_predicted | prediction_confidence |
|---------|--------------|-------------------|-----------------------|-----------------------|
| maya123 | 30           | 2026-01-01        | 2026-01-31            | 0.50                  |
```

---

### Instance 4: The Fertile Window Calculation (Biological Assumption)

**WHEN**: Runs immediately after first forecast  
**TRIGGER**: Automatic - part of prediction generation

#### The Action
```dart
// lib/utils/cycle_utils.dart (ENHANCEMENT)
class CycleUtils {
  static const int LUTEAL_PHASE_CONSTANT = 14; // Biological constant
  static const int FERTILE_WINDOW_DAYS = 5;    // 5 days before ovulation
  
  static DateTime calculateOvulationDate(DateTime nextPeriodDate) {
    // Count back from predicted next period
    return nextPeriodDate.subtract(Duration(days: LUTEAL_PHASE_CONSTANT));
  }
  
  static DateRange calculateFertileWindow(DateTime ovulationDate) {
    final windowStart = ovulationDate.subtract(Duration(days: FERTILE_WINDOW_DAYS));
    final windowEnd = ovulationDate;
    
    return DateRange(start: windowStart, end: windowEnd);
  }
}
```

#### The Logic
**Biological Assumption**: Luteal phase is constant at ~14 days

```
Next Period (Predicted):  January 31st
Luteal Phase:             14 days (constant)
Ovulation Date:           Jan 31 - 14 = January 17th

Fertile Window:           5 days before ovulation + ovulation day
                         = January 12-17 (6 days total)
```

**Why this works**: 
- Ovulation triggers the luteal phase
- Luteal phase → Corpus luteum → Progesterone production
- ~14 days later, if no pregnancy → Period starts
- This is the MOST RELIABLE backwards calculation

#### The Result
- **Calendar Display**: Yellow shading on January 12-17
- **Home Screen Insight**: "Your fertile window is Jan 12-17"
- **Notification Scheduled**: "Your fertile window starts in 10 days" (on Jan 2)

#### Visual Result
```
JANUARY 2026 CALENDAR:
  1  2  [3  4  5  6  7  8  9  10  11] - Period Days (red)
  [12  13  14  15  16  17] - Fertile Window (yellow)
  [17] - Ovulation Day (dark yellow)
  [31] - Predicted Next Period (pink)
```

---

### Instance 5: The Daily Check-In (The "Passive" Watch)

**WHEN**: Every app open + symptom logging  
**TRIGGER**: `initState()` in HomeScreen + any symptom save

#### The Action
```dart
// lib/services/symptom_monitor.dart (NEW - to be created)
class SymptomMonitor {
  static Future<void> checkForPredictiveSignals() async {
    final today = DateTime.now();
    final userData = await SupabaseService().getUserData();
    final predictedDate = DateTime.parse(userData['next_period_predicted']);
    final daysUntilPrediction = predictedDate.difference(today).inDays;
    
    // Get symptoms from last 3 days
    final recentSymptoms = await SupabaseService().getSymptomsInRange(
      startDate: today.subtract(Duration(days: 3)),
      endDate: today,
    );
    
    // Check for high-probability indicators
    final hasCramps = recentSymptoms.any((s) => s.type == 'Cramps');
    final hasTenderBreasts = recentSymptoms.any((s) => s.type == 'Tender Breasts');
    final hasSpotting = recentSymptoms.any((s) => s.type == 'Spotting');
    
    // CRITICAL LOGIC: Symptoms override math
    if (hasCramps && daysUntilPrediction <= 5) {
      await _increasePredictionCertainty(
        reason: 'Cramps logged within 5 days of prediction',
        newConfidence: 0.85, // 85% certainty
      );
    }
    
    if (hasSpotting && daysUntilPrediction <= 3) {
      await _triggerEarlyPeriodAlert(
        expectedDate: today.add(Duration(days: 1)),
        reason: 'Spotting often precedes period by 24-48 hours',
      );
    }
  }
}
```

#### The Logic (Maya's Example)

**Scenario**: January 28th - Maya logs "Cramps"

```
Today:                    January 28th
Predicted Period:         January 31st  
Days Until Prediction:    3 days

Symptom:                  Cramps
Historical Pattern:       Cramps → Period in 2-3 days (learned from past cycles)

Decision:
- Math says: Period on Jan 31 (confidence: 50%)
- Body says: Period likely Jan 29-30 (confidence: 85%)

ACTION: Upgrade prediction certainty, adjust UI messaging
```

#### The Result
- **Confidence Upgrade**: `50%` → `85%`
- **UI Change**: Home screen badge changes from "Expected around Jan 31" to "Likely starting in 2-3 days"
- **Notification**: "Based on your symptoms, your period may start soon. Make sure you're prepared!"

#### Code Implementation
```dart
// lib/providers/prediction_provider.dart
class PredictionNotifier extends StateNotifier<PredictionState> {
  void adjustPredictionBySyptoms(List<Symptom> symptoms, DateTime currentPrediction) {
    final today = DateTime.now();
    final daysUntil = currentPrediction.difference(today).inDays;
    
    // Sensitivity weighting
    if (symptoms.any((s) => s.type == 'Cramps') && daysUntil <= 5) {
      state = state.copyWith(
        confidence: 0.85,
        adjustmentReason: 'symptom_cramps',
        updatedAt: DateTime.now(),
      );
    }
  }
}
```

---

### Instance 6: The Truth Event (Recalibration)

**WHEN**: User taps "Start Period" button  
**TRIGGER**: Manual user action (most critical event)

#### The Action
```dart
// lib/services/supabase_service.dart (ENHANCED)
Future<void> startPeriod([DateTime? startDate]) async {
  final today = startDate ?? DateTime.now();
  final userId = await getCurrentUserId();
  final userData = await getUserData();
  
  // CRITICAL: Retrieve old prediction
  final predictedDate = DateTime.parse(userData['next_period_predicted']);
  final lastPeriodStart = DateTime.parse(userData['last_period_start']);
  
  // Calculate actual cycle length
  final actualCycleLength = today.difference(lastPeriodStart).inDays;
  final predictedCycleLength = userData['cycle_length'] as int;
  final predictionError = actualCycleLength - predictedCycleLength;
  
  // Update cycle length using weighted average
  final newCycleLength = _updateCycleLengthWithLearning(
    oldMean: predictedCycleLength,
    newObservation: actualCycleLength,
    errorMagnitude: predictionError.abs(),
  );
  
  // CLOSE old cycle, OPEN new cycle
  await _closePreviousCycle(lastPeriodStart, today);
  await _openNewCycle(today);
  
  // RECALCULATE all future predictions
  await CycleAnalyzer.recalculateAllPredictions(userId);
}

double _updateCycleLengthWithLearning({
  required int oldMean,
  required int newObservation,
  required int errorMagnitude,
}) {
  // Simple Moving Average (will be replaced with EMA later)
  // Formula: (Old Mean + New Observation) / 2
  
  // For first real cycle: Trust new data more
  if (oldMean == 28 || oldMean == 30) { // Generic template or self-report
    return newObservation.toDouble(); // 100% trust actual data
  }
  
  // For subsequent cycles: Weighted average
  // Large error = trust new data more
  final weight = errorMagnitude > 3 ? 0.7 : 0.5; // 70% vs 50% weight to new
  return (weight * newObservation) + ((1 - weight) * oldMean);
}
```

#### The Logic (Maya's Example)

**Scenario**: January 29th - Maya taps "Period Started"

```
BEFORE:
  Last Period Start:     January 1st
  Predicted Cycle:       30 days (self-reported)
  Expected Period:       January 31st
  Today's Date:          January 29th

CALCULATION:
  Actual Cycle Length:   Jan 29 - Jan 1 = 28 days
  Prediction Error:      28 - 30 = -2 days (2 days early)
  
LEARNING:
  Old Mean:              30 days (self-report, low confidence)
  New Observation:       28 days (ACTUAL data, high confidence)
  
  Decision: Since old mean is self-reported (not based on tracked data),
            REPLACE entirely with actual observation.
  
  New Mean:              28 days

AFTER:
  Updated Cycle Length:  28 days
  New Prediction:        Jan 29 + 28 = February 26th
  Confidence:            65% (based on 1 real data point)
```

#### The Result

**Database Updates**:
```sql
-- Close old cycle
UPDATE periods 
SET end_date = '2026-01-29' 
WHERE user_id = 'maya123' AND start_date = '2026-01-01';

-- Open new cycle
INSERT INTO periods (user_id, start_date, end_date, is_predicted)
VALUES ('maya123', '2026-01-29', NULL, FALSE);

-- Update user profile
UPDATE users 
SET 
  last_period_start = '2026-01-29',
  cycle_length = 28,              -- LEARNED from actual data
  next_period_predicted = '2026-02-26',
  prediction_confidence = 0.65,
  updated_at = NOW()
WHERE user_id = 'maya123';
```

**UI Updates**:
- Calendar: All future predictions shift back by 2 days
  - Old: Jan 31, Mar 2, Apr 1
  - New: Feb 26, Mar 26, Apr 23
- Home Screen: "You're on Day 1 of your cycle"
- Notification: Rescheduled for February 24th (2 days before Feb 26)

**Learning Captured**:
```dart
// Store learning event for analytics
await SupabaseService().logPredictionAccuracy(
  predictedDate: DateTime(2026, 1, 31),
  actualDate: DateTime(2026, 1, 29),
  errorDays: -2,
  cycleNumber: 2,
);
```

---

## State Machine: Prediction Confidence Evolution

```
┌─────────────────────────────────────────────────────────────┐
│ CONFIDENCE PROGRESSION (How Maya's predictions improve)    │
└─────────────────────────────────────────────────────────────┘

CYCLE 1 (Onboarding):
  Data Points:    1 (self-reported)
  Confidence:     50% ("best guess")
  Method:         Static arithmetic (date + 30 days)

CYCLE 2 (First Truth Event):
  Data Points:    1 actual cycle
  Confidence:     65% ("learned once")
  Method:         Simple average (replace self-report)

CYCLE 3 (Second Truth Event):
  Data Points:    2 actual cycles
  Confidence:     75% ("pattern emerging")
  Method:         Simple average ((28 + 29) / 2 = 28.5 days)

CYCLE 4-6 (Establishing Pattern):
  Data Points:    3-5 actual cycles
  Confidence:     85% ("reliable pattern")
  Method:         Moving average with outlier detection

CYCLE 7+ (Mature Profile):
  Data Points:    6+ actual cycles
  Confidence:     90-95% ("highly accurate")
  Method:         Exponential Moving Average + Symptom Override
```

---

## Decision Gates: Summary Table

| Instance | Trigger | Input | Logic | Output | Confidence |
|----------|---------|-------|-------|--------|------------|
| **1. Initialization** | App install | None | Load template | `cycle=28, period=5` | 0% |
| **2. Anchor** | Onboarding | Last period date | Calculate cycle day | `Day 2`, period status | 0% |
| **3. First Forecast** | Anchor saved | Self-reported cycle length | `date + 30 days` | Next period: Jan 31 | 50% |
| **4. Fertile Window** | Forecast complete | Predicted period | `period - 14 days` | Ovulation: Jan 17 | 50% |
| **5. Daily Check** | Symptom logged | Cramps on Jan 28 | Symptom weighting | Confidence → 85% | 85% |
| **6. Truth Event** | Period started | Actual start: Jan 29 | Error correction | New mean: 28 days | 65% |

---

## Code Structure: Where Each Instance Lives

```
lib/
├── screens/
│   ├── onboarding/
│   │   └── onboarding_screen.dart         → Instance 2 (Anchor)
│   ├── main/
│   │   └── home_screen.dart               → Instance 5 (Daily Check)
│   └── calendar_screen.dart               → Instance 3 (Forecast Display)
│
├── services/
│   ├── supabase_service.dart              → Instance 6 (Truth Event)
│   ├── cycle_analyzer.dart (NEW)          → Instance 3 (Forecasting)
│   └── symptom_monitor.dart (NEW)         → Instance 5 (Symptom Logic)
│
├── utils/
│   └── cycle_utils.dart                   → Instance 4 (Fertile Window)
│
└── providers/
    └── prediction_provider.dart (NEW)     → State management for confidence
```

---

## Testing Scenarios

### Scenario 1: Perfect Regular Cycles
```dart
test('Maya has 28-day cycles consistently', () {
  // Cycle 1: 28 days
  // Cycle 2: 28 days
  // Cycle 3: 28 days
  
  // Expected: Confidence = 95%, prediction = 28 days exactly
});
```

### Scenario 2: Early Period
```dart
test('Maya logs period 3 days early', () {
  // Predicted: January 31 (30 days)
  // Actual: January 28 (27 days)
  // Error: -3 days
  
  // Expected: Cycle length updates to 28.5 days (average)
  // Expected: Confidence drops to 60% (higher variance detected)
});
```

### Scenario 3: Symptom Override
```dart
test('Cramps trigger early prediction', () {
  // Predicted: January 31 (math)
  // Symptom: Cramps on January 28
  // Historical pattern: Cramps → Period in 2 days
  
  // Expected: Confidence increases to 85%
  // Expected: UI shows "Likely starting in 2 days"
});
```

---

## Future Enhancements

### Phase 1 (Current): Simple Arithmetic
- ✅ Static cycle length
- ✅ Simple date addition
- ✅ No learning

### Phase 2 (Next): Basic Learning
- ⏳ Simple Moving Average
- ⏳ Confidence scores
- ⏳ Symptom monitoring

### Phase 3 (Advanced): Statistical Intelligence
- ⏳ Exponential Moving Average
- ⏳ Outlier detection (Modified Z-Score)
- ⏳ Phase-specific analysis (Luteal Constant)

### Phase 4 (AI): Predictive Overrides
- ⏳ Symptom correlation (Random Forest)
- ⏳ Confidence clouds (Gaussian distribution)
- ⏳ Context-aware anomaly classification

---

## Key Developer Insights

### 1. The "Truth Event" is Sacred
- **Every period start = recalibration opportunity**
- Never trust self-reported data more than actual logged data
- The more cycles logged, the more accurate predictions become

### 2. Confidence Grows with Data
- 0-1 cycles: 50% confidence (guessing)
- 2-3 cycles: 65-75% confidence (pattern emerging)
- 4-6 cycles: 85% confidence (reliable)
- 7+ cycles: 90-95% confidence (highly accurate)

### 3. Symptoms Trump Math
- If body says period is coming (cramps, spotting), believe the body
- Mathematical predictions are baselines, not absolutes
- Real-time signals override historical averages

### 4. The Luteal Phase is Your Friend
- **Most reliable**: Count backwards 14 days from next period
- **Least reliable**: Count forwards from period start
- Follicular phase varies (stress), luteal phase is constant (hormones)

### 5. Error Correction is Continuous
- Every cycle provides feedback
- Update mean with weighted average (recent cycles matter more)
- Large errors = higher weight to new data (adaptive learning)

---

**Document Version**: 1.0  
**Last Updated**: January 2, 2026  
**Companion Document**: ADVANCED_ANOMALY_DETECTION.md  
**Status**: Core Logic Reference - Ready for Implementation
