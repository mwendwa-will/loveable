# AGENTS.md - Design and Architecture Guide

This document outlines the design and architectural instructions for the Lovely application, using an agent-based model to handle various aspects of the application's logic and data. It incorporates the project's core principles, design system, and coding standards.

## 1. Core Development Principles

-   **Design Philosophy**: Create interfaces that stand out through thoughtful hierarchy, not visual noise. Prioritize usability, and balance beauty with performance.
-   **Code Standards**: Write clean, readable code with meaningful names. Avoid verbose comments and unnecessary abstractions.
-   **Testing**: No feature is complete without passing tests. Update all affected tests after every feature change. Minimum coverage is 80% for business logic.

---

## 2. Agent-Based Architecture

The application is structured around a set of "agents," which are specialized components responsible for managing specific domains. This promotes a clean separation of concerns and modularity.

### 2.1. Cycle & Health Agent

-   **Responsibilities:**
    -   Manages all aspects of the user's menstrual cycle, including period tracking, symptom logging, and mood tracking.
    -   Calculates and predicts cycle phases, fertile windows, and next period dates using the logic defined in the "Cycle Calculations" section.
    -   Provides insights and trends based on historical health data.
-   **Data Models:** `CycleLog`, `Symptom`, `Mood`, `Period`
-   **Backend Interaction:** CRUD operations on the `cycle_logs`, `symptoms`, `moods`, and `periods` tables in Supabase.

### 2.2. Task & Schedule Agent

-   **Responsibilities:**
    -   Manages the user's daily tasks, including creation, editing, and completion.
    -   Handles recurring tasks and scheduling.
    -   Tracks user's progress and streaks.
-   **Data Models:** `Task`
-   **Backend Interaction:** CRUD operations on the `tasks` table in Supabase.

### 2.3. Affirmation & Motivation Agent

-   **Responsibilities:**
    -   Fetches and displays daily affirmations.
    -   Manages user's favorite and custom affirmations.
    -   Provides affirmations based on the user's current cycle phase or mood.
-   **Data Models:** `Affirmation`, `UserAffirmation`
-   **Backend Interaction:** Reads from the `affirmations` table and performs CRUD operations on the `user_affirmations` table.

### 2.4. User & Profile Agent

-   **Responsibilities:**
    -   Manages user authentication (sign-up, login, password reset).
    -   Implements persistent authentication via session management.
    -   Manages user profile data, settings, and preferences.
    -   Handles the onboarding process for new users.
-   **Data Models:** `User`
-   **Backend Interaction:** Interacts with Supabase Auth and performs CRUD operations on the `users` table.
-   **Authentication Flow:**
    ```
    App Launch
        → main() initializes Supabase
        → Supabase reads encrypted tokens from device storage
        → AuthGate checks currentSession
        → If valid: Check onboarding status
            → Completed: Navigate to HomeScreen
            → Incomplete: Navigate to OnboardingScreen
        → If expired: Show WelcomeScreen for re-login
    ```
-   **Session Persistence:**
    -   Tokens stored in SharedPreferences (Android) / UserDefaults (iOS)
    -   Sessions survive app restarts and cache clearing
    -   Sessions expire after 30 days or on explicit logout
    -   Auto-refresh mechanism maintains session validity

### 2.5. Notification Agent

-   **Responsibilities:**
    -   Manages all user notifications, including task reminders, period predictions, and daily affirmations.
    -   Interfaces with Firebase Cloud Messaging (FCM).
    -   Manages user's notification preferences.
-   **Backend Interaction:** Stores FCM tokens in the `users` table and logs notifications in the `notification_logs` table.

### 2.6. Subscription & Monetization Agent

-   **Responsibilities:**
    -   Manages subscription state and tier enforcement (Free vs Premium).
    -   Handles 48-hour free trial activation and expiration tracking.
    -   Integrates with RevenueCat for payment processing and receipt validation.
    -   Enforces feature gates based on subscription tier.
    -   Syncs subscription state between RevenueCat and Supabase.
    -   Manages subscription lifecycle: trial → active → cancelled/expired.
-   **Data Models:** `Subscription`, `SubscriptionPackage`
-   **Backend Interaction:** 
    -   CRUD operations on the `subscriptions` table in Supabase.
    -   RevenueCat SDK for payment processing and subscription management.
    -   Webhook integration for real-time subscription event updates.
-   **Integration with Other Agents:**
    -   **User & Profile Agent**: Triggers subscription initialization on login, cleanup on logout.
    -   **Cycle & Health Agent**: Enforces history limits based on subscription tier (3 months for free, unlimited for premium).
    -   **Affirmation Agent**: Gates custom affirmations behind premium tier.

---

## 3. Technology & State Management

-   **Backend:** **Supabase** is the primary backend for authentication, database (PostgreSQL), and storage. All tables must have Row Level Security (RLS) enabled.
-   **State Management:** **Riverpod** is used for state management. Each agent should have its own set of providers.
    -   Use `StateNotifierProvider` for complex states.
    -   Use `.watch()` in widgets for reactive updates and `.read()` for one-time operations.
-   **Service Layer:** A service layer (`SupabaseService`) abstracts communication with Supabase. Agents use this service to fetch and push data.

---

## 4. Design System & UI

### 4.1. Theme Configuration

-   **Seed Color**: The theme is generated from a single seed color: **Coral Sunset `#FF6F61`**.
-   **Theme Mode**: The app respects the device theme using `ThemeMode.system`.
-   **Dark Theme Background**: Use `#121212` for the scaffold background in dark mode.
-   **Fonts**: Use **Google Fonts "Inter"** for all text.

### 4.2. Color Architecture

-   **Centralized Colors**: All cycle-specific colors must be defined in `lib/constants/app_colors.dart` and accessed via theme-aware methods.

    ```dart
    // DO: Use theme-aware color getters
    AppColors.getPeriodColor(context);
    AppColors.getFertileWindowColor(context);
    AppColors.getOvulationColor(context);

    // DON'T: Hardcode colors
    // color: Color(0xFFFF0000);
    ```

-   **Smart Text Color**: All text on colored backgrounds **must** use the `_getTextColorForBackground` helper to ensure accessibility and contrast.

    ```dart
    Color _getTextColorForBackground(Color backgroundColor) {
      final luminance = backgroundColor.computeLuminance();
      return luminance > 0.5 ? Colors.black87 : Colors.white;
    }
    ```

### 4.3. UI Patterns & Responsive Design

-   **Responsive Sizing**: Use the centralized `ResponsiveSizing` utility from `lib/utils/responsive_utils.dart` for consistent sizing across all screens.

    ```dart
    // Access via context extension
    context.responsive.weekStripCircleSize
    context.responsive.calendarDateFontSize
    context.responsive.iconSize
    context.responsive.spacingMd
    
    // Screen breakpoints:
    // small:  < 360px (compact phones)
    // medium: 360-400px (standard phones)
    // large:  400-600px (large phones)
    // tablet: > 600px (tablets)
    ```

-   **Icons**: Use **Material Icons** for UI indicators. FontAwesome (`font_awesome_flutter` package) for decorative icons.
-   **FilterChips**: Use `Theme.of(context).colorScheme.surfaceTint` for theme-aware chip styling to ensure proper contrast in both light and dark modes.
-   **Mood Colors**: Consistent color mapping for moods across the app:
    - Happy: Green
    - Calm: Blue
    - Tired: Grey
    - Sad: Indigo
    - Irritable: Orange
    - Anxious: Purple
    - Energetic: Amber

---

## 5. Cycle Calculations

The `Cycle & Health Agent` uses the following logic for predictions:

-   **Reference Date**: Current or last period start date.
-   **Average Cycle Length**: `28` days (default, user-configurable).
-   **Current Cycle Day**: `(DateTime.now().difference(referenceDate).inDays % _averageCycleLength) + 1`
-   **Ovulation Date**: `nextPeriodDate.subtract(const Duration(days: 14))` (since the luteal phase is constant).
-   **Fertile Window**: 5 days before and including the ovulation date.

---

## 6. Code Quality & Standards

-   **Naming Conventions**: `PascalCase` for classes, `camelCase` for variables/functions, `_leadingUnderscore` for private members, and `snake_case.dart` for files.
-   **Widget Building**: Keep the `build()` method clean and extract complex UI into private `_buildXyz()` methods with explicit return types.
-   **Deprecated APIs**: Do not use deprecated APIs. For example, use `.withAlpha()` instead of `.withOpacity()` for colors.

---

## 7. Data Models

Key data models for the application:

```dart
class User { ... }
class CycleLog { ... }
class Symptom { ... }
class Task { ... }
class Affirmation { ... }
```
*(Refer to the source code for full implementation details of each model.)*
