// Integration tests run in a full Flutter application, so they exercise the
// native side of the plugin. Run with:
// flutter test integration_test/plugin_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:stable_device_id/stable_device_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getId returns a non-empty identifier', (WidgetTester tester) async {
    final id = await StableDeviceId.getId();

    expect(id, isNotEmpty);
  });

  testWidgets('getId returns the same identifier on every call', (
    WidgetTester tester,
  ) async {
    final first = await StableDeviceId.getId();
    final second = await StableDeviceId.getId(initialValue: 'ignored');

    expect(second, first);
  });
}
