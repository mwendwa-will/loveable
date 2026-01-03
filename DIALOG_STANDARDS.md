# Dialog & Bottom Sheet Standards

This document defines the standard patterns for dialogs and bottom sheets across the Lovely app.

## Overview

The app uses two main modal patterns:
- **Dialogs** (`AppDialog`) - For critical confirmations, alerts, and simple choices
- **Bottom Sheets** (`AppBottomSheet`) - For forms, lists, pickers, and multi-step flows

Both follow Material Design 3 principles with responsive sizing and consistent styling.

---

## AppDialog Usage

### Import
```dart
import 'package:lovely/widgets/app_dialog.dart';
```

### Confirmation Dialog
Use for destructive actions or important decisions requiring explicit confirmation.

```dart
final confirmed = await AppDialog.showConfirmation(
  context,
  title: 'Delete Period Entry?',
  message: 'This will permanently remove this entry from your history.',
  confirmText: 'Delete',
  cancelText: 'Cancel',
  isDangerous: true, // Red confirm button
);

if (confirmed == true) {
  // User confirmed
}
```

### Info Dialog
Use for non-critical information that doesn't require a decision.

```dart
await AppDialog.showInfo(
  context,
  title: 'Feature Coming Soon',
  message: 'Social login will be available in the next update.',
  buttonText: 'Got it',
);
```

### Error Dialog
Use for errors that need user acknowledgment with optional technical details.

```dart
await AppDialog.showError(
  context,
  title: 'Sync Failed',
  message: 'Unable to sync your data. Please check your connection.',
  details: error.toString(), // Optional technical details
  buttonText: 'OK',
);
```

### Success Dialog
Use sparingly for significant achievements or completed multi-step processes.

```dart
await AppDialog.showSuccess(
  context,
  title: 'Profile Updated',
  message: 'Your changes have been saved successfully.',
  buttonText: 'Great!',
);
```

### Warning Dialog
Use for potentially risky actions that aren't destructive.

```dart
final proceed = await AppDialog.showWarning(
  context,
  title: 'Unsaved Changes',
  message: 'You have unsaved changes. Are you sure you want to leave?',
  confirmText: 'Leave',
  cancelText: 'Stay',
);

if (proceed == true) {
  Navigator.pop(context);
}
```

### Loading Dialog
Use for operations that require blocking the UI. Remember to dismiss it.

```dart
AppDialog.showLoading(context, message: 'Saving...');

try {
  await performOperation();
  AppDialog.dismiss(context);
  FeedbackService.showSuccess(context, 'Saved!');
} catch (e) {
  AppDialog.dismiss(context);
  FeedbackService.showError(context, e);
}
```

### Custom Dialog
For complex content that doesn't fit standard patterns.

```dart
await AppDialog.showCustom(
  context,
  title: 'Select Date Range',
  content: DateRangePickerWidget(),
  type: DialogType.info,
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    ),
    FilledButton(
      onPressed: () => Navigator.pop(context, selectedRange),
      child: const Text('Apply'),
    ),
  ],
);
```

---

## AppBottomSheet Usage

### Import
```dart
import 'package:lovely/widgets/app_bottom_sheet.dart';
```

### Standard Bottom Sheet
For custom content with actions.

```dart
final result = await AppBottomSheet.show<DateTime>(
  context,
  title: 'Select Date',
  content: CalendarWidget(),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    ),
    FilledButton(
      onPressed: () => Navigator.pop(context, selectedDate),
      child: const Text('Select'),
    ),
  ],
);
```

### List Selection Bottom Sheet
For choosing from a list of options (better UX than dropdown on mobile).

```dart
final mood = await AppBottomSheet.showList<MoodType>(
  context,
  title: 'How are you feeling?',
  items: [
    BottomSheetItem(
      value: MoodType.happy,
      label: 'Happy',
      icon: Icons.sentiment_very_satisfied,
      color: Colors.green,
    ),
    BottomSheetItem(
      value: MoodType.calm,
      label: 'Calm',
      subtitle: 'Feeling peaceful',
      icon: Icons.spa,
      color: Colors.blue,
    ),
    // ... more items
  ],
  selectedValue: currentMood,
  showSearch: true, // For long lists
);

if (mood != null) {
  // User selected a mood
}
```

### Confirmation Bottom Sheet
Alternative to dialog for mobile-first design.

```dart
final confirmed = await AppBottomSheet.showConfirmation(
  context,
  title: 'Log Sexual Activity?',
  message: 'You have a period logged for this date. Continue?',
  confirmText: 'Yes, Log It',
  cancelText: 'Cancel',
  icon: Icons.info_outline,
);
```

### Form Bottom Sheet
For data entry with keyboard support and loading states.

```dart
await AppBottomSheet.showForm(
  context,
  title: 'Add Note',
  form: TextField(
    controller: noteController,
    decoration: const InputDecoration(labelText: 'Your note'),
    maxLines: 5,
  ),
  onSubmit: () async {
    await saveNote();
    Navigator.pop(context);
  },
  submitText: 'Save',
  isLoading: isSaving,
);
```

---

## Decision Guide: Dialog vs Bottom Sheet

### Use Dialog When:
- ✅ Critical confirmation needed (delete, logout)
- ✅ Simple yes/no decision
- ✅ Error that blocks progress
- ✅ Brief informational message
- ✅ Desktop/tablet experience preferred

### Use Bottom Sheet When:
- ✅ Selecting from a list
- ✅ Form input needed
- ✅ Multi-step process
- ✅ Mobile-first interaction
- ✅ Content needs more space
- ✅ Picker/selector UI

---

## Styling & Theming

### Automatic Theme Integration
Both components automatically adapt to:
- Light/dark mode
- App color scheme
- Material 3 typography
- Dynamic color (Android 12+)

### Responsive Design
- Dialogs: Max width 400px, scales on small screens
- Bottom sheets: Max height 80-90% of screen
- Text scales with accessibility settings
- Touch targets meet minimum 48dp

### Accessibility
- Screen reader support via semantic labels
- Keyboard navigation
- Focus management
- High contrast mode compatible

---

## Best Practices

### DO ✅
- Use `isDangerous: true` for destructive actions
- Provide clear, action-oriented button text
- Keep titles concise (< 60 characters)
- Use bottom sheets for mobile, dialogs for desktop
- Always handle null returns (user dismissed)

### DON'T ❌
- Don't nest modals (dialog over bottom sheet)
- Don't use dialogs for long content
- Don't make dialogs non-dismissible without loading indicator
- Don't use generic "OK/Cancel" when specific actions are clearer
- Don't forget to dismiss loading dialogs

### Error Handling Pattern
```dart
try {
  await performAction();
  FeedbackService.showSuccess(context, 'Done!');
} catch (e) {
  // For critical errors requiring acknowledgment
  await AppDialog.showError(
    context,
    title: 'Operation Failed',
    message: FeedbackService.getErrorMessage(e),
  );
  
  // For non-critical errors, use overlay notification
  FeedbackService.showError(context, e);
}
```

---

## Migration from Old Patterns

### Replace AlertDialog
```dart
// OLD ❌
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Delete?'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
    ],
  ),
);

// NEW ✅
AppDialog.showConfirmation(
  context,
  title: 'Delete Entry?',
  message: 'This action cannot be undone.',
  confirmText: 'Delete',
  isDangerous: true,
);
```

### Replace SnackBar for Confirmations
```dart
// OLD ❌
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Delete this?'),
    action: SnackBarAction(label: 'Delete', onPressed: () {}),
  ),
);

// NEW ✅
final confirmed = await AppDialog.showConfirmation(
  context,
  title: 'Confirm Delete',
  message: 'Permanently remove this entry?',
  confirmText: 'Delete',
  isDangerous: true,
);

if (confirmed == true) {
  await deleteItem();
}
```

---

## Examples in Context

See implementation examples in:
- [Login Screen](../lib/screens/auth/login.dart) - Error dialogs
- [Daily Log Screen](../lib/screens/daily_log_screen.dart) - Confirmation dialogs
- [Profile Screen](../lib/screens/main/profile_screen.dart) - Settings bottom sheets
