# Email Verification Setup Guide

## ✅ Code Implementation Complete

The following has been implemented in your app:

### 1. Email Verification Screen
- **File**: `lib/screens/auth/email_verification_pending_screen.dart`
- Shows when email verification is required
- Allows users to resend verification email
- Provides sign-out option

### 2. Auth Gate Integration
- **File**: `lib/screens/auth/auth_gate.dart`
- Checks if email verification is required using `requiresVerification`
- 7-day grace period before enforcing verification
- Routes to verification screen when needed

### 3. Deep Linking Configuration
- **Android**: `android/app/src/main/AndroidManifest.xml`
  - Added intent filter for `lovely://auth` scheme
- **iOS**: `ios/Runner/Info.plist`
  - Added CFBundleURLTypes for `lovely://` scheme

### 4. Auth State Listener
- **File**: `lib/main.dart`
- Listens for auth state changes
- Automatically handles email verification events
- Logs auth events for debugging

### 5. Service Layer
- **File**: `lib/services/supabase_service.dart` (already has):
  - `isEmailVerified` - Checks if email is confirmed
  - `daysSinceSignup` - Calculates account age
  - `requiresVerification` - Returns true after 24 hour grace period

---

## 🔧 Supabase Dashboard Setup (Required)

### Step 1: Enable Email Confirmation

1. Go to your Supabase project: https://supabase.com/dashboard/project/YOUR_PROJECT_ID
2. Navigate to **Authentication** → **Providers** → **Email**
3. Under **Email Confirmation**:
   - ✅ Enable **Confirm email**
   - Set **Confirmation URL** to: `lovely://auth/verify`
4. Click **Save**

### Step 2: Configure Email Templates (Optional)

1. Go to **Authentication** → **Email Templates**
2. Select **Confirm signup** template
3. Customize the message:
```html
<h2>Welcome to Lovely! 🌸</h2>
<p>Hi {{ .Email }},</p>
<p>Thanks for signing up! Please confirm your email address by clicking the link below:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your email</a></p>
<p>This link will expire in 24 hours.</p>
<p>If you didn't create an account, you can safely ignore this email.</p>
```

### Step 3: Test Email Delivery

**Development Testing:**
1. Sign up with a real email address
2. Check your inbox (and spam folder)
3. Click the verification link
4. App should automatically handle the redirect

**Disable for Testing** (optional):
- Go to **Authentication** → **Settings**
- Temporarily disable **Confirm email** for development
- Re-enable before production

---

## 🚀 How It Works

### User Flow

1. **User signs up** → Supabase creates unverified account
2. **Email sent** → Verification link: `lovely://auth/verify?token=...`
3. **User clicks link** → Deep link opens your app
4. **Supabase verifies** → Updates `email_confirmed_at` field
5. **Auth state changes** → App listener detects verification
6. **AuthGate re-checks** → Routes to onboarding/home

### Grace Period Logic

```dart
// In supabase_service.dart
bool get requiresVerification {
  // Require verification after 7 days grace period
  return !isEmailVerified && daysSinceSignup > 7;
}
```

- **Days 0-7**: Users can use the app without verification
- **Day 8+**: EmailVerificationPendingScreen is shown
- **After verification**: Full access restored

### Verification States

| State | Email Verified? | Days Since Signup | Screen Shown |
|-------|----------------|-------------------|--------------|
| New user | ❌ | 0-7 | Onboarding/Home (grace period) |
| Grace period | ❌ | 0-7 | Onboarding/Home |
| Verification required | ❌ | 8+ | EmailVerificationPendingScreen |
| Verified user | ✅ | Any | Onboarding/Home |

---

## 🧪 Testing the Implementation

### 1. Test Signup Flow
```bash
# Run the app
flutter run
```

1. Sign up with a new email
2. Check that you can access the app (grace period)
3. Check your email for verification link

### 2. Test Deep Linking (Android)
```bash
# Simulate deep link on Android emulator
adb shell am start -W -a android.intent.action.VIEW -d "lovely://auth/verify?token=test"
```

### 3. Test Deep Linking (iOS)
```bash
# Simulate deep link on iOS simulator
xcrun simctl openurl booted "lovely://auth/verify?token=test"
```

### 4. Test Verification Screen
1. Create account and wait 8 days OR
2. Manually set `created_at` in database to 8+ days ago
3. App should show EmailVerificationPendingScreen
4. Test "Resend Email" button

### 5. Test Resend Functionality
- Click "Resend Email" button
- Check inbox for new verification email
- Verify success/error messages display correctly

---

## 🔒 Security Considerations

### Current Implementation
- ✅ 7-day grace period for better UX
- ✅ Verification link expires in 24 hours (Supabase default)
- ✅ Users can still sign out during verification
- ✅ Deep links are validated by Supabase tokens

### Adjust Grace Period
To change the grace period, edit `supabase_service.dart`:
```dart
bool get requiresVerification {
  return !isEmailVerified && daysSinceSignup > 3; // 3 days instead of 7
}
```

### Require Immediate Verification
To require verification immediately:
```dart
bool get requiresVerification {
  return !isEmailVerified; // No grace period
}
```

---

## 📧 Production Email Setup

For production, configure a custom SMTP provider:

### Recommended Providers
- **SendGrid** (12k free emails/month)
- **Postmark** (100 free emails/month)
- **AWS SES** (62k free emails/month)

### Configuration
1. Go to **Project Settings** → **Email**
2. Enable **Custom SMTP**
3. Enter your SMTP credentials:
   - Host
   - Port
   - Username
   - Password
4. Set **Sender email** and **Sender name**
5. Test email delivery

---

## 🐛 Troubleshooting

### Emails Not Received
1. Check spam folder
2. Verify email template is enabled
3. Check Supabase logs: **Authentication** → **Logs**
4. Test with different email provider

### Deep Links Not Working
1. Verify AndroidManifest.xml has intent filter
2. Verify Info.plist has CFBundleURLTypes
3. Check scheme is `lovely://` (no typo)
4. Rebuild app after manifest changes

### Auth State Not Updating
1. Check that auth listener is set up in main.dart
2. Verify Supabase client is initialized
3. Check debug logs for auth events
4. Try hot restart (not hot reload)

### Users Stuck on Verification Screen
1. Check grace period logic
2. Verify `email_confirmed_at` field in database
3. Check if verification link was clicked
4. Allow manual sign-out and retry

---

## 📝 Next Steps

1. **Configure Supabase Dashboard** (required)
   - Enable email confirmation
   - Set confirmation URL to `lovely://auth/verify`

2. **Test the Flow** (recommended)
   - Sign up with real email
   - Click verification link
   - Verify app redirects correctly

3. **Customize Email Template** (optional)
   - Add branding
   - Personalize message
   - Include support contact

4. **Set Up Production SMTP** (before launch)
   - Choose provider
   - Configure credentials
   - Test delivery

---

## ✨ Features Included

- ✅ Email verification screen with resend functionality
- ✅ 7-day grace period for new users
- ✅ Deep linking for email verification
- ✅ Auth state listener for automatic updates
- ✅ Sign-out option during verification
- ✅ Error handling and user feedback
- ✅ Dark mode support
- ✅ Accessible UI with icons and clear messages
