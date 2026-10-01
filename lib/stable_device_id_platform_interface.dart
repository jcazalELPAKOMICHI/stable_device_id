import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'stable_device_id_method_channel.dart';

/// The interface that implementations of stable_device_id must implement.
abstract class StableDeviceIdPlatform extends PlatformInterface {
  /// Constructs a StableDeviceIdPlatform.
  StableDeviceIdPlatform() : super(token: _token);

  static final Object _token = Object();

  static StableDeviceIdPlatform _instance = MethodChannelStableDeviceId();

  /// The default instance of [StableDeviceIdPlatform] to use.
  ///
  /// Defaults to [MethodChannelStableDeviceId].
  static StableDeviceIdPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [StableDeviceIdPlatform] when
  /// they register themselves.
  static set instance(StableDeviceIdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the stable identifier of this device.
  Future<String> getId({String? initialValue}) {
    throw UnimplementedError('getId() has not been implemented.');
  }
}
