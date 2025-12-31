# New Features Added - Sexual Activity, Pregnancy Mode, and Daily Notes

## Overview
Added comprehensive tracking features to the Lovely period tracking app:
- Sexual activity logging with protection tracking
- Pregnancy mode for expecting mothers
- Daily notes/journal entries
- Consolidated daily log screen

## Database Changes

### Run the Migration
Execute the SQL commands in `database_migrations.sql` in your Supabase SQL Editor to:
1. Add pregnancy mode columns to users table
2. Create sexual_activities table
3. Create notes table
4. Set up indexes and Row Level Security policies

## New Models

### 1. SexualActivity (`lib/models/sexual_activity.dart`)
Tracks intimate activity with:
- Date of activity
- Protection used (yes/no)
- Protection type (condom, birth control, IUD, withdrawal, other)
- Optional notes

### 2. Note (`lib/models/note.dart`)
Daily journal/note entries:
- Date
- Content (free text)
- Created/updated timestamps

## New Screens

### 1. DailyLogScreen (`lib/screens/daily_log_screen.dart`)
Comprehensive daily logging interface showing:
- Today's mood (if logged)
- Today's symptoms (if logged)
- Sexual activity toggle with protection options
- Daily note text area

**Access**: Tap the "Log Today" floating action button on the home screen

### 2. PregnancyModeScreen (`lib/screens/pregnancy_mode_screen.dart`)
Pregnancy tracking interface with:
- Enable/disable pregnancy mode
- Conception date selection
- Automatic due date calculation (280 days from conception)
- Weeks pregnant counter
- Days until due date

**Access**: Can be added to profile screen or settings

## Service Methods Added

### SupabaseService Updates (`lib/services/supabase_service.dart`)

#### Sexual Activity Methods:
- `logSexualActivity()` - Log sexual activity for a date
- `getSexualActivityForDate()` - Get activity for specific date
- `getSexualActivitiesInRange()` - Get activities in date range
- `deleteSexualActivity()` - Remove activity entry

#### Note Methods:
- `saveNote()` - Save or update daily note
- `getNoteForDate()` - Get note for specific date
- `getNotesInRange()` - Get notes in date range
- `deleteNote()` - Remove note

#### Pregnancy Mode Methods:
- `enablePregnancyMode()` - Activate pregnancy tracking
- `disablePregnancyMode()` - Deactivate pregnancy tracking
- `getPregnancyInfo()` - Get conception and due dates

## Integration with HomeScreen

The home screen now includes:
- Floating action button "Log Today" to open DailyLogScreen
- Automatic data reload when returning from daily log

## Protection Types

The app tracks the following protection methods:
- 🛡️ Condom
- 💊 Birth Control (pills)
- 🔒 IUD
- ⚠️ Withdrawal
- 📝 Other

## Usage Examples

### Logging Sexual Activity
```dart
await supabase.logSexualActivity(
  date: DateTime.now(),
  protectionUsed: true,
  protectionType: ProtectionType.condom,
);
```

### Saving a Daily Note
```dart
await supabase.saveNote(
  date: DateTime.now(),
  content: 'Had a great day, feeling energetic!',
);
```

### Enabling Pregnancy Mode
```dart
await supabase.enablePregnancyMode(
  conceptionDate: DateTime(2024, 1, 15),
  dueDate: DateTime(2024, 10, 22),
);
```

## Future Enhancements

Consider adding:
- Water intake tracking
- Exercise logging
- Sleep quality monitoring
- Basal body temperature for fertility
- Medication/supplement tracking
- Discharge/cervical mucus observations
- Calendar view with all logged activities
- Charts and trends visualization
- Export data to PDF/CSV
- Partner sharing features
- Appointment reminders

## Testing Checklist

- [ ] Run database migrations in Supabase
- [ ] Test sexual activity logging
- [ ] Test protection type selection
- [ ] Test daily note saving and editing
- [ ] Test pregnancy mode enable/disable
- [ ] Test due date calculation
- [ ] Verify RLS policies work correctly
- [ ] Test daily log screen navigation
- [ ] Verify data persistence across sessions- [x] Test persistent authentication (AuthGate)
- [x] Verify session survives app restart
- [x] Test onboarding flow for new users
- [x] Test direct navigation to home for returning users

---

## Persistent Authentication (AuthGate) - December 31, 2025

### Feature
Implemented seamless authentication that keeps users logged in across app restarts.

### Implementation
- **AuthGate Widget**: New authentication gateway that checks for existing sessions on app launch
- **File**: `lib/screens/auth/auth_gate.dart`
- **Main.dart Update**: Changed home screen from `WelcomeScreen` to `AuthGate`

### User Flow
```
App Launch
    → Supabase reads encrypted tokens from device storage
    → AuthGate checks currentSession
    → Valid session:
        → Onboarding complete → HomeScreen
        → Onboarding incomplete → OnboardingScreen
    → No/expired session → WelcomeScreen
```

### Session Persistence
- **Storage**: SharedPreferences (Android) / UserDefaults (iOS)
- **Survives**: App restarts, cache clearing
- **Lost on**: App data clearing, uninstall
- **Lifetime**: 30 days with auto-refresh, then requires re-login

### Benefits
- Users stay logged in for 30 days
- No repeated login prompts after app restarts
- Seamless user experience
- Secure token storage with automatic refresh