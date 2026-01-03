-- Migration: Add username and split first_name/last_name
-- Date: 2026-01-01
-- Description: Adds username authentication support and splits name into first_name/last_name

-- Step 1: Add new columns to users table
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS username TEXT;

-- Step 2: Migrate existing data from 'name' to 'first_name' and 'last_name'
-- Split name on first space: "John Doe" -> first_name="John", last_name="Doe"
UPDATE users 
SET 
  first_name = CASE 
    WHEN name IS NOT NULL AND position(' ' IN name) > 0 
    THEN split_part(name, ' ', 1)
    ELSE name
  END,
  last_name = CASE 
    WHEN name IS NOT NULL AND position(' ' IN name) > 0 
    THEN substring(name FROM position(' ' IN name) + 1)
    ELSE NULL
  END
WHERE first_name IS NULL;

-- Step 3: Add unique constraint on username (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS users_username_unique_idx 
  ON users (LOWER(username));

-- Step 4: Add index for faster username lookups
CREATE INDEX IF NOT EXISTS users_username_idx 
  ON users (username);

-- Step 5: Add check constraint to ensure username format (alphanumeric, underscore, dot, hyphen only)
ALTER TABLE users 
  ADD CONSTRAINT username_format_check 
  CHECK (username ~ '^[a-zA-Z0-9._-]{3,30}$');

-- Step 6: Add NOT NULL constraint to username (required for signup)
-- first_name collected during onboarding, so not required initially
ALTER TABLE users 
  ALTER COLUMN username SET NOT NULL;

-- Step 7: Update RLS policies to include username-based queries
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;

-- Recreate policies with username support
CREATE POLICY "Users can view own data" 
  ON users FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data" 
  ON users FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" 
  ON users FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Step 8: Create function to check username availability (for client-side validation)
CREATE OR REPLACE FUNCTION is_username_available(check_username TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM users 
    WHERE LOWER(username) = LOWER(check_username)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Create function to find user by username or email (for login)
CREATE OR REPLACE FUNCTION get_user_by_username_or_email(identifier TEXT)
RETURNS TABLE (
  id UUID,
  email TEXT,
  username TEXT,
  first_name TEXT,
  last_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.email, u.username, u.first_name, u.last_name
  FROM users u
  WHERE LOWER(u.username) = LOWER(identifier) 
     OR LOWER(u.email) = LOWER(identifier);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Optional: We can keep the 'name' column for backward compatibility during migration
-- After confirming all clients updated, we can drop it:
-- ALTER TABLE users DROP COLUMN IF EXISTS name;

COMMENT ON COLUMN users.first_name IS 'User first name (required)';
COMMENT ON COLUMN users.last_name IS 'User last name (optional)';
COMMENT ON COLUMN users.username IS 'Unique username for login - REQUIRED (3-30 chars, alphanumeric, _, -, .)';
COMMENT ON FUNCTION is_username_available IS 'Check if username is available (case-insensitive)';
COMMENT ON FUNCTION get_user_by_username_or_email IS 'Find user by username or email for authentication';
