# Lovely Design Guidelines

## Design Philosophy

Lovely is designed to be **warm, supportive, and empowering** - not clinical or intrusive. Every design decision should prioritize user comfort, privacy, and emotional well-being.

### Hybrid Material Design Approach

Lovely follows **Material Design 3 foundations** (spacing, typography, components) while adding **custom warmth and personality** through:
- Custom coral sunset color palette
- Gradients for visual depth and emotion
- Softer, more feminine aesthetic choices

We deviate from strict Material Design where it serves our users better, but maintain accessibility and usability standards.

### Core Principles
1. **Privacy First** - Visual design should reinforce data security
2. **Warmth Over Clinical** - Use soft colors, rounded corners, gentle gradients
3. **Clarity** - Clear hierarchy, readable text, obvious interactions
4. **Responsive** - Adapt gracefully to all device sizes
5. **Accessible** - Sufficient contrast, touch targets, screen reader support
6. **Material Foundation** - Use Material 3 components and patterns as base

---

## Color Palette

### Primary Colors
```
Coral Sunset (Primary)    #FF6F61
Light Coral               #FF8E7E
Soft Peach                #FFB5A7
```

### Cycle Phase Colors
```
Menstrual Phase           #FF6F61 (Coral Red)
Follicular Phase          #FFB5A7 (Soft Peach)
Ovulation Phase           #FF69B4 (Hot Pink)
Luteal Phase              #E8B4F5 (Lavender)
```

### Neutral Colors
```
Dark Background           #2D1B3D
Secondary Dark            #1A1A2E
Light Background          #F8F9FA
Border Gray               #E0E0E0
Text Gray                 #6C757D
```

### Semantic Colors
```
Success Green             #28A745
Warning Orange            #FFC107
Error Red                 #DC3545
Info Blue                 #17A2B8
```

### Usage Rules
- **Primary color (#FF6F61)** for CTAs, active states, key UI elements
- **Dark gradients** for hero cards and important content sections
- **Pastel gradients** for calendar views and soft backgrounds
- **White backgrounds** for content cards and sections
- **Semantic colors** only for status messages and alerts

---

## Typography

### Font Family
- **Primary**: Inter (via Google Fonts)
- **Fallback**: System default sans-serif

### Text Styles

#### Headings
```
Headline Large       24-28px, Bold, Primary Color
Headline Medium      20-24px, Bold, Primary/Default
Headline Small       18-20px, SemiBold, Default
```

#### Body Text
```
Body Large           16-18px, Regular, Default
Body Medium          14-16px, Regular, Default
Body Small           12-14px, Regular, Gray
```

#### Labels & Captions
```
Title Medium         16px, SemiBold, Default
Title Small          14px, SemiBold, Default
Caption              11-13px, Regular, Gray
```

### Typography Rules
- Use Theme.of(context).textTheme for consistency
- Scale font sizes responsively using `_getResponsiveFontSize()`
- Bold for emphasis, not uppercase
- Maintain 1.5 line height for body text
- Maximum line length: 60-80 characters

---

## Spacing System

### Base Unit: 4px

Use multiples of 4 for all spacing:

```
4px   - Minimal spacing (icon-text gap)
8px   - Tight spacing (between related elements)
12px  - Small spacing (list items)
16px  - Standard spacing (section padding)
24px  - Medium spacing (between sections)
32px  - Large spacing (major sections)
48px  - Extra large spacing (page sections)
```

### Implementation
- Use `_getResponsiveSize(context, size)` for all spacing values
- Maintain consistent padding within component types
- Use EdgeInsets.symmetric for balanced spacing

---

## Border Radius

### Standard Radii
```
Small      4px   - Pills, tags
Medium     8px   - Buttons, input fields
Large      16px  - Cards, containers
XLarge     20px  - Hero cards, modals
Circle     50%   - Avatars, mood icons
```

### Rules
- Larger components = larger radius
- Interactive elements: 8-16px
- Content cards: 16-20px
- Never mix sharp and rounded corners in the same component

---

## Component Patterns

### Buttons

#### Primary Button (FilledButton)
```dart
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    padding: EdgeInsets.symmetric(
      horizontal: _getResponsiveSize(context, 24),
      vertical: _getResponsiveSize(context, 16),
    ),
  ),
  onPressed: () {},
  child: const Text('Action'),
)
```

#### Extended FilledButton (for FAB style)
```dart
FilledButton.extended(
  icon: const FaIcon(FontAwesomeIcons.penToSquare),
  label: const Text('Log Today'),
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  onPressed: () {},
)
```

#### FilterChip (Interactive Tags)
```dart
FilterChip(
  onSelected: (selected) {},
  selected: isSelected,
  label: const Text('Mood'),
  backgroundColor: Colors.grey.shade100,
  selectedColor: AppColors.primary.withValues(alpha: 0.2),
  side: BorderSide(
    color: isSelected ? AppColors.primary : Colors.transparent,
    width: 2,
  ),
)
```

#### Secondary Button (OutlinedButton)
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: AppColors.primary),
  ),
  onPressed: () {},
  child: const Text('Secondary'),
)
```

#### Text Button (TextButton)
- Use for tertiary actions
- Default theme styling
- Accessible tap targets (48x48px minimum)

### Cards & Surfaces

#### Soft Material 3 Card (Standard)
```dart
Container(
  margin: EdgeInsets.all(_getResponsiveSize(context, 16)),
  padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(_getResponsiveSize(context, 24)), // Increased for premium feel
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: // Content
)
```

#### Premium Glassmorphism (Overlays)
For a "premium" feel, use semi-transparent overlays on top of gradients:
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1.5,
    ),
  ),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: // Content
  ),
)
```

**Material 3 Shadow Rules:**
- **Elevated**: `offset(0, 4), blur 10, alpha 0.04` (Subtle, modern depth)
- **Layered**: Use multiple shadows for a "lifted" effect on hero cards.
- **Surface**: Use gradients + glass overlays for dashboard headers.

#### Dark Hero Card (with Gradient)
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(_getResponsiveSize(context, 24)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: // Content
)
```

### Icons

#### Sizing
```
Small      14-16px (inline icons)
Medium     20-24px (list items)
Large      40-56px (feature icons)
XLarge     80px+    (hero icons)
```

#### Usage
- Use FontAwesome Flutter icons for consistency
- Scale with `_getResponsiveFontSize()` or `_getResponsiveSize()`
- Primary color for active states
- Gray for inactive states
- White for dark backgrounds

### Input Fields

```dart
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: _getResponsiveSize(context, 16),
      vertical: _getResponsiveSize(context, 12),
    ),
  ),
)
```

---

## Modern Flutter APIs (No Deprecated Patterns)

### Radio Button Groups (Flutter 3.35+)

**Modern Pattern - RadioGroup Widget:**
```dart
RadioGroup<int>(
  groupValue: selectedTheme,
  onChanged: (value) {
    setState(() => selectedTheme = value);
  },
  child: Column(
    children: [
      Row(
        children: [
          Radio<int>(value: 0),  // No groupValue or onChanged
          const Icon(Icons.light_mode),
          const SizedBox(width: 8),
          const Text('Light'),
        ],
      ),
      Row(
        children: [
          Radio<int>(value: 1),
          const Icon(Icons.dark_mode),
          const SizedBox(width: 8),
          const Text('Dark'),
        ],
      ),
    ],
  ),
)
```

**Benefits:**
- Centralized group value management
- Better accessibility (ARIA compliant)
- Improved keyboard navigation
- Cleaner, more readable code
- No individual `Radio.onChanged` callbacks

**NOT USING (Deprecated):**
```dart
// ❌ DEPRECATED - Do not use
Radio<int>(
  value: 0,
  groupValue: selectedTheme,  // DEPRECATED
  onChanged: (value) { ... }, // DEPRECATED
)
```

---

## Layout Patterns

### App Bar Structure
```dart
AppBar(
  leading: [Avatar/Icon with navigation],
  title: [Greeting or page title],
  actions: [Max 2-3 icon buttons],
)
```

### Screen Layout
```
1. AppBar (56-64px height)
2. Optional Banner (verification, alerts)
3. Scrollable Content
   - Hero Section (if applicable)
   - Content Sections with consistent spacing
4. Bottom Navigation (if applicable)
```

### Content Hierarchy
1. **Hero/Primary Content** - Largest, most prominent
2. **Secondary Sections** - Medium cards with clear headings
3. **Supporting Info** - Smaller cards, lists
4. **Actions** - Buttons, CTAs at logical points

---

## Responsive Design

### Breakpoints
```
Small Phone    < 375px (base size)
Medium Phone   375-414px
Large Phone    414-480px
Tablet         > 480px
```

### Scaling Functions

Always use these helper functions for responsive sizing:

```dart
// For percentages of screen dimensions
_getResponsiveWidth(BuildContext context, double percentage)
_getResponsiveHeight(BuildContext context, double percentage)

// For scaling fixed sizes proportionally (base: 375px width)
_getResponsiveSize(BuildContext context, double size)
_getResponsiveFontSize(BuildContext context, double size)
```

### Responsive Rules
1. **Never use fixed pixel values** - Always use responsive helpers
2. **Test on multiple sizes** - Minimum 320px width, maximum tablet
3. **Scale proportionally** - Maintain aspect ratios
4. **Readable text** - Minimum 12px after scaling
5. **Touch targets** - Minimum 48x48px for interactive elements (Material Design standard)

---

## Animation Guidelines

### Built-in Animations (ImplicitlyAnimatedWidget)

Use Flutter's implicit animation widgets for smooth transitions:

#### AnimatedScale - Button/Element Selection
```dart
AnimatedScale(
  scale: isSelected ? 1.08 : 1.0,
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  child: FilterChip(
    onSelected: (selected) {},
    selected: isSelected,
    label: const Text('Option'),
  ),
)
```
- **Use for**: Mood/symptom selection, chip selection
- **Scale range**: 1.0 (rest) → 1.05-1.08 (selected)
- **Duration**: 200ms for snappy feedback

#### AnimatedOpacity - Appearance/Fade
```dart
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: Container(
    // Widget that fades in/out
  ),
)
```
- **Use for**: Sections appearing on load, tips, alerts
- **Duration**: 300-600ms for gentle fade

#### AnimatedPadding - Spacing Changes
```dart
AnimatedPadding(
  padding: isExpanded 
    ? EdgeInsets.all(20) 
    : EdgeInsets.all(10),
  duration: const Duration(milliseconds: 250),
  child: // Content
)
```
- **Use for**: Expanding/collapsing sections
- **Duration**: 200-250ms

### Page Transitions & Dialogs

#### Standard Page Transition
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const NextScreen()),
);
```
- Material 3 provides default slide animation
- No additional configuration needed

#### Dialog Animation
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    // Dialog content
  ),
);
```
- Material 3 default: Scale in + fade
- Built-in Material animation

### Progress Indicators

#### LinearProgressIndicator (Cycle Timeline)
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: LinearProgressIndicator(
    value: progressValue,  // 0.0 to 1.0
    minHeight: 6,
    backgroundColor: Colors.grey.shade200,
    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
  ),
)
```
- Shows cycle progress visually
- Color-coded: Red (period), Primary (rest)
- Minimal, clean look

### General Animation Patterns

**DO** animate:
- Element selection/focus
- Page/modal transitions
- Loading states
- Visibility changes

**DON'T** animate:
- Text content updates
- Data list refreshes
- Status badges
- Error messages (but use opacity for appearance)

### Durations
```
Quick      100-200ms  (hover, ripple, selection feedback)
Standard   200-300ms  (scale transitions, chips)
Smooth     300-600ms  (opacity fades, page transitions)
```

### Curves
- **easeInOut** - Default for most animations (smooth both directions)
- **easeOut** - Elements entering from animation (fast initial)
- **easeIn** - Elements exiting from animation (gradual acceleration)
- **linear** - Only for continuous progress indicators

---

## Accessibility

### Contrast Ratios
- **Normal text**: Minimum 4.5:1
- **Large text (18px+)**: Minimum 3:1
- **Interactive elements**: Minimum 3:1

### Touch Targets
- **Minimum size: 48x48px** (Material Design standard)
- Spacing between: 8px minimum
- Can use visual padding to make smaller-looking buttons while maintaining tap area

### Semantic Labels
- All icons must have tooltips or labels
- Form fields must have proper labels
- Use Semantics widget where appropriate

---

## Material Design Compliance

### What We Follow Strictly ✅

1. **Spacing System** - 4dp grid (4px base unit)
2. **Typography Scale** - Using Material's type system via ThemeData
3. **Component APIs** - FilledButton, OutlinedButton, TextField, AppBar, etc.
4. **Touch Targets** - 48x48px minimum
5. **Contrast Ratios** - WCAG AA compliance (4.5:1 for text)
6. **Animation Timing** - Standard durations (200-300ms)
7. **Accessibility** - Semantic labels, screen reader support

### Intentional Deviations 🎨

1. **Custom Color Palette** - Coral sunset theme instead of default Material colors
   - *Why*: Creates warm, supportive emotional response
   
2. **Gradients** - Used for hero cards and backgrounds
   - *Why*: Adds depth and visual interest while maintaining clarity
   - *Material 3 prefers*: Flat tonal surfaces
   
3. **Custom Shadows** - BoxShadow instead of Material elevation tokens
   - *Why*: More control over card depth and hierarchy
   - *Material 3 prefers*: Surface tint colors for elevation

4. **Feminine Aesthetic** - Softer colors, rounded corners, gentle curves
   - *Why*: Target audience preference, reduces clinical feel

### When in Doubt

- **Usability & Accessibility** - Always follow Material standards
- **Visual Style** - Adapt to Lovely's warm aesthetic
- **New Components** - Start with Material 3, customize if needed

---

## Best Practices

### DO ✅
- Use ThemeData for colors and text styles when possible
- Maintain consistent spacing using the 4px system
- Test on different screen sizes
- Use semantic color names (primary, error, success)
- Group related content in cards
- Provide loading states for async operations
- Show clear error messages with recovery actions

### DON'T ❌
- Use arbitrary spacing values
- Mix different design patterns in the same context
- Use fixed pixel sizes without responsive helpers
- Overwhelm users with too many colors
- Hide critical actions or information
- Use low-contrast color combinations
- Create deeply nested layouts

---

## Responsive Design System

### Screen Size Breakpoints

```
Small      < 360px    Compact phones (iPhone SE, etc)
Medium     360-400px  Standard phones (iPhone 12, etc)
Large      400-600px  Large phones (iPhone 14 Pro Max, etc)
Tablet     > 600px    Tablets and desktop
```

### Using ResponsiveSizing

All screen elements should use the centralized `ResponsiveSizing` utility:

```dart
// Access via context extension
context.responsive.weekStripCircleSize        // 36-40px
context.responsive.calendarDateFontSize       // 11-13px
context.responsive.calendarIconSize           // 9-10px
context.responsive.weekStripMoodIconSize      // 14-16px
context.responsive.spacingMd                  // 8-16px
context.responsive.borderRadius               // 12-16px

// Or via direct instantiation
final sizing = ResponsiveSizing.of(context);
Icon(Icons.star, size: sizing.iconSize);
```

### Properties Available

**Calendar Indicators:**
- `calendarCellAspectRatio` - Cell proportion adjustment
- `calendarDateFontSize` - Date number size
- `calendarIconSize` - Mood/activity icons in calendar
- `calendarActivityIconSize` - Heart icon size

**Week Strip:**
- `weekStripCircleSize` - Date circle diameter (36-40px)
- `weekStripDateFontSize` - Date font in circle
- `weekStripMoodIconSize` - Mood emoji/icon size
- `weekStripActivityIconSize` - Activity heart icon
- `weekStripDotSize` - Symptom dot size

**General:**
- `smallFontSize`, `bodyFontSize`, `titleFontSize`
- `smallIconSize`, `iconSize`, `largeIconSize`
- `spacingXs`, `spacingSm`, `spacingMd`, `spacingLg`
- `minTouchTarget` - 44-48px
- `borderRadius`, `borderRadiusSm`

---

## Indicator Patterns (Calendar & Week Strip)

### Mood Icons
- Material Design sentiment icons (not emojis)
- Color-coded by emotion:
  - Green: Happy
  - Blue: Calm
  - Grey: Tired
  - Indigo: Sad
  - Orange: Irritable
  - Purple: Anxious
  - Amber: Energetic

### Sexual Activity Indicator
- Heart icon (Icons.favorite)
- **Unprotected**: Heart only (red/error color at 80% opacity)
- **Protected**: Heart + Shield badge overlay
  - Shield icon in small circle
  - Primary color (#FF6F61)
  - 40% of heart size
  - Positioned bottom-right

### Symptom Dots
- 3x3px circles per small devices
- Up to 5px on large devices
- Secondary color (coral)
- Shows 1-3 dots max (if 5+ symptoms, still 3 dots)
- Responsive spacing via `context.responsive.weekStripDotSize`

### Information Hierarchy
1. **Most Important** (background): Phase color
2. **Very Important** (center): Mood icon
3. **Important** (corners): Symptom dots
4. **Discrete** (top): Activity indicator

---

## Component Checklist

Before creating a new component, ensure:

- [ ] Uses responsive sizing helpers
- [ ] Follows color palette
- [ ] Matches spacing system (multiples of 4)
- [ ] Consistent border radius
- [ ] Proper touch target size (48x48px min)
- [ ] Accessible contrast ratios (WCAG AA)
- [ ] Clear visual hierarchy
- [ ] Matches existing patterns
- [ ] Handles loading/error states
- [ ] Works on small and large screens
- [ ] Mounted checks before navigation
- [ ] No setState after dispose

---

## File Organization

### Widget Files
```
lib/
  widgets/           # Reusable components
  screens/           # Full screens
    auth/            # Authentication screens
    main/            # Main app screens
    onboarding/      # Onboarding flow
  services/          # Business logic
  utils/             # Utilities (responsive_utils.dart)
```

### Naming Conventions
- **Files**: snake_case.dart
- **Classes**: PascalCase
- **Variables**: camelCase
- **Constants**: SCREAMING_SNAKE_CASE
- **Private members**: _leadingUnderscore

---

## Code Style

### Widget Structure
```dart
class MyWidget extends StatelessWidget {
  // 1. Constructor
  const MyWidget({super.key});
  
  // 2. Helper methods (private)
  double _getResponsiveSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / 375);
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    // Build UI
  }
  
  // 4. Sub-widget builders (if needed)
  Widget _buildSection() {
    // Build section
  }
}
```

### Constants
Define color constants at the top:
```dart
static const Color _primaryColor = Color(0xFFFF6F61);
static const Color _darkBackground = Color(0xFF2D1B3D);
```

---

## Version History

**Version 1.0** - December 30, 2025
- Initial design guidelines
- Established color palette and typography
- Defined spacing and component patterns
- Responsive design system

---

## Questions or Updates?

These guidelines are living documents. As the app evolves, update this file to reflect new patterns, components, and decisions. Always prioritize consistency and user experience.
