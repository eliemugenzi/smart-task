# SmartTask - Task Management App

Welcome to **SmartTask**, a modern task management application built with Flutter. This app helps users create, manage, and track tasks with due date reminders, assignee management, and filtering capabilities. This README provides an overview of the tech stack, setup instructions, and key features to get you started.

---

## Table of Contents
- [Tech Stack](#tech-stack)
- [Setup Instructions](#setup-instructions)
- [Features](#features)
- [Contributing](#contributing)
- [License](#license)

---

## Tech Stack

### Frontend
- **Flutter**: Cross-platform framework for building native Android and iOS apps using Dart.
- **Dart**: Programming language for Flutter, used for app logic and UI development.
- **GoRouter**: Navigation package for managing app routes and navigation.

### Backend & Data
- **SQLite**: Local database (via `sqflite`) for storing tasks, assignees, and metadata.
- **Firebase Cloud Messaging (FCM)**: For push notifications (Android setup completed, iOS in progress).
- **SharedPreferences**: For storing user authentication tokens and data locally.

### Dependencies
- `firebase_core: ^2.24.2`
- `firebase_messaging: ^14.7.10`
- `flutter_local_notifications: ^16.3.0`
- `timezone: ^0.9.2`
- `sqflite: ^2.3.0`
- `path: ^1.8.0`
- `go_router: ^10.1.2`
- `intl: ^2.0.0`
- `shared_preferences: ^2.0.15`

### Tools
- **Android Studio / VS Code**: IDEs for Flutter development.
- **FlutterFire CLI** (optional, manual Firebase setup used): For configuring Firebase (not currently working on your setup, manual configuration provided instead).
- **Gradle (Kotlin DSL)**: For Android build configuration.

---

## Setup Instructions

Follow these steps to set up and run the SmartTask project locally on your machine:

### Prerequisites
- **Flutter SDK**: Install Flutter from [flutter.dev](https://flutter.dev/docs/get-started/install). Verify installation with:
```bash
  flutter --version
```

``Dart SDK``: Included with Flutter, but ensure it’s up-to-date.
``Android Studio / Xcode``: For Android and iOS development, respectively.
- Android: Install Android SDK (API 21 or higher) and configure an emulator or connect a device.
- iOS: Install Xcode (macOS only) and configure an iPhone simulator or device.
``Node.js and npm (optional)``: For Firebase setup, if you decide to reintegrate Firebase CLI later.
``Firebase Account``: For push notifications and optional backend integration (manual setup provided).

### Installation

- Install Flutter dependencies:

```bash
flutter pub get
```

### Setup firebase(Android)

- Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
- Register your Android app:  Enter your package name `com.example.smarttask` from `android/app/build.gradle.kts`, download `google-services.json` and place it in `android/app` directory
- Configure Firebase in `lib/firebase_options.dart` with your project details(see below)

### Configure Firebase options
- Update `lib/firebase_options.dart` with your firebase configuration

```dart
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    androidClientId: 'YOUR_ANDROID_CLIENT_ID', // Optional
  );
}
```
- Obtain these values from Firebase Console > Project Settings > General(see previous instructions for details)

### Configure Android Build

- Ensure `android/build.gradle.kts` and `android/app/build.gradle.kts` are configured for Firebase and core library desugaring
- Project level `android/build.gradle.kts`

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

- App level `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
}

android {
    compileSdk = 33

    defaultConfig {
        applicationId = "com.example.smarttask"
        minSdk = 21
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

### Run the app

- Connect an Android/iOS device or start an emulator:
```bash
flutter emulators --launch <emulator-name>
```

- Run the app

```bash
flutter run --verbose
```

## Features

### Task Management:
- Create, update, and delete tasks with titles, descriptions, due dates, statuses (pending, in progress, completed), priorities (low, medium, high), tags, and assignees.
- Filter tasks by title, due date, priority, and tags.
### Assignee Management:
- Add and remove assignees to tasks, fetched from an API and stored locally with initials displayed.
- Mark the current user with "(You)" in assignee lists for clarity.
### Due Date Reminders:
- Receive push notifications 15 minutes before a task’s due date (Android implemented, iOS pending).
- Local notifications scheduled via ``flutter_local_notifications`` and Firebase Cloud Messaging.
### User Authentication:
Login and signup screens with email/password authentication, stored in ``SharedPreferences``.
Splash screen with animated welcome message and navigation to login/signup.
### Responsive Design:
- Optimized for both Android and iOS, with reusable components for buttons, text fields, and app bars.
- Adaptive layouts for various screen sizes using Flutter’s ``MediaQuery`` and ``SafeArea``.
### Offline Support:
- Tasks stored in a local SQLite database, synced with a backend.

