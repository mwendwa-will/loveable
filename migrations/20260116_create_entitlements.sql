-- Create entitlements table for tracking purchases

CREATE TABLE IF NOT EXISTS entitlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id text NOT NULL,
  platform text NOT NULL,
  purchase_token text,
  expires_at timestamptz,
  is_active boolean DEFAULT false,
  raw_response jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS entitlements_user_idx ON entitlements(user_id);

-- Enable row level security
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;

-- Allow users to SELECT only their own entitlements
CREATE POLICY "Select own entitlements" ON entitlements
  FOR SELECT
  USING (auth.uid() = user_id::text);

-- Do NOT create INSERT/UPDATE/DELETE policies for regular users
-- Server-side functions / service role should perform writes

-- Helpful example: a function to upsert entitlements (used from secure server code)
-- (Optional) You can create a SQL function that upserts and sets updated_at

CREATE OR REPLACE FUNCTION public.upsert_entitlement(
  p_user_id uuid,
  p_product_id text,
  p_platform text,
  p_purchase_token text,
  p_expires_at timestamptz,
  p_is_active boolean,
  p_raw_response jsonb
)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO entitlements (user_id, product_id, platform, purchase_token, expires_at, is_active, raw_response)
  VALUES (p_user_id, p_product_id, p_platform, p_purchase_token, p_expires_at, p_is_active, p_raw_response)
  ON CONFLICT (id) DO UPDATE SET
    product_id = EXCLUDED.product_id,
    platform = EXCLUDED.platform,
    purchase_token = EXCLUDED.purchase_token,
    expires_at = EXCLUDED.expires_at,
    is_active = EXCLUDED.is_active,
    raw_response = EXCLUDED.raw_response,
    updated_at = now();
END;
$$;

-- Note: service-role key should be used by server functions to call this upsert safely.
