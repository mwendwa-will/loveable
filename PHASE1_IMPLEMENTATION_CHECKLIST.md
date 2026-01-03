# Phase 1 Implementation Checklist

## Pre-Implementation Steps

### 1. Database Migration
- [ ] Open Supabase Dashboard → SQL Editor
- [ ] Copy contents of `database_migrations_phase1.sql`
- [ ] Run migration
- [ ] Verify tables created:
  - [ ] `prediction_logs` table exists
  - [ ] `users` table has new columns: `next_period_predicted`, `prediction_confidence`, `prediction_method`, `average_cycle_length`
- [ ] Test RLS policies with test query

### 2. Code Review
- [ ] Review `lib/services/cycle_analyzer.dart` (new file)
- [ ] Review changes to `lib/services/supabase_service.dart`
- [ ] Review changes to `lib/screens/onboarding/onboarding_screen.dart`
- [ ] Review `lib/widgets/prediction_card.dart` (new file)
- [ ] Review `lib/screens/settings/cycle_settings_screen.dart` (new file)

---

## Implementation Steps

### Step 1: Run Database Migration
```bash
# In Supabase SQL Editor, paste and run:
# database_migrations_phase1.sql
```

Expected output:
```
ALTER TABLE
CREATE TABLE
CREATE INDEX
ALTER TABLE (enable RLS)
CREATE POLICY (x3)
COMMENT (x3)
```

### Step 2: Test the Code
```bash
# Analyze for errors
dart analyze

# Expected: 0 errors, 0 warnings
```

### Step 3: Create Test User
1. Delete existing test account (optional - for fresh start)
2. Sign up new account
3. Complete onboarding with last period date
4. Verify:
   - [ ] Console shows: "✅ Initial prediction generated"
   - [ ] Database has entry in `prediction_logs` table
   - [ ] `users.next_period_predicted` is set
   - [ ] `users.prediction_confidence` = 0.50

### Step 4: Test Home Screen
1. Open app after onboarding
2. Verify Prediction Card shows:
   - [ ] Next period date
   - [ ] Confidence bar (50% - red)
   - [ ] Method: "Based on your estimated cycle length"
   - [ ] Tip: "Low confidence - prediction will improve over time"

### Step 5: Test Truth Event (Period Start)
1. Wait or manually set date forward
2. Tap "Start Period" (FAB or elsewhere)
3. Select today or custom date
4. Verify console logs:
   - [ ] "📊 Prediction accuracy: X days early/late"
   - [ ] "✅ Recalculated: X.X days avg, XX% confidence"
5. Check database:
   - [ ] `prediction_logs.actual_date` is filled
   - [ ] `prediction_logs.error_days` is calculated
   - [ ] `users.prediction_confidence` increased (if 2+ cycles)

### Step 6: Test Cycle Settings Screen
1. Navigate: Profile → (need to add menu item)
2. Or directly navigate for testing
3. Verify:
   - [ ] Prediction accuracy card shows if data exists
   - [ ] Cycle length slider works (21-45 days)
   - [ ] Period length slider works (2-10 days)
   - [ ] Last period date picker works
   - [ ] Save button triggers recalculation

---

## Testing Scenarios

### Scenario 1: New User Journey
```
Day 1: Onboarding
  - Sets last period: Jan 1
  - Sets cycle length: 30 days
  - Expected prediction: Jan 31 (50% confidence)

Day 30: First Truth Event
  - Actual period: Jan 29 (2 days early)
  - Expected: Cycle length updates to 28 days
  - Expected: Confidence increases to ~65%
  - Expected: Next prediction: Feb 26

Day 58: Second Truth Event
  - Actual period: Feb 27 (1 day late)
  - Expected: Cycle length updates to 28.5 days
  - Expected: Confidence increases to ~75%
```

### Scenario 2: Settings Adjustment
```
1. User opens Cycle Settings
2. Changes cycle length from 28 to 30 days
3. Taps Save
4. Expected: Next prediction shifts by 2 days
5. Expected: Confidence may drop (manual override)
```

### Scenario 3: Irregular Cycles
```
Cycle 1: 28 days (confidence: 65%)
Cycle 2: 29 days (confidence: 75%)
Cycle 3: 45 days (huge outlier)
Expected: Confidence drops to ~60%
Expected: Average includes outlier (Phase 3 will exclude)
```

---

## Verification Queries

### Check Prediction Logs
```sql
SELECT 
  cycle_number,
  predicted_date,
  actual_date,
  error_days,
  prediction_method,
  confidence_at_prediction
FROM prediction_logs
WHERE user_id = 'YOUR_USER_ID'
ORDER BY cycle_number DESC;
```

### Check User Predictions
```sql
SELECT 
  username,
  cycle_length,
  average_cycle_length,
  next_period_predicted,
  prediction_confidence,
  prediction_method
FROM users
WHERE id = 'YOUR_USER_ID';
```

### Calculate Accuracy
```sql
SELECT 
  COUNT(*) as total_predictions,
  AVG(ABS(error_days)) as avg_error,
  COUNT(CASE WHEN ABS(error_days) <= 2 THEN 1 END) * 100.0 / COUNT(*) as accuracy_percent
FROM prediction_logs
WHERE user_id = 'YOUR_USER_ID'
  AND actual_date IS NOT NULL;
```

---

## Troubleshooting

### Issue: "Table prediction_logs does not exist"
**Solution**: Run the migration SQL in Supabase dashboard

### Issue: Prediction not showing on home screen
**Checklist**:
- [ ] Migration ran successfully?
- [ ] Onboarding completed?
- [ ] `users.next_period_predicted` has value?
- [ ] PredictionCard widget added to HomeScreen?

### Issue: Confidence not updating after period start
**Checklist**:
- [ ] `CycleAnalyzer.recalculateAfterPeriodStart()` being called?
- [ ] At least 2 completed periods in database?
- [ ] Check console for error logs

### Issue: Import errors
**Solution**: Ensure all imports added:
```dart
// supabase_service.dart
import 'package:lovely/services/cycle_analyzer.dart';

// onboarding_screen.dart
import 'package:lovely/services/cycle_analyzer.dart';

// home_screen.dart
import 'package:lovely/widgets/prediction_card.dart';
```

---

## Next Steps After Phase 1

Once Phase 1 is working:

1. **Add Settings Navigation**
   - Add "Cycle Settings" to Profile screen menu
   - Or add gear icon to Prediction Card

2. **Enhanced Period Start Dialog**
   - Show prediction accuracy in dialog
   - Add "This was X days early/late" message

3. **Start Phase 2: Symptom Intelligence**
   - See `IMPLEMENTATION_ROADMAP.md` for Phase 2 steps

---

## Success Criteria

Phase 1 is complete when:
- [x] Database migration successful
- [x] New user can complete onboarding
- [x] Prediction Card shows on home screen
- [x] Confidence is 50% for new users
- [x] Starting period triggers recalculation
- [x] Cycle Settings screen works
- [x] Confidence increases with more cycles
- [x] Prediction accuracy is logged

---

**Document Version**: 1.0  
**Last Updated**: January 2, 2026  
**Status**: Ready for Implementation
