import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_messaging_manager/firebase_messaging_manager.dart';

void main() {
  test('provides singleton messaging manager', () {
    expect(FirebaseMessagingManager.instance, isA<FirebaseMessagingManager>());
  });

  test('default config uses messageId dedupe', () {
    const config = FirebaseMessagingManagerConfig();
    expect(config.duplicateStrategy, DuplicateStrategy.messageId);
  });
}
