import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:stable_device_id/stable_device_id.dart';
import 'package:stable_device_id/stable_device_id_method_channel.dart';
import 'package:stable_device_id/stable_device_id_platform_interface.dart';

class MockStableDeviceIdPlatform
    with MockPlatformInterfaceMixin
    implements StableDeviceIdPlatform {
  String? receivedInitialValue;

  @override
  Future<String> getId({String? initialValue}) {
    receivedInitialValue = initialValue;
    return Future.value('device-id');
  }
}

void main() {
  final StableDeviceIdPlatform initialPlatform = StableDeviceIdPlatform.instance;

  test('$MethodChannelStableDeviceId is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelStableDeviceId>());
  });

  test('getId delegates to the platform', () async {
    final fakePlatform = MockStableDeviceIdPlatform();
    StableDeviceIdPlatform.instance = fakePlatform;

    expect(await StableDeviceId.getId(initialValue: 'legacy'), 'device-id');
    expect(fakePlatform.receivedInitialValue, 'legacy');
  });
}
