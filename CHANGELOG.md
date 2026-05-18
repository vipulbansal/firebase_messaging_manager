## 0.0.2

* Renamed public API to `FirebaseMessagingManager` and `FirebaseMessagingManagerConfig` (with deprecated compatibility aliases).
* Added support for multiple Android notification channels with event-based channel resolution.
* Improved package and example documentation for callback behavior, local notification orchestration, and setup clarity.
* Updated pub.dev metadata links (`homepage`, `repository`, `issue_tracker`) to point to the GitHub repository.

## 0.0.1

* Introduced `FirebaseMessagingLifecycle` singleton for notification lifecycle orchestration.
* Added configurable dedupe support via `DuplicateStrategy` and `dedupeDuration`.
* Added typed `NotificationEvent` callbacks for foreground, tap, initial, and background flows.
* Added local notification orchestration with Android notification channel support.
* Added permission helper methods and comprehensive package README.
