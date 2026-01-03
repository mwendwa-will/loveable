# Phase 1 Implementation: UI Mockups

This document shows what the UI looks like after implementing Phase 1 (Basic Learning).

## 1. Home Screen - Prediction Card

```
┌─────────────────────────────────────────────────────┐
│  Good Morning                                    🔔│
│  Day 15 of 28-day cycle                            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  [Week Strip - Days with colored circles]          │
│                                                     │
├─────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────┐ │
│  │ 📅 Next Period Prediction                    │ │
│  │ Learning from your tracked cycles            │ │
│  │                                               │ │
│  │ Your period will likely start in 13 days     │ │
│  │ 🗓️ Friday, January 15                        │ │
│  │                                               │ │
│  │ Confidence                            85%     │ │
│  │ ████████████████████████░░░░░░                │ │
│  │                                               │ │
│  │ 💡 High confidence - pattern well established│ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  [Cycle Card - Current status]                     │
│  [Mood Section]                                    │
│  [Symptoms Section]                                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Color Scheme:
- **High Confidence (85%+)**: Green progress bar
- **Medium Confidence (65-85%)**: Orange progress bar  
- **Low Confidence (< 65%)**: Red progress bar
- **Background**: Gradient from coral pink (subtle) to white

### Dynamic Text:
The prediction text changes based on confidence:
- **85%+**: "Your period will likely start in X days"
- **65-85%**: "Your period is expected in about X days"
- **< 65%**: "Your period may start around X days from now"

### Method Badge:
- `self_reported`: "Based on your estimated cycle length"
- `simple_average`: "Learning from your tracked cycles"
- `symptom_adjusted`: "Adjusted based on your symptoms"

---

## 2. Cycle Settings Screen

```
┌─────────────────────────────────────────────────────┐
│  ← Cycle Settings                          ✓ Save  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ 📊 Prediction Accuracy                       │ │
│  │                                               │ │
│  │ Current Confidence:                     85%   │ │
│  │ ████████████████████████░░░░░░                │ │
│  │                                               │ │
│  │ Total Predictions:            6               │ │
│  │ Average Error:                ±1.3 days       │ │
│  │ Accuracy (±2 days):           83%             │ │
│  │ Method:                       simple average  │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ Average Cycle Length                          │ │
│  │ Days from period start to next period start   │ │
│  │                                               │ │
│  │       ⊖          29 days          ⊕          │ │
│  │   ├─────────────●─────────────────────┤       │ │
│  │  21                                 45        │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ Average Period Length                         │ │
│  │ Number of days you typically bleed            │ │
│  │                                               │ │
│  │       ⊖           5 days           ⊕          │ │
│  │   ├─────────────●─────────────┤               │ │
│  │   2                          10               │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ Last Period Start Date                        │ │
│  │ Update this if you made a mistake             │ │
│  │                                               │ │
│  │ 📅 December 20, 2025                    ✏️   │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ ℹ️  How Predictions Work                      │ │
│  │                                               │ │
│  │ • The app learns from your actual cycles     │ │
│  │ • Predictions improve after 2-3 cycles       │ │
│  │ • Confidence increases with regularity       │ │
│  │ • Manual changes trigger recalculation       │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Features:
1. **Prediction Accuracy Card** - Shows real statistics
2. **Cycle Length Slider** - Range: 21-45 days
3. **Period Length Slider** - Range: 2-10 days
4. **Last Period Date Picker** - Quick correction if user made mistake
5. **Info Box** - Explains how learning works

### Access:
- From Profile Screen → Settings → Cycle Settings
- Or from Prediction Card → Tap to edit

---

## 3. Prediction Confidence Evolution

### New User (Cycle 1):
```
┌─────────────────────────────────────────────────────┐
│ 📅 Next Period Prediction                          │
│ Based on your estimated cycle length               │
│                                                     │
│ Your period may start around 30 days from now      │
│ 🗓️ Monday, January 31                              │
│                                                     │
│ Confidence                                   50%   │
│ ████████████████░░░░░░░░░░░░░░░░░░░░░░              │
│                                                     │
│ 💡 Low confidence - prediction will improve        │
└─────────────────────────────────────────────────────┘
```

### After 2 Cycles (Learning):
```
┌─────────────────────────────────────────────────────┐
│ 📅 Next Period Prediction                          │
│ Learning from your tracked cycles                  │
│                                                     │
│ Your period is expected in about 28 days           │
│ 🗓️ Thursday, January 30                            │
│                                                     │
│ Confidence                                   75%   │
│ ██████████████████████████░░░░░░░░░░                │
│                                                     │
│ 💡 Moderate - track more cycles for accuracy       │
└─────────────────────────────────────────────────────┘
```

### After 6+ Cycles (Confident):
```
┌─────────────────────────────────────────────────────┐
│ 📅 Next Period Prediction                          │
│ Learning from your tracked cycles                  │
│                                                     │
│ Your period will likely start in 29 days           │
│ 🗓️ Friday, January 31                              │
│                                                     │
│ Confidence                                   92%   │
│ ████████████████████████████████████░░              │
│                                                     │
│ 💡 High confidence - pattern well established      │
└─────────────────────────────────────────────────────┘
```

---

## 4. Truth Event: Period Started

When user taps "Start Period":

```
┌─────────────────────────────────────────────────────┐
│                Start New Period                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  When did your period start?                       │
│                                                     │
│  ○ Today (January 2, 2026)                         │
│  ○ Yesterday                                       │
│  ○ Custom date...                                  │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │ ℹ️  Prediction Update                         │ │
│  │                                               │ │
│  │ Predicted: January 5                          │ │
│  │ Actual: January 2                             │ │
│  │ Error: 3 days early                           │ │
│  │                                               │ │
│  │ Your cycle predictions will be recalculated   │ │
│  │ to improve accuracy.                          │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│               [Cancel]    [Start Period]           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

After confirmation:
```
✅ Period started, predictions recalculated
📊 Prediction accuracy: 3 days early (cycle 3)
✅ Recalculated: 28.2 days avg, 78% confidence
```

---

## 5. Color Coding & Visual Language

### Confidence Colors:
- 🟢 **Green (85%+)**: High confidence, reliable pattern
- 🟠 **Orange (65-84%)**: Moderate confidence, establishing pattern
- 🔴 **Red (< 65%)**: Low confidence, needs more data

### Icons:
- 📅 Calendar icon for predictions
- 📊 Analytics icon for statistics
- 💡 Lightbulb for tips
- ℹ️ Info for explanations
- ⊕⊖ Plus/minus for adjustments
- ✏️ Edit icon for date picker

### Layout Philosophy:
- **Cards** for discrete information blocks
- **Gradient backgrounds** for primary prediction (coral pink fade)
- **Progress bars** for confidence visualization
- **Sliders** for numeric adjustments
- **Blue info boxes** for helpful tips (not warnings)

---

## 6. Navigation Flow

```
Home Screen
  ├─ [Prediction Card]
  │    └─ Tap → Cycle Settings Screen
  │
  ├─ [Start Period FAB]
  │    └─ Dialog → Record accuracy → Recalculate
  │
  └─ Profile Screen
       └─ Settings
            └─ Cycle Settings
```

---

## Files Created/Modified Summary

### New Files:
1. `lib/services/cycle_analyzer.dart` - Core learning engine
2. `lib/widgets/prediction_card.dart` - Prediction display widget
3. `lib/screens/settings/cycle_settings_screen.dart` - Settings UI
4. `database_migrations_phase1.sql` - Schema updates

### Modified Files:
1. `lib/services/supabase_service.dart` - Enhanced startPeriod() with Truth Event
2. `lib/screens/onboarding/onboarding_screen.dart` - Added initial prediction generation
3. `lib/screens/main/home_screen.dart` - Added PredictionCard widget

### Migration Required:
Run `database_migrations_phase1.sql` in Supabase SQL Editor before testing.

---

**Document Version**: 1.0  
**Last Updated**: January 2, 2026  
**Status**: Phase 1 Complete - Ready for Testing
