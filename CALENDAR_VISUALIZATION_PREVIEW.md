# Calendar & Week Strip Visualization - Recommended Approach Preview

## Implementation Status: ✅ Week Strip Complete

### What You'll See Now:

## 📅 **Week Strip (Home Screen) - IMPLEMENTED**

```
╔════════════════════════════════════════════════════════╗
║  Mon    Tue    Wed    Thu    Fri    Sat    Sun        ║
║   28     29     30     31      1      2      3         ║
║  ┌──┐   ┌──┐   ┌──┐   ┌──┐   ┌──┐   ┌──┐   ┌──┐     ║
║  │28│   │29│   │30│   │31│   │ 1│   │ 2│   │ 3│     ║
║  └──┘   └──┘   └──┘   └──┘   └──┘   └──┘   └──┘     ║
║   🔴     🔴     🔴     🔴     ⚪     ⚪     ⚪        ║ ← Phase Color
║   😊     😔     😰     ⚡     😴     😊     -         ║ ← Mood Icon (colored)
║   ••     ••••   •      ••     -      •      -         ║ ← Symptom Dots
║   ❤      -      ❤🛡    -      -      ❤      -         ║ ← Activity Icon
╚════════════════════════════════════════════════════════╝
```

### Visual Breakdown:

**Row 1: Day Letter**
- Single letter (M, T, W, T, F, S, S)
- Gray text, small font (12px)

**Row 2: Date Circle**
- 40x40px circle
- Background = cycle phase color
  - 🔴 Red = Period
  - 🔵 Blue = Fertile window
  - 🟣 Purple = Ovulation
  - 🩷 Pink = Luteal phase
- White/black text based on background
- Bold border on today's date

**Row 3: Mood Icon** (18px height) **[ICONS, NOT EMOJI]**
- Icons.sentiment_very_satisfied (Happy) - Tertiary color
- Icons.sentiment_satisfied (Calm) - Tertiary color
- Icons.sentiment_neutral (Tired) - Tertiary color
- Icons.sentiment_dissatisfied (Sad) - Tertiary color
- Icons.sentiment_very_dissatisfied (Irritable) - Tertiary color
- Icons.mood_bad (Anxious) - Tertiary color
- Icons.bolt (Energetic) - Tertiary color
- 16px icon size, colored with theme
- Empty if no mood logged

**Row 4: Symptom Dots** (12px height)
- Small circular dots (3x3px each)
- Secondary color (coral/pink)
- Shows 1-3 dots max (if 5 symptoms, still shows 3 dots)
- Horizontal spacing: 1px between dots
- Empty if no symptoms

**Row 5: Sexual Activity** (14px height) **[ICONS, NOT EMOJI]**
- ❤ Icons.favorite = Activity logged (unprotected)
- ❤🛡 Icons.favorite + Icons.shield = Activity with protection
- Heart (14px, error color) + Shield (8px, primary color)
- Shield in small circle badge overlay
- Empty if no activity

---

## 🎨 **Color Scheme**

### Phase Colors (Circle Background):
```dart
Period (Days 1-5):
  Light mode: #EF5350 (Light Red)
  Dark mode:  #E53935 (Red)

Fertile Window (Days 8-13):
  Light mode: #BBDEFB (Light Blue)
  Dark mode:  #1976D2 (Blue)

Ovulation (Day 14):
  Light mode: #E1BEE7 (Light Purple)
  Dark mode:  #7B1FA2 (Purple)

Luteal Phase (Days 15-28):
  Light mode: #F8BBD0 (Light Pink)
  Dark mode:  #AD1457 (Pink)
```

### Indicator Colors:
```dart
Symptom Dots: colorScheme.secondary (Coral)
Activity Heart: Default emoji color
Protection Shield: Default emoji color
Mood: Default emoji color
```

---

## 📱 **Responsive Behavior**

### Container Spacing:
- Total container: 16px margin all sides
- Internal padding: 16px
- Between elements: 2-4px vertical gaps
- Horizontal: Divided equally (Expanded widgets)

### Touch Targets:
- Each date circle: 40x40px (48px with padding)
- Tap anywhere in column to see details
- Future: Bottom sheet with full day info

---

## 🔄 **Data Loading**

### Stream Providers Used:
```dart
ref.watch(moodStreamProvider(dateKey))
ref.watch(symptomsStreamProvider(dateKey))
ref.watch(sexualActivityStreamProvider(dateKey))
```

### Performance:
- 7 dates × 3 streams = 21 active subscriptions
- All cached and auto-disposed when widget unmounts
- Real-time updates when data changes

---

## 📊 **Information Density**

### Per Day Cell:
- **Phase**: Background color (always visible)
- **Date**: Number 1-31 (always visible)
- **Mood**: 0-1 emoji (16px space reserved)
- **Symptoms**: 0-3 dots (12px space reserved)
- **Activity**: 0-1 indicator (14px space reserved)

### Total Height Per Column:
```
Day letter:     12px text + 8px gap
Date circle:    40px
Mood:          16px (or empty)
Symptoms:      12px (or empty)
Activity:      14px (or empty)
Gaps:          8px total
─────────────────────────
TOTAL:         ~102px
```

---

## 🎯 **User Experience**

### What Users See:
1. **At a glance**: Week overview with cycle phases
2. **Quick scan**: Mood patterns across the week
3. **Health tracking**: Symptom frequency (dots)
4. **Intimacy tracking**: Private activity indicators
5. **Today highlight**: Bold border on current date

### Future Interactions:
- **Tap date**: Open bottom sheet with full details
- **Swipe**: Navigate weeks (future enhancement)
- **Long press**: Quick add mood/symptom (future)

---

## 🔐 **Privacy Features**

### Current Implementation:
- Sexual activity: Subtle heart emoji
- Protection: Small shield badge
- No explicit text labels
- Discrete dot system for symptoms
- Emoji-based mood (not text)

### Future Privacy Options:
```dart
Settings > Privacy:
☑️ Show sexual activity indicators
☑️ Show protection status
☐ Hide activity on lock screen
☐ Require PIN to view activity details
```

---

## 🐛 **Known Limitations**

1. **Week starts Monday**: Hardcoded to Mon-Sun
2. **Fixed 7 days**: Cannot expand/collapse
3. **No scrolling**: Only current week visible
4. **No tap action yet**: Details view not implemented
5. **Emoji size fixed**: Not customizable

---

## 🚀 **Next Steps**

### Phase 1: Calendar Month View (Next Implementation)
- Same indicator system
- Monthly grid layout
- Scrollable months
- Tap to see details

### Phase 2: Detail Bottom Sheet
```
Tap any date →
╔═══════════════════════════╗
║ Tuesday, Dec 31           ║
║ Cycle Day 5 • Period      ║
╠═══════════════════════════╣
║ 😊 Calm                   ║
║                           ║
║ Symptoms (3):             ║
║ • Cramps (4/5)           ║
║ • Headache (3/5)         ║
║ • Fatigue (2/5)          ║
║                           ║
║ ❤️ Sexual Activity       ║
║ • Protection: Condom     ║
║                           ║
║ 🩸 Flow: Heavy           ║
║ 📝 Note: Feeling better  ║
╚═══════════════════════════╝
```

### Phase 3: Calendar Enhancements
- Week navigation (swipe left/right)
- Month view with same indicators
- Statistics view (mood trends)
- Export data feature

---

## 💡 **Design Rationale**

### Why This Approach?

1. **Minimal Visual Noise**
   - Clean, scannable layout
   - No text labels cluttering the view
   - Color-coded for quick recognition

2. **Information Hierarchy**
   - Most important (phase) = background
   - Very important (mood) = center, larger
   - Important (symptoms) = small dots
   - Private (activity) = discrete icons

3. **Accessibility**
   - Large enough touch targets (40px circles)
   - Color + icon redundancy (not just color)
   - Emoji universally understood
   - High contrast text on colored backgrounds

4. **Privacy by Design**
   - No explicit labels for intimate data
   - Heart emoji could be "favorite day"
   - Dots could be "events"
   - Shield not immediately obvious

5. **Performance**
   - Stream-based = real-time updates
   - Cached data = no repeated queries
   - Auto-dispose = memory efficient
   - Widget rebuilds only affected dates

---

## 🎨 **Visual Examples**

### Example Week (Period Week):
```
Mon 28: Period Day 3
  🔴 (red circle)
  😔 (sad)
  •••• (4 symptoms)
  ❤️🛡️ (protected activity)

Tue 29: Period Day 4
  🔴 (red circle)
  😰 (anxious)
  •• (2 symptoms)
  - (no activity)

Wed 30: Period Day 5
  🔴 (red circle)
  😊 (happy - feeling better!)
  • (1 symptom)
  - (no activity)
```

### Example Week (Fertile Window):
```
Fri 12: Fertile Day
  🔵 (blue circle)
  😊 (happy)
  - (no symptoms)
  ❤️ (unprotected - trying to conceive)

Sat 13: Fertile Day
  🔵 (blue circle)
  😌 (calm)
  • (1 symptom)
  ❤️ (unprotected - fertile window)

Sun 14: Ovulation
  🟣 (purple circle)
  ⚡ (energetic)
  - (no symptoms)
  ❤️🛡️ (protected)
```

---

## 🧪 **Testing Scenarios**

### Test Case 1: Empty Week
- All circles show phase colors
- No mood emojis
- No symptom dots
- No activity indicators
- Clean, minimal look

### Test Case 2: Busy Week
- All dates have mood
- Multiple symptoms per day
- Some days have activity
- Information-dense but scannable

### Test Case 3: Today's Date
- Bold border on current date
- All other features same
- Easy to identify "today"

### Test Case 4: Dark Mode
- Darker phase colors
- White text on dark backgrounds
- Same emoji visibility
- Maintained contrast ratios

---

## 📝 **Implementation Notes**

### Code Structure:
```dart
_buildWeekStrip()
  ├── Container (card)
  ├── Row (7 columns)
  │   └── Expanded (each day)
  │       └── Column
  │           ├── Day letter (Text)
  │           ├── Date circle (Container)
  │           ├── Mood emoji (AsyncValue widget)
  │           ├── Symptom dots (AsyncValue widget)
  │           └── Activity icon (AsyncValue widget)
  │
  ├── _getMoodEmoji(MoodType)
  ├── _buildSymptomDots(List<Symptom>)
  └── _buildActivityIndicator(SexualActivity)
```

### Helper Methods:
- `_getMoodEmoji()`: Maps MoodType to emoji string
- `_buildSymptomDots()`: Creates 1-3 dots based on count
- `_buildActivityIndicator()`: Shows heart with optional shield

---

**Status**: ✅ Ready to test!

**Test it**: Hot restart your app and navigate to the home screen. You'll see the enhanced week strip with mood, symptoms, and activity indicators!

**Next**: Shall we implement the same approach for the Calendar Month View?
