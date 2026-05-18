import '../enums/duplicate_strategy.dart';
import '../models/firebase_messaging_lifecycle_config.dart';
import '../models/notification_event.dart';

class NotificationDeduplicator {
  NotificationDeduplicator(this._config);

  final FirebaseMessagingManagerConfig _config;
  final Map<String, DateTime> _handledNotifications = <String, DateTime>{};

  bool isDuplicate(NotificationEvent event, {DateTime? now}) {
    if (_config.duplicateStrategy == DuplicateStrategy.none) {
      return false;
    }

    final dedupeKey = _resolveDedupeKey(event);
    if (dedupeKey == null || dedupeKey.isEmpty) {
      return false;
    }

    final currentTime = now ?? DateTime.now();
    _cleanupExpiredEntries(currentTime);

    final previous = _handledNotifications[dedupeKey];
    if (previous == null) {
      _handledNotifications[dedupeKey] = currentTime;
      return false;
    }

    if (currentTime.difference(previous) <= _config.dedupeDuration) {
      return true;
    }

    _handledNotifications[dedupeKey] = currentTime;
    return false;
  }

  void clear() {
    _handledNotifications.clear();
  }

  void _cleanupExpiredEntries(DateTime now) {
    if (_handledNotifications.isEmpty) {
      return;
    }

    _handledNotifications.removeWhere((_, handledAt) {
      return now.difference(handledAt) > _config.dedupeDuration;
    });
  }

  String? _resolveDedupeKey(NotificationEvent event) {
    switch (_config.duplicateStrategy) {
      case DuplicateStrategy.none:
        return null;
      case DuplicateStrategy.messageId:
        return event.id ??
            '${event.title}|${event.body}|${event.data.toString()}|${event.appState.name}|${event.wasTapped}';
      case DuplicateStrategy.customKey:
        final key = _config.customDuplicateKey;
        if (key == null || key.isEmpty) {
          return event.id;
        }
        final value = event.data[key];
        return value?.toString() ?? event.id;
    }
  }
}
