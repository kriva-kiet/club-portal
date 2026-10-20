<div align="center">

# 🚀 KRIVA
### The Next-Generation Community & Ecosystem Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

*A full-stack, cross-platform mobile and web application built for seamless student & developer community management, peer-to-peer collaboration, structured learning, and organization governance.*

**Designed & Developed with ❤️ by [Abhisht Singh](https://github.com/Abhisht2000)**

---

</div>

## 📖 Overview

**KRIVA** is an all-in-one community ecosystem platform designed to streamline student onboarding, skills roadmaps, hackathon team matching, community engagement, and administrative governance. 

Built with **Flutter** and powered by **Firebase**, KRIVA delivers a fluid experience across Android, iOS, and Web with role-based access control, real-time database synchronization, dynamic theming, and intuitive dashboards.

---

## ✨ Key Features

### 👥 1. Multi-Portal Role-Based Access Control (RBAC)
- **Member Portal**: Access community roadmaps, peer chats, hackathon teams, streak milestones, and leaderboards.
- **Lead Hub**: Manage domain-specific teams, track assigned learners, host mentoring sessions, and broadcast updates.
- **Admin & Developer Portal**: Comprehensive analytics suite, member admissions, role assignment, complaint resolution, and profile verification workflows.

### 🗺️ 2. Structured Learning & Roadmaps
- Curated step-by-step technology roadmaps (Web, Mobile, Cloud, AI/ML, DevOps).
- Dynamic progress tracking with completion checkpoints.
- Community-driven curated learning resources and session scheduling.

### 🤝 3. Collaboration & Hackathons
- Discover ongoing hackathons and innovation challenges.
- In-app team discovery and automated team joining/recruitment requests.
- Showcase project portfolios and connect with peer collaborators.

### 🏆 4. Gamification & Streaks
- Daily active streaks with visual rewards and milestone badges.
- Global and domain-specific competitive leaderboards.
- Integrated skill quizzes with instant scoring and badge rewards.

### 🛡️ 5. Governance & Authority Board
- Transparent directory of leads, department heads, and club authorities.
- Private complaint submission and resolution tracking.
- Verified profile edit requests for credential authentication.

### 🎨 6. Modern Cyberpunk Dark UI
- Curated high-contrast palette featuring deep blacks (`#0A0A0A`) with crimson red & neon accents (`#E53935`).
- Smooth micro-animations powered by `flutter_animate` and `lottie`.
- Glassmorphism containers and adaptive layouts for mobile and web.

---

## 🏗️ Architecture & Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (Dart 3.11+) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev) |
| **Navigation & Routing** | [GoRouter](https://pub.dev/packages/go_router) |
| **Backend & Database** | [Firebase](https://firebase.google.com) (Firestore, Firebase Auth, Cloud Storage) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) + Web Service Workers + Local Notifications |
| **Data Visualization** | [FL Chart](https://pub.dev/packages/fl_chart) |
| **Typography & Icons** | [Google Fonts](https://fonts.google.com) (Outfit, Inter) + Cupertino Icons |
| **Platform Support** | Android, iOS, Web, macOS, Linux, Windows |

```
lib/
├── core/
│   ├── localization/         # Multi-language & string translations
│   ├── routing/              # GoRouter configuration & role guards
│   └── theme/                # Custom design system, typography & palette
├── features/
│   ├── admin/                # Admin dashboards, member moderation & charts
│   ├── auth/                 # Authentication, onboarding & profile setup
│   ├── authorities/          # Community authorities & directory
│   ├── collaboration/        # Team requests & project collaboration
│   ├── community/            # Feed, discussions & announcements
│   ├── complaints/           # Private grievance & dispute management
│   ├── dashboard/            # Personalized user home & quick actions
│   ├── lead/                 # Domain lead management workspace
│   ├── leaderboard/          # Rankings, achievements & badges
│   ├── quiz/                 # Standalone assessment module
│   ├── roadmap/              # Learning paths & resource modules
│   └── web/                  # Web-specific shells & responsive layouts
├── models/                   # Immutable data schemas & Firestore mappers
├── services/                 # Firebase Auth, Firestore repositories & notifications
└── widgets/                  # Reusable UI components & animations
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0` or later)
- [Dart SDK](https://dart.dev/get-dart)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- Android Studio / Xcode / VS Code with Flutter extensions

---

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kriva-kiet/club-portal.git
   cd club-portal
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Generate the platform configuration using the FlutterFire CLI:
   ```bash
   # Log in to your Firebase account
   firebase login

   # Configure your Flutter app with your Firebase project
   flutterfire configure
   ```
   > ℹ️ *Note: This will generate `lib/firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist` locally.*

4. **Web Push Notifications (Optional for Web):**
   If deploying on the web, ensure `web/firebase-messaging-sw.js` is populated with your Firebase Web configuration parameters.

5. **Run the App:**
   - **Android / iOS:**
     ```bash
     flutter run
     ```
   - **Web:**
     ```bash
     flutter run -d chrome
     ```

---

## 🔒 Security & Safe Development

- Real Firebase credentials (`google-services.json`, `GoogleService-Info.plist`, `lib/firebase_options.dart`) and service account files are strictly ignored by `.gitignore`.
- Ensure proper [Firestore Security Rules](firestore.rules) and [Storage Rules](storage.rules) are deployed to your Firebase environment before going to production:
  ```bash
  firebase deploy --only firestore:rules,storage
  ```

---

## 🤝 Contributing

Contributions are always welcome!
1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'feat: add some amazing feature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 📬 Contact & Support

**Abhisht Singh**  
- GitHub: [@Abhisht2000](https://github.com/Abhisht2000)
- Repository: [kriva-kiet/club-portal](https://github.com/kriva-kiet/club-portal)

