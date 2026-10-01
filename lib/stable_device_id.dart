import 'src/android_id_source.dart';
import 'stable_device_id_platform_interface.dart';

export 'src/android_id_source.dart';

/// Provides a device identifier that survives app updates and reinstalls.
///
/// * **Android** – by default returns `Settings.Secure.ANDROID_ID`, scoped to
///   the app signing key, the user and the device. Pass
///   [AndroidIdSource.widevine] to use the Widevine DRM device ID instead,
///   which on most devices also survives a factory reset.
/// * **iOS** – returns a UUID stored in the Keychain with
///   `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. It survives
///   reinstalls, is never synced to iCloud and is not restored onto another
///   device. It changes when the device is erased.
class StableDeviceId {
  const StableDeviceId._();

  /// Returns the stable identifier of this device.
  ///
  /// [androidSource] selects the native source on Android. The source is
  /// never switched silently: if it is not available, a `PlatformException`
  /// is thrown. Ignored on iOS.
  ///
  /// [initialValue] is only used on iOS, the first time an identifier is
  /// requested and nothing is stored in the Keychain yet. Pass the identifier
  /// your app already uses (e.g. one saved in `SharedPreferences`) to keep it
  /// instead of generating a new one. Ignored on Android.
  ///
  /// Throws a `PlatformException` if the identifier cannot be read or stored.
  static Future<String> getId({
    AndroidIdSource androidSource = AndroidIdSource.androidId,
    String? initialValue,
  }) {
    return StableDeviceIdPlatform.instance.getId(
      androidSource: androidSource,
      initialValue: initialValue,
    );
  }
}
