# Supabase Setup Guide

## Overview
Your Lovely app is now configured to use Supabase for authentication and data storage. Follow these steps to complete the setup.

## ✅ Credentials Already Configured
Your Supabase credentials are already set in `lib/config/supabase_config.dart`:
- **Project URL**: https://kzscdhegefjvymjvmlaa.supabase.co
- **Anon Key**: sb_publishable_xqnJJTQrJml3MgDqq8MRVQ_8ylhXiXJ

## 📋 Required Database Setup

### Step 1: Create the Users Table

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/kzscdhegefjvymjvmlaa
2. Navigate to **SQL Editor** (in the left sidebar)
3. Click **New Query**
4. Copy and paste the following SQL:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    date_of_birth TIMESTAMP WITH TIME ZONE,
    average_cycle_length INTEGER DEFAULT 28,
    average_period_length INTEGER DEFAULT 5,
    last_period_start TIMESTAMP WITH TIME ZONE,
    notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can view their own data
CREATE POLICY "Users can view own data"
    ON public.users
    FOR SELECT
    USING (auth.uid() = id);

-- Create policy: Users can insert their own data
CREATE POLICY "Users can insert own data"
    ON public.users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Create policy: Users can update their own data
CREATE POLICY "Users can update own data"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Create index for faster queries
CREATE INDEX users_email_idx ON public.users(email);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

5. Click **Run** to execute the query

### Step 2: Create Cycle Tracking Tables

Copy and paste this SQL to create the period tracking, symptoms, moods, and cycles tables:

```sql
-- Create periods table (tracks individual period entries)
CREATE TABLE IF NOT EXISTS public.periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE,
    flow_intensity TEXT CHECK (flow_intensity IN ('light', 'medium', 'heavy')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create symptoms table (tracks daily symptoms)
CREATE TABLE IF NOT EXISTS public.symptoms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    symptom_type TEXT NOT NULL CHECK (symptom_type IN ('cramps', 'headache', 'fatigue', 'bloating', 'nausea', 'back_pain', 'breast_tenderness', 'acne')),
    severity INTEGER CHECK (severity BETWEEN 1 AND 5),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date, symptom_type)
);

-- Create moods table (tracks daily mood)
CREATE TABLE IF NOT EXISTS public.moods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood_type TEXT NOT NULL CHECK (mood_type IN ('happy', 'calm', 'tired', 'sad', 'irritable', 'anxious', 'energetic')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Create cycles table (stores calculated cycle information)
CREATE TABLE IF NOT EXISTS public.cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cycle_number INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    cycle_length INTEGER,
    period_length INTEGER,
    predicted_next_period DATE,
    predicted_ovulation DATE,
    predicted_fertile_window_start DATE,
    predicted_fertile_window_end DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, cycle_number)
);

-- Enable Row Level Security on all tables
ALTER TABLE public.periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cycles ENABLE ROW LEVEL SECURITY;

-- Periods table policies
CREATE POLICY "Users can view own periods"
    ON public.periods FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own periods"
    ON public.periods FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own periods"
    ON public.periods FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own periods"
    ON public.periods FOR DELETE
    USING (auth.uid() = user_id);

-- Symptoms table policies
CREATE POLICY "Users can view own symptoms"
    ON public.symptoms FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own symptoms"
    ON public.symptoms FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own symptoms"
    ON public.symptoms FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own symptoms"
    ON public.symptoms FOR DELETE
    USING (auth.uid() = user_id);

-- Moods table policies
CREATE POLICY "Users can view own moods"
    ON public.moods FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own moods"
    ON public.moods FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own moods"
    ON public.moods FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own moods"
    ON public.moods FOR DELETE
    USING (auth.uid() = user_id);

-- Cycles table policies
CREATE POLICY "Users can view own cycles"
    ON public.cycles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cycles"
    ON public.cycles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cycles"
    ON public.cycles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cycles"
    ON public.cycles FOR DELETE
    USING (auth.uid() = user_id);

-- Create indexes for better query performance
CREATE INDEX periods_user_date_idx ON public.periods(user_id, start_date DESC);
CREATE INDEX symptoms_user_date_idx ON public.symptoms(user_id, date DESC);
CREATE INDEX moods_user_date_idx ON public.moods(user_id, date DESC);
CREATE INDEX cycles_user_number_idx ON public.cycles(user_id, cycle_number DESC);

-- Create or replace updated_at trigger function (in case it doesn't exist)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create updated_at triggers
CREATE TRIGGER update_periods_updated_at
    BEFORE UPDATE ON public.periods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cycles_updated_at
    BEFORE UPDATE ON public.cycles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Step 3: Configure Email Authentication

1. In your Supabase Dashboard, go to **Authentication** → **Providers**
2. Make sure **Email** is enabled
3. Under **Email Auth** settings:
   - ✅ **Enable Email provider**
   - ⚠️ **Confirm email**: You can disable this for testing (users can login immediately)
   - For production, keep this enabled for security

### Step 3: Configure Site URL (for password resets)

1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL** to your app's deep link or localhost for testing:
   - For testing: `http://localhost`
   - For production: Your app's URL or deep link scheme

### Step 4: Test Email Templates (Optional)

1. Go to **Authentication** → **Email Templates**
2. Customize the email templates for:
   - Confirm signup
   - Magic link
   - Reset password

## 🧪 Testing Your Setup

### Test User Signup Flow:
1. Run your Flutter app: `flutter run`
2. Navigate through:
   - Welcome Screen → Sign Up
   - Enter your details (use a real email for testing)
   - Complete the onboarding questionnaire
   - You should be taken to the Home screen

### Test Login Flow:
1. From Welcome Screen → Login
2. Enter the credentials you just created
3. You should be logged in and see the Home screen

### Test Password Reset:
1. From Login Screen → "Forgot Password?"
2. Enter your email
3. Check your inbox for the password reset email
4. Click the link to reset your password

## 🔍 Verify Data in Supabase

After completing onboarding:
1. Go to **Table Editor** in Supabase Dashboard
2. Select the `users` table
3. You should see your user data with all onboarding information

## 🔒 Security Notes

- ✅ Your `supabase_config.dart` is in `.gitignore` (not committed to version control)
- ✅ Row-Level Security (RLS) is enabled - users can only access their own data
- ✅ Using the anon/public key (safe for client-side apps)
- ⚠️ Never share your `service_role` key in the Flutter app

## 📱 What's Implemented

### Authentication Features:
- ✅ Email/Password signup with name metadata
- ✅ Email/Password login
- ✅ Password reset via email
- ✅ Sign out
- ✅ Session management
- ✅ Auth state persistence

### Onboarding Data Collection:
- ✅ Name
- ✅ Date of Birth
- ✅ Average Cycle Length (21-35 days)
- ✅ Average Period Length (3-7 days)
- ✅ Last Period Start Date
- ✅ Notification Preferences

### Navigation Flow:
- Welcome → Login/Signup
- Signup → Onboarding → Home
- Login → Home (if onboarding completed)
- Login → Onboarding (if not completed)

## 🚀 Next Steps

1. **Create the database table** using the SQL above
2. **Test the signup flow** to verify everything works
3. **Implement remaining features** from SPEC.md:
   - Task management
   - Daily affirmations
   - Cycle tracking calendar
   - Period predictions
   - Analytics

## 🐛 Troubleshooting

### "Invalid API key" error:
- Double-check your credentials in `lib/config/supabase_config.dart`
- Make sure you're using the **anon/public** key, not the service role key

### "Row level security" errors:
- Make sure you ran the SQL to create RLS policies
- Verify the user is authenticated before accessing data

### Email not sending:
- Check your Supabase email quota (free tier has limits)
- Verify email provider settings in Authentication → Providers
- Check spam folder

### Build errors:
- Run `flutter pub get` to ensure all dependencies are installed
- Run `flutter clean` and rebuild if you see persistent errors

## 📚 Resources

- [Supabase Flutter Docs](https://supabase.com/docs/reference/dart)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
