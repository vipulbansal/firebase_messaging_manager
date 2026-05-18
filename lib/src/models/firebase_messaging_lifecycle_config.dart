import '../enums/duplicate_strategy.dart';
import 'android_notification_channel_config.dart';
import 'notification_event.dart';

typedef AndroidChannelIdResolver = String? Function(NotificationEvent event);

class FirebaseMessagingManagerConfig {
  const FirebaseMessagingManagerConfig({
    this.requestPermission = true,
    this.showForegroundNotifications = true,
    this.showBackgroundNotifications = false,
    this.duplicateStrategy = DuplicateStrategy.messageId,
    this.customDuplicateKey,
    this.dedupeDuration = const Duration(seconds: 10),
    this.androidChannelId = 'firebase_messaging_manager_default_channel',
    this.androidChannelName = 'General Notifications',
    this.androidChannelDescription = 'Default notification channel.',
    this.additionalAndroidChannels = const <AndroidNotificationChannelConfig>[],
    this.resolveAndroidChannelId,
    this.androidNotificationIcon = '@mipmap/ic_launcher',
    this.enableLogs = false,
  });

  final bool requestPermission;
  final bool showForegroundNotifications;
  final bool showBackgroundNotifications;
  final DuplicateStrategy duplicateStrategy;
  final String? customDuplicateKey;
  final Duration dedupeDuration;
  final String androidChannelId;
  final String androidChannelName;
  final String androidChannelDescription;
  final List<AndroidNotificationChannelConfig> additionalAndroidChannels;
  final AndroidChannelIdResolver? resolveAndroidChannelId;
  final String androidNotificationIcon;
  final bool enableLogs;
}

@Deprecated(
  'Use FirebaseMessagingManagerConfig instead. '
  'This alias will be removed in a future major release.',
)
typedef FirebaseMessagingLifecycleConfig = FirebaseMessagingManagerConfig;
