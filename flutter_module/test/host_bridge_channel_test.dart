import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_demo_flutter_module/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ping button invokes host bridge MethodChannel', (tester) async {
    String? receivedMethod;
    String? receivedPayload;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(kHostBridgeChannel),
      (call) async {
        receivedMethod = call.method;
        receivedPayload = call.arguments as String?;
        return jsonEncode({
          'v': 1,
          'id': 'test-1',
          'ok': true,
          'result': {
            'postCount': 2,
            'isStale': false,
            'cacheAgeSeconds': 3,
            'source': 'snapshot',
          },
        });
      },
    );

    await tester.pumpWidget(const SuperDemoFlutterHostApp());
    await tester.tap(find.text('Ping feed.cacheStatus'));
    await tester.pumpAndSettle();

    expect(receivedMethod, kInvokeHostBridge);
    expect(receivedPayload, isNotNull);
    final decoded = jsonDecode(receivedPayload!) as Map<String, dynamic>;
    expect(decoded['v'], 1);
    expect(decoded['method'], 'feed.cacheStatus');
    expect(find.textContaining('"postCount":2'), findsOneWidget);
  });
}
