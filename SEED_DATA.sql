-- SEED DATA FOR TESTING
-- Run this in your Supabase SQL editor after running database_migrations.sql
-- Replace YOUR_USER_ID with the actual user ID from your auth.users table

-- Get your user ID by running: SELECT id FROM auth.users LIMIT 1;
-- Then replace 'YOUR_USER_ID' below with that UUID

-- Example: If your user ID is '550e8400-e29b-41d4-a716-446655440000'
-- Replace all instances of 'YOUR_USER_ID' with that

BEGIN;

-- 1. INSERT PERIODS DATA
-- December 2025 period (5 days starting from Dec 5)
INSERT INTO periods (user_id, start_date, end_date, flow_intensity, created_at)
VALUES (
  '4b2f2616-de09-4586-91c1-bc0b2acc1b83',
  '2025-12-05'::date,
  '2025-12-09'::date,
  'medium',
  NOW()
);

-- November 2025 period
INSERT INTO periods (user_id, start_date, end_date, flow_intensity, created_at)
VALUES (
  '4b2f2616-de09-4586-91c1-bc0b2acc1b83',
  '2025-11-07'::date,
  '2025-11-11'::date,
  'medium',
  NOW()
);

-- October 2025 period
INSERT INTO periods (user_id, start_date, end_date, flow_intensity, created_at)
VALUES (
  '4b2f2616-de09-4586-91c1-bc0b2acc1b83',
  '2025-10-09'::date,
  '2025-10-13'::date,
  'light',
  NOW()
);

-- 2. INSERT MOODS DATA
INSERT INTO moods (user_id, date, mood_type, created_at)
VALUES 
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-28'::date, 'happy', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-27'::date, 'calm', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-26'::date, 'tired', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-25'::date, 'happy', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-24'::date, 'energetic', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-23'::date, 'anxious', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-22'::date, 'sad', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-21'::date, 'irritable', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-20'::date, 'calm', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-19'::date, 'energetic', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-18'::date, 'happy', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-10'::date, 'sad', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-09'::date, 'irritable', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-08'::date, 'tired', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-07'::date, 'anxious', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-06'::date, 'tired', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-05'::date, 'sad', NOW())
ON CONFLICT (user_id, date) DO NOTHING;

-- 3. INSERT SYMPTOMS DATA
INSERT INTO symptoms (user_id, date, symptom_type, severity, created_at)
VALUES 
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-28'::date, 'cramps', 2, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-27'::date, 'bloating', 3, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-26'::date, 'headache', 2, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-25'::date, 'fatigue', 3, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-24'::date, 'nausea', 1, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-23'::date, 'back_pain', 2, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-22'::date, 'cramps', 4, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-20'::date, 'acne', 1, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-10'::date, 'bloating', 2, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-09'::date, 'cramps', 3, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-08'::date, 'fatigue', 2, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-07'::date, 'headache', 2, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-06'::date, 'cramps', 3, NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-05'::date, 'bloating', 2, NOW())
ON CONFLICT (user_id, date, symptom_type) DO NOTHING;

-- 4. INSERT SEXUAL ACTIVITIES DATA
INSERT INTO sexual_activities (user_id, date, protection_used, protection_type, notes, created_at)
VALUES 
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-28'::date, true, 'condom', 'Safe', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-26'::date, true, 'birth_control', 'On pill', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-24'::date, false, NULL, 'Withdrawal method', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-20'::date, true, 'condom', 'Safe', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-15'::date, true, 'birth_control', 'On pill', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-10'::date, true, 'iud', 'IUD in place', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-05'::date, false, NULL, 'Partner away', NOW())
ON CONFLICT (user_id, date) DO NOTHING;

-- 5. INSERT NOTES DATA
INSERT INTO notes (user_id, date, content, created_at)
VALUES 
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-28'::date, 'Feeling great today!', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-27'::date, 'Had a good workout', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-26'::date, 'Relaxed day at home', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-25'::date, 'Christmas day - had family gathering', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-24'::date, 'Christmas Eve preparations', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-23'::date, 'Shopping for gifts', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-22'::date, 'Feeling a bit off', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-21'::date, 'Started period. Feeling cramps', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-20'::date, 'PMS symptoms noted', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-15'::date, 'Mid cycle - feeling energetic', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-10'::date, 'End of last period', NOW()),
  ('4b2f2616-de09-4586-91c1-bc0b2acc1b83', '2025-12-05'::date, 'Started period tracking', NOW())
ON CONFLICT (user_id, date) DO NOTHING;

COMMIT;

-- VERIFICATION QUERIES (run these to check your data):
-- SELECT COUNT(*) as period_count FROM periods WHERE user_id = '4b2f2616-de09-4586-91c1-bc0b2acc1b83';
-- SELECT COUNT(*) as mood_count FROM moods WHERE user_id = '4b2f2616-de09-4586-91c1-bc0b2acc1b83';
-- SELECT COUNT(*) as symptom_count FROM symptoms WHERE user_id = '4b2f2616-de09-4586-91c1-bc0b2acc1b83';
-- SELECT COUNT(*) as activity_count FROM sexual_activities WHERE user_id = '4b2f2616-de09-4586-91c1-bc0b2acc1b83';
-- SELECT COUNT(*) as note_count FROM notes WHERE user_id = '4b2f2616-de09-4586-91c1-bc0b2acc1b83';
