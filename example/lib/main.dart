import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_manager/firebase_messaging_manager.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging Manager Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const MessagingDemoPage(),
    );
  }
}

class MessagingDemoPage extends StatefulWidget {
  const MessagingDemoPage({super.key});

  @override
  State<MessagingDemoPage> createState() => _MessagingDemoPageState();
}

class _MessagingDemoPageState extends State<MessagingDemoPage> {
  final List<String> _logs = <String>[];
  final TextEditingController _customKeyController = TextEditingController(
    text: 'notification_id',
  );

  DuplicateStrategy _strategy = DuplicateStrategy.messageId;
  String _customKey = 'notification_id';
  bool _showForegroundNotifications = true;
  bool _showBackgroundNotifications = false;
  bool _initialized = false;
  AuthorizationStatus? _permissionStatus;
  String? _token;

  void _addLog(String text) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String()}  $text');
    });
  }

  Future<void> _initializeManager() async {
    final config = FirebaseMessagingManagerConfig(
      requestPermission: true,
      showForegroundNotifications: _showForegroundNotifications,
      showBackgroundNotifications: _showBackgroundNotifications,
      duplicateStrategy: _strategy,
      customDuplicateKey:
          _strategy == DuplicateStrategy.customKey ? _customKey : null,
      dedupeDuration: const Duration(seconds: 12),
      androidChannelId: 'fmm_example_channel',
      androidChannelName: 'FMM Example Notifications',
      androidChannelDescription:
          'Used by the firebase_messaging_manager example',
      additionalAndroidChannels: <AndroidNotificationChannelConfig>[
        AndroidNotificationChannelConfig(
          id: 'chat_messages',
          name: 'Chat Messages',
          description: 'Chat and conversation notifications',
        ),
        AndroidNotificationChannelConfig(
          id: 'marketing_updates',
          name: 'Marketing Updates',
          description: 'Promotions and marketing campaigns',
        ),
      ],
      resolveAndroidChannelId: (event) {
        final category = event.data['category']?.toString();
        if (category == 'chat') {
          return 'chat_messages';
        }
        if (category == 'marketing') {
          return 'marketing_updates';
        }
        return null;
      },
      enableLogs: true,
    );

    await FirebaseMessagingManager.instance.initialize(
      config: config,
      onForegroundMessage: (event) async {
        _addLog(
          'Foreground message id=${event.id} title=${event.title} data=${event.data}',
        );
      },
      onNotificationTap: (event) async {
        _addLog(
          'Notification tap from ${event.appState.name} id=${event.id} data=${event.data}',
        );
      },
      onInitialNotification: (event) async {
        _addLog('Initial notification (terminated launch) id=${event.id}');
      },
      onBackgroundMessage: (event) async {
        _addLog('Background data message id=${event.id} data=${event.data}');
      },
    );

    final status =
        await FirebaseMessagingManager.instance.getPermissionStatus();
    final token = await FirebaseMessagingManager.instance.getToken();

    setState(() {
      _initialized = true;
      _permissionStatus = status;
      _token = token;
    });

    _addLog(
      'Manager initialized with strategy=${_strategy.name}, permission=${status.name}',
    );
  }

  Future<void> _requestPermission() async {
    final settings =
        await FirebaseMessagingManager.instance.requestPermission();
    setState(() {
      _permissionStatus = settings.authorizationStatus;
    });
    _addLog('Permission requested -> ${settings.authorizationStatus.name}');
  }

  Future<void> _refreshPermissionStatus() async {
    final status =
        await FirebaseMessagingManager.instance.getPermissionStatus();
    setState(() {
      _permissionStatus = status;
    });
    _addLog('Permission status -> ${status.name}');
  }

  Future<void> _refreshToken() async {
    final token = await FirebaseMessagingManager.instance.getToken();
    setState(() {
      _token = token;
    });
    _addLog('FCM token refreshed.');
  }

  @override
  void dispose() {
    _customKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Messaging Manager Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Lifecycle & Duplicate Prevention Demo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButton<DuplicateStrategy>(
              value: _strategy,
              items:
                  DuplicateStrategy.values
                      .map(
                        (strategy) => DropdownMenuItem<DuplicateStrategy>(
                          value: strategy,
                          child: Text(strategy.name),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _strategy = value;
                });
              },
            ),
            if (_strategy == DuplicateStrategy.customKey)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Custom duplicate key in payload',
                ),
                controller: _customKeyController,
                onChanged: (value) => _customKey = value.trim(),
              ),
            SwitchListTile(
              title: const Text('Show foreground local notifications'),
              value: _showForegroundNotifications,
              onChanged: (value) {
                setState(() {
                  _showForegroundNotifications = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text(
                'Show background local notifications (data-only)',
              ),
              value: _showBackgroundNotifications,
              onChanged: (value) {
                setState(() {
                  _showBackgroundNotifications = value;
                });
              },
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _initializeManager,
                  child: const Text('Initialize Manager'),
                ),
                OutlinedButton(
                  onPressed: _initialized ? _requestPermission : null,
                  child: const Text('Request Permission'),
                ),
                OutlinedButton(
                  onPressed: _initialized ? _refreshPermissionStatus : null,
                  child: const Text('Check Permission'),
                ),
                OutlinedButton(
                  onPressed: _initialized ? _refreshToken : null,
                  child: const Text('Get Token'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(_logs.clear);
                  },
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Permission: ${_permissionStatus?.name ?? "unknown"}'),
            const SizedBox(height: 4),
            SelectableText(
              'Token: ${_token ?? "not available"}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'How to test duplicate prevention:\n'
              '1) Send two pushes with same messageId or same custom key.\n'
              '2) Keep second push inside dedupe window (12 sec).\n'
              '3) Confirm second event is ignored in logs.',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
