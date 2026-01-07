-- Migration: Add cycle metrics for floating window predictions
-- Date: January 6, 2026
-- Purpose: Track recent vs baseline cycle patterns and detect anomalies

-- STEP 1: Add new columns to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS recent_average_cycle_length DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS baseline_cycle_length DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS cycle_variability DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS detected_anomalies INTEGER DEFAULT 0;

-- STEP 2: Add comments for documentation
COMMENT ON COLUMN public.users.recent_average_cycle_length IS 
  'Average of last 3-6 cycles (floating window) - used for current predictions';

COMMENT ON COLUMN public.users.baseline_cycle_length IS 
  'From onboarding/self-reported - historical baseline for comparison';

COMMENT ON COLUMN public.users.cycle_variability IS 
  'Standard deviation of recent cycles (0-10+ range) - measures regularity';

COMMENT ON COLUMN public.users.detected_anomalies IS 
  'Count of outlier cycles detected - used for trend analysis';

-- STEP 3: Create cycle_anomalies table (optional but helpful for insights)
CREATE TABLE IF NOT EXISTS public.cycle_anomalies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    period_date DATE NOT NULL,
    cycle_length INTEGER NOT NULL,
    average_cycle DECIMAL(5,2),
    variability DECIMAL(5,2),
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- STEP 4: Enable RLS on cycle_anomalies
ALTER TABLE public.cycle_anomalies ENABLE ROW LEVEL SECURITY;

-- STEP 5: Create RLS policies for cycle_anomalies
CREATE POLICY "Users can view own anomalies"
  ON public.cycle_anomalies FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert anomalies"
  ON public.cycle_anomalies FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own anomalies"
  ON public.cycle_anomalies FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- STEP 6: Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_cycle_anomalies_user_id 
  ON public.cycle_anomalies(user_id);

CREATE INDEX IF NOT EXISTS idx_cycle_anomalies_detected_at 
  ON public.cycle_anomalies(detected_at DESC);

-- STEP 7: Initialize existing users' baseline from their average_cycle_length
UPDATE public.users
SET baseline_cycle_length = average_cycle_length::DECIMAL(5,2)
WHERE baseline_cycle_length IS NULL AND average_cycle_length IS NOT NULL;

-- Fallback to 28 if no average_cycle_length exists
UPDATE public.users
SET baseline_cycle_length = 28.0
WHERE baseline_cycle_length IS NULL;

-- Initialize recent average same as baseline for existing users (they haven't had floating window yet)
UPDATE public.users
SET recent_average_cycle_length = baseline_cycle_length
WHERE recent_average_cycle_length IS NULL;

-- Migration completed successfully

-- Verification query (run after migration)
-- SELECT 
--   COUNT(*) as total_users,
--   COUNT(baseline_cycle_length) as with_baseline,
--   AVG(baseline_cycle_length) as avg_baseline,
--   COUNT(recent_average_cycle_length) as with_recent,
--   AVG(recent_average_cycle_length) as avg_recent
-- FROM public.users
-- WHERE has_completed_onboarding = true;
