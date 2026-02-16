-- Migration: Add daily_flows table for tracking daily period flow intensity
-- Date: 2026-02-16
-- Purpose: Allow users to log different flow intensities for each day of their period

-- Create daily_flows table
CREATE TABLE IF NOT EXISTS public.daily_flows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    flow_intensity TEXT NOT NULL CHECK (flow_intensity IN ('light', 'medium', 'heavy')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_daily_flows_user_date ON daily_flows(user_id, date DESC);

-- Enable Row Level Security
ALTER TABLE daily_flows ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own daily flows"
    ON daily_flows FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily flows"
    ON daily_flows FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily flows"
    ON daily_flows FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own daily flows"
    ON daily_flows FOR DELETE
    USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON daily_flows TO authenticated;

-- Add comment
COMMENT ON TABLE public.daily_flows IS 'Tracks daily flow intensity variations within a period';
COMMENT ON COLUMN public.daily_flows.date IS 'The specific date of flow tracking';
COMMENT ON COLUMN public.daily_flows.flow_intensity IS 'Flow intensity for this specific day (light, medium, heavy)';
