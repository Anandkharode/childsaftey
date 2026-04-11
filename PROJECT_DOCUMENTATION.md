# Child Safety App Documentation

## 1. Overview

This project is a Flutter mobile app for monitoring a child-carrying BLE device, likely an ESP32 beacon. The app supports:

- account registration and login with Firebase Authentication
- profile storage in Cloud Firestore
- a BLE scan/connect flow using `flutter_blue_plus`
- a dashboard that estimates child distance and heading
- safe-range alerts when the child crosses a configured distance boundary
- asset-based alert sound playback


At a high level, the app combines three systems:

1. Firebase for identity and child profile storage
2. GetX for routing, dependency injection, and reactive UI state
3. BLE services for realtime device communication

## 2. High-Level Architecture

### App layers

- `lib/main.dart`
  - initializes Flutter and Firebase
  - configures device orientation and system UI
  - starts `GetMaterialApp`
- `lib/app/routes/*`
  - defines named routes and page bindings
- `lib/app/modules/*`
  - contains feature-level UI and controller logic
- `lib/app/core/*`
  - shared styling and theme helpers
- `firebase_options.dart`
  - generated Firebase configuration per platform

### Main feature modules

- `splash`
  - shows startup progress and decides initial route
- `login`
  - signs in an existing Firebase user
- `signup`
  - creates a Firebase user and stores child profile data
- `main`
  - BLE tracking dashboard, boundary logic, and live status UI

## 3. Startup Flow

### File

- `lib/main.dart`

### What happens

1. Flutter bindings are initialized.
2. Firebase is initialized with `DefaultFirebaseOptions.currentPlatform`.
3. Portrait orientation is enforced.
4. `GetMaterialApp` is launched with `AppRoutes.splash` as the initial route.

### Why this matters

Every app session begins at the splash screen, so the splash controller is the correct place to decide whether to send the user to login or directly into the dashboard.

## 4. Authentication Flow

### Registration

### File

- `lib/app/modules/signup/signup_controller.dart`

### Sequence

1. User enters child name, email, and password.
2. `FirebaseAuth.instance.createUserWithEmailAndPassword(...)` creates the account.
3. The child name is copied into Firebase Auth via `user.updateDisplayName(...)`.
4. The same profile is stored in Firestore at `users/{uid}` with:
   - `uid`
   - `childName`
   - `email`
   - `createdAt`
   - `provider`
5. The user is routed to the main dashboard.

### Why child name is stored twice

- Firebase Auth `displayName`
  - useful as a quick profile fallback
- Firestore `childName`
  - better for custom profile fields and future expansion

This gives redundancy and makes UI personalization more reliable.

### Login

### File

- `lib/app/modules/login/login_controller.dart`

### Sequence

1. User enters email and password.
2. `signInWithEmailAndPassword(...)` authenticates with Firebase.
3. On success, GetX routes to `AppRoutes.main`.

### Logout

### Files

- `lib/app/modules/main/main_controller.dart`
- `lib/app/modules/main/main_view.dart`

### Sequence

1. User taps the logout button on the dashboard.
2. Firebase Auth signs out the active user.
3. The dashboard resets local BLE connection state.
4. The app routes back to `AppRoutes.login`.

### Session persistence

Firebase Auth already persists the signed-in user on mobile by default. That means the user usually should not need to log in every time the app opens.

The original issue was not that Firebase forgot the user. The issue was that the splash controller always redirected to `AppRoutes.login`, even when `FirebaseAuth.instance.currentUser` already existed.

### Fix applied

### File

- `lib/app/modules/splash/splash_controller.dart`

### Updated behavior

After the splash animation completes:

- if `FirebaseAuth.instance.currentUser == null`
  - route to login
- otherwise
  - route to main dashboard

This makes app reopen behavior match Firebase's built-in persistent session handling.

## 5. Dashboard Profile Flow

### Files

- `lib/app/modules/main/main_controller.dart`
- `lib/app/modules/main/main_view.dart`

### What happens now

When the dashboard controller starts:

1. it reads the currently signed-in Firebase user
2. it uses `displayName` as an immediate fallback child name
3. it reads `users/{uid}` from Firestore
4. if Firestore contains `childName`, that value overrides the fallback
5. the dashboard UI updates automatically through GetX reactive state

### UI areas using the child name

- dashboard subtitle
- status banner
- safe-range title
- radar legend label
- dashboard header beside the new logout action

Because `childName` is stored as an `RxString`, any widget wrapped in `Obx(...)` rebuilds automatically when the profile data arrives.

## 6. BLE Tracking Flow

### File

- `lib/app/modules/main/main_controller.dart`

### Reactive state used by the dashboard

- `distance`
  - estimated child distance in meters
- `headingAngle`
  - heading reported by the BLE device
- `directionLabel`
  - human-readable direction text
- `boundaryDistance`
  - user-set safe range threshold
- `isConnected`
  - current BLE connection status
- `isScanning`
  - scanning status
- `isBoundaryExceeded`
  - whether the child is outside the safe range
- `childName`
  - dashboard display name loaded from Firebase

### Controller startup sequence

In `onInit()`:

1. `loadChildProfile()` fetches the child name
2. `startBleScan()` begins Bluetooth setup and scanning

### BLE connection sequence

1. Request runtime permissions:
   - location
   - bluetooth scan
   - bluetooth connect
2. Ensure the Bluetooth adapter is on
3. Scan for a device named `ESP32_Compass`
4. Stop scan when found
5. Connect to the device
6. Discover services
7. Find the configured service UUID and characteristic UUID
8. Enable notifications
9. Listen to streamed BLE packets

### Expected BLE payload format

The code expects incoming UTF-8 payloads in a comma-separated format:

```text
heading,direction
```

Example:

```text
135.0,South-East
```

### Incoming data processing

For each BLE update:

1. decode bytes as UTF-8
2. split the string by comma
3. parse the first value as heading
4. parse the second value as a direction label
5. update UI observables
6. periodically call `readRssi()` to estimate physical distance

## 7. Distance Estimation Logic

### Source

- `lib/app/modules/main/main_controller.dart`

### Formula

The code estimates distance from RSSI using:

```text
distance = 10 ^ ((-59 - rssi) / 20)
```

This assumes:

- reference transmit power around `-59 dBm` at 1 meter this should be set after calibration only to get accurate d  distance
- path-loss factor approximately `2`

### Important limitation

This is an approximation, not precise indoor positioning. RSSI is affected by:

- walls
- phone orientation
- interference
- body blocking
- device antenna variation

So the displayed distance is best treated as an estimate for safety guidance, not exact measurement.

## 8. Boundary Alert Logic

### What it does

The controller compares:

- current estimated `distance`
- user-selected `boundaryDistance`

If the child crosses the threshold:

- `isBoundaryExceeded` changes
- a vibration alert pattern is triggered

### Alert behavior

- critical alert
  - several quick vibration pulses
  - app tries to play `assets/audio/boundary_alert.mp3`
- safe return alert
  - gentler vibration pattern

### Why `_previousBoundaryState` exists

Without state tracking, the app would trigger alerts continuously on every measurement while the child remains outside the boundary. The controller avoids this by only alerting when the safe/out-of-range state changes.

## 9. Asset Pipeline

### Files and folders

- `assets/images/app_icon.png`
- `assets/audio/boundary_alert.mp3`
- `pubspec.yaml`

### What happens

1. `pubspec.yaml` declares `assets/images/` and `assets/audio/`.
2. The launcher icon source image is `assets/images/app_icon.png`.
3. `flutter_launcher_icons` uses that image to generate Android and iOS app icons.
4. Boundary alert playback uses `assets/audio/boundary_alert.mp3`.
5. If the child crosses the configured boundary, the app plays that asset when available.

### How to update the alert sound

Put your sound file at:

- `assets/audio/boundary_alert.mp3`

Then run:

```bash
flutter pub get
```

### How to regenerate the app icon

After changing `assets/images/app_icon.png`, run:

```bash
dart run flutter_launcher_icons
```

## 10. UI Reactivity with GetX

### Pattern used

The app uses `Rx` observables such as:

```dart
final distance = 2.8.obs;
```

Widgets use `Obx(() { ... })` to rebuild automatically when those values change.

### Benefits

- no manual `setState()` needed in controllers
- dashboard updates live from BLE data
- profile name updates as soon as it is loaded

## 11. Navigation Model

### Files

- `lib/app/routes/app_routes.dart`
- `lib/app/routes/app_pages.dart`

### Routes

- `/`
  - splash
- `/login`
  - login page
- `/signup`
  - signup page
- `/main`
  - dashboard page

### Binding pattern

Each route has a binding that injects its controller when the page is opened. This keeps controller creation scoped to the feature page.

## 12. Low-Level Data Lifecycle

### From registration input to dashboard label

1. User types child name in signup form.
2. `SignupController` validates the form.
3. Firebase Auth account is created.
4. Child name is stored in:
   - Auth `displayName`
   - Firestore `users/{uid}.childName`
5. User enters the app.
6. On later app launches, splash checks `currentUser`.
7. If authenticated, splash routes directly to main.
8. `MainController.loadChildProfile()` loads the stored profile.
9. `childName` observable updates.
10. `Obx` widgets redraw with the registered child name.

### From BLE packet to dashboard radar

1. BLE notification arrives as raw bytes.
2. Raw bytes are decoded to text.
3. Heading and direction are parsed.
4. RSSI is read from the connected BLE device.
5. Approximate distance is calculated.
6. Dashboard observables update.
7. Text, signal bars, banner, and radar repaint automatically.
8. Boundary logic evaluates whether an alert should fire.

## 13. Files Most Important to Understand

- `lib/main.dart`
  - app bootstrapping
- `lib/app/modules/splash/splash_controller.dart`
  - startup routing and session reuse
- `lib/app/modules/login/login_controller.dart`
  - sign-in logic
- `lib/app/modules/signup/signup_controller.dart`
  - account creation and profile persistence
- `lib/app/modules/main/main_controller.dart`
  - BLE, distance calculation, alerts, logout, sound playback, and profile loading
- `lib/app/modules/main/main_view.dart`
  - live dashboard UI including connection and logout controls
- `pubspec.yaml`
  - dependencies, assets, and launcher icon configuration

