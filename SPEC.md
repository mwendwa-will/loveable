# Lovely - App Specification Sheet

**Version:** 1.0  
**Date:** December 30, 2025  
**Platform:** Flutter (iOS & Android)

---

## 1. App Overview

**Name:** Lovely  
**Tagline:** Your journey to wellness and self-care starts here  
**Category:** Health & Wellness  
**Target Audience:** Women seeking holistic wellness tracking and self-care support

**Core Purpose:**
A comprehensive women's wellness app that combines health tracking, task management, and daily affirmations to support physical and mental well-being.

---

## 2. Design System

### Color Palette (Coral Sunset Theme)
- **Primary:** `#FF6F61` (Vibrant Coral)
- **Secondary:** `#FF8F7A` (Soft Coral)
- **Tertiary:** `#FFB3A0` (Peachy Pink)
- **Background Light:** `#FFE5D4` (Very Light Peach)
- **Background Dark:** `#121212` (Very Dark)
- **Surface Dark:** `#1E1E1E` (Dark Surface)

### Typography
- **Font Family:** Inter (via Google Fonts)
- **Headings:** Bold
- **Body:** Regular/Medium

### Visual Style
- Rounded corners (12-16px radius)
- Minimal elevation
- Clean, feminine aesthetic
- Flo-inspired design patterns
- Card-based UI components

---

## 3. Core Features

### 3.1 Authentication & Onboarding
- [x] Welcome screen with features preview
- [x] Email/Password login
- [x] Email/Password signup
- [x] Social login (Google, Facebook, Apple)
- [ ] Forgot password flow
- [ ] Email verification
- [ ] Onboarding questionnaire
  - Age
  - Cycle tracking preferences
  - Health goals
  - Notification preferences

### 3.2 Health Tracking
- [ ] **Period/Cycle Tracking**
  - Cycle calendar view
  - Period start/end logging
  - Cycle predictions
  - Fertile window indicators
  - Cycle phase education

- [ ] **Symptom Logging**
  - Mood tracking (happy, sad, anxious, energetic, etc.)
  - Physical symptoms (cramps, headache, bloating, etc.)
  - Energy levels (1-5 scale)
  - Sleep quality
  - Custom symptoms

- [ ] **Health Metrics**
  - Water intake tracker
  - Weight tracking (optional)
  - Temperature logging
  - Exercise/activity logging

### 3.3 Task Reminders
- [ ] **Task Management**
  - Create daily/recurring tasks
  - Task categories:
    - Health (medications, vitamins)
    - Wellness (meditation, exercise)
    - Self-care (skincare, journaling)
    - Personal
  - Priority levels (high, medium, low)
  - Due dates and times
  - Completion tracking

- [ ] **Reminders**
  - Smart notifications based on task time
  - Gentle reminder tones
  - Snooze functionality
  - Custom repeat intervals

- [ ] **Streaks & Progress**
  - Daily completion percentage
  - Weekly/monthly statistics
  - Streak counter for recurring tasks
  - Achievement badges

### 3.4 Daily Affirmations
- [ ] **Affirmation System**
  - Daily affirmation card on home screen
  - Morning/evening affirmations
  - Cycle-synced affirmations (follicular, ovulation, luteal, menstrual)
  - Mood-based suggestions
  - Categories:
    - Confidence
    - Body Positivity
    - Mental Health
    - Self-Love
    - Relationships
    - Strength

- [ ] **Customization**
  - Save favorite affirmations
  - Create custom affirmations
  - Share to social media
  - Notification scheduling

- [ ] **Affirmation Library**
  - 200+ pre-written affirmations
  - Filter by category
  - Search functionality
  - Random affirmation generator

### 3.5 Insights & Analytics
- [ ] **Dashboard**
  - Current cycle phase
  - Days until next period
  - Symptom patterns
  - Task completion stats
  - Mood trends

- [ ] **Reports**
  - Monthly cycle summary
  - Symptom correlation analysis
  - Health pattern recognition
  - Exportable PDF reports

### 3.6 User Settings
- [x] Dark/Light mode (auto-detect)
- [ ] Dark/Light mode manual toggle
- [ ] Notification preferences
- [ ] Data privacy settings
- [ ] Profile management
- [ ] Cycle settings (average length, period duration)
- [ ] Data export/backup
- [ ] Biometric login (fingerprint/face ID)
- [ ] Account deletion

---

## 4. Screen Architecture

### 4.1 Authentication Flow
```
Welcome Screen → Login Screen ↔ Sign Up Screen
                ↓
           Home Screen
```

### 4.2 Main Navigation (Bottom Tab Bar)
1. **Home** - Dashboard with affirmation & quick stats
2. **Calendar** - Cycle tracking & symptom logging
3. **Tasks** - Task list & reminders
4. **Insights** - Analytics & reports
5. **Profile** - Settings & user preferences

### 4.3 Screen Details

#### Home Screen
- Daily affirmation card
- Cycle status widget
- Quick actions (log symptom, add task, log water)
- Today's tasks preview (3 most important)
- Streak counter
- Motivational messages

#### Calendar Screen
- Monthly calendar view
- Period tracking interface
- Symptom logging modal
- Cycle predictions visualization
- Phase education tooltips

#### Tasks Screen
- Task list (today, upcoming, completed)
- Add task button
- Filter by category
- Sort options (priority, time, category)
- Task detail/edit modal
- Streak badges

#### Insights Screen
- Cycle overview chart
- Mood graph (last 30 days)
- Symptom frequency chart
- Task completion statistics
- Export data button

#### Profile Screen
- User info
- Settings sections:
  - Account
  - Notifications
  - Cycle Settings
  - Privacy & Security
  - About
- Sign out button

---

## 5. Data Models

### 5.1 User
```dart
class User {
  String id;
  String email;
  String name;
  DateTime dateOfBirth;
  int averageCycleLength; // days
  int averagePeriodLength; // days
  DateTime? lastPeriodStart;
  bool notificationsEnabled;
  String preferredTheme; // 'light', 'dark', 'system'
  DateTime createdAt;
}
```

### 5.2 CycleLog
```dart
class CycleLog {
  String id;
  String userId;
  DateTime periodStartDate;
  DateTime? periodEndDate;
  int cycleLength;
  List<String> symptoms; // references to Symptom
  DateTime createdAt;
}
```

### 5.3 Symptom
```dart
class Symptom {
  String id;
  String userId;
  DateTime date;
  String type; // 'mood', 'physical', 'energy'
  String value; // e.g., 'happy', 'cramps', '4/5'
  int? severity; // 1-5 scale
  String? notes;
}
```

### 5.4 Task
```dart
class Task {
  String id;
  String userId;
  String title;
  String? description;
  String category; // 'health', 'wellness', 'self-care', 'personal'
  String priority; // 'high', 'medium', 'low'
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isRecurring;
  String? recurringPattern; // 'daily', 'weekly', 'monthly'
  bool isCompleted;
  DateTime? completedAt;
  int streakCount;
  DateTime createdAt;
}
```

### 5.5 Affirmation
```dart
class Affirmation {
  String id;
  String text;
  String category;
  String? cyclePhase; // 'follicular', 'ovulation', 'luteal', 'menstrual', null
  bool isFavorite;
  bool isCustom;
  String? userId; // null for pre-built, userId for custom
}
```

### 5.6 WaterIntake
```dart
class WaterIntake {
  String id;
  String userId;
  DateTime date;
  int glassesCount;
  int targetGlasses; // default 8
}
```

---

## 6. Technical Requirements

### 6.1 Dependencies
- [x] `google_fonts` - Typography
- [x] `font_awesome_flutter` - Icons
- [ ] `supabase_flutter` - Backend (Auth, Database, Storage)
- [ ] `shared_preferences` - Local storage
- [ ] `sqflite` - Local database/cache
- [ ] `firebase_core` - FCM setup
- [ ] `firebase_messaging` - Push notifications only
- [ ] `intl` - Date formatting
- [ ] `provider` or `riverpod` - State management
- [ ] `table_calendar` - Calendar widget
- [ ] `fl_chart` - Charts/graphs
- [ ] `local_auth` - Biometric authentication
- [ ] `share_plus` - Social sharing
- [ ] `pdf` - Report generation
- [ ] `flutter_local_notifications` - Local notification display
- [ ] `crypto` - Data encryption

### 6.2 Backend Architecture

**Primary Backend: Supabase**
- **Authentication:** Supabase Auth (Email/Password, OAuth)
- **Database:** PostgreSQL (via Supabase)
- **Storage:** Supabase Storage (for user avatars, exports)
- **Real-time:** Supabase Realtime (PostgreSQL subscriptions)
- **Edge Functions:** Supabase Edge Functions (for complex operations)

**Notifications: Firebase Cloud Messaging**
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Reason:** Industry standard, reliable delivery, excellent Flutter support
- **Integration:** User FCM tokens stored in Supabase user profiles

**Analytics: PostHog or Mixpanel**
- Open-source analytics
- Privacy-focused
- Custom event tracking

### 6.3 Local Storage
- User preferences (SharedPreferences)
- Cached data for offline mode (SQLite)
- Secure storage for sensitive data (flutter_secure_storage)

### 6.4 Accessibility
- [x] Semantics labels on all interactive elements
- [x] Button hints for screen readers
- [x] Form field labels
- [ ] High contrast mode support
- [ ] Font scaling support (test at 200%)
- [ ] Color contrast ratio: minimum 4.5:1

---

## 7. Database Schema (PostgreSQL)

### Tables:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  date_of_birth DATE,
  average_cycle_length INTEGER DEFAULT 28,
  average_period_length INTEGER DEFAULT 5,
  last_period_start DATE,
  notifications_enabled BOOLEAN DEFAULT true,
  preferred_theme TEXT DEFAULT 'system',
  fcm_token TEXT, -- Firebase Cloud Messaging token
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cycle logs
CREATE TABLE cycle_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  period_start_date DATE NOT NULL,
  period_end_date DATE,
  cycle_length INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Symptoms
CREATE TABLE symptoms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  cycle_log_id UUID REFERENCES cycle_logs(id) ON DELETE SET NULL,
  date DATE NOT NULL,
  type TEXT NOT NULL, -- 'mood', 'physical', 'energy'
  value TEXT NOT NULL,
  severity INTEGER CHECK (severity >= 1 AND severity <= 5),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL, -- 'health', 'wellness', 'self-care', 'personal'
  priority TEXT DEFAULT 'medium', -- 'high', 'medium', 'low'
  due_date DATE,
  due_time TIME,
  is_recurring BOOLEAN DEFAULT false,
  recurring_pattern TEXT, -- 'daily', 'weekly', 'monthly'
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  streak_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Affirmations (pre-built, global)
CREATE TABLE affirmations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  text TEXT NOT NULL,
  category TEXT NOT NULL,
  cycle_phase TEXT, -- 'follicular', 'ovulation', 'luteal', 'menstrual', NULL
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User affirmations (custom + favorites)
CREATE TABLE user_affirmations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  affirmation_id UUID REFERENCES affirmations(id) ON DELETE CASCADE,
  is_favorite BOOLEAN DEFAULT false,
  is_custom BOOLEAN DEFAULT false,
  custom_text TEXT, -- Only if is_custom = true
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Water intake tracking
CREATE TABLE water_intake (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  glasses_count INTEGER DEFAULT 0,
  target_glasses INTEGER DEFAULT 8,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- FCM Notification logs (for debugging)
CREATE TABLE notification_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  title TEXT,
  body TEXT,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  delivery_status TEXT DEFAULT 'sent' -- 'sent', 'delivered', 'failed'
);
```

### Indexes:
```sql
CREATE INDEX idx_cycle_logs_user_date ON cycle_logs(user_id, period_start_date DESC);
CREATE INDEX idx_symptoms_user_date ON symptoms(user_id, date DESC);
CREATE INDEX idx_tasks_user_date ON tasks(user_id, due_date, is_completed);
CREATE INDEX idx_water_intake_user_date ON water_intake(user_id, date DESC);
```

### Row Level Security (RLS):
```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_affirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_intake ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see/edit their own data
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own cycles" ON cycle_logs
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own symptoms" ON symptoms
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own tasks" ON tasks
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own affirmations" ON user_affirmations
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own water intake" ON water_intake
  FOR ALL USING (auth.uid() = user_id);

-- Affirmations are public (read-only)
CREATE POLICY "Anyone can view affirmations" ON affirmations
  FOR SELECT USING (true);
```

---

## 8. Notifications Strategy (Firebase Cloud Messaging)

### Architecture:
- **FCM Tokens:** Stored in Supabase `users.fcm_token` field
- **Trigger:** Supabase Edge Functions or scheduled jobs
- **Delivery:** Firebase Cloud Messaging
- **Local Display:** flutter_local_notifications

### Implementation Flow:
1. User grants notification permission
2. App retrieves FCM token
3. Token saved to Supabase user profile
4. Backend sends notifications via FCM Admin SDK
5. App receives and displays with local notifications

### Types:
1. **Task Reminders** - At scheduled time
2. **Period Predictions** - 2 days before expected start
3. **Affirmations** - Morning (8 AM) and Evening (8 PM)
4. **Water Intake** - Hourly reminders (9 AM - 9 PM)
5. **Health Check-ins** - Daily at user's preferred time

### Notification Settings:
- Master on/off toggle
- Individual notification type toggles
- Custom quiet hours
- Sound/vibration preferences

---

## 9. Privacy & Security

### Data Protection:
- End-to-end encryption for sensitive health data
- Local data encryption
- Biometric authentication option
- No data sharing with third parties
- GDPR/HIPAA compliant
- Clear privacy policy
- Data export capability
- Account deletion with full data removal

### Permissions:
- Notifications (optional)
- Camera (for profile photo, optional)
- Biometric (for app lock, optional)

---

## 10. Development Phases

### Phase 1: MVP (Weeks 1-3)
- [x] Authentication screens (Welcome, Login, Sign Up)
- [x] Theme implementation
- [x] Accessibility setup
- [ ] Home screen with basic layout
- [ ] Simple task list
- [ ] Basic affirmation display
- [ ] Bottom navigation

### Phase 2: Core Features (Weeks 4-6)
- [ ] Cycle tracking calendar
- [ ] Symptom logging
- [ ] Task CRUD operations
- [ ] Affirmation library
- [ ] Local storage implementation
- [ ] Firebase integration

### Phase 3: Advanced Features (Weeks 7-9)
- [ ] Analytics dashboard
- [ ] Insights generation
- [ ] Streak tracking
- [ ] Custom affirmations
- [ ] Notifications system
- [ ] Data export

### Phase 4: Polish & Launch (Weeks 10-12)
- [ ] Onboarding flow
- [ ] Tutorial/walkthrough
- [ ] Performance optimization
- [ ] Testing (unit, widget, integration)
- [ ] App store assets
- [ ] Beta testing
- [ ] Launch!

---

## 11. Future Enhancements (Post-Launch)

- [ ] Community forum (anonymous)
- [ ] Expert articles/blog
- [ ] Pregnancy mode
- [ ] Partner sharing (optional cycle sharing)
- [ ] Apple Health / Google Fit integration
- [ ] Wearable device sync
- [ ] AI-powered insights
- [ ] Chatbot for health questions
- [ ] Premium features (advanced analytics, unlimited custom affirmations)
- [ ] Widget support (iOS/Android)
- [ ] Apple Watch / Wear OS apps

---

## 12. Success Metrics

### User Engagement:
- Daily active users (DAU)
- Monthly active users (MAU)
- Average session duration
- Feature usage rates
- Task completion rate
- Streak maintenance

### Retention:
- Day 1, 7, 30 retention rates
- Churn rate
- Re-engagement rate

### Satisfaction:
- App store ratings
- User feedback
- NPS (Net Promoter Score)

---

## 13. Competitive Analysis

**Similar Apps:**
- Flo (period tracker + health insights)
- Clue (cycle tracking)
- Ovia (fertility + pregnancy)
- Habitica (gamified tasks)
- Shine (affirmations + mental health)

**Lovely's Unique Value:**
- All-in-one wellness solution
- Affirmations integrated with cycle phases
- Beautiful, calming UI
- Task management specific to self-care
- No overwhelming features - focused simplicity

---

## Notes

- Prioritize user privacy and data security
- Keep UI simple and calming
- Focus on building trust with users
- Regular content updates (new affirmations)
- Community feedback loop for improvements
- Accessibility is non-negotiable

---

**Next Steps:**
1. Review and approve spec
2. Set up Firebase project
3. Implement state management architecture
4. Build home screen MVP
5. Create task management system
6. Build affirmation feature
