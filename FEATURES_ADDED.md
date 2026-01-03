# New Features Added - Sexual Activity, Pregnancy Mode, Daily Notes, and UI Components

## Overview
Added comprehensive tracking features and UI component standards to the Lovely period tracking app:
- Sexual activity logging with protection tracking
- Pregnancy mode for expecting mothers
- Daily notes/journal entries
- Consolidated daily log screen
- **Mood & Symptom Pickers** (December 31, 2025)
- **Standardized Dialog & Bottom Sheet Components** (December 31, 2025)
- **App-Specific PIN Security** (January 3, 2026)

---

## January 3, 2026 - App-Specific PIN Security System

### PIN Lock Feature ✅
**Purpose:** Protect sensitive health data with app-specific 4-digit PIN (independent of device security)

**Files Created:**
- `lib/services/pin_service.dart` - PIN storage and verification service
- `lib/providers/pin_lock_provider.dart` - Riverpod state management for PIN lock
- `lib/screens/security/pin_setup_screen.dart` - PIN creation interface with confirmation
- `lib/screens/security/pin_unlock_screen.dart` - PIN entry screen for app unlock

**Files Modified:**
- `lib/screens/main/profile_screen.dart` - Added Privacy & Security section with PIN settings
- `lib/main.dart` - Added app lifecycle observer for auto-lock on background
- `lib/utils/responsive_utils.dart` - Added `spacingXl` constant for PIN screens
- `pubspec.yaml` - Added security dependencies

**Security Architecture:**
- **SHA-256 Hashing**: PINs are never stored in plain text
- **Encrypted Storage**: Uses `flutter_secure_storage` for platform-level encryption
  - Android: AES encryption in KeyStore
  - iOS: Keychain with kSecAttrAccessible protection
- **App-Specific**: Independent of device PIN/biometric for maximum privacy
- **No Cloud Sync**: PIN stored only on local device

**User Experience:**
- **Setup Flow**:
  1. Navigate to Profile → Privacy & Security → App PIN Lock
  2. Create 4-digit PIN
  3. Confirm PIN (mismatch detection with retry)
  4. Success confirmation: "PIN enabled! Your data is now protected 🔒"

- **Lock Behavior**:
  - Auto-locks when app enters background (paused/inactive state)
  - Requires PIN entry on app resume
  - Prevents back navigation during unlock (can't bypass)
  - Failed attempts tracked with error animation

- **UI Features**:
  - Circular number pad (0-9) with haptic feedback
  - 4-dot visual feedback (filled/unfilled animation)
  - Lovely branding on unlock screen (gradient circle + heart)
  - Color-coded sections in profile (pink #E91E63 for Privacy & Security)

**Settings Management:**
- **Enable PIN**: First-time setup via modal bottom sheet
- **Change PIN**: Verify old PIN, set new PIN (placeholder - to be implemented)
- **Disable PIN**: Confirmation dialog → removes PIN and disables lock
- **Profile Completion**: Enabling PIN counts toward profile completion tracking

**State Management (Riverpod):**
```dart
class PinLockState {
  final bool isEnabled;  // Is PIN feature enabled?
  final bool isLocked;   // Is app currently locked?
  final bool hasPin;     // Does user have a PIN set?
}
```

**Dependencies Added:**
- `local_auth: ^2.3.0` - Infrastructure for future biometric integration
- `flutter_secure_storage: ^9.2.2` - Encrypted storage for PIN hash
- `crypto: ^3.0.5` - SHA-256 hashing algorithm

**Testing Status:**
- ✅ Manual testing complete
- ✅ No analyzer errors in production code
- ⏳ Unit tests pending

**Future Enhancements:**
- [ ] Biometric unlock option (Face ID/Touch ID/fingerprint)
- [ ] PIN attempt lockout (temporary lock after X failed attempts)
- [ ] Forgot PIN recovery flow
- [ ] Change PIN implementation (UI exists, logic pending)

---

## December 31, 2025 - Radio Button Migration & Account Management

### RadioGroup API Migration ✅
**Files Modified:**
- `lib/screens/main/profile_screen.dart` - Migrated theme selection to modern RadioGroup
- `lib/services/supabase_service.dart` - Added deleteAccount() method

**Migration Details:**
- **Old Pattern (Deprecated)**: Individual `Radio` widgets with `groupValue` and `onChanged`
- **New Pattern (Modern)**: `RadioGroup<T>` wrapper managing group state with child `Radio` widgets
- **Compliance**: Flutter 3.35+ standard (replaces deprecated API from 3.32.0)
- **Benefit**: Better accessibility (ARIA compliant), cleaner API, improved keyboard navigation

**Code Example:**
```dart
// Modern RadioGroup Pattern
RadioGroup<int>(
  groupValue: selectedValue,
  onChanged: (value) {
    setState(() => selectedValue = value);
  },
  child: Column(
    children: [
      Radio<int>(value: 0),  // No groupValue or onChanged needed
      Radio<int>(value: 1),
      Radio<int>(value: 2),
    ],
  ),
)
```

### Account Deletion Feature ✅
**Added Method**: `SupabaseService.deleteAccount()`

**Features:**
- Deletes all user data from related tables:
  - Moods
  - Symptoms
  - Periods
  - Sexual Activities
  - Notes
- Deletes user profile record
- Deletes auth account via Supabase Admin API
- Auto sign-out after deletion
- Proper error handling with rethrow

**Security:**
- Cascading deletes ensure data integrity
- Admin API for account deletion
- Automatic session cleanup

### API Compliance Updates
**Status**: 100% Deprecated API Free
- ✅ No Radio.groupValue usage
- ✅ No Radio.onChanged usage
- ✅ No RadioListTile deprecated patterns
- ✅ All color opacity using `.withValues(alpha: ...)`
- ✅ All buttons using modern Material Design 3 APIs

---

## December 31, 2025 - UI Components, Pickers, Calendar & Week Strip Visualization

### Mood & Symptom Pickers ✨
**Files Created:**
- `lib/widgets/mood_picker.dart` - Reusable mood selection component
- `lib/widgets/symptom_picker.dart` - Symptom selection with severity levels
- `test/widgets/mood_picker_test.dart` - 5 tests (all passing)
- `test/widgets/symptom_picker_test.dart` - 9 tests (all passing)

**Files Modified:**
- `lib/screens/daily_log_screen.dart` - Integrated pickers with add/delete functionality
- `lib/screens/main/home_screen.dart` - Converted to stream-based architecture for consistency
- `lib/services/supabase_service.dart` - Added `deleteMood()`, `deleteSymptom()`, fixed data types
- `lib/providers/daily_log_provider.dart` - Simplified stream filtering logic
- `database_migrations.sql` - Added moods and symptoms tables

**Features:**
- **Mood Picker**: Bottom sheet with 7 mood types (Happy, Calm, Tired, Sad, Irritable, Anxious, Energetic)
- **Symptom Picker**: Bottom sheet with 8 symptom types, includes search functionality
- **Severity Picker**: 1-5 scale with descriptive labels (Mild to Extreme)
- **Visual Indicators**: Color-coded icons for each mood/symptom
- **Selected State**: Checkmarks on already-logged items
- **Delete Confirmation**: AppDialog integration for safe deletion
- **Real-time Updates**: Automatic refresh after add/delete operations
- **Error Handling**: FeedbackService integration for user notifications

**Critical Fixes Applied:**
1. **Database Column Naming**: Fixed `saveMood()` to use `mood_type` instead of `mood`
2. **Symptom Type Serialization**: Fixed to use `.value` (snake_case) instead of `.name` (camelCase)
3. **Stream Filtering Bug**: Changed from exclusive `isAfter/isBefore` to inclusive `!isBefore` comparison
4. **Data Synchronization**: Both HomeScreen and DailyLogScreen now use same stream providers
5. **Date Key Consistency**: Normalized to `DateTime(year, month, day)` without time components
6. **Multiple Symptoms Support**: Fixed severity preservation when adding additional symptoms
7. **setState After Dispose**: Added mounted checks before all setState calls

**Architecture Improvements:**
- **HomeScreen Refactored**: Removed local state, now uses `moodStreamProvider` and `symptomsStreamProvider`
- **Reactive UI**: Both screens auto-update when database changes
- **Provider Invalidation**: Explicit `ref.invalidate()` after save/delete operations
- **Consistent Date Keys**: All date comparisons use midnight DateTime for accuracy

**User Experience:**
1. HomeScreen: Tap "+" icon → Select mood/symptom → Choose severity → Auto-save
2. DailyLogScreen: Same picker interface with "Add" button
3. Data syncs instantly between both screens
4. Delete with confirmation dialog from either screen
5. Multiple symptoms fully supported with severity tracking

**Bug Fixes:**
- ❌ "setState called after dispose" → ✅ Added mounted checks
- ❌ "No column such as moods" → ✅ Created moods/symptoms tables
- ❌ Moods not saving → ✅ Fixed column name from `mood` to `mood_type`
- ❌ Symptoms not visible → ✅ Fixed stream filtering logic (inclusive dates)
- ❌ Can't add multiple symptoms → ✅ Fixed severity map preservation
- ❌ Adding symptom clears all → ✅ Fixed enum value serialization (.name → .value)
- ❌ Data not syncing between screens → ✅ Unified stream providers

### Calendar & Week Strip Visualization ✨ (December 31, 2025)
**Files Modified:**
- `lib/screens/main/home_screen.dart` - Enhanced week strip with mood/symptom/activity indicators
- `lib/screens/calendar_screen.dart` - Added mood/symptom/activity visualization to calendar cells

**Features:**
- **Week Strip Indicators**:
  - Sexual activity (heart icon with shield for protection) above date
  - Phase-colored date circles (red=period, blue=fertile, purple=ovulation, pink=luteal)
  - Mood icons with color-coded meanings (green=happy, blue=calm, orange=irritable, etc.)
  - Symptom dots (1-3 dots based on symptom count)

- **Calendar Month View**:
  - Same visual language as week strip
  - Sexual activity indicator at top of each cell
  - Date in center with phase background color
  - Mood icon below date
  - Symptom dots at bottom

- **Responsive Design**:
  - Adaptive sizing for different screen widths
  - Small phones (<360px): Compact mode with smaller icons/fonts
  - Medium phones (360-400px): Balanced sizing
  - Large phones/tablets (>400px): Full-size display

**Icon-Based Design** (not emojis):
- All indicators use Flutter Material Icons
- Mood icons use the same colors as MoodPicker bottom sheet
- Heart icon for sexual activity (red/error color)
- Shield badge overlay for protected activity
- Theme-aware colors for light/dark mode support

**Performance:**
- Stream-based data loading for real-time updates
- Cached calendar data with lazy loading
- Responsive grid aspect ratios to prevent overflow

### Centralized Responsive Sizing Utility ✨ (December 31, 2025)
**Files Created:**
- `lib/utils/responsive_utils.dart` - Centralized responsive sizing system

**Features:**
- **Screen Size Detection**: Automatically categorizes devices (small/medium/large/tablet)
- **Breakpoints**:
  - Small: < 360px (compact phones)
  - Medium: 360-400px (standard phones)
  - Large: 400-600px (large phones)
  - Tablet: > 600px (tablets)

- **Easy Usage via Context Extension**:
  ```dart
  context.responsive.weekStripCircleSize
  context.responsive.calendarDateFontSize
  context.responsive.iconSize
  ```

- **Available Properties**:
  - Calendar: `calendarCellAspectRatio`, `calendarDateFontSize`, `calendarIconSize`, `calendarActivityIconSize`, `calendarDotSize`
  - Week Strip: `weekStripCircleSize`, `weekStripDateFontSize`, `weekStripMoodIconSize`, `weekStripActivityIconSize`, `weekStripDotSize`
  - Typography: `smallFontSize`, `bodyFontSize`, `titleFontSize`
  - Icons: `smallIconSize`, `iconSize`, `largeIconSize`
  - Spacing: `spacingXs`, `spacingSm`, `spacingMd`, `spacingLg`
  - Touch Targets: `minTouchTarget`
  - Containers: `borderRadius`, `borderRadiusSm`

**Benefits:**
- Single source of truth for responsive sizing
- Consistent UI across all device sizes
- Easy to maintain and update
- No duplicate code in individual screens

### Material Design 3 Compliance
**Files Modified:**
- `lib/screens/welcome_screen.dart` - Migrated ElevatedButton → FilledButton
- `lib/screens/onboarding/onboarding_screen.dart` - Migrated ElevatedButton → FilledButton

**Reason**: Material Design 3 recommends FilledButton for high-emphasis actions

---

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

---

## Calendar Interactivity & Responsive Design - December 31, 2025

### Major Features Added

#### 1. **Day Detail Bottom Sheet** 📋
**Files Created:**
- `lib/widgets/day_detail_bottom_sheet.dart` - Full day information view

**Features:**
- Tap any date to view complete day details
- Shows: mood, symptoms (with severity), sexual activity (with protection status), notes
- Edit button for quick navigation to DailyLogScreen
- Real-time stream-based data loading

#### 2. **Long Press Quick Add Menu** ⚡
**Quick access to add data:**
- Long press any date on week strip or calendar
- Three colored buttons: Mood (green), Symptom (coral), Activity (red)
- Navigates to DailyLogScreen pre-selected with chosen date
- Mounted checks prevent navigation after widget disposal

#### 3. **Week Navigation with Swipe** ➡️
**Files Modified:**
- `lib/screens/main/home_screen.dart` - Refactored with PageController

**Features:**
- Swipe left/right to navigate between weeks
- Week labels: "This Week", "Last Week", "Next Week"
- Tap label to jump back to current week
- PageController with page 100 as center for infinite scroll
- `_weekOffset` state variable tracks current week offset

#### 4. **Responsive Sizing System** 📱
**Files Created:**
- `lib/utils/responsive_utils.dart` - Centralized sizing utility

**Features:**
- Screen breakpoints: small (<360px), medium (360-400px), large (400-600px), tablet (>600px)
- Auto-scaling for: fonts, icons, spacing, touch targets, containers
- Easy access: `context.responsive.propertyName`
- Consistent sizing across all screens

**Available Properties:**
- Calendar: `calendarCellAspectRatio`, `calendarDateFontSize`, `calendarIconSize`, `calendarActivityIconSize`
- Week Strip: `weekStripCircleSize`, `weekStripDateFontSize`, `weekStripMoodIconSize`, `weekStripActivityIconSize`
- Typography: `bodyFontSize`, `titleFontSize`
- General: `iconSize`, `spacingMd`, `borderRadius`

#### 5. **Lifecycle Safety Improvements** 🛡️
**Critical Fixes:**

1. **DayDetailBottomSheet Edit Button**
   ```dart
   onPressed: () async {
     if (!context.mounted) return;
     Navigator.pop(context);
     if (!context.mounted) return;
     await Navigator.push(...);
   }
   ```

2. **Quick Add Menu Navigation**
   ```dart
   onTap: () async {
     Navigator.pop(ctx);        // Pop bottom sheet first
     if (!mounted) return;       // Check mounted before navigation
     await Navigator.push(...);  // Navigate to DailyLogScreen
   }
   ```

3. **Context Usage**
   - Pop uses bottom sheet context (`ctx`)
   - Push uses outer screen context (`context`)
   - Both checked with `mounted` before proceeding

**Prevents:**
- "setState called after dispose" errors
- "BuildContext getter inside widget constructor" errors
- Navigator pop/push timing issues
- Context stale reference bugs

### Bug Fixes Applied
- ✅ Mounted checks before all navigations
- ✅ Proper context scoping in callbacks
- ✅ Async/await for navigation chains
- ✅ No navigation after widget disposal
- ✅ Safe bottom sheet to screen transitions

### Calendar Visualization
**Features:**
- Same indicator system as week strip
- Sexual activity icon above date (privacy-first)
- Phase-colored backgrounds
- Mood icons with matching colors
- Symptom dots (1-3)
- Responsive cell sizes based on screen width
- Tap for details, long press for quick add

### Performance
- Stream-based real-time updates
- Responsive sizing calculated once per screen change
- Lazy loading with cached color values
- Efficient PageView week navigation