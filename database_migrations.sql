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

-- 4. Create moods table
CREATE TABLE IF NOT EXISTS moods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mood_type TEXT NOT NULL CHECK (mood_type IN ('happy', 'calm', 'tired', 'sad', 'irritable', 'anxious', 'energetic')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- 5. Create symptoms table
CREATE TABLE IF NOT EXISTS symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    symptom_type TEXT NOT NULL CHECK (symptom_type IN ('cramps', 'headache', 'fatigue', 'bloating', 'nausea', 'backPain', 'breastTenderness', 'acne')),
    severity INTEGER NOT NULL DEFAULT 3 CHECK (severity >= 1 AND severity <= 5),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_sexual_activities_user_date ON sexual_activities(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_date ON notes(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_moods_user_date ON moods(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_symptoms_user_date ON symptoms(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_users_pregnancy_mode ON users(id) WHERE pregnancy_mode = TRUE;

-- 7. Enable Row Level Security (RLS)
ALTER TABLE sexual_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS policies for sexual_activities
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

-- 9. Create RLS policies for notes
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

-- 10. Create RLS policies for moods
CREATE POLICY "Users can view their own moods"
    ON moods FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own moods"
    ON moods FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own moods"
    ON moods FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own moods"
    ON moods FOR DELETE
    USING (auth.uid() = user_id);

-- 11. Create RLS policies for symptoms
CREATE POLICY "Users can view their own symptoms"
    ON symptoms FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own symptoms"
    ON symptoms FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own symptoms"
    ON symptoms FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own symptoms"
    ON symptoms FOR DELETE
    USING (auth.uid() = user_id);

-- 12. Grant necessary permissions
GRANT ALL ON sexual_activities TO authenticated;
GRANT ALL ON notes TO authenticated;
GRANT ALL ON moods TO authenticated;
GRANT ALL ON symptoms TO authenticated;
