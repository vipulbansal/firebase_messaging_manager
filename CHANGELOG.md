## 0.0.1

* Introduced `FirebaseMessagingLifecycle` singleton for notification lifecycle orchestration.
* Added configurable dedupe support via `DuplicateStrategy` and `dedupeDuration`.
* Added typed `NotificationEvent` callbacks for foreground, tap, initial, and background flows.
* Added local notification orchestration with Android notification channel support.
* Added permission helper methods and comprehensive package README.
