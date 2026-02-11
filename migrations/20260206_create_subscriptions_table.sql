-- ================================================
-- Subscriptions Table Migration
-- Creates separate subscriptions table with RLS
-- ================================================

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'trial', 'expired', 'cancelled')),
  trial_starts_at TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  billing_cycle TEXT CHECK (billing_cycle IN ('monthly', 'yearly')),
  payment_provider TEXT,
  transaction_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_expires_at ON subscriptions(expires_at);

-- Enable Row Level Security
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own subscription
CREATE POLICY "Users can view own subscription"
  ON subscriptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own subscription"
  ON subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription"
  ON subscriptions FOR UPDATE
  USING (auth.uid() = user_id);

-- ================================================
-- Trigger: Auto-update updated_at timestamp
-- ================================================

CREATE OR REPLACE FUNCTION update_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_subscriptions_updated_at();

-- ================================================
-- Trigger: Auto-create free subscription on sign-up
-- ================================================

CREATE OR REPLACE FUNCTION create_default_subscription()
RETURNS TRIGGER AS $$
BEGIN
  -- Create a free subscription for new users
  INSERT INTO subscriptions (user_id, tier, status)
  VALUES (NEW.id, 'free', 'active')
  ON CONFLICT DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: This trigger runs on auth.users which is managed by Supabase Auth
-- If you encounter permission issues, you may need to use a different approach
-- such as creating the subscription during the onboarding process
CREATE TRIGGER trigger_create_default_subscription
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_default_subscription();

-- ================================================
-- Comments for documentation
-- ================================================

COMMENT ON TABLE subscriptions IS 'Manages user subscription tiers and payment state';
COMMENT ON COLUMN subscriptions.tier IS 'Subscription tier: free or premium';
COMMENT ON COLUMN subscriptions.status IS 'Subscription status: active, trial, expired, or cancelled';
COMMENT ON COLUMN subscriptions.trial_starts_at IS 'When 48-hour trial began';
COMMENT ON COLUMN subscriptions.trial_ends_at IS 'When 48-hour trial expires';
COMMENT ON COLUMN subscriptions.billing_cycle IS 'Billing frequency: monthly or yearly';
COMMENT ON COLUMN subscriptions.payment_provider IS 'Payment processor (e.g., revenuecat)';
COMMENT ON COLUMN subscriptions.transaction_id IS 'External transaction/receipt identifier';
