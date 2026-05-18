class AndroidNotificationChannelConfig {
  const AndroidNotificationChannelConfig({
    required this.id,
    required this.name,
    this.description = 'Notification channel.',
  });

  final String id;
  final String name;
  final String description;
}
