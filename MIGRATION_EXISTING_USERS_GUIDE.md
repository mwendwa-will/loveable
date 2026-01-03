# Migration Guide: Existing Users vs New Users

## For Existing Users (Already Have Period Data)

### What Happens During Migration

1. **Database columns added** with safe defaults
2. **Historical periods analyzed** automatically
3. **Predictions calculated** from actual data
4. **Confidence determined** by regularity

### Backfill Process

The migration includes a smart backfill function that:

```sql
FOR EACH existing user WITH period data:
  1. Fetch all completed periods (with end_date)
  2. Calculate actual cycle lengths between periods
  3. Compute average cycle length
  4. Calculate standard deviation (regularity)
  5. Determine confidence score
  6. Generate next period prediction
  7. Update user record
```

### Examples

#### Existing User A: Has 5 logged periods
```
Periods: Jan 1, Jan 29, Feb 27, Mar 28, Apr 26
Cycle lengths: [28, 29, 29, 29] days
Average: 28.75 days
Standard deviation: 0.5 (very regular)
Confidence: 95%
Next predicted: May 25
Method: 'simple_average'
```

#### Existing User B: Has 2 logged periods
```
Periods: Jan 1, Feb 2
Cycle lengths: [32] days
Average: 32 days
Confidence: 65% (only 1 cycle)
Next predicted: Mar 6
Method: 'simple_average'
```

#### Existing User C: Has 1 period (ongoing)
```
Periods: Jan 1 (no end_date yet)
Cycle lengths: []
Falls back to: Self-reported cycle_length (28 days)
Confidence: 50% (no actual data)
Next predicted: Jan 29
Method: 'self_reported'
```

---

## Migration Output Example

When you run the migration, you'll see:

```
NOTICE:  Backfilled predictions for user maya123: cycle=28.5 days, confidence=85%, method=simple_average
NOTICE:  Backfilled predictions for user sarah_doe: cycle=30.0 days, confidence=75%, method=simple_average
NOTICE:  Backfilled predictions for user jane_w: cycle=28.0 days, confidence=50%, method=self_reported
NOTICE:  Backfill complete!
```

---

## User Experience After Migration

### Existing Users See:

#### Home Screen
```
┌─────────────────────────────────────────────┐
│ 📅 Next Period Prediction                  │
│ Learning from your tracked cycles           │ ← Smart message
│                                             │
│ Your period will likely start in 12 days   │
│ 🗓️ Thursday, January 14                    │
│                                             │
│ Confidence                            85%   │ ← Calculated from real data
│ ████████████████████████░░░░                │
│                                             │
│ 💡 High confidence - pattern established   │
└─────────────────────────────────────────────┘
```

#### Cycle Settings Screen
```
┌─────────────────────────────────────────────┐
│ 📊 Prediction Accuracy                     │
│                                             │
│ Current Confidence:                   85%   │
│ ████████████████████████░░░░                │
│                                             │
│ Total Predictions:            0             │ ← No predictions logged yet
│ Average Error:                N/A           │ ← Will fill as cycles complete
│ Accuracy (±2 days):           N/A           │
│ Method:                       simple average│ ← Based on history
└─────────────────────────────────────────────┘
```

---

## What Gets Updated

### `users` Table - BEFORE Migration
```sql
| id      | cycle_length | last_period_start | next_period_predicted | prediction_confidence | prediction_method |
|---------|--------------|-------------------|----------------------|----------------------|-------------------|
| user123 | 28           | 2025-12-20        | NULL                 | NULL                 | NULL              |
```

### `users` Table - AFTER Migration
```sql
| id      | cycle_length | average_cycle_length | last_period_start | next_period_predicted | prediction_confidence | prediction_method |
|---------|--------------|---------------------|-------------------|----------------------|----------------------|-------------------|
| user123 | 28           | 28.75               | 2025-12-20        | 2026-01-18           | 0.85                 | simple_average    |
```

### `prediction_logs` Table - Initially Empty
```sql
| id | user_id | cycle_number | predicted_date | actual_date | error_days | confidence_at_prediction | prediction_method |
|----|---------|--------------|----------------|-------------|------------|-------------------------|-------------------|
| (empty - will populate as new periods start)                                                                             |
```

---

## Edge Cases Handled

### Case 1: User has ongoing period (no end_date)
- ✅ Uses last_period_start
- ✅ Falls back to self-reported cycle_length
- ✅ Confidence = 50%

### Case 2: User has irregular cycles
```
Cycles: [25, 28, 35, 29, 31]
Average: 29.6 days
Std Dev: 3.5 days
Confidence: ~72% (moderate variance)
```

### Case 3: User never started tracking
- ✅ No backfill (migration skips them)
- ✅ Predictions generated on first period log
- ✅ No errors thrown

---

## Testing for Existing Users

### Step 1: Check Current Data
```sql
-- See what users have
SELECT 
  u.username,
  u.cycle_length,
  COUNT(p.id) as period_count,
  COUNT(CASE WHEN p.end_date IS NOT NULL THEN 1 END) as completed_periods
FROM users u
LEFT JOIN periods p ON p.user_id = u.id
GROUP BY u.id, u.username, u.cycle_length
ORDER BY period_count DESC;
```

### Step 2: Run Migration
```sql
-- Execute database_migrations_phase1.sql
```

### Step 3: Verify Backfill
```sql
-- Check predictions were created
SELECT 
  username,
  average_cycle_length,
  TO_CHAR(prediction_confidence, 'FM990.00') as confidence,
  prediction_method,
  next_period_predicted::DATE as predicted_date
FROM users
WHERE next_period_predicted IS NOT NULL
ORDER BY prediction_confidence DESC;
```

### Step 4: Test in App
1. Open app as existing user
2. Verify Prediction Card shows
3. Check confidence matches database
4. Open Cycle Settings → verify stats

---

## Confidence Levels Explained

The backfill calculates confidence based on:

| Cycles Tracked | Std Dev | Confidence | Meaning |
|---------------|---------|------------|---------|
| 1 cycle       | Any     | 65%        | Pattern emerging |
| 2 cycles      | Any     | 75%        | More data |
| 3+ cycles     | < 2     | 95%        | Very regular |
| 3+ cycles     | 2-5     | 80-90%     | Regular |
| 3+ cycles     | 5-10    | 70-80%     | Moderate |
| 3+ cycles     | > 10    | 60%        | Irregular |

---

## App Behavior Changes

### BEFORE Migration
- Users see cycle day tracker
- No predictions displayed
- Manual period marking only

### AFTER Migration
- ✅ Prediction Card appears on home screen
- ✅ Confidence-based messaging
- ✅ Learning from historical data
- ✅ Settings to adjust if needed

---

## Rollback Plan (If Needed)

If something goes wrong:

```sql
-- Rollback: Remove new columns
ALTER TABLE users DROP COLUMN IF EXISTS next_period_predicted;
ALTER TABLE users DROP COLUMN IF EXISTS prediction_confidence;
ALTER TABLE users DROP COLUMN IF EXISTS prediction_method;
ALTER TABLE users DROP COLUMN IF EXISTS average_cycle_length;

-- Rollback: Drop new table
DROP TABLE IF EXISTS prediction_logs;
```

---

## Support Scenarios

### User Reports: "My prediction seems wrong"

**Check**:
```sql
SELECT 
  username,
  cycle_length as self_reported,
  average_cycle_length as calculated,
  prediction_confidence,
  prediction_method
FROM users
WHERE username = 'problem_user';

SELECT start_date, end_date
FROM periods
WHERE user_id = (SELECT id FROM users WHERE username = 'problem_user')
ORDER BY start_date DESC;
```

**Solution**: User can adjust in Cycle Settings screen

### User Reports: "I don't see predictions"

**Check**:
```sql
SELECT next_period_predicted 
FROM users 
WHERE username = 'problem_user';
```

**Causes**:
- User has no period data → Need to log first period
- Migration didn't run → Re-run migration
- UI bug → Check PredictionCard widget rendering

---

**Migration Safety**: ✅ Safe for production  
**Tested On**: New users, existing users, edge cases  
**Rollback Available**: Yes  
**User Impact**: Positive - instant smart predictions
