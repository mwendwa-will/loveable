-- ============================================
-- FIX: Add Period Duration Validation
-- ============================================
-- Prevents periods longer than 15 days (reasonable maximum)

-- 1. Clean existing bad data
DELETE FROM periods 
WHERE (end_date IS NOT NULL AND (end_date::date - start_date::date) > 15)
   OR (end_date IS NULL AND (NOW()::date - start_date::date) > 15);

-- 2. Add check constraint for future records
ALTER TABLE periods 
DROP CONSTRAINT IF EXISTS valid_period_duration;

ALTER TABLE periods 
ADD CONSTRAINT valid_period_duration 
CHECK (
  end_date IS NULL 
  OR (end_date::date - start_date::date) <= 15
);

-- 3. Add check that end_date is after start_date
ALTER TABLE periods
DROP CONSTRAINT IF EXISTS end_after_start;

ALTER TABLE periods
ADD CONSTRAINT end_after_start
CHECK (end_date IS NULL OR end_date >= start_date);

-- 4. Verify the fix
SELECT 
  id,
  start_date,
  end_date,
  CASE 
    WHEN end_date IS NULL THEN 'Ongoing'
    ELSE (end_date::date - start_date::date) || ' days'
  END as duration
FROM periods
WHERE user_id = auth.uid()
ORDER BY start_date DESC;
