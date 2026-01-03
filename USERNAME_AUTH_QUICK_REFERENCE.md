# Username Authentication - Quick Reference

## User Signup Example

```dart
// lib/screens/auth/signup.dart

await supabase.signUp(
  email: 'john@example.com',
  password: 'SecurePass123',
  username: 'johndoe',
  firstName: 'John',
  lastName: 'Doe',  // optional
);

// Stored in auth.users.raw_user_meta_data:
// {
//   "username": "johndoe",
//   "first_name": "John",
//   "last_name": "Doe"
// }
```

## User Login Examples

### Login with Email:
```dart
await supabase.signIn(
  emailOrUsername: 'john@example.com',
  password: 'SecurePass123',
);
// Backend: Detects @ → uses email directly
```

### Login with Username:
```dart
await supabase.signIn(
  emailOrUsername: 'johndoe',
  password: 'SecurePass123',
);
// Backend: No @ → looks up email by username → signs in
```

## Check Username Availability

```dart
final available = await supabase.isUsernameAvailable('johndoe');

if (available) {
  // ✅ Username is available
} else {
  // ❌ Username already taken
}
```

## Profile Provider Usage

```dart
// Get profile
final profile = ref.watch(profileProvider);

// Display name
Text(profile.fullName);  // "John Doe"

// Display initials in avatar
UserAvatar(
  initials: profile.initials,  // "JD"
  size: 50,
);

// Update profile
await ref.read(profileProvider.notifier).updateProfile(
  firstName: 'Jane',
  lastName: 'Smith',
  username: 'janesmith',
  bio: 'Hello world!',
  dateOfBirth: DateTime(1990, 1, 1),
);
```

## UserProfile Model

```dart
class UserProfile {
  final String firstName;       // Required
  final String? lastName;        // Optional
  final String? username;        // Optional
  final String? bio;             // Optional
  final DateTime? dateOfBirth;   // Optional
  
  String get fullName;   // "John Doe" or "John"
  String get initials;   // "JD" or "JO"
}
```

## Avatar Widget

```dart
import 'package:lovely/widgets/user_avatar.dart';

// Default gradient avatar
UserAvatar(
  initials: 'JD',
  size: 50,
);

// Custom colors
UserAvatar(
  initials: 'JD',
  size: 80,
  backgroundColor: Colors.purple,
  textColor: Colors.white,
);
```

## Database Queries

### Check username availability (SQL):
```sql
SELECT is_username_available('johndoe');
-- Returns: true/false
```

### Find user by username or email:
```sql
SELECT * FROM get_user_by_username_or_email('johndoe');
-- Returns: user row with id, email, username, first_name, last_name
```

### Get user profile:
```sql
SELECT first_name, last_name, username, bio, date_of_birth
FROM users
WHERE id = auth.uid();
```

## Validation Rules

### Username:
- Min length: 3 characters
- Max length: 30 characters
- Allowed: `a-z`, `A-Z`, `0-9`, `_`, `-`, `.`
- Case-insensitive uniqueness
- Pattern: `^[a-zA-Z0-9._-]{3,30}$`

### First Name:
- Required
- Any valid text

### Last Name:
- Optional
- Any valid text

## Common Patterns

### Signup Form:
```dart
TextFormField(
  controller: _usernameController,
  decoration: InputDecoration(
    labelText: 'Username *',
    suffixIcon: _isCheckingUsername
        ? CircularProgressIndicator()
        : _usernameAvailable
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.error, color: Colors.red),
  ),
  onChanged: (value) {
    if (value.length >= 3) {
      _checkUsernameAvailability(value);
    }
  },
  validator: (value) {
    if (!_usernameAvailable) {
      return 'Username already taken';
    }
    return null;
  },
);
```

### Login Form:
```dart
TextFormField(
  controller: _emailOrUsernameController,
  keyboardType: TextInputType.text,  // Not email!
  decoration: InputDecoration(
    labelText: 'Email or Username',
    hintText: 'Enter your email or username',
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or username';
    }
    return null;  // No @ validation
  },
);
```

## Error Handling

### Username already taken:
```dart
try {
  await supabase.signUp(...);
} catch (e) {
  if (e.toString().contains('duplicate key value')) {
    // Username already exists
    setState(() {
      _usernameError = 'Username already taken';
    });
  }
}
```

### Invalid credentials:
```dart
try {
  await supabase.signIn(...);
} catch (e) {
  if (e is AuthException && e.code == 'invalid_credentials') {
    // Wrong username/email or password
  }
}
```

## Migration Rollback

If you need to rollback the migration:

```sql
-- Remove new columns
ALTER TABLE users DROP COLUMN IF EXISTS first_name;
ALTER TABLE users DROP COLUMN IF EXISTS last_name;
ALTER TABLE users DROP COLUMN IF EXISTS username;

-- Drop functions
DROP FUNCTION IF EXISTS is_username_available;
DROP FUNCTION IF EXISTS get_user_by_username_or_email;

-- Drop indexes
DROP INDEX IF EXISTS users_username_unique_idx;
DROP INDEX IF EXISTS users_username_idx;

-- Drop constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS username_format_check;
```

## Tips & Best Practices

✅ **Do:**
- Always trim whitespace from username input
- Use debouncing (500ms) for availability checks
- Show real-time feedback (check/error icons)
- Support both email and username in login
- Make last name optional for better UX
- Use optimistic updates in profile provider

❌ **Don't:**
- Force users to have a username (make it optional)
- Allow usernames with spaces or special chars
- Validate for @ in login field (accept both)
- Forget to handle fallback queries if RPC fails
- Skip username format validation on frontend

## Testing Commands

```bash
# Analyze code
dart analyze

# Run with username support
flutter run

# Test signup with username
# Test login with email
# Test login with username
```

---

**Happy Coding! 🚀**
