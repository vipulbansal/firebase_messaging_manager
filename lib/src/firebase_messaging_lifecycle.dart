import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'callbacks/notification_callbacks.dart';
import 'enums/notification_app_state.dart';
import 'models/firebase_messaging_lifecycle_config.dart';
import 'models/notification_event.dart';
import 'services/local_notification_service.dart';
import 'utilities/notification_deduplicator.dart';

class FirebaseMessagingManager {
  FirebaseMessagingManager._();

  static final FirebaseMessagingManager instance = FirebaseMessagingManager._();

  FirebaseMessagingManagerConfig _config =
      const FirebaseMessagingManagerConfig();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  NotificationDeduplicator _deduplicator = NotificationDeduplicator(
    const FirebaseMessagingManagerConfig(),
  );

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;

  NotificationEventCallback? _onForegroundMessage;
  NotificationEventCallback? _onNotificationTap;
  NotificationEventCallback? _onInitialNotification;
  NotificationEventCallback? _onBackgroundMessage;

  bool _isInitialized = false;

  Future<void> initialize({
    FirebaseMessagingManagerConfig config =
        const FirebaseMessagingManagerConfig(),
    NotificationEventCallback? onForegroundMessage,
    NotificationEventCallback? onNotificationTap,
    NotificationEventCallback? onInitialNotification,
    NotificationEventCallback? onBackgroundMessage,
  }) async {
    _config = config;
    _onForegroundMessage = onForegroundMessage;
    _onNotificationTap = onNotificationTap;
    _onInitialNotification = onInitialNotification;
    _onBackgroundMessage = onBackgroundMessage;
    _deduplicator = NotificationDeduplicator(config);

    if (_isInitialized) {
      _log('initialize called again; updating callbacks only.');
      return;
    }

    if (_config.requestPermission) {
      await requestPermission();
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _localNotificationService.initialize(_config);

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    _onMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTapFromBackground,
    );

    _isInitialized = true;
    _log('FirebaseMessagingManager initialized.');

    await handleInitialMessage();
  }

  Future<NotificationSettings> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    _log('Permission status: ${settings.authorizationStatus.name}');
    return settings;
  }

  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<String?> getToken() {
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> handleInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) {
        return;
      }

      final event = NotificationEvent.fromRemoteMessage(
        message: message,
        appState: NotificationAppState.terminated,
        wasTapped: true,
      );

      if (_isDuplicate(event)) {
        _log('Initial notification ignored (duplicate): ${event.id}');
        return;
      }

      _log('Initial notification handled: ${event.id}');
      if (_onInitialNotification != null) {
        await _onInitialNotification!(event);
      } else if (_onNotificationTap != null) {
        await _onNotificationTap!(event);
      }
    } catch (error, stackTrace) {
      _logError('Failed to handle initial message.', error, stackTrace);
    }
  }

  Future<void> dispose() async {
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedSubscription?.cancel();
    _onMessageSubscription = null;
    _onMessageOpenedSubscription = null;
    _deduplicator.clear();
    _isInitialized = false;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final event = NotificationEvent.fromRemoteMessage(
      message: message,
      appState: NotificationAppState.foreground,
      wasTapped: false,
    );

    if (_isDuplicate(event)) {
      _log('Foreground message ignored (duplicate): ${event.id}');
      return;
    }

    _log('Foreground message received: ${event.id}');

    if (_config.showForegroundNotifications) {
      final title = event.title;
      final body = event.body;
      if (title != null && body != null) {
        final channelId = _resolveAndroidChannelId(event);
        await _localNotificationService.showNotification(
          title: title,
          body: body,
          androidChannelId: channelId,
          payload: jsonEncode(event.data),
        );
        _log('Foreground local notification shown for: ${event.id}');
      }
    }

    if (_onForegroundMessage != null) {
      await _onForegroundMessage!(event);
    }
  }

  Future<void> _handleNotificationTapFromBackground(
    RemoteMessage message,
  ) async {
    final event = NotificationEvent.fromRemoteMessage(
      message: message,
      appState: NotificationAppState.background,
      wasTapped: true,
    );

    if (_isDuplicate(event)) {
      _log('Background tap ignored (duplicate): ${event.id}');
      return;
    }

    _log('Notification tapped from background: ${event.id}');
    if (_onNotificationTap != null) {
      await _onNotificationTap!(event);
    }
  }

  bool _isDuplicate(NotificationEvent event) {
    return _deduplicator.isDuplicate(event);
  }

  String? _resolveAndroidChannelId(NotificationEvent event) {
    final resolver = _config.resolveAndroidChannelId;
    if (resolver == null) {
      return null;
    }
    return resolver(event);
  }

  void _log(String message) {
    if (_config.enableLogs && kDebugMode) {
      debugPrint('[firebase_messaging_manager] $message');
    }
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    if (_config.enableLogs && kDebugMode) {
      debugPrint('[firebase_messaging_manager] $message Error: $error');
      debugPrint('[firebase_messaging_manager] StackTrace: $stackTrace');
    }
  }
}

@Deprecated(
  'Use FirebaseMessagingManager instead. '
  'This alias will be removed in a future major release.',
)
class FirebaseMessagingLifecycle {
  FirebaseMessagingLifecycle._();

  static FirebaseMessagingManager get instance =>
      FirebaseMessagingManager.instance;
}

final FirebaseMessagingManager firebaseMessagingManager =
    FirebaseMessagingManager.instance;

@Deprecated(
  'Use firebaseMessagingManager instead. '
  'This alias will be removed in a future major release.',
)
final FirebaseMessagingManager firebaseMessagingLifecycle =
    FirebaseMessagingManager.instance;

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  final manager = FirebaseMessagingManager.instance;
  final event = NotificationEvent.fromRemoteMessage(
    message: message,
    appState: NotificationAppState.background,
    wasTapped: false,
  );

  if (manager._isDuplicate(event)) {
    manager._log('Background message ignored (duplicate): ${event.id}');
    return;
  }

  manager._log('Background message received: ${event.id}');

  if (manager._config.showBackgroundNotifications &&
      message.notification == null &&
      event.title != null &&
      event.body != null) {
    final channelId = manager._resolveAndroidChannelId(event);
    await manager._localNotificationService.showNotification(
      title: event.title!,
      body: event.body!,
      androidChannelId: channelId,
      payload: jsonEncode(event.data),
    );
  }

  if (manager._onBackgroundMessage != null) {
    await manager._onBackgroundMessage!(event);
  }
}
