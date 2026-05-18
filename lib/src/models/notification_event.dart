import 'package:firebase_messaging/firebase_messaging.dart';

import '../enums/notification_app_state.dart';

class NotificationEvent {
  const NotificationEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.appState,
    required this.wasTapped,
    required this.rawMessage,
  });

  final String? id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final NotificationAppState appState;
  final bool wasTapped;
  final RemoteMessage rawMessage;

  factory NotificationEvent.fromRemoteMessage({
    required RemoteMessage message,
    required NotificationAppState appState,
    required bool wasTapped,
  }) {
    return NotificationEvent(
      id: message.messageId,
      title: message.notification?.title ?? message.data['title'] as String?,
      body: message.notification?.body ?? message.data['body'] as String?,
      data: Map<String, dynamic>.from(message.data),
      appState: appState,
      wasTapped: wasTapped,
      rawMessage: message,
    );
  }
}
