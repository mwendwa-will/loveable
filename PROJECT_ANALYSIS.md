Lovely — Project Analysis and Developer Guide

This document summarizes the architecture, data flow, dependencies, state management, navigation, and key features of the `lovely` Flutter app. It is generated from the workspace sources (notably `lib/`) and aims to help you onboard, extend, and maintain the app.

Summary: The app is a feature-first, Riverpod-managed Flutter application with Supabase as the primary backend and Firebase/Awesome Notifications for push/local notifications.

Table of contents
- Project structure overview
- Architecture & patterns
- State management
- Data flow
- Navigation & routing
- Dependencies
- API integration & networking
- Data models & serialization
- Dependency injection
- Key features
- Utilities & helpers
- Testing
- Developer guide (how-to)
- Flow diagrams (textual)
- Potential issues & recommendations

---

Project Structure Overview

lib/
├── main.dart                    # App entrypoint, initializes Firebase, notifications, Supabase, and PIN handling
├── firebase_options.dart        # Generated Firebase options (platform-specific)
├── config/                      # App configuration templates (e.g., Supabase keys)
│   └── supabase_config.dart.template  # Template for Supabase URL/anon key
├── constants/                   # Color, style and other constant definitions
│   └── app_colors.dart          # Centralized colors and helpers
├── providers/                   # Riverpod providers (state) for app domains
│   ├── auth_provider.dart       # Auth stream, session and user providers
│   ├── pin_lock_provider.dart   # PIN Lock state (Notifier)
│   ├── period_provider.dart     # Period / calendar stream providers
│   └── profile_provider.dart    # Profile state (Notifier)
├── services/                    # Service layer for backend and platform integrations
│   ├── supabase_service.dart    # Main API layer for Supabase (singleton)
│   ├── notification_service.dart# AwesomeNotifications + FCM wrapper
│   ├── pin_service.dart         # Secure PIN storage and timeout logic
│   └── cycle_analyzer.dart      # Prediction logic (floating window, logging)
├── models/                      # Domain models (manual JSON serialization)
│   ├── period.dart
│   ├── mood.dart
│   ├── symptom.dart
│   ├── sexual_activity.dart
│   └── note.dart
├── screens/                     # UI screens organized by area (auth, onboarding, main, settings)
│   ├── auth/                    # Authentication flows (login, signup, verify)
│   ├── onboarding/
│   ├── main/                    # `home_screen.dart`, `profile_screen.dart` (main app UI)
│   └── security/                # PIN setup/unlock
├── widgets/                     # Reusable UI widgets (bottom sheets, dialogs, mood picker)
└── utils/                       # Helpers (responsive sizing, date helpers)

What each area is responsible for:
- `lib/main.dart`: Initializes platform services, provides the root `ProviderScope`, mounts `AuthGate` and handles app lifecycle PIN locking.
- `lib/services/supabase_service.dart`: Centralized data access and business operations (auth, CRUD for periods, moods, symptoms, prediction logging). Uses Supabase client and implements the Repository-like service.
- `lib/providers/*`: Riverpod providers and Notifier classes (state holders) used throughout the UI.
- `lib/models/*`: Manual `fromJson`/`toJson` typed models — no codegen or `json_serializable`.
- `lib/screens/*` and `lib/widgets/*`: UI layer with Consumers/Widgets using Riverpod providers and service calls.

---

Architecture Pattern

- Pattern: Feature-first / Service-oriented with elements of Clean Architecture.
  - UI layer: `lib/screens` + `lib/widgets`
  - State / domain layer: `lib/providers` (Riverpod Notifiers and Providers)
  - Data / infra: `lib/services` (SupabaseService, NotificationService, PinService)

- Separation of concerns: UI calls Providers (Riverpod) which use Services to fetch/persist data. Models are simple DTOs living in `lib/models`.

- Design patterns used:
  - Singleton: `SupabaseService` and `NotificationService` use singletons.
  - Repository-like Service: `SupabaseService` centralizes data access logic and validation.
  - Notifier (State Holder): Riverpod `Notifier` classes (`ProfileNotifier`, `PinLockNotifier`).
  - Provider Factory: Providers return service instances or Notifier instances via Riverpod.

Architecture diagram (text):

UI (screens/widgets)
  ↕ (watch/read)
Riverpod Providers / Notifiers (state)
  ↕ (call)
Services (SupabaseService, NotificationService, PinService)
  ↕ (network/local)
Supabase (Postgres + Auth) + Firebase (FCM)

---

State Management

- Package used: `flutter_riverpod` (version ^3.1.0 in `pubspec.yaml`).
- Patterns in codebase:
  - `NotifierProvider` / `Notifier` for complex, mutable state (e.g., `PinLockNotifier`, `ProfileNotifier`).
  - `StreamProvider` and `FutureProvider` for asynchronous/snapshot data (e.g., `authStateProvider`, `periodsStreamProvider`, `userDataProvider`).

- Where state classes are located: `lib/providers/*`.

Concrete example (how state is created and flows):
- Creation: `pinLockProvider` is a `NotifierProvider` in `lib/providers/pin_lock_provider.dart`.
  - `PinLockNotifier.build()` calls internal initialization which reads `PinService` and sets initial `PinLockState`.
- UI triggers change: `LovelyApp` (in `lib/main.dart`) reads `pinLockProvider` and calls `ref.read(pinLockProvider.notifier).lock()` when app goes background, or `.unlock()` when PIN entry succeeds.
- UI reacts: Widgets use `ref.watch(pinLockProvider)` or `ref.watch(authStateProvider)` to rebuild automatically when provider state changes.

Code snippet (observed in repo):
```dart
// Watch auth state
final authState = ref.watch(authStateProvider);

// Notifier provider declaration
final pinLockProvider = NotifierProvider<PinLockNotifier, PinLockState>(() {
  return PinLockNotifier();
});

// Trigger unlock from PIN screen
await ref.read(pinLockProvider.notifier).unlock();
```

---

Data Flow

Typical user action sequence (e.g., logging mood):
1. User taps 'Log mood' in UI (`lib/screens/*` or `DayDetailBottomSheet`).
2. UI calls a provider or directly calls `SupabaseService.saveMood()` via a provider reference (e.g., `ref.read(supabaseServiceProvider)`).
3. `SupabaseService` performs the DB operation using `Supabase.instance.client.from('moods')...` and returns a `Mood` model.
4. Provider updates state (Notifier or stream) and UI watchers (`ref.watch(...)`) receive updated snapshots and rebuild.

Sequence diagram (text):
User → UI Widget → Provider / Notifier → SupabaseService → Supabase (network DB)
Supabase → SupabaseService (response) → Provider updates state → UI rebuilds

Where parsing/serialization occurs: Models implement `fromJson` / `toJson` (e.g., `lib/models/mood.dart`). Data transformation is handled in `SupabaseService` and model constructors.

Error handling: `SupabaseService` has try/catch blocks and throws domain-specific exceptions (see `core/exceptions/app_exceptions.dart`) or generic exceptions. UI often shows error feedback using `FeedbackService`.

---

Navigation & Routing

- Approach: Navigator 1.0 (imperative) with `MaterialPageRoute` usage — no `go_router` or `auto_route` detected.
- Where routes are defined: There is no global `routes` map; screens navigate directly via `Navigator.push` / `Navigator.pushReplacement` from widgets.
- Entry point: `MaterialApp(home: AuthGate())` in `lib/main.dart`.
- Example navigation code (from `lib/main.dart`):
```dart
Navigator.of(navigatorKey.currentContext!).push(
  MaterialPageRoute(builder: (context) => PinUnlockScreen(...)),
);
```
- Nested navigation / bottom navigation: `HomeScreen` behaves like a hub; it uses internal navigation (PageView and sheet modals) but no nested Navigator patterns were found in global route sense.

---

Dependencies & Packages

`pubspec.yaml` notable packages and usage:
- `flutter_riverpod`: State management (providers, notifiers). Used throughout `lib/providers`.
- `supabase_flutter`: Backend (auth, DB, real-time streams). Central to `SupabaseService`.
- `supabase_auth_ui`: UI helpers for auth flows.
- `firebase_core` / `firebase_messaging`: Initialize Firebase and receive push messages.
- `awesome_notifications`: Local & scheduled notifications with rich features; used together with FCM.
- `flutter_secure_storage`: Securely store PIN hash and lock timestamp (`PinService`).
- `google_fonts`, `font_awesome_flutter`: UI typography and icons.
- `shared_preferences`: Lightweight local persistence (some settings may use it).
- `local_auth`: Biometric auth (used in PIN/lock flows, likely in security screens).
- `crypto`: SHA-256 hashing used in `PinService` to hash PINs.

Where used: See `lib/services/*` and `lib/providers/*` for concrete usage locations.

---

API Integration & Networking

- HTTP client: `supabase_flutter` (under the hood uses PostgREST Websockets/HTTP). `Supabase.instance.client` is used directly.
- Endpoints: No explicit REST endpoints — all interactions use Supabase client to operate on tables and RPC functions (e.g., `client.from('periods').insert(...)`, `client.rpc('is_username_available', params: {...})`).
- Requests: Made in `lib/services/supabase_service.dart`. The service handles all CRUD and RPC calls, streaming via `.stream()`.
- Responses: Mapped to model objects via `Model.fromJson(...)` in the service.
- Error handling: Try/catch blocks in `SupabaseService` translate Supabase exceptions to domain exceptions (`core/exceptions/app_exceptions.dart`) or rethrow. Network exceptions and timeouts are handled in places (e.g., sign up uses `SocketException`/`TimeoutException`).
- Authentication: Managed by Supabase auth API. Tokens are handled by `supabase_flutter` helper; `authStateProvider` listens to `Supabase.instance.client.auth.onAuthStateChange` for session updates. `SupabaseService.currentUser` reads `client.auth.currentUser`.

Example API call (from code):
```dart
final response = await client
  .from('periods')
  .insert(data)
  .select()
  .single();
return Period.fromJson(response);
```

---

Data Models & Serialization

- Models located in `lib/models/` and use manual `fromJson` / `toJson` methods.
- No codegen: No `freezed` or `json_serializable` detected — manual parsing is the pattern.

Key model examples:
- `lib/models/period.dart` — `Period.fromJson(...)`, `toJson()` and `FlowIntensity` enum.
- `lib/models/mood.dart`, `lib/models/symptom.dart` — both provide `fromJson`/`toJson` and enums for typed values.

Relationships: Models are flat DTOs representing single DB tables; relationships are handled at service level by looking up `user_id` and making additional queries.

---

Dependency Injection (DI)

- Approach: Lightweight DI using Riverpod providers and singletons.
  - `SupabaseService` is a singleton class; additionally, there is a `supabaseServiceProvider` in `lib/providers/period_provider.dart` that returns `SupabaseService()` via `Provider`.
  - No `get_it` or `injectable` detected.

How to access dependencies:
- Use `ref.read(supabaseServiceProvider)` or create a provider that returns the service instance. Notifier classes instantiate services directly where necessary.

Example:
```dart
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Usage in widget/notifier
final supabase = ref.read(supabaseServiceProvider);
await supabase.getCurrentPeriod();
```

---

Key Features (high-level)

1. Period tracking & predictions
   - Files: `lib/services/supabase_service.dart`, `lib/services/cycle_analyzer.dart`, `lib/models/period.dart`, `lib/screens/calendar_screen.dart`, `lib/screens/main/home_screen.dart`.
   - Data sources: Supabase `periods` table, user meta in `users` table.
   - Logic: `CycleAnalyzer` does floating-window predictions and logs accuracy.

2. Daily logs (mood, symptoms, notes, sexual activity)
   - Files: `lib/services/supabase_service.dart`, `lib/models/mood.dart`, `lib/models/symptom.dart`, `lib/widgets/mood_picker.dart`, `lib/screens/daily_log_screen.dart`.
   - Data sources: `moods`, `symptoms`, `notes`, `sexual_activities` tables.

3. Authentication & Onboarding
   - Files: `lib/screens/auth/*`, `lib/services/supabase_service.dart`, `lib/providers/auth_provider.dart`.
   - Flow: `AuthGate` routes user to `WelcomeScreen`, `OnboardingScreen`, or `HomeScreen`.

4. Security: App PIN and biometric locking
   - Files: `lib/services/pin_service.dart`, `lib/providers/pin_lock_provider.dart`, `lib/screens/security/*`.
   - Stores hashed PIN via `flutter_secure_storage` + SHA-256.

5. Notifications & reminders
   - Files: `lib/services/notification_service.dart`, uses `awesome_notifications` and `firebase_messaging`.

6. Profile management
   - Files: `lib/providers/profile_provider.dart`, `lib/screens/settings/edit_profile_screen.dart` and service calls to update user profile.

---

Common Utilities & Helpers

- `lib/utils/responsive_utils.dart`: Centralized responsive sizing helpers used across UI.
- `lib/constants/app_colors.dart`: Centralized color palette and theming helpers (ensures consistent theme-aware colors).
- `lib/services/cycle_analyzer.dart`: Encapsulates prediction algorithms and analytics helpers.
- `lib/core/feedback/feedback_service.dart` (used in screens) for user-visible success/error toast/snackbar messaging.

Extensions and shared helpers are organized under `lib/utils` and `lib/constants`.

---

Testing Structure

- Tests: `test/` folder exists; `integration_test` configured in `dev_dependencies`.
- Testing packages: `flutter_test`, `integration_test`, `mockito`.
- Observed approach: Standard Flutter unit/widget and integration test tooling. (No explicit tests were enumerated in this analysis run — inspect `test/` directory for specifics.)

---

Developer Guide — Common Tasks

- Add a new feature (recommended):
  1. Create a feature folder under `lib/screens/<feature_name>` and `lib/widgets/<feature_name>` as needed.
  2. Add model(s) to `lib/models/` if new entities are required.
  3. Add service methods to `SupabaseService` to persist/fetch data for that feature.
  4. Add Riverpod providers in `lib/providers/` (use `NotifierProvider` for complex state or `FutureProvider`/`StreamProvider` for async data).
  5. Update UI to `ref.watch(...)` or `ref.read(...)` the provider; call service methods via `ref.read(supabaseServiceProvider)` or provider-managed service.

- Add a new screen:
  1. Create `lib/screens/<area>/<new_screen>.dart`.
  2. Use `Navigator.push(MaterialPageRoute(...))` to navigate from existing screens (consistent with current project approach).
  3. Use `ref.watch` to listen to providers and `ref.read(...notifier).method()` to trigger changes.

- Make an API call:
  1. Add a method to `SupabaseService` (follow existing error handling and session checks).
  2. Map DB responses to model `fromJson` or return simple DTO.
  3. Expose a provider if callers should access a cached instance (optional).

- Create a new model:
  1. Add `lib/models/<name>.dart` with typed fields.
  2. Implement `factory fromJson(Map<String,dynamic>)` and `Map<String,dynamic> toJson()`.
  3. Update `SupabaseService` to use the new model where appropriate.

- Manage state for a new feature:
  1. Create a `Notifier` if you need complex mutable state and side effects.
  2. Use `NotifierProvider` to expose it and `ref.watch`/`ref.read` in UI code.
  3. For simple async data, use `FutureProvider` or `StreamProvider`.

Conventions:
- Manual model serialization (no code generation). Keep `toJson()` and `fromJson()` stable.
- Services are the single source of truth for data access.
- Use `ref.watch` for reactive UI and `ref.read(...notifier)` for commands.

---

Flow Diagrams (textual)

1) App initialization flow (`lib/main.dart`):
  - `main()`
    → Initialize Firebase
    → Initialize NotificationService
    → Initialize SupabaseService
    → `runApp(ProviderScope(child: LovelyApp()))`
    → `LovelyApp` performs PIN check and mounts `AuthGate` or PIN screens

2) Authentication flow:
  - `AuthGate` watches `authStateProvider` (Supabase auth stream)
    → No session: `WelcomeScreen`
    → Session present: check onboarding via Supabase `users` table
      → Onboarded: `HomeScreen`
      → Not onboarded: `OnboardingScreen`

3) Data fetching flow (example — period list):
  - `HomeScreen` or calendar widget requests periods via `periodsStreamProvider`
  - Provider calls `SupabaseService.getPeriodsStream(startDate, endDate)`
  - Supabase stream emits changes → provider map to `Period` models → UI rebuilds

4) Navigation flow: Imperative Navigator 1.0 with push/pop and modal bottom sheets for details.

---

Potential Issues & Recommendations

- Inconsistent DI: Some Notifiers instantiate `SupabaseService()` directly; others use `supabaseServiceProvider`. Recommend standardizing to a provider for easier testing and mocking.
- Manual JSON parsing: Works but is error-prone; consider `json_serializable` or `freezed` for immutability and safer parsing.
- Large `SupabaseService`: Single file is large (~1,400+ lines). Split responsibilities into smaller services (AuthService, PeriodService, MoodService) to improve maintainability and testability.
- Error handling: Many `try/catch` blocks are present; ensure that UI consistently handles errors from providers (some `FutureBuilder` fallbacks default to home screen). Centralize user-facing error messages via `FeedbackService`.
- Navigation centralization: Consider a centralized router (`go_router` or `auto_route`) for clearer navigation graph as app grows.
- Tests: Add focused unit tests for `CycleAnalyzer` and `SupabaseService` wrappers (mock Supabase client). Use `mockito` to mock service responses.

---

Next steps / Where to add changes

- To add network logic for a feature: update `SupabaseService` (or create a smaller dedicated service) and model in `lib/models`.
- To add state: create a `Notifier` in `lib/providers` and expose via `NotifierProvider`.
- To add UI: create a screen in `lib/screens/<area>` and use Riverpod `ref.watch`.

---

If you'd like, I can:
- Generate a smaller refactor plan to split `SupabaseService` into per-domain services.
- Add unit tests for `CycleAnalyzer` and `PinService`.
- Produce a diagram image (SVG) for architecture and sequence flows.

File created: `PROJECT_ANALYSIS.md`
