# PIN Login Black Screen - Fix Summary

**Date**: January 6, 2026
**Issue**: Black screen when logging in with app PIN
**Root Cause**: Race condition in PIN unlock flow causing improper state management

---

## Problems Identified

### 1. **Race Condition in Callback Handling**
- When `PinUnlockScreen` was displayed as the initial home widget, the `onUnlocked` callback wasn't properly updating the parent state
- The state update to `_pinUnlocked = true` wasn't triggering a rebuild of the `FutureBuilder`

### 2. **Improper Navigation Flow for Routed PIN Screen**
- When PIN screen was pushed as a route (via `_showPinUnlock()`), it called `Navigator.pop(context, true)` before the provider was updated
- The `.then()` callback tried to update Riverpod after navigation, causing timing issues

### 3. **Timing Issues with Frame Synchronization**
- Used `WidgetsBinding.instance.endOfFrame` which could cause race conditions
- Needed explicit delay and better error handling

---

## Changes Made

### 1. **lib/main.dart - initState() method**
```dart
// BEFORE: Used endOfFrame
_pinCheckFuture = WidgetsBinding.instance.endOfFrame.then((_) async {

// AFTER: Use explicit 100ms delay for reliability
_pinCheckFuture = Future.delayed(const Duration(milliseconds: 100)).then((_) async {
```

**Benefits:**
- More predictable timing across different devices
- Better Android initialization handling
- Added detailed debug logging

### 2. **lib/main.dart - home widget builder**
```dart
// BEFORE: Called ref.read() in callback (potential timing issue)
onUnlocked: () {
  if (mounted) {
    setState(() => _pinUnlocked = true);
    ref.read(pinLockProvider.notifier).unlock();  // ← May execute after pop
  }
},

// AFTER: Simplified to just update local state
onUnlocked: () {
  debugPrint('🔓 PIN unlocked via callback');
  if (mounted) {
    setState(() {
      _pinUnlocked = true;
      debugPrint('✅ PIN state updated: _pinUnlocked = true');
    });
  }
},
```

**Benefits:**
- Callback is now a simple state setter
- No async operations in callback that could cause timing issues
- State update triggers FutureBuilder rebuild immediately

### 3. **lib/main.dart - _showPinUnlock() method**
```dart
// BEFORE: Used .then() after Navigator.push to update state
Navigator.of(navigatorKey.currentContext!).push(...)
  .then((unlocked) {
    if (unlocked == true) {
      ref.read(pinLockProvider.notifier).unlock();
    }
  });

// AFTER: Handle everything in the onUnlocked callback
Navigator.of(navigatorKey.currentContext!).push(
  MaterialPageRoute(
    builder: (context) => PinUnlockScreen(
      onUnlocked: () async {
        await ref.read(pinLockProvider.notifier).unlock();
        if (mounted && navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pop(true);
        }
      },
    ),
    fullscreenDialog: true,
  ),
);
```

**Benefits:**
- Single source of truth for unlock logic
- Riverpod state updated before navigation
- Clear separation of concerns

### 4. **lib/screens/security/pin_unlock_screen.dart - _verifyPin() method**
```dart
// BEFORE: Called Navigator.pop immediately after callback
widget.onUnlocked?.call();
Navigator.pop(context, true);

// AFTER: Only call callback, let it handle navigation
widget.onUnlocked?.call();
```

**Benefits:**
- Callback is responsible for its own navigation
- Works for both initial widget and routed navigation
- Prevents duplicate navigation attempts

---

## Debug Flow

When PIN is enabled on startup, you'll now see:

```
✅ PIN check complete - PIN enabled
🔒 Showing PIN unlock screen (initial)
[User enters PIN]
✅ PIN verified successfully
🔓 PIN unlocked via callback
✅ PIN state updated: _pinUnlocked = true
🚀 Showing AuthGate
```

---

## How It Works Now

### Initial App Launch (PIN Enabled)
1. App initializes and checks if PIN is enabled
2. `_pinCheckFuture` completes after 100ms
3. FutureBuilder shows `PinUnlockScreen` if `_pinEnabled && !_pinUnlocked`
4. User enters PIN
5. `onUnlocked` callback sets `_pinUnlocked = true` via `setState()`
6. FutureBuilder rebuilds and now shows `AuthGate` instead
7. User proceeds to login/app flow

### PIN Lock During App Use (Lifecycle Event)
1. App goes to background → `didChangeAppLifecycleState` locks app
2. App returns to foreground → Checks timeout
3. If not timed out, shows PIN screen via `Navigator.push()`
4. User enters PIN
5. `onUnlocked` callback updates Riverpod state and pops the screen
6. App continues with `AuthGate` visible

---

## Testing

To verify the fix:

1. **Test Initial PIN Screen:**
   - Enable PIN in app settings
   - Close and reopen app
   - Verify loading spinner appears briefly
   - Verify PIN screen appears
   - Enter correct PIN
   - Verify AuthGate appears and app proceeds normally

2. **Test PIN Lock on Resume:**
   - Open app and unlock with PIN
   - Press home button (app goes to background)
   - Wait < 30 minutes
   - Return to app
   - Verify PIN screen appears
   - Verify app unlocks and continues

3. **Test Incorrect PIN:**
   - Enter wrong PIN multiple times
   - Verify error message appears
   - Verify PIN clears after 500ms
   - Try again with correct PIN

4. **Test No PIN Scenario:**
   - Disable PIN in settings
   - Restart app
   - Verify no PIN screen shown
   - Verify AuthGate appears immediately

