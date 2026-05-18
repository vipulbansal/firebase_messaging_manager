import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/android_notification_channel_config.dart';
import '../models/firebase_messaging_lifecycle_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingManagerNotificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  // Intentionally left empty. Keep this entry-point so background taps
  // do not get stripped in release builds.
}

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FirebaseMessagingManagerConfig? _config;
  final Map<String, AndroidNotificationChannelConfig> _androidChannels =
      <String, AndroidNotificationChannelConfig>{};
  bool _isInitialized = false;

  Future<void> initialize(FirebaseMessagingManagerConfig config) async {
    if (_isInitialized) {
      return;
    }

    _config = config;

    final androidSettings = AndroidInitializationSettings(
      config.androidNotificationIcon,
    );
    const iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveBackgroundNotificationResponse:
          firebaseMessagingManagerNotificationTapBackground,
    );

    _cacheAndroidChannels(config);
    await _createAndroidChannels();
    _isInitialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? androidChannelId,
    String? payload,
  }) async {
    final config = _config;
    if (!_isInitialized || config == null) {
      return;
    }

    final selectedChannel = _resolveAndroidChannel(config, androidChannelId);
    final androidDetails = AndroidNotificationDetails(
      selectedChannel.id,
      selectedChannel.name,
      channelDescription: selectedChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _cacheAndroidChannels(FirebaseMessagingManagerConfig config) {
    _androidChannels
      ..clear()
      ..[config.androidChannelId] = AndroidNotificationChannelConfig(
        id: config.androidChannelId,
        name: config.androidChannelName,
        description: config.androidChannelDescription,
      );

    for (final channel in config.additionalAndroidChannels) {
      _androidChannels[channel.id] = channel;
    }
  }

  AndroidNotificationChannelConfig _resolveAndroidChannel(
    FirebaseMessagingManagerConfig config,
    String? channelId,
  ) {
    if (channelId != null) {
      final match = _androidChannels[channelId];
      if (match != null) {
        return match;
      }
    }

    return _androidChannels[config.androidChannelId] ??
        AndroidNotificationChannelConfig(
          id: config.androidChannelId,
          name: config.androidChannelName,
          description: config.androidChannelDescription,
        );
  }

  Future<void> _createAndroidChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin == null) {
      return;
    }

    for (final channel in _androidChannels.values) {
      final androidChannel = AndroidNotificationChannel(
        channel.id,
        channel.name,
        description: channel.description,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }
}
