# Raheeq Main Application

## Overview
Raheeq is a comprehensive Flutter-based mobile application that provides robust functionalities including user authentication, real-time map integration, seamless payment processing, and in-app customer support. The app is localized in English and Arabic and features dynamic state management and persistent local storage.

## Features & Technologies Used
- **Framework**: Flutter SDK (>= 3.11.0)
- **State & Local Storage**: Hive, Hive Flutter
- **Networking**: Dio
- **Authentication**: Google Sign-In, Sign in with Apple, standard authentication flow.
- **Maps & Location**: Google Maps Flutter (`google_maps_flutter`)
- **Payments**: PayTabs integration (`flutter_paytabs_bridge`)
- **Push Notifications**: Firebase Messaging (`firebase_messaging`), Flutter Local Notifications (`flutter_local_notifications`)
- **Customer Support**: Freshchat SDK (`freshchat_sdk`)
- **Environment Management**: Flutter Dotenv (`flutter_dotenv`)
- **UI Components**: Shimmer effects, Lottie animations, DotLottie, FontAwesome, Material Symbols.
- **Localization**: English (`en`) and Arabic (`ar`) via `flutter_localizations` and `intl`.

## Project Structure
The core logic resides within the `lib/` directory:

- `lib/api/`: Handles network requests and API integration (Dio).
- `lib/common_widgets/`: Reusable UI components used across the app.
- `lib/l10n/`: Localization delegates and language files.
- `lib/models/`: Data models for serialization/deserialization.
- `lib/pages/`: Contains the main screens and UI workflows.
  - `splashScreen/`: App initialization UI.
  - `onboard/`: New user introduction.
  - `authentication/`: Login, registration, and social sign-in.
  - `home/`: The main dashboard and core features.
  - `order/`: Order management and checkout process.
- `lib/services/`: Background services including Firebase, Notifications, and Freshchat.
- `lib/storage/`: Local data persistence (Hive for `AuthStorage`).
- `lib/utils/`: Helper functions, extensions, and constants.

## Application Workflows

### 1. App Initialization & Splash Workflow
- **Entry Point (`main.dart`)**: The app initializes core Flutter bindings and immediately renders `SplashScreen()`.
- **Background Initialization**: While the splash screen is visible, heavy dependencies are initialized asynchronously:
  - `.env` variables are loaded.
  - `AuthStorage` (Hive) is initialized to check user session.
  - `Firebase` is initialized.
  - Notification permissions are requested and `NotificationService` is set up.
  - `Freshchat` is initialized with app credentials. If a user session exists, the user is identified in Freshchat.
- **Navigation**: Based on the `AuthStorage` state, the app navigates the user either to the Onboarding, Authentication, or Home screen.

### 2. Onboarding Workflow
- Located in `lib/pages/onboard/`.
- Designed for first-time users to introduce app features and value propositions.
- Completing the onboarding sets a flag in local storage to prevent it from showing on subsequent app launches.

### 3. Authentication Workflow
- Located in `lib/pages/authentication/`.
- **Methods**:
  - Email/Password login.
  - Google Sign-In (`google_sign_in`).
  - Apple Sign-In (`sign_in_with_apple`).
- **Session Management**: Upon successful authentication, a token/session is stored securely via `AuthStorage`. The `localeNotifier` and other global states may be updated.
- **Freshchat Link**: The authenticated user's ID/details are passed to Freshchat via `FreshchatService.identifyUser()` to link support chats to the specific user profile.

### 4. Main App & Home Workflow
- Located in `lib/pages/home/`.
- Once authenticated, users land on the main dashboard.
- Features include browsing items, viewing locations via Google Maps, and interacting with core app functionalities.
- **Localization**: Users can switch between English and Arabic, triggering an app-wide rebuild using `ValueListenableBuilder<Locale>`.

### 5. Ordering & Payment Workflow
- Located in `lib/pages/order/`.
- Users can add items to their cart and proceed to checkout.
- **Payment Gateway**: The app utilizes `flutter_paytabs_bridge` to handle secure transactions.
- Once an order is placed, an API request is made via `Dio`, and the user is presented with an order confirmation screen.

### 6. Notifications & Customer Support Workflow
- **Push Notifications**: Handled by `Firebase Messaging`. Background and foreground messages are intercepted and displayed using `flutter_local_notifications`.
- **In-App Chat**: Users can initiate a support chat from the app interface. This opens the Freshchat UI, where their session is already authenticated and linked to their account.

## Setup & Run Instructions

1. **Environment Configuration**:
   Create a `.env` file at the project root based on the provided assets configuration with the following keys:
   ```env
   FRESHCHAT_APP_ID=your_freshchat_app_id
   FRESHCHAT_APP_KEY=your_freshchat_app_key
   FRESHCHAT_DOMAIN=your_freshchat_domain
   # Add other required API keys (e.g., Maps, PayTabs) here
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   ```

3. **Run the Application**:
   ```bash
   flutter run
   ```

## Assets
The project utilizes specific assets declared in `pubspec.yaml`:
- Fonts: `SF Pro` (Regular, Medium, Bold)
- Images & Icons: Located in `assets/`, `assets/onboarding/`, `assets/login/`, `assets/masjid/`
- `.env` file for secure configuration.
