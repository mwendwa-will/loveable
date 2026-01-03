-- Notification System Database Migration
-- Run this in Supabase SQL Editor to add notification support

-- Add FCM Token column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add Notification Preferences column with default values
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{
  "periodRemindersEnabled": true,
  "periodReminderHour": 9,
  "periodReminderMinute": 0,
  "moodCheckInEnabled": true,
  "moodCheckInHour": 18,
  "moodCheckInMinute": 0,
  "affirmationsEnabled": true,
  "affirmationHour": 7,
  "affirmationMinute": 0,
  "taskRemindersEnabled": true,
  "taskReminderHour": 8,
  "taskReminderMinute": 0
}'::jsonb;

-- Add helpful comments
COMMENT ON COLUMN users.fcm_token IS 'Firebase Cloud Messaging token for push notifications';
COMMENT ON COLUMN users.notification_preferences IS 'User notification preferences (enable/disable, custom times)';

-- Optional: Create index on fcm_token for faster queries
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token) WHERE fcm_token IS NOT NULL;

-- Verify migration
SELECT 
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'users' 
AND column_name IN ('fcm_token', 'notification_preferences')
ORDER BY column_name;

-- Output should show:
-- fcm_token | text | YES
-- notification_preferences | jsonb | YES
