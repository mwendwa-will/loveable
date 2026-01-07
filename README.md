# Lovely - Women's Wellness & Period Tracking App

A comprehensive women's wellness application built with Flutter and Supabase, designed to help women track their menstrual cycles, manage daily tasks, and maintain their wellness journey with dignity and care.

## About

Lovely is a privacy-focused wellness app that combines period tracking, task management, and daily affirmations in a beautiful, accessible interface. Built with modern Flutter architecture and powered by Supabase, it prioritizes user data security and experience.

## Features

### Implemented ✅
- **User Authentication** - Secure email/password signup and login via Supabase Auth
- **Password Recovery** - Email-based password reset functionality
- **Email Verification** - 7-day grace period with verification reminders
- **Personalized Onboarding** - Collects essential cycle information during first-time setup
- **Profile Management** - User profile with settings and account management
- **App-Specific PIN Security** - 4-digit PIN lock with SHA-256 hashing, auto-lock on background, encrypted storage, **30-minute timeout logout** (banking app behavior)
- **Period Logging** - Start/end period tracking with flow intensity
- **Mood Tracking** - Daily mood logging with 7 emotional states via bottom sheet picker
- **Symptom Tracking** - Log 8 different symptoms with severity levels (1-5 scale)
- **Sexual Activity Logging** - Track intimate activity with protection details
- **Daily Notes** - Journal entries for each day
- **Pregnancy Mode** - Specialized tracking for expecting mothers
- **Cycle Dashboard** - Visual cycle card showing current period status
- **Week Strip View** - 7-day swipeable view with mood/symptom/activity icons, date navigation
- **Calendar Month View** - Full calendar with phase colors, icons, responsive cells
- **Day Detail Bottom Sheet** - Tap any date to see complete day information
- **Quick Add Menu** - Long press for fast mood/symptom/activity logging
- **Real-time Data Sync** - Stream-based architecture with instant updates across screens
- **Responsive Design** - Centralized sizing utility scales UI for all device sizes
- **Lifecycle Safety** - Proper mounted checks prevent common Flutter errors
- **Material Design 3** - Icons (not emojis), FilledButton, modern elevation standards
- **Modern APIs** - RadioGroup widget (Flutter 3.35+), no deprecated patterns
- **Dark Mode Support** - Automatic theme switching based on system preferences
- **Accessibility** - 48x48px+ touch targets, color + icon redundancy, semantic labels
- **Coral Sunset Theme** - Warm, feminine color palette (#FF6F61 seed color)
- **Account Management** - Full account deletion with cascading data cleanup

### In Development 🔄
- Privacy Settings (hide activity indicators - PIN protection ✅ completed)
- Biometric unlock (Face ID/Touch ID/fingerprint) - infrastructure ready
- Statistics & Trends View (mood patterns, symptom frequency)
- Export Data (CSV/PDF download)
- Cycle predictions and insights based on historical data
- Task management system
- Daily affirmations
- Analytics and health trends
- Push notifications via Firebase Cloud Messaging

## Technology Stack

**Frontend**
- Flutter 3.35+ (RadioGroup widget support)
- Dart
- Material Design 3
- Google Fonts (Inter)
- Font Awesome Flutter icons

**Backend**
- Supabase (PostgreSQL database)
- Supabase Auth (authentication)
- Row-Level Security policies
- Firebase Cloud Messaging (planned)

**Security**
- flutter_secure_storage - Encrypted local storage
- crypto - SHA-256 PIN hashing
- local_auth - Biometric infrastructure (ready for future use)

**Architecture**
- Service layer pattern
- Riverpod state management (PIN lock, providers)
- Singleton pattern for API clients
- App lifecycle observers

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK
- A Supabase account (free tier available)
- Android Studio / VS Code / IntelliJ IDEA
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/lovely.git
cd lovely
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Configure Supabase:

   a. Copy the template configuration file:
   ```bash
   cp lib/config/supabase_config.dart.template lib/config/supabase_config.dart
   ```

   b. Edit `lib/config/supabase_config.dart` and add your credentials:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. Set up the database:
   - Follow the detailed instructions in [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
   - Run the SQL scripts to create tables and security policies
   - Configure email authentication settings

5. Run the application:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/
│   ├── supabase_config.dart           # Supabase credentials (gitignored)
│   └── supabase_config.dart.template  # Template for configuration
├── models/                             # Data models (to be implemented)
├── screens/
│   ├── auth/
│   │   ├── login.dart                 # Login screen
│   │   ├── signup.dart                # Registration screen
│   │   └── forgot_password.dart       # Password recovery
│   ├── main/
│   │   └── home_screen.dart           # Main dashboard
│   ├── onboarding/
│   │   └── onboarding_screen.dart     # First-time user setup
│   └── welcome_screen.dart            # Landing page
├── services/
│   └── supabase_service.dart          # API service layer
└── main.dart                           # Application entry point
```

## Configuration

### Environment Setup

The app requires a Supabase project. See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for:
- Database schema and table creation
- Row-Level Security (RLS) policy setup
- Authentication provider configuration
- Email template customization
- Testing procedures

### Theme Customization

The app uses a Coral Sunset color scheme:
- Primary: #FF6F61 (Vibrant Coral)
- Secondary: #FF8F7A (Soft Coral)
- Tertiary: #FFB3A0 (Peachy Pink)
- Background: #FFE5D4 (Very Light Peach)
- Dark mode: #121212 base with coral accents

## Security

- User credentials are never stored locally
- Supabase configuration file is excluded from version control
- Row-Level Security (RLS) ensures users can only access their own data
- All authentication flows use secure Supabase Auth APIs
- Password reset uses email verification

## Database Schema

See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for the complete schema. Main tables:

**users**
- id (UUID, references auth.users)
- email, name, date_of_birth
- average_cycle_length, average_period_length
- last_period_start, notifications_enabled
- created_at, updated_at

## Development Roadmap

### Phase 1: Foundation (Completed)
- [x] User authentication system
- [x] Onboarding flow
- [x] Profile data collection
- [x] Theme implementation
- [x] Accessibility foundation

### Phase 2: Core Features (In Progress)
- [x] Database schema (periods, symptoms, moods, cycles tables)
- [x] Data models (Period, Symptom, Mood, Cycle)
- [x] Period start/end logging with flow intensity
- [x] Symptom tracking interface (8 symptom types)
- [x] Mood tracking (7 emotional states)
- [x] Service layer methods (CRUD operations)
- [ ] Calendar view for cycle visualization
- [ ] Cycle predictions based on historical data

### Phase 3: Wellness Features
- [ ] Task management system
- [ ] Daily affirmations
- [ ] Reminder notifications
- [ ] Insights and tips based on cycle phase

### Phase 4: Analytics & Insights
- [ ] Cycle pattern analysis
- [ ] Health trend visualization
- [ ] Period history view
- [ ] Data export functionality
- [ ] Backup and sync

## Testing

Run tests with:
```bash
flutter test
```

Integration tests:
```bash
flutter test integration_test
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

Contributions are welcome. Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please ensure your code follows Flutter best practices and includes appropriate tests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Design inspiration from Flo and other period tracking apps
- Built with Flutter framework
- Powered by Supabase backend
- Icons provided by Font Awesome Flutter
- Typography using Google Fonts (Inter)

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing documentation in SUPABASE_SETUP.md
- Review the spec sheet in SPEC.md

## Author

Created and maintained by [Your Name]

- GitHub: [@yourusername](https://github.com/yourusername)
- LinkedIn: [Your LinkedIn Profile](https://linkedin.com/in/yourprofile)
- Email: your.email@example.com

---

**Note:** This application is under active development. Features and functionality are being continuously improved.
