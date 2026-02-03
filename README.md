<div align="center">
  <img src="https://raw.githubusercontent.com/FortAwesome/Font-Awesome/master/svgs/solid/heart.svg" width="80" height="80" />
  <h1>Lovely</h1>
  <p><strong>A Modern, Compassionate Wellness & Period Tracking Ecosystem</strong></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
  [![Material Design](https://img.shields.io/badge/Material-3-757575?logo=materialdesign&logoColor=white)](https://m3.material.io)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
</div>

---

## 🌸 Overview

**Lovely** is not just a period tracker; it's a supportive companion for the modern woman. Built with a "Privacy First, Warmth Always" philosophy, Lovely combines clinical accuracy with a premium, glassmorphic aesthetic to empower users throughout their unique wellness journeys.

## ✨ Key Features

### 📅 Advanced Cycle Intelligence
- **Intelligent Tracking**: Log period starts, ends, and flow intensity with a single tap.
- **Dynamic Dashboard**: Visual overview of your current phase with color-coded insights.
- **Full-Spectrum Calendar**: Responsive monthly views with integrated mood and intimacy indicators.

### 🛡️ Premium Security & Privacy
- **App PIN Lock**: Banking-grade security with SHA-256 hashing and encrypted local storage.
- **Auto-Security**: Intelligent session management with 30-minute auto-logout and background locking.
- **Privacy Mode**: Discretely hide sensitive indicators in public views.

### 💖 Personalized Experience
- **Medically-Backed Insights**: Daily health tips curated by medical professionals, tailored to your cycle phase.
- **Premium Dashboard**: A stunning, glassmorphic profile hub with dynamic progress rings.
- **Social Integration**: Seamless, secure authentication via Google and Apple OAuth.
- **Deep Linking**: Integrated redirection for verified email and social auth flows.

### 📊 Data & Wellness
- **Multidimensional Logging**: Track 7+ moods and 8+ physical symptoms on a granular scale.
- **Intimacy Tracking**: Log protected and unprotected activity with dedicated safety indicators.
- **Export Capabilities**: Download your entire history in professional CSV formats for medical consultation.

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Frontend** | Flutter 3.35+ (Dart), Material 3, Google Fonts |
| **State Management** | Riverpod (for security & user preference states) |
| **Backend** | Supabase (PostgreSQL, Auth, RLS, Storage) |
| **Native Integration** | AppLinks (Deep Linking), Secure Storage, Local Auth |
| **Design System** | Custom "Coral Sunset" theme with Glassmorphism |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.35.0`
- Supabase Account
- Android Studio / VS Code

### Installation

1. **Clone & Install**
   ```bash
   git clone https://github.com/mwendwa-will/lovely.git
   cd lovely
   flutter pub get
   ```

2. **Configure Supabase**
   - Create a project on [Supabase.com](https://supabase.com).
   - Copy `lib/config/supabase_config.dart.template` to `lib/config/supabase_config.dart`.
   - Update with your `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

3. **Initialize Database**
   - Run the provided SQL migrations in `SUPABASE_SETUP.md` to configure tables and **Row-Level Security (RLS)**.

4. **Run App**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

Lovely follows a strict **Layered Service Pattern** for scalability and maintainability:
- **Presentation**: Reactive UI built with Riverpod providers.
- **Service Layer**: Business logic (AuthService, TipService, PinService).
- **Repository Layer**: Data access patterns and API integrations (AuthRepository).
- **Core**: Shared exceptions, constants (AppColors), and responsive utilities.

## 🤝 Contributing

We welcome contributions that align with our goal of empowering women's health. Please review our [DESIGN_GUIDELINES.md](DESIGN_GUIDELINES.md) before submitting pull requests to ensure aesthetic consistency.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
<div align="center">
  <p>Built with ❤️ for dignity, care, and wellness.</p>
</div>
