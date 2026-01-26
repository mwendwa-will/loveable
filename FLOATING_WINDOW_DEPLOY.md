# Floating Window Implementation - Quick Deploy Guide

**Status**: ✅ READY TO DEPLOY

---

## Step 1: Run Database Migration (CRITICAL)

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Create a new query
3. Copy entire contents from: `migrations/20260106_add_cycle_metrics.sql`
4. Click **RUN**
5. Verify success (no errors)

**Expected Output:**
```
ALTER TABLE
CREATE TABLE
ALTER TABLE
CREATE POLICY (x3)
CREATE INDEX (x2)
UPDATE (multiple rows)
INSERT
```

---

## Step 2: Deploy Code

All code is already implemented in:
- ✅ `lib/services/cycle_analyzer.dart` - Floating window logic
- ✅ `lib/widgets/cycle_insights.dart` - NEW shift detection widget
- ✅ `lib/widgets/prediction_card.dart` - Updated with dual predictions
- ✅ `lib/screens/main/home_screen.dart` - Integrated CycleInsights

**No additional code changes needed!**

---

## Step 3: Test on Device

### Quick Test (5 minutes):
```
1. Run: flutter pub get
2. Run: flutter run
3. Navigate to Home Screen
4. Verify: PredictionCard displays
5. Verify: CycleInsights widget renders (if shift detected)
6. Check console: No errors in debug output
```

### Full Test (30 minutes):
Follow "Testing Checklist" in [FLOATING_WINDOW_IMPLEMENTATION.md](FLOATING_WINDOW_IMPLEMENTATION.md)

---

## Step 4: Verify Database Updates

In Supabase SQL Editor, run:
```sql
-- Check migration success
SELECT 
  COUNT(*) as total_users,
  COUNT(baseline_cycle_length) as with_baseline,
  COUNT(recent_average_cycle_length) as with_recent,
  COUNT(cycle_variability) as with_variability
FROM public.users;

-- Check anomalies table exists
SELECT COUNT(*) as anomalies FROM public.cycle_anomalies;
```

**Expected:**
- All users have baseline_cycle_length
- All users have recent_average_cycle_length
- cycle_anomalies table empty (until user triggers anomaly)

---

## If Something Goes Wrong

### "Users table doesn't have new columns"
→ Migration didn't run. Go back to Step 1 and run it.

### "CycleInsights widget not found"
→ Clear Flutter cache: `flutter clean` then `flutter pub get`

### "Prediction card looks weird"
→ May need hot restart (not just reload): `flutter run`

### "Anomaly detection not working"
→ Check that periods have both start_date AND end_date
→ User must mark period as complete for it to be "completed"

---

## What Users Will See

### Before (Old System):
```
Next Period: Friday, Jan 31
Confidence: 75%
```

### After (New System):
```
Next Period Prediction: Friday, Jan 31
Based on recent cycles (adapts to changes)
Confidence: 78%

[If pattern stayed the same: Friday, Jan 28 — strikethrough]

[CycleInsights widget — only shows if shift detected]
```

---

## Key Metrics Tracked

Per user, we now track:
- `baseline_cycle_length` - Original self-reported (never changes)
- `recent_average_cycle_length` - Current prediction (updates each cycle)
- `cycle_variability` - Regularity measure (0-10+ scale)
- `prediction_method` - 'floating_window', 'simple_average', or 'self_reported'
- `detected_anomalies` - Count of outliers

---

## Rollback Plan

If major issues occur:

1. **Quick rollback**: Just don't use the migration, app continues with old system
2. **Full rollback**: Drop the new columns:
   ```sql
   ALTER TABLE public.users
   DROP COLUMN IF EXISTS recent_average_cycle_length,
   DROP COLUMN IF EXISTS baseline_cycle_length,
   DROP COLUMN IF EXISTS cycle_variability,
   DROP COLUMN IF EXISTS detected_anomalies;
   
   DROP TABLE IF EXISTS public.cycle_anomalies;
   ```

---

## Performance Impact

- **Database**: Minimal (4 new indexed columns)
- **API calls**: Same as before (no new endpoints)
- **Memory**: Same (calculations are O(6) = constant)
- **UI**: Slightly more processing (shift detection) but negligible

---

## Success Criteria

✅ You'll know it's working when:

1. App launches without errors
2. Prediction card displays next period
3. After 3+ logged periods, CycleInsights may show (if shift detected)
4. Console shows floating window calculations
5. Database has data in cycle_anomalies (if anomaly triggered)

---

## Support

For issues, check:
1. Migration status in Supabase
2. Console debug output
3. [FLOATING_WINDOW_IMPLEMENTATION.md](FLOATING_WINDOW_IMPLEMENTATION.md) - Full docs
4. Code comments in cycle_analyzer.dart

---

**Estimated Deployment Time**: 10 minutes (5 min migration + 5 min testing)

Ready to deploy! 🚀
