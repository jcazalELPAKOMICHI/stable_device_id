/// The native source used to build the identifier on Android.
///
/// Ignored on iOS.
enum AndroidIdSource {
  /// `Settings.Secure.ANDROID_ID`.
  ///
  /// Survives updates and reinstalls. Changes after a factory reset or when
  /// the app is signed with another key. Available on every device.
  androidId,

  /// The Widevine DRM device unique ID, hashed with the app package name.
  ///
  /// Survives updates, reinstalls and, on most devices, a factory reset. Not
  /// available on every device (some emulators, devices without Google
  /// services, custom ROMs): in that case `getId` throws a
  /// `PlatformException` with code `WIDEVINE_UNAVAILABLE` instead of
  /// silently falling back to another source.
  widevine,
}
