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
- [x] Forgot password flow
- [x] Email verification
- [x] Onboarding questionnaire
  - Age
  - Cycle tracking preferences
  - Health goals
  - Notification preferences

### 3.2 Health Tracking
- [x] **Period/Cycle Tracking**
  - Cycle calendar view
  - Period start/end logging
  - Cycle predictions
  - Fertile window indicators
  - Cycle phase visualization

- [x] **Symptom Logging**
  - Mood tracking (7 types: happy, calm, tired, sad, irritable, anxious, energetic)
  - Physical symptoms (8 types: cramps, headache, fatigue, bloating, nausea, back pain, breast tenderness, acne)
  - Symptom severity (1-5 scale)
  - Real-time mood icons with color coding
  - Mood/symptom indicators on calendar

- [x] **Intimate Activity Tracking**
  - Sexual activity logging
  - Protection method tracking (condom, birth control, IUD, withdrawal, other)
  - Protection status indicator (heart + shield icon)
  - Private, discreet indicators

- [ ] **Health Metrics**
  - [ ] Water intake tracker (model exists, UI pending)
  - [ ] Weight tracking (optional)
  - [ ] Temperature logging
  - [ ] Exercise/activity logging

- [x] **Daily Notes/Journal**
  - Journal entries for each day
  - Notes attached to specific dates
  - Free-text note field
  - Real-time saving

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
- [x] Data privacy settings (PIN lock)
- [ ] Profile management
- [ ] Cycle settings (average length, period duration)
- [ ] Data export/backup
- [ ] Biometric login (fingerprint/face ID)
- [ ] Account deletion

---

## 4. Screen Architecture

### 4.1 Authentication Flow

**Initial Launch:**
```
App Launch
    → main() initializes Supabase
    → Supabase reads encrypted tokens from device storage
    → AuthGate checks currentSession
    → If valid: Check onboarding status
        → Completed: Navigate to HomeScreen
        → Incomplete: Navigate to OnboardingScreen
    → If expired/missing: Show WelcomeScreen for login
```

**First-Time User:**
```
Welcome Screen → Sign Up Screen → Email Verification → Onboarding → Home Screen
```

**Returning User (with session):**
```
App Launch → AuthGate → HomeScreen (seamless, no login required)
```

**Session Expired:**
```
Welcome Screen → Login Screen → Home Screen
```

**Session Persistence:**
- Tokens stored in SharedPreferences (Android) / UserDefaults (iOS)
- Sessions survive app restarts and cache clearing
- Sessions expire after 30 days or on explicit logout
- Auto-refresh mechanism maintains session validity

### 4.2 Main Navigation (Floating Action Buttons)
**Note:** App currently uses floating action buttons instead of bottom tab bar for navigation:
1. **Home** (default) - Week strip, cycle dashboard, predictions
2. **Calendar** (FAB) - Full month view with symptom logging
3. **Daily Log** (FAB) - Comprehensive daily logging screen
4. **Profile** (FAB) - Settings & user preferences

**Not Yet Implemented:**
- Tasks screen
- Insights/Analytics screen

### 4.3 Screen Details

#### Home Screen
- [ ] Daily affirmation card (not implemented)
- [x] Cycle status widget (current phase, days tracking)
- [x] **Week Strip**:
  - [x] 7-day view with swipe navigation
  - [x] Phase-colored date circles
  - [x] Mood icons (color-coded)
  - [x] Symptom indicators (1-3 dots)
  - [x] Sexual activity heart icon with protection badge
  - [x] Tap date for full day details
  - [x] Long press for quick add menu
- [x] **Cycle Predictions Card** (next period, fertile window, ovulation)
- [x] Email verification banner
- [ ] Quick actions (log symptom, add task, log water) - partial (log period button)
- [ ] Today's tasks preview
- [ ] Streak counter
- [ ] Motivational messages

#### Calendar Screen
- [x] Monthly calendar view
- [x] **Calendar Indicators**:
  - [x] Phase background colors (period, fertile, ovulation, luteal)
  - [x] Mood icons (7 types with colors)
  - [x] Symptom dots (up to 3 visible)
  - [x] Sexual activity indicators (heart with shield for protected)
  - [x] Responsive cell sizing per device
  - [x] Tap date for day details bottom sheet
  - [x] Long press for quick add menu
- [x] Month navigation (swipe left/right)
- [x] Stream-based real-time updates

#### Day Detail Bottom Sheet
- [x] Full day information view
- [x] Mood display with color badge and icon
- [x] Symptom list with severity (1-5 scale)
- [x] Sexual activity with protection status
- [x] Notes/journal entry display
- [x] Edit button to navigate to full DailyLogScreen
- [x] Real-time stream-based data
- [x] Quick add buttons for mood/symptoms
- [x] Phase indicator
- [ ] Cycle predictions visualization (on home screen instead)
- [ ] Phase education tooltips

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

#### Settings Screens
- [x] **Edit Profile Screen**
  - [x] First name, last name, username fields
  - [x] Date of birth (optional)
  - [x] Profile photo (placeholder)
  - [x] Username availability check
  - [x] Save/cancel actions

- [x] **Change Password Screen**
  - [x] Current password verification
  - [x] New password with confirmation
  - [x] Password strength validation
  - [x] Show/hide password toggles

- [x] **Notifications Settings Screen**
  - [x] Period reminders toggle
  - [x] Symptom reminders toggle
  - [x] Daily check-in toggle
  - [x] Tips & insights toggle
  - [x] Master notification toggle

- [x] **Cycle Settings Screen**
  - [x] Average cycle length adjustment
  - [x] Average period length adjustment
  - [x] Last period start date
  - [x] Save changes functionality

- [x] **Security Screens**
  - [x] PIN Setup Screen (4-digit with confirmation)
  - [x] PIN Unlock Screen (auto-lock with timeout)

#### Profile Screen
- [x] User info (name, email, profile completion percentage)
- [x] Settings sections:
  - [x] Profile Management (Edit Profile with avatar)
  - [x] Your Wellness (Cycle Settings, Pregnancy Mode)
  - [x] Preferences (Notifications, Theme - auto only)
  - [x] Privacy & Security (PIN Lock, Account Deletion)
  - [x] Support & Legal (Help, Privacy Policy, Terms)
  - [x] Account Actions (Sign Out, Delete Account)
- [x] Pull-to-refresh functionality
- [x] Card-based UI with color coding
- [x] Profile completion tracking

---

## 5. Data Models

### 5.1 User (Implemented ✅)
```dart
class User {
  String id;
  String email;
  String? name;
  String? firstName;
  String? lastName;
  String? username;
  DateTime? dateOfBirth;
  int averageCycleLength; // days (default 28)
  int averagePeriodLength; // days (default 5)
  DateTime? lastPeriodStart;
  bool notificationsEnabled;
  String? preferredTheme; // 'light', 'dark', 'system'
  bool pregnancyMode;
  DateTime? conceptionDate;
  DateTime? dueDate;
  Map<String, dynamic>? notificationPreferences;
  String? fcmToken;
  DateTime createdAt;
  DateTime updatedAt;
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

### 5.3 Mood (Implemented ✅)
```dart
class Mood {
  String id;
  String userId;
  DateTime date;
  MoodType type; // happy, calm, tired, sad, irritable, anxious, energetic
  String? notes;
  DateTime createdAt;
}
```

### 5.4 Symptom (Implemented ✅)
```dart
class Symptom {
  String id;
  String userId;
  DateTime date;
  SymptomType type; // cramps, headache, fatigue, bloating, nausea, backPain, breastTenderness, acne
  int severity; // 1-5 scale (mild to extreme)
  String? notes;
  DateTime createdAt;
}
```

### 5.5 Sexual Activity (Implemented ✅)
```dart
class SexualActivity {
  String id;
  String userId;
  DateTime date;
  bool protectionUsed;
  ProtectionType? protectionType; // condom, birthControl, iud, withdrawal, other
  String? notes;
  DateTime createdAt;
}
```

### 5.6 Note (Implemented ✅)
```dart
class Note {
  String id;
  String userId;
  DateTime date;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 5.7 Period (Implemented ✅)
```dart
class Period {
  String id;
  String userId;
  DateTime startDate;
  DateTime? endDate;
  FlowIntensity? flowIntensity; // light, moderate, heavy
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 5.8 Cycle (Implemented ✅)
```dart
class Cycle {
  String id;
  String userId;
  DateTime startDate;
  DateTime? endDate;
  int? lengthDays;
  DateTime createdAt;
}
```

### 5.9 Task (Not Implemented)
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

### 5.10 Affirmation (Not Implemented)
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

### 5.11 WaterIntake (Not Implemented)
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

### 6.0 Widgets & Components Implemented

#### Reusable Widgets (✅ Implemented):
- [x] **AppDialog** - Standardized confirmation/alert dialogs
- [x] **AppBottomSheet** - Standardized modal bottom sheets
- [x] **MoodPicker** - Bottom sheet for selecting mood (7 types)
- [x] **SymptomPicker** - Bottom sheet with search for symptom selection
- [x] **DayDetailBottomSheet** - Full day information modal
- [x] **PredictionCard** - Cycle predictions display (next period, fertile window, ovulation)
- [x] **EmailVerificationBanner** - Verification reminder with resend
- [x] **UserAvatar** - Profile photo placeholder
- [x] **OverlayNotification** - Toast-style notifications

#### Services (✅ Implemented):
- [x] **SupabaseService** - Complete database operations
- [x] **NotificationService** - FCM integration
- [x] **PinService** - PIN security with SHA-256 hashing
- [x] **CycleAnalyzer** - Cycle predictions and phase calculations
- [x] **FeedbackService** - Error handling and user feedback

#### Providers (✅ Implemented - Riverpod):
- [x] **PeriodProvider** - Period tracking state
- [x] **DailyLogProvider** - Daily data streams (moods, symptoms, notes, activities)
- [x] **CalendarProvider** - Calendar data and navigation
- [x] **NotificationProvider** - Notification preferences
- [x] **ProfileProvider** - User profile state
- [x] **PinLockProvider** - PIN lock state management

#### Utilities (✅ Implemented):
- [x] **ResponsiveSizing** - Device-aware sizing (small/medium/large/tablet breakpoints)
- [x] **CycleUtils** - Cycle phase calculations
- [x] **AppColors** - Theme-aware color system

### 6.1 Dependencies
- [x] `google_fonts` - Typography (Inter font)
- [x] `font_awesome_flutter` - Decorative icons
- [x] `supabase_flutter` - Backend (Auth, Database, Storage)
- [ ] `shared_preferences` - Local storage
- [ ] `sqflite` - Local database/cache
- [x] `firebase_core` - FCM setup
- [x] `firebase_messaging` - Push notifications
- [x] `intl` - Date formatting
- [x] `flutter_riverpod` - State management (providers throughout app)
- [ ] `table_calendar` - Calendar widget (built custom calendar instead)
- [ ] `fl_chart` - Charts/graphs
- [x] `local_auth` - Biometric authentication (infrastructure ready)
- [ ] `share_plus` - Social sharing
- [ ] `pdf` - Report generation
- [x] `flutter_local_notifications` - Local notification display
- [x] `awesome_notifications` - Rich local notifications
- [x] `crypto` - SHA-256 PIN hashing
- [x] `flutter_secure_storage` - Encrypted PIN storage
- [x] `mockito` - Testing mocks
- [x] `build_runner` - Code generation

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
- [x] **App-Specific PIN Lock** - 4-digit PIN to protect sensitive health data
  - SHA-256 hashed PIN storage
  - Auto-lock when app goes to background
  - **Automatic timeout logout** (30 minutes) - like banking apps
  - Encrypted storage via flutter_secure_storage
  - Independent of device PIN/biometric for enhanced security
- [ ] End-to-end encryption for sensitive health data
- [ ] Local data encryption
- [ ] Biometric authentication option (infrastructure ready)
- No data sharing with third parties
- GDPR/HIPAA compliant
- Clear privacy policy
- [ ] Data export capability
- [x] Account deletion with full data removal

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
- [x] Home screen with week strip and cycle dashboard
- [ ] Simple task list
- [ ] Basic affirmation display
- [ ] Bottom navigation (navigation via floating buttons instead)

### Phase 2: Core Features (Weeks 4-6)
- [x] Cycle tracking calendar (full month view with indicators)
- [x] Symptom logging (mood + physical symptoms with severity)
- [ ] Task CRUD operations
- [ ] Affirmation library
- [x] Database implementation (Supabase)
- [x] Firebase integration (FCM for notifications)

### Phase 3: Advanced Features (Weeks 7-9)
- [ ] Analytics dashboard (not implemented)
- [x] Insights generation (CycleAnalyzer service with predictions)
- [ ] Streak tracking (not implemented)
- [ ] Custom affirmations (not implemented)
- [x] Notifications system (FCM infrastructure, NotificationService, local notifications)
- [x] Data export (account deletion with data removal implemented, CSV/PDF export pending)
- [x] **Additional Advanced Features Completed:**
  - [x] Pregnancy mode tracking
  - [x] PIN security with timeout logout
  - [x] Responsive design system
  - [x] Real-time data streaming with Riverpod
  - [x] Profile completion tracking
  - [x] Cycle phase predictions
  - [x] Comprehensive settings screens

### Phase 4: Polish & Launch (Weeks 10-12)
- [x] Onboarding flow (basic implementation)
- [ ] Tutorial/walkthrough
- [ ] Performance optimization
- [x] Testing (unit, widget, integration - partial)
  - [x] Widget tests (WelcomeScreen, HomeScreen, CalendarScreen)
  - [x] Unit tests (models, cycle calculations, app colors)
  - [x] Service tests (CycleAnalyzer with mocks)
  - [x] Widget component tests (MoodPicker, SymptomPicker, AppDialog, AppBottomSheet, PredictionCard)
  - [x] Integration tests (app flow, cycle tracking)
  - [ ] Full test coverage (currently partial)
- [ ] App store assets
- [ ] Beta testing
- [ ] Launch!

---

## 10.1 Testing Implementation

### Unit Tests (✅ Implemented):
- `test/unit/models_test.dart` - Data model tests
- `test/unit/cycle_calculations_test.dart` - Cycle logic tests
- `test/unit/app_colors_test.dart` - Theme color tests

### Widget Tests (✅ Implemented):
- `test/widget/welcome_screen_test.dart` - Welcome screen rendering
- `test/widget/home_screen_test.dart` - Home screen components
- `test/widget/calendar_screen_test.dart` - Calendar functionality

### Component Tests (✅ Implemented):
- `test/widgets/mood_picker_test.dart` - 5 tests (selection, search, display)
- `test/widgets/symptom_picker_test.dart` - 9 tests (selection, severity, search)
- `test/widgets/app_dialog_test.dart` - Dialog component tests
- `test/widgets/app_bottom_sheet_test.dart` - Bottom sheet tests
- `test/widgets/prediction_card_test.mocks.dart` - Mock generation

### Service Tests (✅ Implemented):
- `test/services/cycle_analyzer_test.dart` - Cycle prediction logic
- `test/services/cycle_analyzer_test.mocks.dart` - Service mocks

### Integration Tests (✅ Implemented):
- `test/integration/app_integration_test.dart` - Full app flow
- `test/integration/cycle_tracking_integration_test.dart` - Cycle tracking end-to-end
- `test/integration/prediction_flow_test.dart` - Prediction flow (has errors)

### Test Coverage Status:
- ✅ Widget tests passing
- ✅ Unit tests passing
- ✅ Component tests passing (14 total)
- ✅ Service tests passing with mocks
- ⚠️ Integration tests (some with errors)
- 📊 Coverage: ~60-70% estimated (aim for 80%+)

## 11. Future Enhancements (Post-Launch)

- [ ] Community forum (anonymous)
- [ ] Expert articles/blog
- [x] Pregnancy mode (basic implementation with conception/due date tracking)
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
