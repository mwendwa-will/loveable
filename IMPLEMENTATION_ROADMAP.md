# Implementation Roadmap: From Simple Tracking to AI-Powered Predictions

This document provides a step-by-step guide to implement the advanced prediction engine and anomaly detection features described in `ADVANCED_ANOMALY_DETECTION.md` and `PREDICTION_ENGINE_LOGIC_FLOW.md`.

---

## Overview: The Journey

```
CURRENT STATE (Simple)
└─ Static predictions (28-day default)
└─ No learning from user data
└─ No symptom intelligence
└─ No anomaly detection

↓ PHASE 1 ↓

BASIC LEARNING (2-3 weeks)
└─ Track actual cycle lengths
└─ Simple Moving Average
└─ Confidence scores
└─ Truth Event recalibration

↓ PHASE 2 ↓

SYMPTOM INTELLIGENCE (2 weeks)
└─ Symptom-based prediction adjustment
└─ Daily passive monitoring
└─ Real-time confidence updates

↓ PHASE 3 ↓

STATISTICAL ANOMALY DETECTION (3 weeks)
└─ Multi-layer cycle vectors
└─ Modified Z-Score outlier detection
└─ Context-aware classification
└─ Exclude anomalies from calculations

↓ PHASE 4 ↓

ADVANCED AI (3-4 weeks)
└─ Exponential Moving Average
└─ Luteal Constant phase analysis
└─ Symptom correlation ML
└─ Confidence clouds (Gaussian)
```

---

## Phase 1: Basic Learning Engine (Foundation)

**Goal**: Make the app learn from real data instead of using static assumptions.

**Timeline**: 2-3 weeks  
**Complexity**: Medium  
**Dependencies**: None (can start immediately)

### Step 1.1: Database Schema Updates

**File to modify**: `database_migrations.sql` (or create new migration)

```sql
-- Add prediction tracking columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS next_period_predicted TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS prediction_confidence DECIMAL(3,2) DEFAULT 0.50;
ALTER TABLE users ADD COLUMN IF NOT EXISTS prediction_method TEXT DEFAULT 'static';
ALTER TABLE users ADD COLUMN IF NOT EXISTS average_cycle_length DECIMAL(5,2);

-- Track prediction accuracy over time
CREATE TABLE IF NOT EXISTS prediction_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  cycle_number INT NOT NULL,
  predicted_date DATE NOT NULL,
  actual_date DATE,
  error_days INT,
  prediction_method TEXT,
  confidence_at_prediction DECIMAL(3,2),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_prediction_logs_user ON prediction_logs(user_id, cycle_number DESC);

-- Enable RLS
ALTER TABLE prediction_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own prediction logs" ON prediction_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own prediction logs" ON prediction_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own prediction logs" ON prediction_logs
  FOR UPDATE USING (auth.uid() = user_id);
```

**Testing**: Run migration in Supabase SQL Editor, verify columns exist.

---

### Step 1.2: Create CycleAnalyzer Service

**New file**: `lib/services/cycle_analyzer.dart`

```dart
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/period.dart';

/// Handles cycle length calculations and predictions
class CycleAnalyzer {
  static final _supabase = SupabaseService();
  
  /// Generate initial predictions for new users (Instance 3)
  static Future<void> generateInitialPredictions(String userId) async {
    try {
      final userData = await _supabase.getUserData();
      final lastPeriodStart = DateTime.parse(userData['last_period_start']);
      final cycleLength = userData['cycle_length'] as int;
      
      // Calculate first prediction using self-reported cycle length
      final nextPeriodDate = lastPeriodStart.add(Duration(days: cycleLength));
      
      // Store prediction with low confidence (50% - based on self-report)
      await _supabase.updateUserData({
        'next_period_predicted': nextPeriodDate.toIso8601String(),
        'prediction_confidence': 0.50,
        'prediction_method': 'self_reported',
      });
      
      // Log this prediction for future accuracy tracking
      await _logPrediction(
        userId: userId,
        cycleNumber: 1,
        predictedDate: nextPeriodDate,
        confidence: 0.50,
        method: 'self_reported',
      );
      
      debugPrint('✅ Initial prediction: ${nextPeriodDate.toLocal()}');
    } catch (e) {
      debugPrint('❌ Error generating initial predictions: $e');
    }
  }
  
  /// Recalculate predictions based on actual logged periods (Instance 6)
  static Future<void> recalculateAfterPeriodStart(String userId) async {
    try {
      // Get all completed periods (sorted newest first)
      final periods = await _supabase.getCompletedPeriods(limit: 12);
      
      if (periods.isEmpty) {
        debugPrint('⚠️ No periods to analyze');
        return;
      }
      
      // Calculate cycle lengths from completed periods
      final cycleLengths = <int>[];
      for (int i = 0; i < periods.length - 1; i++) {
        final currentPeriod = periods[i];
        final nextPeriod = periods[i + 1];
        final cycleLength = nextPeriod.startDate.difference(currentPeriod.startDate).inDays;
        cycleLengths.add(cycleLength);
      }
      
      if (cycleLengths.isEmpty) {
        debugPrint('⚠️ Need at least 2 periods to calculate cycle length');
        return;
      }
      
      // LEARNING ALGORITHM: Simple Moving Average (for now)
      final averageCycleLength = _calculateSimpleAverage(cycleLengths);
      final confidence = _calculateConfidence(cycleLengths);
      
      // Get most recent period
      final lastPeriod = periods.first;
      final nextPredicted = lastPeriod.startDate.add(
        Duration(days: averageCycleLength.round())
      );
      
      // Update database
      await _supabase.updateUserData({
        'cycle_length': averageCycleLength.round(),
        'average_cycle_length': averageCycleLength,
        'next_period_predicted': nextPredicted.toIso8601String(),
        'prediction_confidence': confidence,
        'prediction_method': 'simple_average',
      });
      
      // Log the new prediction
      await _logPrediction(
        userId: userId,
        cycleNumber: cycleLengths.length + 1,
        predictedDate: nextPredicted,
        confidence: confidence,
        method: 'simple_average',
      );
      
      debugPrint('✅ Recalculated: ${averageCycleLength.toStringAsFixed(1)} days avg, ${(confidence * 100).toStringAsFixed(0)}% confidence');
    } catch (e) {
      debugPrint('❌ Error recalculating predictions: $e');
    }
  }
  
  /// Calculate simple average of cycle lengths
  static double _calculateSimpleAverage(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return 28.0;
    
    final sum = cycleLengths.reduce((a, b) => a + b);
    return sum / cycleLengths.length;
  }
  
  /// Calculate confidence based on variance
  /// Low variance = high confidence
  static double _calculateConfidence(List<int> cycleLengths) {
    if (cycleLengths.length == 1) return 0.65; // Single data point
    if (cycleLengths.length == 2) return 0.75; // Two data points
    
    // Calculate standard deviation
    final mean = _calculateSimpleAverage(cycleLengths);
    final variance = cycleLengths.map((x) => 
      (x - mean) * (x - mean)
    ).reduce((a, b) => a + b) / cycleLengths.length;
    
    final stdDev = sqrt(variance);
    
    // Map stdDev to confidence (inverse relationship)
    // stdDev < 2: 95% confidence (very regular)
    // stdDev = 5: 80% confidence (moderate)
    // stdDev > 10: 60% confidence (irregular)
    
    if (stdDev < 2) return 0.95;
    if (stdDev > 10) return 0.60;
    
    // Linear interpolation
    return 0.95 - (stdDev / 10) * 0.35;
  }
  
  /// Log prediction for accuracy tracking
  static Future<void> _logPrediction({
    required String userId,
    required int cycleNumber,
    required DateTime predictedDate,
    required double confidence,
    required String method,
  }) async {
    try {
      await _supabase.client.from('prediction_logs').insert({
        'user_id': userId,
        'cycle_number': cycleNumber,
        'predicted_date': predictedDate.toIso8601String(),
        'confidence_at_prediction': confidence,
        'prediction_method': method,
      });
    } catch (e) {
      debugPrint('⚠️ Failed to log prediction: $e');
    }
  }
  
  /// Update prediction log when period actually starts (Truth Event)
  static Future<void> recordPredictionAccuracy({
    required String userId,
    required int cycleNumber,
    required DateTime actualDate,
  }) async {
    try {
      // Find the prediction for this cycle
      final logs = await _supabase.client
        .from('prediction_logs')
        .select()
        .eq('user_id', userId)
        .eq('cycle_number', cycleNumber)
        .limit(1);
      
      if (logs.isEmpty) {
        debugPrint('⚠️ No prediction log found for cycle $cycleNumber');
        return;
      }
      
      final log = logs.first;
      final predictedDate = DateTime.parse(log['predicted_date']);
      final errorDays = actualDate.difference(predictedDate).inDays;
      
      // Update the log
      await _supabase.client
        .from('prediction_logs')
        .update({
          'actual_date': actualDate.toIso8601String(),
          'error_days': errorDays,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', log['id']);
      
      debugPrint('📊 Prediction accuracy: ${errorDays.abs()} days ${errorDays > 0 ? "late" : "early"}');
    } catch (e) {
      debugPrint('❌ Error recording accuracy: $e');
    }
  }
}
```

**Testing**:
```dart
// test/services/cycle_analyzer_test.dart
void main() {
  group('CycleAnalyzer', () {
    test('calculates simple average correctly', () {
      final avg = CycleAnalyzer._calculateSimpleAverage([28, 29, 27, 30]);
      expect(avg, 28.5);
    });
    
    test('confidence increases with more data', () {
      final conf1 = CycleAnalyzer._calculateConfidence([28]);
      final conf3 = CycleAnalyzer._calculateConfidence([28, 29, 27]);
      
      expect(conf3, greaterThan(conf1));
    });
  });
}
```

---

### Step 1.3: Integrate Truth Event in SupabaseService

**File to modify**: `lib/services/supabase_service.dart`

Find the `startPeriod()` method and enhance it:

```dart
// BEFORE (existing code around line 380-400)
Future<void> startPeriod([DateTime? startDate]) async {
  final today = startDate ?? DateTime.now();
  final userId = await getCurrentUserId();
  
  // Create new period
  await client.from('periods').insert({
    'user_id': userId,
    'start_date': today.toIso8601String(),
    'is_predicted': false,
  });
  
  // Update user's last period start
  await updateUserData({'last_period_start': today.toIso8601String()});
}

// AFTER (enhanced with learning)
Future<void> startPeriod([DateTime? startDate]) async {
  final today = startDate ?? DateTime.now();
  final userId = await getCurrentUserId();
  final userData = await getUserData();
  
  // STEP 1: Close previous period if exists
  final lastPeriodStart = userData['last_period_start'] != null
    ? DateTime.parse(userData['last_period_start'])
    : null;
  
  if (lastPeriodStart != null) {
    // Calculate cycle number for this truth event
    final completedPeriods = await getCompletedPeriods(limit: 100);
    final cycleNumber = completedPeriods.length + 1;
    
    // Record prediction accuracy (Instance 6: Truth Event)
    await CycleAnalyzer.recordPredictionAccuracy(
      userId: userId,
      cycleNumber: cycleNumber,
      actualDate: today,
    );
  }
  
  // STEP 2: Create new period
  await client.from('periods').insert({
    'user_id': userId,
    'start_date': today.toIso8601String(),
    'is_predicted': false,
  });
  
  // STEP 3: Update user's last period start
  await updateUserData({'last_period_start': today.toIso8601String()});
  
  // STEP 4: RECALCULATE all predictions based on new data
  await CycleAnalyzer.recalculateAfterPeriodStart(userId);
  
  debugPrint('✅ Period started, predictions recalculated');
}
```

**Testing**: 
1. Start a period manually
2. Check `prediction_logs` table for accuracy record
3. Verify `users.next_period_predicted` updated
4. Check `users.prediction_confidence` increased

---

### Step 1.4: Update Onboarding to Generate Initial Predictions

**File to modify**: `lib/screens/onboarding/onboarding_screen.dart`

Find the `_saveOnboardingData()` method (around line 600-650):

```dart
// Add this AFTER saving user data
Future<void> _saveOnboardingData() async {
  // ... existing code to save data ...
  
  await SupabaseService().saveUserData({
    'last_period_start': _lastPeriodStart!.toIso8601String(),
    'cycle_length': _cycleLength,
    'period_length': _periodLength,
    'has_completed_onboarding': true,
  });
  
  // ✨ NEW: Generate initial predictions (Instance 3)
  final userId = await SupabaseService().getCurrentUserId();
  await CycleAnalyzer.generateInitialPredictions(userId);
  
  // Navigate to home
  // ... existing navigation code ...
}
```

**Testing**:
1. Complete onboarding with new account
2. Check `users.next_period_predicted` is set
3. Verify `prediction_logs` has entry with method='self_reported'
4. Check confidence = 0.50

---

### Step 1.5: Display Predictions on Home Screen

**File to modify**: `lib/screens/main/home_screen.dart`

Add prediction display widget:

```dart
// Add new method around line 300
Widget _buildPredictionCard() {
  return Consumer(
    builder: (context, ref, child) {
      final userData = ref.watch(userDataProvider);
      
      return userData.when(
        data: (data) {
          final nextPredicted = data['next_period_predicted'] != null
            ? DateTime.parse(data['next_period_predicted'])
            : null;
          final confidence = data['prediction_confidence'] as double? ?? 0.5;
          
          if (nextPredicted == null) return SizedBox.shrink();
          
          final daysUntil = nextPredicted.difference(DateTime.now()).inDays;
          
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text('Next Period Prediction',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Prediction date with confidence
                  Text(
                    _getPredictionText(daysUntil, confidence),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Confidence indicator
                  LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      confidence > 0.8 ? Colors.green :
                      confidence > 0.6 ? Colors.orange :
                      Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}% confidence',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => SizedBox.shrink(),
        error: (_, __) => SizedBox.shrink(),
      );
    },
  );
}

String _getPredictionText(int daysUntil, double confidence) {
  if (daysUntil <= 0) return 'Your period may have started';
  if (daysUntil == 1) return 'Your period may start tomorrow';
  
  // Adjust language based on confidence
  if (confidence >= 0.85) {
    return 'Your period will likely start in $daysUntil days';
  } else if (confidence >= 0.65) {
    return 'Your period is expected in about $daysUntil days';
  } else {
    return 'Your period may start around $daysUntil days from now';
  }
}

// Add to build() method's Column children (around line 200)
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildWeekStrip(),
          _buildPredictionCard(), // ✨ ADD THIS
          _buildQuickActions(),
          // ... rest of widgets
        ],
      ),
    ),
  );
}
```

**Testing**:
1. Open home screen
2. Verify prediction card shows next period date
3. Check confidence percentage matches database
4. Complete a period, verify prediction updates

---

## Phase 2: Symptom Intelligence (Real-time Adjustment)

**Goal**: Use symptoms to adjust predictions in real-time (Instance 5).

**Timeline**: 2 weeks  
**Complexity**: Medium-High  
**Dependencies**: Phase 1 complete

### Step 2.1: Create SymptomMonitor Service

**New file**: `lib/services/symptom_monitor.dart`

```dart
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/symptom.dart';

/// Monitors symptoms for predictive signals (Instance 5)
class SymptomMonitor {
  static final _supabase = SupabaseService();
  
  /// Symptom patterns learned from historical data
  static const Map<String, Map<String, dynamic>> SYMPTOM_PATTERNS = {
    'Cramps': {'days_before_period': 2, 'confidence_boost': 0.20},
    'Spotting': {'days_before_period': 1, 'confidence_boost': 0.25},
    'Tender Breasts': {'days_before_period': 3, 'confidence_boost': 0.15},
    'Bloating': {'days_before_period': 2, 'confidence_boost': 0.10},
    'Acne': {'days_before_period': 5, 'confidence_boost': 0.10},
  };
  
  /// Check for predictive signals when symptoms are logged
  static Future<void> checkForPredictiveSignals(String userId) async {
    try {
      final userData = await _supabase.getUserData();
      final predictedDate = userData['next_period_predicted'] != null
        ? DateTime.parse(userData['next_period_predicted'])
        : null;
      
      if (predictedDate == null) return;
      
      final today = DateTime.now();
      final daysUntilPrediction = predictedDate.difference(today).inDays;
      
      // Get recent symptoms (last 3 days)
      final recentSymptoms = await _supabase.getSymptomsInRange(
        startDate: today.subtract(Duration(days: 3)),
        endDate: today,
      );
      
      if (recentSymptoms.isEmpty) return;
      
      // Check each symptom for predictive signals
      for (final symptom in recentSymptoms) {
        if (SYMPTOM_PATTERNS.containsKey(symptom.type)) {
          await _processSymptomSignal(
            userId: userId,
            symptom: symptom,
            currentPrediction: predictedDate,
            daysUntil: daysUntilPrediction,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking symptom signals: $e');
    }
  }
  
  static Future<void> _processSymptomSignal({
    required String userId,
    required Symptom symptom,
    required DateTime currentPrediction,
    required int daysUntil,
  }) async {
    final pattern = SYMPTOM_PATTERNS[symptom.type]!;
    final expectedDaysBefore = pattern['days_before_period'] as int;
    final confidenceBoost = pattern['confidence_boost'] as double;
    
    // Check if symptom timing matches pattern
    if ((daysUntil - expectedDaysBefore).abs() <= 2) {
      // SYMPTOM MATCHES PATTERN - Increase confidence
      final userData = await _supabase.getUserData();
      final currentConfidence = userData['prediction_confidence'] as double? ?? 0.5;
      final newConfidence = (currentConfidence + confidenceBoost).clamp(0.0, 0.99);
      
      await _supabase.updateUserData({
        'prediction_confidence': newConfidence,
        'prediction_method': 'symptom_adjusted',
      });
      
      debugPrint('✨ ${symptom.type} detected → Confidence: ${(currentConfidence * 100).toStringAsFixed(0)}% → ${(newConfidence * 100).toStringAsFixed(0)}%');
      
      // Optionally send notification
      if (newConfidence >= 0.85) {
        await NotificationService().showNotification(
          title: '💡 Prediction Updated',
          body: 'Based on your ${symptom.type}, your period may start soon. Make sure you\'re prepared!',
        );
      }
    }
  }
  
  /// Run passive monitoring (called on app open)
  static Future<void> runPassiveMonitoring(String userId) async {
    await checkForPredictiveSignals(userId);
  }
}
```

**Testing**:
```dart
test('Symptom increases confidence when within pattern window', () async {
  // Setup: Period predicted in 3 days, user logs "Cramps"
  // Expected: Confidence increases by 20%
});
```

---

### Step 2.2: Integrate Symptom Monitoring

**File to modify**: `lib/screens/main/home_screen.dart`

```dart
// Add to initState() (around line 80)
@override
void initState() {
  super.initState();
  _loadData();
  
  // ✨ NEW: Run passive symptom monitoring on app open
  _runPassiveMonitoring();
}

Future<void> _runPassiveMonitoring() async {
  try {
    final userId = await SupabaseService().getCurrentUserId();
    await SymptomMonitor.runPassiveMonitoring(userId);
    
    // Refresh UI to show updated confidence
    ref.invalidate(userDataProvider);
  } catch (e) {
    debugPrint('⚠️ Passive monitoring failed: $e');
  }
}
```

**File to modify**: `lib/providers/daily_log_provider.dart`

```dart
// Add after saving symptom (around line 100)
Future<void> saveSymptom(Symptom symptom) async {
  // ... existing save logic ...
  
  await SupabaseService().saveSymptom(symptom);
  
  // ✨ NEW: Check for predictive signals
  final userId = await SupabaseService().getCurrentUserId();
  await SymptomMonitor.checkForPredictiveSignals(userId);
  
  // Refresh home screen to show updated prediction
  ref.invalidate(userDataProvider);
}
```

**Testing**:
1. Log "Cramps" 2-3 days before predicted period
2. Verify confidence increases by ~20%
3. Check notification appears if confidence > 85%
4. Verify home screen prediction card updates

---

## Phase 3: Anomaly Detection (Statistical Intelligence)

**Timeline**: 3 weeks  
**Complexity**: High  
**Dependencies**: Phase 1 & 2 complete

### Step 3.1: Create Data Models

**New file**: `lib/models/cycle_vector.dart`

```dart
class CycleVector {
  final int cycleNumber;
  final DateTime startDate;
  final int totalLength;
  final int periodLength;
  final int follicularLength;
  final int lutealLength;
  final DateTime timestamp;
  
  CycleVector({
    required this.cycleNumber,
    required this.startDate,
    required this.totalLength,
    required this.periodLength,
    required this.follicularLength,
    required this.lutealLength,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'cycle_number': cycleNumber,
    'start_date': startDate.toIso8601String(),
    'total_length': totalLength,
    'period_length': periodLength,
    'follicular_length': follicularLength,
    'luteal_length': lutealLength,
  };
  
  factory CycleVector.fromJson(Map<String, dynamic> json) => CycleVector(
    cycleNumber: json['cycle_number'],
    startDate: DateTime.parse(json['start_date']),
    totalLength: json['total_length'],
    periodLength: json['period_length'],
    follicularLength: json['follicular_length'],
    lutealLength: json['luteal_length'],
    timestamp: DateTime.parse(json['created_at']),
  );
}
```

**New file**: `lib/models/outlier.dart`

```dart
enum Severity { low, moderate, high, extreme }
enum OutlierMethod { modifiedZScore, IQR, standardDeviation }

class Outlier {
  final int index;
  final int value;
  final double score;
  final Severity severity;
  final String method;
  
  Outlier({
    required this.index,
    required this.value,
    required this.score,
    required this.severity,
    required this.method,
  });
}
```

*(Continue with Step 3.2: Database migrations, Step 3.3: CycleAnomalyDetector service, etc.)*

---

## Implementation Priority Matrix

```
┌─────────────────────────────────────────────────────────┐
│ PRIORITY: What to Build First                          │
└─────────────────────────────────────────────────────────┘

🔴 CRITICAL (Do First - Foundation):
  1. Database migrations (prediction_logs table)
  2. CycleAnalyzer service (basic learning)
  3. Truth Event integration (startPeriod recalculation)
  4. Home screen prediction display

🟡 HIGH (Do Second - User Value):
  5. Symptom monitoring service
  6. Real-time confidence adjustment
  7. Prediction accuracy tracking

🟢 MEDIUM (Do Third - Advanced Features):
  8. Anomaly detection (Modified Z-Score)
  9. Context collection dialogs
  10. Exclude anomalies from calculations

🔵 LOW (Do Last - Polish):
  11. Exponential Moving Average
  12. Confidence clouds visualization
  13. Symptom correlation ML
```

---

## Testing Strategy Per Phase

### Phase 1 Testing Checklist
- [ ] New user completes onboarding → prediction_logs entry created
- [ ] User starts period → recalculation triggered
- [ ] Cycle length updates after 2+ periods
- [ ] Confidence increases with more cycles
- [ ] Home screen shows prediction with confidence

### Phase 2 Testing Checklist
- [ ] Log "Cramps" → confidence increases
- [ ] Symptom outside pattern window → no change
- [ ] High confidence → notification sent
- [ ] App open → passive monitoring runs

### Phase 3 Testing Checklist
- [ ] 45-day cycle → flagged as outlier
- [ ] User provides context → marked as anomaly
- [ ] Anomaly excluded from mean calculation
- [ ] Recalculation without anomaly → accurate prediction

---

## Success Metrics

### Phase 1: Basic Learning
- **Goal**: 70% prediction accuracy within ±2 days
- **Metric**: `AVG(ABS(error_days)) FROM prediction_logs`
- **Target**: < 2.0 days average error

### Phase 2: Symptom Intelligence
- **Goal**: 85% confidence when symptoms present
- **Metric**: `AVG(prediction_confidence WHERE prediction_method='symptom_adjusted')`
- **Target**: > 0.85

### Phase 3: Anomaly Detection
- **Goal**: Identify and exclude 90% of true anomalies
- **Metric**: `COUNT(*) FROM periods WHERE is_anomaly=true AND exclude_from_stats=true`
- **Target**: User-confirmed anomalies correctly excluded

---

## Code Review Checklist

Before merging each phase:

- [ ] All new code follows AGENTS.md architecture (agent-based design)
- [ ] Services use SupabaseService abstraction (no direct Supabase calls)
- [ ] State management uses Riverpod providers
- [ ] Error handling with try-catch and debug logging
- [ ] RLS policies enabled on all new tables
- [ ] Unit tests written with >80% coverage
- [ ] Integration tests for critical flows
- [ ] UI matches Design System (AppColors, ResponsiveSizing)
- [ ] No deprecated APIs used
- [ ] `dart analyze` passes with 0 errors

---

**Document Version**: 1.0  
**Last Updated**: January 2, 2026  
**Status**: Implementation Guide - Ready to Code
