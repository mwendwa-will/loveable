# Authentication Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           LOVELY APP                                │
│                      Authentication System                          │
└─────────────────────────────────────────────────────────────────────┘

┌───────────────┐      ┌───────────────┐      ┌───────────────────┐
│  Signup Form  │      │  Login Form   │      │  Profile Screen   │
│               │      │               │      │                   │
│ • First Name  │      │ • Email/      │      │ • Display Name    │
│ • Last Name   │      │   Username    │      │ • Avatar (init)   │
│ • Username    │      │ • Password    │      │ • Edit Profile    │
│ • Email       │      │               │      │                   │
│ • Password    │      └───────┬───────┘      └─────────┬─────────┘
│               │              │                        │
└───────┬───────┘              │                        │
        │                      │                        │
        │                      │                        │
        ▼                      ▼                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       SupabaseService                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │ Authentication Methods                                    │     │
│  │                                                           │     │
│  │  signUp({                                                │     │
│  │    email, password,                                      │     │
│  │    username, firstName, lastName                         │     │
│  │  })                                                      │     │
│  │                                                           │     │
│  │  signIn({                                                │     │
│  │    emailOrUsername,  ◄── Auto-detects email vs username │     │
│  │    password                                              │     │
│  │  })                                                      │     │
│  │                                                           │     │
│  │  isUsernameAvailable(username)  ◄── Real-time check     │     │
│  │                                                           │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │ Profile Methods                                           │     │
│  │                                                           │     │
│  │  getUserData()                                           │     │
│  │  saveUserData({firstName, lastName, username, ...})      │     │
│  │  updateUserProfile({firstName, lastName, bio, ...})      │     │
│  │  hasCompletedOnboarding()  ◄── Checks first_name        │     │
│  │                                                           │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        SUPABASE BACKEND                             │
│                                                                     │
│  ┌────────────────────┐          ┌──────────────────────────┐     │
│  │   auth.users       │          │  public.users            │     │
│  │                    │          │                          │     │
│  │ • id (UUID)        │  sync    │ • id (FK)                │     │
│  │ • email            │◄────────►│ • email                  │     │
│  │ • encrypted_pw     │          │ • first_name  (required) │     │
│  │ • user_metadata    │          │ • last_name   (optional) │     │
│  │   ├─ username      │          │ • username    (optional) │     │
│  │   ├─ first_name    │          │ • bio         (optional) │     │
│  │   └─ last_name     │          │ • date_of_birth          │     │
│  │                    │          │ • created_at             │     │
│  └────────────────────┘          │ • updated_at             │     │
│                                  │                          │     │
│                                  │ UNIQUE: username (lower) │     │
│                                  │ CHECK: username format   │     │
│                                  └──────────────────────────┘     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │ RPC Functions                                             │     │
│  │                                                           │     │
│  │  is_username_available(check_username TEXT)              │     │
│  │  → Returns BOOLEAN                                       │     │
│  │  → Case-insensitive check                                │     │
│  │                                                           │     │
│  │  get_user_by_username_or_email(identifier TEXT)          │     │
│  │  → Returns user record (id, email, username, names)      │     │
│  │  → Used for login conversion                             │     │
│  │                                                           │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Signup Flow Diagram

```
┌───────────────┐
│ User fills    │
│ signup form   │
└───────┬───────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Enter username: "johndoe"             │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Debounce 500ms                        │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Check: isUsernameAvailable('johndoe')│
└───────┬───────────────────────────────┘
        │
        ├─── Available ──────► ✅ Show green check
        │
        └─── Taken ──────────► ❌ Show error icon
                                 "Username already taken"
                                 
┌───────────────────────────────────────┐
│ User clicks "Sign Up"                 │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ signUp({                              │
│   email: "john@example.com",          │
│   password: "SecurePass123",          │
│   username: "johndoe",                │
│   firstName: "John",                  │
│   lastName: "Doe"                     │
│ })                                    │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Supabase Auth creates user            │
│ • Stores in auth.users                │
│ • Saves metadata (username, names)    │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Navigate to Onboarding                │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ User completes onboarding             │
│ (cycle info, preferences)             │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ saveUserData({                        │
│   firstName, lastName, username,      │
│   cycleLength, periodLength, ...      │
│ })                                    │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Data saved to public.users table      │
│ hasCompletedOnboarding() = true       │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Navigate to Home Screen               │
└───────────────────────────────────────┘
```

## Login Flow Diagram

### Email Login:
```
┌───────────────────────────────────────┐
│ User enters: "john@example.com"       │
│ Password: "SecurePass123"             │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ signIn({                              │
│   emailOrUsername: "john@example.com",│
│   password: "SecurePass123"           │
│ })                                    │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Backend detects "@" in input          │
│ → Uses email directly                 │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ auth.signInWithPassword(              │
│   email: "john@example.com",          │
│   password: "SecurePass123"           │
│ )                                     │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ ✅ Success → Create session           │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Check: hasCompletedOnboarding()       │
└───────┬───────────────────────────────┘
        │
        ├─── Yes ──────► Home Screen
        │
        └─── No ───────► Onboarding Screen
```

### Username Login:
```
┌───────────────────────────────────────┐
│ User enters: "johndoe"                │
│ Password: "SecurePass123"             │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ signIn({                              │
│   emailOrUsername: "johndoe",         │
│   password: "SecurePass123"           │
│ })                                    │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Backend detects NO "@" in input       │
│ → Lookup username                     │
└───────┬───────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│ Call: get_user_by_username_or_email( │
│   identifier: "johndoe"               │
│ )                                     │
└───────┬───────────────────────────────┘
        │
        ├─── Found ──────► email = "john@example.com"
        │                  │
        │                  ▼
        │         ┌────────────────────────┐
        │         │ auth.signInWithPassword│
        │         │ email: converted email │
        │         │ password: user input   │
        │         └────────┬───────────────┘
        │                  │
        │                  ▼
        │         ┌────────────────────────┐
        │         │ ✅ Success → Session   │
        │         └────────────────────────┘
        │
        └─── Not Found ──► ❌ Invalid credentials error
```

## Profile Provider State Flow

```
┌─────────────────────────────────────────────┐
│          ProfileNotifier (Riverpod)         │
└─────────────────────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   Initial State:      │
        │   firstName: "Loading"│
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  loadProfile()                │
        │  → getUserData()              │
        │  → Parse first_name, etc.     │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  State Updated:               │
        │  firstName: "John"            │
        │  lastName: "Doe"              │
        │  username: "johndoe"          │
        │  bio: "Hello!"                │
        └───────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  UI reads:                    │
        │  • fullName → "John Doe"      │
        │  • initials → "JD"            │
        └───────────────────────────────┘
                    
                    
        User triggers edit...
                    │
                    ▼
        ┌───────────────────────────────┐
        │  updateProfile({              │
        │    firstName: "Jane"          │
        │  })                           │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  Optimistic Update            │
        │  state = state.copyWith(...)  │
        │  → UI updates INSTANTLY       │
        └───────────┬───────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │  Save to Supabase             │
        │  updateUserProfile(...)       │
        └───────┬───────────────────────┘
                │
                ├─── Success ──────► Keep state
                │
                └─── Error ────────► Rollback to previous state
```

## Avatar Generation Logic

```
Input: UserProfile with firstName and lastName

┌─────────────────────────────────────────┐
│ firstName = "John"                      │
│ lastName = "Doe"                        │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ initials getter:                        │
│   if lastName exists:                   │
│     return firstName[0] + lastName[0]   │
│   else:                                 │
│     return firstName[0..1]              │
└─────────────┬───────────────────────────┘
              │
              ▼
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
lastName                lastName
present?                null?
    │                   │
    ▼                   ▼
 "JD"                 "JO"
(John Doe)           (John)


Display in UserAvatar:
┌─────────────────────────┐
│        ┌───────┐        │
│        │  JD   │        │
│        └───────┘        │
│    (gradient circle)    │
└─────────────────────────┘
```

## Data Flow Summary

```
┌─────────────┐                    ┌──────────────┐
│   Signup    │───── signUp ──────►│   Supabase   │
│   Screen    │                    │     Auth     │
└─────────────┘                    └──────┬───────┘
                                          │
                                          │ user_metadata
                                          │ {username, names}
                                          ▼
┌─────────────┐                    ┌──────────────┐
│ Onboarding  │─── saveUserData ──►│  users table │
│   Screen    │                    │ (public DB)  │
└─────────────┘                    └──────┬───────┘
                                          │
                                          │ first_name,
                                          │ last_name,
                                          │ username, etc.
                                          ▼
┌─────────────┐                    ┌──────────────┐
│   Profile   │◄─── loadProfile ───│ ProfileNotif │
│   Screen    │                    │     ier      │
└─────────────┘                    └──────────────┘
      │                                    
      │ displays                           
      ▼                                    
┌─────────────┐                            
│ UserAvatar  │                            
│  (initials) │                            
└─────────────┘                            
```

---

**Architecture Complete! All flows documented.**
