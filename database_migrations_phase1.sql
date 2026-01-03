-- Phase 1: Basic Learning Engine - Database Migrations
-- Run this in Supabase SQL Editor

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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_prediction_logs_user ON prediction_logs(user_id, cycle_number DESC);
CREATE INDEX IF NOT EXISTS idx_prediction_logs_created ON prediction_logs(created_at DESC);

-- Enable RLS
ALTER TABLE prediction_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own prediction logs" ON prediction_logs;
CREATE POLICY "Users can view own prediction logs" ON prediction_logs
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own prediction logs" ON prediction_logs;
CREATE POLICY "Users can insert own prediction logs" ON prediction_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own prediction logs" ON prediction_logs;
CREATE POLICY "Users can update own prediction logs" ON prediction_logs
  FOR UPDATE USING (auth.uid() = user_id);

-- Add comment for documentation
COMMENT ON TABLE prediction_logs IS 'Tracks prediction accuracy to measure learning algorithm performance';
COMMENT ON COLUMN prediction_logs.error_days IS 'Negative = early, Positive = late';
COMMENT ON COLUMN users.prediction_confidence IS 'Range 0.00 to 0.99, higher = more accurate predictions';

-- ========================================
-- BACKFILL FOR EXISTING USERS
-- ========================================

-- Function to calculate average cycle length from historical periods
CREATE OR REPLACE FUNCTION calculate_user_cycle_stats(p_user_id UUID)
RETURNS TABLE (
  avg_cycle_length DECIMAL(5,2),
  confidence DECIMAL(3,2),
  next_predicted TIMESTAMP,
  method TEXT
) AS $$
DECLARE
  v_cycle_lengths INT[];
  v_cycle_count INT;
  v_avg_length DECIMAL(5,2);
  v_std_dev DECIMAL(5,2);
  v_confidence DECIMAL(3,2);
  v_last_period_start TIMESTAMP;
  v_user_cycle_length INT;
BEGIN
  -- Get completed periods (with end_date) for this user
  SELECT ARRAY_AGG(
    (lead_start::DATE - start_date::DATE)::INT
  )
  INTO v_cycle_lengths
  FROM (
    SELECT 
      start_date,
      LEAD(start_date) OVER (ORDER BY start_date) as lead_start
    FROM periods
    WHERE user_id = p_user_id
      AND end_date IS NOT NULL
    ORDER BY start_date
  ) cycle_calc
  WHERE lead_start IS NOT NULL;
  
  -- Get last period start date
  SELECT start_date INTO v_last_period_start
  FROM periods
  WHERE user_id = p_user_id
  ORDER BY start_date DESC
  LIMIT 1;
  
  -- Get user's self-reported cycle length
  SELECT average_cycle_length INTO v_user_cycle_length
  FROM users
  WHERE id = p_user_id;
  
  -- If no completed cycles, use self-reported data
  IF v_cycle_lengths IS NULL OR array_length(v_cycle_lengths, 1) = 0 THEN
    RETURN QUERY SELECT 
      v_user_cycle_length::DECIMAL(5,2),
      0.50::DECIMAL(3,2),
      v_last_period_start + (v_user_cycle_length || ' days')::INTERVAL,
      'self_reported'::TEXT;
    RETURN;
  END IF;
  
  -- Calculate statistics
  v_cycle_count := array_length(v_cycle_lengths, 1);
  
  SELECT AVG(val)::DECIMAL(5,2), STDDEV(val)::DECIMAL(5,2)
  INTO v_avg_length, v_std_dev
  FROM unnest(v_cycle_lengths) AS val;
  
  -- Calculate confidence based on variance
  IF v_cycle_count = 1 THEN
    v_confidence := 0.65;
  ELSIF v_cycle_count = 2 THEN
    v_confidence := 0.75;
  ELSIF v_std_dev < 2 THEN
    v_confidence := 0.95;
  ELSIF v_std_dev > 10 THEN
    v_confidence := 0.60;
  ELSE
    v_confidence := (0.95 - (v_std_dev / 10) * 0.35)::DECIMAL(3,2);
  END IF;
  
  -- Return results
  RETURN QUERY SELECT 
    v_avg_length,
    v_confidence,
    v_last_period_start + (v_avg_length || ' days')::INTERVAL,
    'simple_average'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Backfill predictions for all existing users with period data
DO $$
DECLARE
  v_user RECORD;
  v_stats RECORD;
BEGIN
  -- Loop through all users who have periods but no predictions
  FOR v_user IN 
    SELECT DISTINCT u.id, u.username
    FROM users u
    INNER JOIN periods p ON p.user_id = u.id
    WHERE u.next_period_predicted IS NULL
  LOOP
    -- Calculate stats for this user
    SELECT * INTO v_stats
    FROM calculate_user_cycle_stats(v_user.id);
    
    -- Update user with predictions
    UPDATE users
    SET 
      average_cycle_length = v_stats.avg_cycle_length,
      next_period_predicted = v_stats.next_predicted,
      prediction_confidence = v_stats.confidence,
      prediction_method = v_stats.method
    WHERE id = v_user.id;
    
    RAISE NOTICE 'Backfilled predictions for user %: cycle=% days, confidence=%, method=%', 
      v_user.username, 
      v_stats.avg_cycle_length, 
      v_stats.confidence,
      v_stats.method;
  END LOOP;
  
  RAISE NOTICE 'Backfill complete!';
END $$;

-- Handle users who completed onboarding but never logged periods
-- (Generate initial predictions for them)
DO $$
DECLARE
  v_user RECORD;
  v_predicted_date TIMESTAMP;
BEGIN
  -- Find users with last_period_start but no predictions and no period logs
  FOR v_user IN 
    SELECT u.id, u.username, u.last_period_start, u.average_cycle_length
    FROM users u
    LEFT JOIN periods p ON p.user_id = u.id
    WHERE u.last_period_start IS NOT NULL
      AND u.next_period_predicted IS NULL
      AND p.id IS NULL
  LOOP
    -- Calculate next period based on self-reported data
    v_predicted_date := v_user.last_period_start + (v_user.average_cycle_length || ' days')::INTERVAL;
    
    -- Update user with initial prediction
    UPDATE users
    SET 
      average_cycle_length = v_user.average_cycle_length::DECIMAL(5,2),
      next_period_predicted = v_predicted_date,
      prediction_confidence = 0.50,
      prediction_method = 'self_reported'
    WHERE id = v_user.id;
    
    RAISE NOTICE 'Generated initial prediction for onboarded user %: next period on %', 
      v_user.username,
      v_predicted_date::DATE;
  END LOOP;
  
  RAISE NOTICE 'Initial predictions complete!';
END $$;

-- Drop the helper function (no longer needed after migration)
DROP FUNCTION calculate_user_cycle_stats(UUID);

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Check backfilled users
SELECT 
  username,
  average_cycle_length,
  TO_CHAR(prediction_confidence, 'FM990.00') as confidence,
  prediction_method,
  next_period_predicted
FROM users
WHERE next_period_predicted IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
