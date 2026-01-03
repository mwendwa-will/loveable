-- Migration: Remove old 'name' column
-- Date: 2026-01-02
-- Description: Removes the deprecated 'name' column after splitting into first_name/last_name

-- Option 1: Make name nullable first (safer for rollback)
ALTER TABLE users 
  ALTER COLUMN name DROP NOT NULL;

-- Option 2: Drop the column entirely (recommended after migration confirmed)
-- Uncomment after verifying first_name/last_name migration is successful
-- ALTER TABLE users DROP COLUMN IF EXISTS name;

COMMENT ON COLUMN users.first_name IS 'User first name (optional - collected in profile settings)';
COMMENT ON COLUMN users.last_name IS 'User last name (optional - collected in profile settings)';
COMMENT ON COLUMN users.username IS 'Unique username for login - REQUIRED (3-30 chars, alphanumeric, _, -, .)';
