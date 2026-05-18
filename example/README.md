# firebase_messaging_manager example

This example demonstrates:

- initialization of `FirebaseMessagingManager`
- notification permission request/status checks
- token retrieval
- foreground/background/terminated callback logging
- duplicate-prevention strategy toggles
- multiple Android channels with category-based routing (`chat`, `marketing`)

## Run

1. Configure Firebase for this app (`android`, `ios`) with FlutterFire.
2. Ensure `Firebase.initializeApp()` is valid for your project setup.
3. Run:

```bash
fvm flutter pub get
fvm flutter run
```

## Manual test checklist

- Send push while app in foreground -> callback + optional local notification.
- Send push while app in background -> tap triggers notification tap callback.
- Kill app and open via push tap -> initial notification callback fires.
- Send duplicate payloads inside dedupe window -> second event is ignored.
- Send payload with `category: chat` -> local notification uses `chat_messages` channel.
- Send payload with `category: marketing` -> local notification uses `marketing_updates` channel.
