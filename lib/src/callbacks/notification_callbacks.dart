import '../models/notification_event.dart';

typedef NotificationEventCallback =
    Future<void> Function(NotificationEvent event);
