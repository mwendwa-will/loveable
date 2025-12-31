-- Database migrations for additional features
-- Run these in your Supabase SQL editor

-- 1. Add pregnancy mode columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS pregnancy_mode BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS conception_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS due_date TIMESTAMPTZ;

-- 2. Create sexual_activities table
CREATE TABLE IF NOT EXISTS sexual_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    protection_used BOOLEAN NOT NULL DEFAULT FALSE,
    protection_type TEXT CHECK (protection_type IN ('condom', 'birth_control', 'iud', 'withdrawal', 'other')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- 3. Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    UNIQUE(user_id, date)
);

-- 4. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_sexual_activities_user_date ON sexual_activities(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_date ON notes(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_users_pregnancy_mode ON users(id) WHERE pregnancy_mode = TRUE;

-- 5. Enable Row Level Security (RLS)
ALTER TABLE sexual_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for sexual_activities
CREATE POLICY "Users can view their own sexual activities"
    ON sexual_activities FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sexual activities"
    ON sexual_activities FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own sexual activities"
    ON sexual_activities FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sexual activities"
    ON sexual_activities FOR DELETE
    USING (auth.uid() = user_id);

-- 7. Create RLS policies for notes
CREATE POLICY "Users can view their own notes"
    ON notes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notes"
    ON notes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notes"
    ON notes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notes"
    ON notes FOR DELETE
    USING (auth.uid() = user_id);

-- 8. Grant necessary permissions
GRANT ALL ON sexual_activities TO authenticated;
GRANT ALL ON notes TO authenticated;
