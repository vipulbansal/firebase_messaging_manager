# firebase_messaging_manager

A production-safe Firebase Messaging lifecycle manager for Flutter that helps you:

- handle foreground, background, and terminated notification flows
- orchestrate `firebase_messaging` with `flutter_local_notifications`
- prevent duplicate notifications using configurable dedupe strategies
- request and check notification permissions on Android and iOS
- receive unified typed notification events through clean callbacks

## Features

- Notification lifecycle handling (foreground, background, terminated)
- Notification tap handling from background and terminated launch
- Duplicate notification prevention (`none`, `messageId`, `customKey`)
- Configurable dedupe duration
- Local notification orchestration with Android notification channels
- Unified `NotificationEvent` model for all callbacks
- Optional debug logs

## Installation

Add the package:

```yaml
dependencies:
  firebase_messaging_manager: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Firebase Setup

### 1) Add Firebase to your app

Set up Firebase for Android and iOS in your app using the official Firebase docs:

- [FlutterFire setup](https://firebase.google.com/docs/flutter/setup)
- [Firebase Cloud Messaging setup](https://firebase.google.com/docs/cloud-messaging/flutter/client)

Recommended CLI flow:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 2) Initialize Firebase before using messaging

```dart
await Firebase.initializeApp();
```

## Android Setup

1) Add notification permission for Android 13+ in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

2) Ensure internet permission exists:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

3) Keep a valid launcher icon (`@mipmap/ic_launcher`) or pass a custom icon via `androidNotificationIcon`.

4) Keep notification channel IDs stable in production (`androidChannelId`, `androidChannelName`).

## iOS Setup

1) In Xcode (`ios/Runner.xcworkspace`) enable capabilities:
- Push Notifications
- Background Modes -> Remote notifications

2) Ensure APNs is configured in Firebase Console (key or certificate).

3) In `ios/Runner/Info.plist`, ensure notification usage descriptions are present for your app if needed by your compliance/review flow.

4) For iOS foreground delivery behavior, this package sets:
- alert: true
- badge: true
- sound: true

## Quick Start

```dart
import 'package:firebase_messaging_manager/firebase_messaging_manager.dart';

Future<void> initializePushNotifications() async {
  await FirebaseMessagingManager.instance.initialize(
    config: const FirebaseMessagingManagerConfig(
      requestPermission: true,
      showForegroundNotifications: true,
      showBackgroundNotifications: false,
      duplicateStrategy: DuplicateStrategy.messageId,
      dedupeDuration: Duration(seconds: 10),
      androidChannelId: 'high_importance_notifications',
      androidChannelName: 'High Importance Notifications',
      additionalAndroidChannels: <AndroidNotificationChannelConfig>[
        AndroidNotificationChannelConfig(
          id: 'chat_messages',
          name: 'Chat Messages',
          description: 'Conversation and message alerts',
        ),
        AndroidNotificationChannelConfig(
          id: 'marketing_updates',
          name: 'Marketing Updates',
          description: 'Promotions and offers',
        ),
      ],
      enableLogs: true,
    ),
    onForegroundMessage: (event) async {
      // Update UI, badges, in-app state, etc.
    },
    onNotificationTap: (event) async {
      // Route user to a screen using event.data
    },
    onInitialNotification: (event) async {
      // Handle terminated -> app launched from notification tap
    },
    onBackgroundMessage: (event) async {
      // Handle data-only background processing if needed
    },
  );
}
```

### Multiple Android Channels (Categories)

For apps with categories (chat, marketing, orders, alerts), you can register multiple channels and route events to a specific channel:

```dart
await FirebaseMessagingManager.instance.initialize(
  config: FirebaseMessagingManagerConfig(
    androidChannelId: 'general',
    androidChannelName: 'General',
    additionalAndroidChannels: const [
      AndroidNotificationChannelConfig(id: 'chat', name: 'Chat'),
      AndroidNotificationChannelConfig(id: 'orders', name: 'Orders'),
      AndroidNotificationChannelConfig(id: 'marketing', name: 'Marketing'),
    ],
    resolveAndroidChannelId: (event) {
      final type = event.data['type']?.toString();
      if (type == 'chat') return 'chat';
      if (type == 'order') return 'orders';
      if (type == 'marketing') return 'marketing';
      return null; // falls back to default channel
    },
  ),
);
```

## What `initialize(...)` Actually Does

When you call `FirebaseMessagingManager.instance.initialize(...)`, the package:

- optionally requests notification permission (`requestPermission: true`)
- configures iOS foreground presentation options
- initializes local notification support (`flutter_local_notifications`)
- creates the configured Android notification channel
- registers FCM listeners for foreground, tap-from-background, and terminated-launch flows
- registers background message handling
- normalizes all incoming events to `NotificationEvent`
- applies duplicate-prevention checks before invoking callbacks

## Local Notification Behavior (Important)

This package is not only callback wiring. It also orchestrates local notifications.

- If `showForegroundNotifications` is `true`, foreground messages can trigger a local notification.
- If `showBackgroundNotifications` is `true`, background data-only messages can trigger a local notification.
- Android local notifications use `androidChannelId` and `androidChannelName`.
- Duplicate checks are applied before callbacks and local-notification display.

In short: callbacks are hooks for your app logic, while display/orchestration can be handled by package config.

## Callback Behavior (Who Does What)

### `onForegroundMessage`
- Trigger: FCM message while app is in foreground.
- Package: normalize -> dedupe -> optionally show local notification.
- Your callback: app logic (update UI, refresh data, analytics, etc.).

### `onNotificationTap`
- Trigger: user taps notification and app opens from background.
- Package: normalize -> dedupe.
- Your callback: navigation/routing/business logic.

### `onInitialNotification`
- Trigger: app launched from terminated state via notification tap.
- Package: normalize -> dedupe.
- Your callback: startup routing/deeplink handling.
- Fallback: if not provided, package falls back to `onNotificationTap`.

### `onBackgroundMessage`
- Trigger: background message handler path.
- Package: normalize -> dedupe -> optional local notification for data-only payloads (when enabled).
- Your callback: background-safe app work (sync/cache/light processing).

## Integration Checklist

- Call `WidgetsFlutterBinding.ensureInitialized()` before Firebase init.
- Call `Firebase.initializeApp()` before lifecycle manager init.
- Initialize `FirebaseMessagingManager` once during app startup.
- Register callbacks for foreground/tap/initial/background states.
- Verify dedupe strategy against your payload shape (`messageId` or custom key).
- Test on real devices for both Android and iOS.

## Notification Event Model

All callbacks use `NotificationEvent`:

```dart
class NotificationEvent {
  final String? id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final NotificationAppState appState;
  final bool wasTapped;
  final RemoteMessage rawMessage;
}
```

## Duplicate Prevention

Choose strategy from `FirebaseMessagingManagerConfig`:

- `DuplicateStrategy.none`: no dedupe
- `DuplicateStrategy.messageId`: dedupe by FCM message ID (fallback fingerprint if ID missing)
- `DuplicateStrategy.customKey`: dedupe by a payload key (`customDuplicateKey`)

Example:

```dart
const FirebaseMessagingManagerConfig(
  duplicateStrategy: DuplicateStrategy.customKey,
  customDuplicateKey: 'notification_id',
  dedupeDuration: Duration(seconds: 15),
);
```

## Foreground, Background, Terminated Behavior

- **Foreground**: `onMessage` is normalized to `NotificationEvent`; local notification can be shown.
- **Background**: tap events are delivered through `onNotificationTap`.
- **Terminated**: launch payload is delivered through `onInitialNotification`.

## Permissions

You can let the package request permission during initialization or call helpers manually:

```dart
final status = await FirebaseMessagingManager.instance.getPermissionStatus();
final settings = await FirebaseMessagingManager.instance.requestPermission();
```

## Common Issues

- No notifications on iOS: verify APNs key/cert and iOS capabilities.
- No foreground banners: ensure `showForegroundNotifications` is `true`.
- Duplicate messages: choose a stricter dedupe strategy and verify payload identifiers.
- Tap callbacks not firing: ensure `initialize()` is called once early in app startup.
- Data-only background flow not observed: verify payload is truly data-only and app/background constraints are satisfied.

## FAQ

### Does this replace Firebase Messaging?
No. It wraps `firebase_messaging` and `flutter_local_notifications` into a cleaner lifecycle API.

### Can I still access raw `RemoteMessage`?
Yes, each `NotificationEvent` includes `rawMessage`.

### Is this package opinionated about routing?
No, routing decisions stay in your callback handlers.

## Roadmap

- Additional sample scenarios in `example/` (routing and state restoration)
- More advanced Android/iOS platform customization
- Expanded testing for lifecycle edge cases
