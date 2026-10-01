# stable_device_id

[![pub package](https://img.shields.io/pub/v/stable_device_id.svg)](https://pub.dev/packages/stable_device_id)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Flutter plugin that returns a device identifier that **does not change when the app is updated or reinstalled**, read natively on Android and iOS. On Android you can opt in to an identifier that, on most physical devices, **also survives a factory reset**.

Most device-id packages either return a value that resets on every reinstall (a UUID saved in `SharedPreferences`, `identifierForVendor`), or silently switch between several sources, so the same device can report different identifiers. `stable_device_id` uses the most stable identifier each platform allows and **never switches source behind your back**.

| Platform | Source | Updates | Reinstall | Factory reset |
|---|---|:---:|:---:|:---:|
| Android (default) | `Settings.Secure.ANDROID_ID` | ✅ | ✅ | ❌ |
| Android (`AndroidIdSource.widevine`) | Widevine DRM device ID, hashed per app | ✅ | ✅ | ✅ on most physical devices¹ |
| iOS | UUID stored in the Keychain | ✅ | ✅ | ❌² |

¹ Depends on the device's Widevine implementation. See [Surviving a factory reset](#surviving-a-factory-reset).
² No on-device identifier survives erasing an iPhone. See [Surviving a factory reset](#surviving-a-factory-reset) for the server-side alternative.

- No permissions, entitlements or `Info.plist` keys required.
- Never synced to iCloud and never restored onto another device from a backup.
- Typed errors instead of `null` or random fallbacks.
- Supports migrating the identifier your app already uses.

## Platform support

| Android | iOS |
|:---:|:---:|
| API 24+ | iOS 13+ |

Supports both CocoaPods and Swift Package Manager on iOS.

## Installation

```bash
flutter pub add stable_device_id
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  stable_device_id: ^0.2.0
```

No additional native setup is needed.

## Usage

```dart
import 'package:stable_device_id/stable_device_id.dart';

final String deviceId = await StableDeviceId.getId();
```

The first call creates the identifier (iOS) or reads it (Android); every later call returns the same value. The call is cheap, but you can cache the result in memory if you need it often.

### Choosing the Android source

```dart
// Default: ANDROID_ID. Available on every device; resets on factory reset.
final id = await StableDeviceId.getId();

// Widevine: on most physical devices it also survives a factory reset.
final id = await StableDeviceId.getId(androidSource: AndroidIdSource.widevine);
```

| | `AndroidIdSource.androidId` (default) | `AndroidIdSource.widevine` |
|---|---|---|
| Survives reinstall | ✅ | ✅ |
| Survives factory reset | ❌ | ✅ on most physical devices |
| Available on | Every device | Most devices with Google Play; not on some emulators, custom ROMs or devices without Widevine |
| Format | 16 hex characters | 64 hex characters (SHA-256) |
| Same value in another app | No (scoped to signing key) | No (hashed with the package name) |
| Speed | Instant | Up to a few hundred ms on the first call (runs off the main thread) |

`androidSource` is ignored on iOS, which always returns the Keychain identifier.

**Pick one source and keep it.** The two sources return different values. If you switch from one to the other in a later release, every device will report a new identifier.

If Widevine is not available, `getId` throws `WIDEVINE_UNAVAILABLE`. It never falls back to `ANDROID_ID` on its own, because a silent fallback would make the same device report different identifiers. If you want a fallback, make it explicit and store which source you used:

```dart
import 'package:flutter/services.dart';
import 'package:stable_device_id/stable_device_id.dart';

Future<String> readDeviceId() async {
  try {
    return await StableDeviceId.getId(androidSource: AndroidIdSource.widevine);
  } on PlatformException catch (e) {
    if (e.code != 'WIDEVINE_UNAVAILABLE') rethrow;
    return StableDeviceId.getId(); // ANDROID_ID — send the source to your backend too
  }
}
```

### Handling errors

`getId()` throws a `PlatformException` when the identifier cannot be obtained:

| Code | Platform | Meaning |
|---|---|---|
| `UNAVAILABLE` | Android / Dart | `ANDROID_ID` is not available, or the platform returned an empty value |
| `WIDEVINE_UNAVAILABLE` | Android | `AndroidIdSource.widevine` was requested but the device has no usable Widevine DRM |
| `INVALID_ARGUMENT` | Android | Unknown Android source (only possible with a custom platform implementation) |
| `KEYCHAIN_ERROR` | iOS | Reading or writing the Keychain failed; `details` holds the `OSStatus` code |

```dart
import 'package:flutter/services.dart';
import 'package:stable_device_id/stable_device_id.dart';

try {
  final id = await StableDeviceId.getId();
} on PlatformException catch (e) {
  debugPrint('Could not read device id: ${e.code} ${e.message}');
}
```

### Migrating from an identifier you already store

If your app already generates its own identifier (for example a UUID in `SharedPreferences`), pass it as `initialValue`. On iOS it is saved to the Keychain the first time `getId()` runs, so existing users keep the identifier your backend already knows:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stable_device_id/stable_device_id.dart';

Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final legacyId = prefs.getString('device_id');

  return StableDeviceId.getId(initialValue: legacyId);
}
```

How `initialValue` is used:

- **iOS** – only when the Keychain has no identifier yet. Once an identifier is stored, `initialValue` is ignored.
- **Android** – always ignored; the native identifier is returned. If your backend depends on the old identifier, plan the transition on the server side (for example, send both values for a while).

## Surviving a factory reset

If you need to recognize a device after the user erases it (for example to keep a blocked device blocked), this is what each platform allows:

| | Android | iOS |
|---|---|---|
| On-device identifier that survives a reset | Widevine (`AndroidIdSource.widevine`), on most physical devices | **None.** Erasing the device wipes the Keychain and resets `identifierForVendor` |
| Official server-side mechanism | [Play Integrity API – device recall](https://developer.android.com/google/play/integrity/verdicts) (beta): 3 bits per device stored by Google | [DeviceCheck](https://developer.apple.com/documentation/devicecheck): 2 bits per device stored by Apple |

### Android: Widevine

The Widevine DRM device ID comes from a key provisioned into the device's secure hardware. On physical devices with hardware-backed Widevine (L1), that key is not on the data partition, so the ID usually survives a factory reset. Things to keep in mind:

- **Not every device has it.** Some emulators, custom ROMs, devices without Google services and some low-end devices fail, and you get `WIDEVINE_UNAVAILABLE`.
- **Emulators behave differently.** They use software Widevine (L3) stored on the data partition, so wiping the emulator *does* change the ID. Test factory-reset behavior on physical devices.
- **Behavior depends on the manufacturer.** It is not part of a public guarantee from Google.
- **Privacy.** The raw Widevine ID is shared by every app on the device and cannot be reset by the user. The plugin never returns it as is: it returns `SHA-256(widevineId + packageName)`, so every app gets a different value and the raw ID is never exposed. Google Play allows non-resettable identifiers for fraud prevention, but not for advertising. Declare it in the Data safety form.

### iOS: DeviceCheck

Apple does not offer any identifier that survives erasing an iPhone. The only official mechanism is **DeviceCheck**: your server can store two bits per device on Apple's servers (for example "this device is blocked"). Apple keeps them until your server changes them, across reinstalls and, according to Apple and most implementers, also after the device is erased; verify this on a real device before relying on it. It does not give you an identifier. Your app generates a token with `DCDevice`, sends it to your backend, and your backend queries or updates the bits through Apple's API with a DeviceCheck key from your developer account.

### Blocking a device

A client-side identifier alone is not enough to block a determined attacker: on a rooted or jailbroken device any value the app reads can be spoofed. A robust setup combines:

1. **This plugin** – a stable identifier to recognize the device on every request (`widevine` on Android if you need it to survive resets).
2. **Server-side flags** – Play Integrity device recall on Android and DeviceCheck on iOS, which survive resets and cannot be changed from the device.
3. **Integrity checks** – Play Integrity and App Attest to reject modified apps and compromised devices.

This plugin covers step 1. Steps 2 and 3 need a backend and are outside its scope.

## How it works

### Android

- **`androidId`** returns `Settings.Secure.ANDROID_ID`. Since Android 8.0 (API 26), the value is unique per **app signing key, user and device**. With Play App Signing the signing key stays the same across releases, so the value does not change between versions. Debug builds signed with your local debug key get a **different** value than release builds.
- **`widevine`** reads `MediaDrm.PROPERTY_DEVICE_UNIQUE_ID` for the Widevine scheme on a background thread, hashes it with the app package name using SHA-256 and returns it as 64 lowercase hex characters. Different package names (for example flavors with an `applicationIdSuffix`) get different values.

### iOS

- On the first call, the plugin stores an identifier in the Keychain and returns that value from then on. It uses your `initialValue` if you pass one, otherwise `identifierForVendor`, or a random UUID if that is unavailable.
- The item is saved with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: it can be read in the background after the first unlock, is **never synced to iCloud Keychain** and is **never restored onto another device** from a backup.
- If the Keychain cannot be read (for example before the first unlock after a reboot), the plugin throws `KEYCHAIN_ERROR` instead of generating a new identifier.
- The Keychain service is `<your bundle identifier>.stable_device_id`, so every app gets its own value.
- Keychain items persisting after an app is deleted is the current iOS behavior, but Apple does not formally guarantee it.

## FAQ

**Can I get the IMEI, serial number or MAC address?**
No. Android 10+ blocks these for regular apps, and iOS has never exposed them. This plugin returns the most stable identifiers the platforms allow.

**Is the identifier the same on Android and iOS for the same user?**
No. It identifies a device, not a user. Use your own account id to identify users across devices.

**Will it change if the user restores a backup onto a new phone?**
Yes, on both platforms. A new device gets a new identifier.

**Can I use it for advertising or cross-app tracking?**
No. Use the platform advertising APIs (and App Tracking Transparency on iOS) for that.

## Privacy

The returned value is a device identifier. If you send it to a server:

- Declare **Device ID** in the App Store privacy details.
- Declare **Device or other IDs** in the Google Play Data safety form.

The plugin itself does not collect or send any data, and ships an empty iOS privacy manifest (`PrivacyInfo.xcprivacy`).

## Example

A complete example app is available in the [`example`](example) folder. It shows the identifier from both Android sources.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/jcazalELPAKOMICHI/stable_device_id).

The project pins its Flutter version with [FVM](https://fvm.app) in `.fvmrc` (currently Flutter 3.47.5 / Dart 3.13). Using the same version avoids differences in analysis and generated native files:

```bash
fvm install   # installs the version from .fvmrc
fvm flutter pub get
```

Prefix the commands below with `fvm` (`fvm flutter test`, …) when using FVM. To run the tests:

```bash
# Dart unit tests
flutter test

# Native integration tests (needs a running emulator, simulator or device)
cd example
flutter test integration_test/plugin_integration_test.dart

# Kotlin unit tests (build the example app once first)
cd example/android
./gradlew :stable_device_id:testDebugUnitTest
```

## License

MIT © Jose Cazal. See [LICENSE](LICENSE).
