# Database Setup - Moods & Symptoms Tables

## ⚠️ IMPORTANT: Run This Migration First

The app requires `moods` and `symptoms` tables in your Supabase database.

## Steps to Setup Database

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project

2. **Navigate to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Run the Updated Migration**
   - Copy the entire contents of `database_migrations.sql`
   - Paste into the SQL editor
   - Click "Run"

4. **Verify Tables Created**
   Run this query to verify:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('moods', 'symptoms');
   ```
   
   You should see both tables listed.

## What Was Added

### Moods Table
- Stores user mood entries per day
- One mood per user per day (UNIQUE constraint on user_id + date)
- 7 mood types: `happy`, `calm`, `tired`, `sad`, `irritable`, `anxious`, `energetic`
- Column name: `mood_type` (NOT `mood` - this was a critical fix)

**Important:** The app uses `mood_type` as the column name. Earlier versions incorrectly tried to use `mood`, causing save failures.

### Symptoms Table
- Stores user symptom entries
- Multiple symptoms allowed per day
- 8 symptom types stored as snake_case values:
  - `cramps`
  - `headache`
  - `fatigue`
  - `bloating`
  - `nausea`
  - `back_pain` (NOT `backPain`)
  - `breast_tenderness` (NOT `breastTenderness`)
  - `acne`
- Includes severity rating (1-5, default 3)
- Optional notes field

**Critical:** The database stores symptom types in snake_case (`back_pain`) while the Dart enum uses camelCase names (`backPain`). The code now correctly uses `type.value` instead of `type.name` when saving.

### Security
- Row Level Security (RLS) enabled
- Users can only access their own data
- Policies for SELECT, INSERT, UPDATE, DELETE

## Common Issues & Solutions

### "No column such as moods"
**Cause:** Tables not created in database  
**Solution:** Run the migration SQL in Supabase SQL Editor

### "Moods not saving" or "Invalid column mood"
**Cause:** Old code tried to use `mood` instead of `mood_type`  
**Solution:** Updated - code now uses correct column name `mood_type`

### "Symptoms clear when adding another"
**Cause:** Enum name (`backPain`) doesn't match database constraint (`back_pain`)  
**Solution:** Fixed - code now uses `type.value` for correct snake_case values

### "Symptoms not visible after saving"
**Cause:** Stream filtering used exclusive comparison (`isAfter/isBefore`)  
**Solution:** Fixed - now uses inclusive comparison (`!isBefore`)

### "Data doesn't sync between HomeScreen and DailyLogScreen"
**Cause:** Different data sources (local state vs streams)  
**Solution:** Fixed - both screens now use same stream providers

## After Migration

Once you've run the migration:
1. **Hot restart** your Flutter app (not just hot reload)
2. Mood and symptom logging will work correctly
3. Data will sync between HomeScreen and DailyLogScreen
4. Multiple symptoms per day fully supported

## Database Schema

```sql
-- Moods Table
CREATE TABLE moods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood_type TEXT NOT NULL CHECK (mood_type IN ('happy', 'calm', 'tired', 'sad', 'irritable', 'anxious', 'energetic')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Symptoms Table  
CREATE TABLE symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    symptom_type TEXT NOT NULL CHECK (symptom_type IN ('cramps', 'headache', 'fatigue', 'bloating', 'nausea', 'back_pain', 'breast_tenderness', 'acne')),
    severity INTEGER NOT NULL DEFAULT 3 CHECK (severity >= 1 AND severity <= 5),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## Troubleshooting

**Error: "relation 'moods' already exists"**
- This is fine - the migration uses `CREATE TABLE IF NOT EXISTS`

**Error: "policy already exists"**
- This is fine - Supabase won't create duplicate policies

**Still getting errors after migration?**
- Check you're connected to the correct Supabase project
- Verify the `supabase_url` and `supabase_anon_key` in `lib/config/supabase_config.dart`
- Ensure you ran the migration in the SQL Editor (not locally)
- Try clearing app data and logging in again
