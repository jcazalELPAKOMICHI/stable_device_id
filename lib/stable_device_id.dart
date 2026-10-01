import 'stable_device_id_platform_interface.dart';

/// Provides a device identifier that survives app updates and reinstalls.
///
/// * **Android** – returns `Settings.Secure.ANDROID_ID`. Since Android 8.0 it
///   is scoped to the app signing key, the user and the device. It only
///   changes after a factory reset or when the app is signed with another key.
/// * **iOS** – returns a UUID stored in the Keychain with
///   `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. It survives
///   reinstalls, is never synced to iCloud and is not restored onto another
///   device. It only changes after the device is erased.
class StableDeviceId {
  const StableDeviceId._();

  /// Returns the stable identifier of this device.
  ///
  /// [initialValue] is only used on iOS, the first time an identifier is
  /// requested and nothing is stored in the Keychain yet. Pass the identifier
  /// your app already uses (e.g. one saved in `SharedPreferences`) to keep it
  /// instead of generating a new one. Ignored on Android.
  ///
  /// Throws a `PlatformException` if the identifier cannot be read or stored.
  static Future<String> getId({String? initialValue}) {
    return StableDeviceIdPlatform.instance.getId(initialValue: initialValue);
  }
}
