# Black Screen Issue - Debugging Guide

**Date**: December 31, 2025  
**Issue**: App shows completely black screen on startup

---

## Root Causes & Solutions

### 1. **Dark Mode Colors Too Dark** ⚫

**Diagnosis:**
- System is in dark mode
- Dark scaffold color: `#121212`
- Dark card color: `#1E1E1E`
- May appear completely black on some screens

**Solution - Temporary (Currently Applied):**
```dart
// In lib/main.dart line 81
themeMode: ThemeMode.light,  // Force light mode to debug
```

**Solution - Permanent:**
Increase dark mode brightness:
```dart
// In lib/constants/app_colors.dart
static const Color darkScaffold = Color(0xFF1A1A1A);  // Changed from #121212
static const Color darkCard = Color(0xFF242424);      // Changed from #1E1E1E
```

### 2. **Supabase Initialization Hanging** 🔄

**Symptoms:**
- App stays black, no loading indicator visible
- Debug console shows no initialization messages
- App doesn't respond to touches

**Solution Applied:**
Added debug logging to track initialization:
```dart
// In lib/main.dart
debugPrint('🚀 Initializing Supabase...');
await SupabaseService.initialize();
debugPrint('✅ Supabase initialized successfully');
```

**Check Debug Console:**
- Look for `🚀 Initializing Supabase...` message
- If missing → Supabase init is hanging
- If present but no ✅ → Supabase init failed

**Fix:** Check `lib/config/supabase_config.dart` for:
- Valid `SUPABASE_URL`
- Valid `SUPABASE_ANON_KEY`
- Internet connectivity

### 3. **AuthGate Not Rendering** 👻

**Symptoms:**
- Black screen even during initial load
- No "Loading Lovely..." text visible
- No loading spinner visible

**Solution Applied:**
Enhanced loading state with visible feedback:
```dart
// In lib/screens/auth/auth_gate.dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading Lovely...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
```

---

## Testing Steps

### Step 1: Verify Light Mode
1. Run app with `themeMode: ThemeMode.light`
2. Check if UI is visible
3. If visible → Dark mode colors issue
4. If still black → Different issue

### Step 2: Check Debug Console
```bash
flutter run -v  # Verbose output
```

Look for these messages:
- ✅ `🚀 Initializing Supabase...`
- ✅ `✅ Supabase initialized successfully`
- ✅ `🎨 Launching app...`
- ⚠️ Any error messages

### Step 3: Test Different Themes
Change `themeMode` to test:
```dart
themeMode: ThemeMode.light,   // Light mode
themeMode: ThemeMode.dark,    // Dark mode
themeMode: ThemeMode.system,  // System setting
```

### Step 4: Check Device Settings
**Android:**
- Settings → Display → Dark theme (toggle off/on)

**iOS:**
- Settings → Display & Brightness → Light/Dark

---

## Quick Fixes

### Option A: Force Light Mode (Temporary)
```dart
// lib/main.dart, line 81
themeMode: ThemeMode.light,  // Debugging
```

### Option B: Increase Dark Mode Brightness
```dart
// lib/constants/app_colors.dart
static const Color darkScaffold = Color(0xFF1A1A1A);  // Brighter
static const Color darkCard = Color(0xFF242424);      // Brighter
```

### Option C: Check Supabase Config
```dart
// lib/config/supabase_config.dart
// Verify URL and API key are correct
final String supabaseUrl = 'YOUR_SUPABASE_URL';
final String supabaseAnonKey = 'YOUR_SUPABASE_KEY';
```

---

## Expected Behavior

### Correct Startup Sequence:
1. ✅ App launches
2. ✅ Console: `🚀 Initializing Supabase...`
3. ✅ Black/loading screen briefly
4. ✅ Console: `✅ Supabase initialized successfully`
5. ✅ Console: `🎨 Launching app...`
6. ✅ "Loading Lovely..." text appears
7. ✅ Loading spinner visible
8. ✅ AuthGate routes to WelcomeScreen or HomeScreen

### If You See:
- **"Loading Lovely..." text** → Good! Supabase initialized
- **No text, black screen** → Supabase still initializing or failed
- **Flutter spinner only** → Using Scaffold but no custom text

---

## Current Status

**Applied Fixes:**
- ✅ Added debug logging to main.dart
- ✅ Enhanced AuthGate loading UI
- ✅ Force light mode (temporary for debugging)
- ✅ Improved error messages

**To Restore System Theme:**
Change line 81 in `lib/main.dart` from:
```dart
themeMode: ThemeMode.light,  // Debugging
```

To:
```dart
themeMode: ThemeMode.system,  // Normal operation
```

---

## Next Steps

1. **Run with verbose logging:**
   ```bash
   flutter run -v
   ```

2. **Check debug console for messages starting with 🚀, ✅, ⚠️**

3. **If Supabase message doesn't appear:**
   - Check internet connection
   - Verify Supabase config in `lib/config/supabase_config.dart`
   - Check Supabase project is active

4. **If light mode works but dark mode is black:**
   - Increase dark theme colors as shown in "Option B" above
   - Test with updated colors

5. **Once fixed, revert to `ThemeMode.system`**

---

## Files Modified

- ✅ `lib/main.dart` - Added debug logging, set light theme
- ✅ `lib/screens/auth/auth_gate.dart` - Enhanced loading UI with text
- No changes needed to `app_colors.dart` unless colors are truly wrong
