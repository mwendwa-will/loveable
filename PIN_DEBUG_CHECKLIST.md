# PIN Login Black Screen - Quick Debug Checklist

## If You Still See a Black Screen When Logging In With PIN

### Check 1: Verify PIN Initialization
Look for these debug prints in the console:
```
✅ PIN check complete - PIN enabled
🔒 Showing PIN unlock screen (initial)
```

**If NOT visible:**
- Clear app data/cache and reinstall
- Check if `isPinEnabled()` is hanging
- Add breakpoint in `PinService.isPinEnabled()`

### Check 2: Verify PIN Input
Look for:
```
✅ PIN verified successfully
```

**If NOT visible after entering PIN:**
- PIN verification failed (wrong PIN entered)
- Check if `PinService.verifyPin()` is hanging
- Verify PIN hash in secure storage

### Check 3: Verify State Update
Look for:
```
🔓 PIN unlocked via callback
✅ PIN state updated: _pinUnlocked = true
```

**If NOT visible after correct PIN:**
- `onUnlocked` callback not being called
- Check if widget is mounted
- Verify callback is passed correctly

### Check 4: Verify Navigation
Look for:
```
🚀 Showing AuthGate
```

**If NOT visible after PIN unlocked:**
- FutureBuilder not rebuilding after state change
- Verify `_pinUnlocked` state is actually `true`
- Check for exceptions in AuthGate

---

## Common Issues & Solutions

| Symptom | Cause | Solution |
|---------|-------|----------|
| Black screen for 5+ seconds | PIN check taking too long | Check Secure Storage permissions |
| PIN screen appears then closes | Callback called but state not updated | Verify `setState()` is called |
| PIN unlocks but black screen | FutureBuilder not rebuilding | Check `_pinUnlocked` variable |
| Can't enter PIN | `_onNumberPressed` not working | Check haptic feedback permissions |
| Same PIN entered 3 times fails | PIN hash mismatch | Clear app data and reset PIN |

---

## Force Light Mode for Debugging

If you suspect a dark mode issue, temporarily force light mode:

```dart
// In lib/main.dart, line ~260
themeMode: ThemeMode.light,  // Change from ThemeMode.system
```

This will help identify if the black screen is actually a color issue.

---

## Critical Log Points

Add these breakpoints to trace the full flow:

1. **lib/main.dart (initState)** - Line 90: PIN check begins
2. **lib/main.dart (FutureBuilder)** - Line 285: PIN screen decision
3. **lib/screens/security/pin_unlock_screen.dart (onNumberPressed)** - Line 50: PIN input
4. **lib/screens/security/pin_unlock_screen.dart (_verifyPin)** - Line 75: PIN verification
5. **lib/main.dart (onUnlocked callback)** - Line 290: State update

If you hit all 5 breakpoints but still see black screen, the issue is in AuthGate.

