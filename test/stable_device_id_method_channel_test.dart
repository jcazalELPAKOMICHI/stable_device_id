import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stable_device_id/stable_device_id.dart';
import 'package:stable_device_id/stable_device_id_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelStableDeviceId();
  const channel = MethodChannel('stable_device_id');
  MethodCall? lastCall;

  void mockResponse(Object? response) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          lastCall = methodCall;
          return response;
        });
  }

  tearDown(() {
    lastCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getId returns the native identifier', () async {
    mockResponse('device-id');

    expect(await platform.getId(), 'device-id');
    expect(lastCall?.method, 'getId');
    expect(lastCall?.arguments, {
      'androidSource': 'androidId',
      'initialValue': null,
    });
  });

  test('getId forwards the Android source and initialValue', () async {
    mockResponse('legacy');

    await platform.getId(
      androidSource: AndroidIdSource.widevine,
      initialValue: 'legacy',
    );

    expect(lastCall?.arguments, {
      'androidSource': 'widevine',
      'initialValue': 'legacy',
    });
  });

  test('getId throws when the platform returns null', () async {
    mockResponse(null);

    expect(platform.getId(), throwsA(isA<PlatformException>()));
  });

  test('getId throws when the platform returns an empty string', () async {
    mockResponse('');

    expect(platform.getId(), throwsA(isA<PlatformException>()));
  });
}
