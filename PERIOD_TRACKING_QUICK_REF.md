# Period Tracking Issue - Quick Reference

## The Issue in One Example

### Scenario: User Corrects Their Period Date

```
Day 1 (User onboards):
├─ User says: "Last period started January 1"
├─ Database saves: users.last_period_start = "2026-01-01"
├─ Prediction: January 31 (Jan 1 + 30 days) ✅

Day 5 (User realizes mistake):
├─ User: "Actually, my period started December 28"
├─ User: Opens calendar and logs Dec 28
├─ System calls: startPeriod(startDate: Dec 28)
│
├─ PROBLEM: startPeriod() does this:
│  ├─ await updateUserData({
│  │  'last_period_start': Dec 28,  ← OVERWRITES Jan 1 ❌
│  │})
│  ├─ await CycleAnalyzer.recalculateAfterPeriodStart()
│  │  ├─ Reads from periods table
│  │  ├─ Sees Dec 28 as newest period
│  │  ├─ Uses Dec 28 as anchor
│  │  └─ Predicts: Jan 27 (Dec 28 + 30)
│  │
│  └─ Result: Original onboarded date LOST ❌

Result:
├─ users.last_period_start = "2026-12-28" (was Jan 1!)
├─ users.next_period_predicted = "2026-01-27" (was Jan 31!)
├─ Prediction confidence may drop
└─ Cycle history incomplete ❌
```

---

## Code References

### Where It Happens

**File**: [lib/services/supabase_service.dart](lib/services/supabase_service.dart#L520-L530)

```dart
// STEP 3: Update user's last period start
// ❌ PROBLEM: This overwrites the onboarding date!
await updateUserData({'last_period_start': startDate.toIso8601String()});

// STEP 4: Recalculate using the new (overwritten) date
await CycleAnalyzer.recalculateAfterPeriodStart(user.id);
```

---

## What Should Happen

```
Database Schema (Current):
├─ users.last_period_start (Date of last period)
└─ users.average_cycle_length (Calculated average)

Database Schema (Proposed):
├─ users.onboarding_period_start (Original onboarded date) ← NEW
├─ users.last_period_start (Most recent logged period)
└─ users.average_cycle_length (Calculated from periods table)

When retroactively logging a date:
1. Check if date is earlier than existing periods
2. Insert as separate period record (don't overwrite)
3. Recalculate based on ORDERED periods, not just the new one
4. Keep onboarding_period_start unchanged
```

---

## Impact Analysis

### Who Is Affected?
- **Any user** who logs a period date different from today
- **Any user** who corrects a previously logged period
- **Any user** who realizes their onboarded date was wrong

### What Breaks?
- 🔴 Onboarded period is lost
- 🔴 Prediction recalculation uses wrong anchor date
- 🔴 Cycle length calculation becomes inaccurate
- 🔴 Historical data becomes incomplete

### Severity: HIGH
- Directly impacts prediction accuracy
- Data loss (original onboarded date)
- Core feature of the app (cycle tracking)

---

## Fix Priority

| Fix | Effort | Impact | Priority |
|-----|--------|--------|----------|
| Add `onboarding_period_start` column | 1 day | High | 🔴 CRITICAL |
| Update SupabaseService to preserve it | 1 hour | High | 🔴 CRITICAL |
| Update prediction logic to use it | 2 hours | High | 🔴 CRITICAL |
| Add validation for retroactive dates | 1 day | Medium | 🟡 HIGH |
| Add data migration for existing users | 2 hours | Medium | 🟡 HIGH |

---

## Testing Checklist

- [ ] User onboards with date = Dec 28
- [ ] Prediction generated = Jan 27
- [ ] User logs period on Jan 15 for Dec 25 (earlier date)
- [ ] Verify: users.onboarding_period_start = Dec 28 (unchanged)
- [ ] Verify: Periods table has both Dec 25 and Dec 28
- [ ] Verify: Cycle calculation uses both periods correctly
- [ ] Verify: Prediction stays accurate

