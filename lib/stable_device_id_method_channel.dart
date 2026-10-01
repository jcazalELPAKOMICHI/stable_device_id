import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'stable_device_id_platform_interface.dart';

/// An implementation of [StableDeviceIdPlatform] that uses method channels.
class MethodChannelStableDeviceId extends StableDeviceIdPlatform {
  static const String _getIdMethod = 'getId';
  static const String _initialValueArgument = 'initialValue';
  static const String _unavailableErrorCode = 'UNAVAILABLE';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('stable_device_id');

  @override
  Future<String> getId({String? initialValue}) async {
    final id = await methodChannel.invokeMethod<String>(_getIdMethod, {
      _initialValueArgument: initialValue,
    });
    if (id == null || id.isEmpty) {
      throw PlatformException(
        code: _unavailableErrorCode,
        message: 'The platform returned an empty device identifier.',
      );
    }
    return id;
  }
}
