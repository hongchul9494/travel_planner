## Project Blueprint: AdMob & Firebase Integration

### 1. Overview

This document outlines the plan to fix AdMob integration by correctly setting up the required Firebase dependency. The primary issue is a build failure caused by a missing Firebase configuration file (`google-services.json`), which prevents the Google Mobile Ads (GMA) SDK from initializing alongside Firebase.

### 2. Style, Design, and Features (Current State)

- **Initial App**: A basic Flutter application.
- **AdMob Integration (Attempted)**: The `google_mobile_ads` package is installed, and the Dart code for a banner ad is correctly implemented using a `StatefulWidget`.
- **Firebase Dependency (Incomplete)**: `firebase_core` and `firebase_analytics` have been added to `pubspec.yaml`, and Gradle files have been updated. However, the build fails because the project is not linked to a Firebase project via `google-services.json`.

### 3. Plan for Current Change: Finalize Firebase Setup

The goal is to resolve the Gradle build error and display a test banner ad.

1.  **Add Firebase Dependencies**:
    -   `firebase_core`: Added.
    -   `firebase_analytics`: Added.
2.  **Configure Android Gradle Files**:
    -   Update project-level `build.gradle.kts` to include the `google-services` plugin classpath. (Done)
    -   Update app-level `build.gradle.kts` to apply the plugin and add the Firebase BoM. (Done)
3.  **Link to Firebase Project (Action Required by User)**:
    -   The user must download the `google-services.json` file from their Firebase project console.
    -   The file must be placed in the `android/app/` directory.
4.  **Verify Implementation**:
    -   Run `flutter run` to confirm the build succeeds and the app launches.
    -   Confirm that the test banner ad is now visible in the running application.
