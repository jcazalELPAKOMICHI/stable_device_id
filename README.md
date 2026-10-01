# stable_device_id

[![pub package](https://img.shields.io/pub/v/stable_device_id.svg)](https://pub.dev/packages/stable_device_id)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Flutter plugin that returns a device identifier that **does not change when the app is updated or reinstalled**, read natively on Android and iOS.

Most device-id packages either return a value that resets on every reinstall (a UUID saved in `SharedPreferences`, `identifierForVendor`) or rely on hardware identifiers that modern Android and iOS no longer expose. `stable_device_id` uses the most stable identifier each platform allows:

| Platform | Source | Survives updates | Survives reinstall | Changes when |
|---|---|:---:|:---:|---|
| Android | `Settings.Secure.ANDROID_ID` | ✅ | ✅ | Factory reset, a different device user, or the app is signed with another key |
| iOS | UUID stored in the Keychain | ✅ | ✅ | The device is erased or its Keychain is reset |

- No permissions, entitlements or `Info.plist` keys required.
- Never synced to iCloud and never restored onto another device from a backup.
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
  stable_device_id: ^0.1.0
```

No additional native setup is needed.

## Usage

```dart
import 'package:stable_device_id/stable_device_id.dart';

final String deviceId = await StableDeviceId.getId();
```

The first call creates the identifier (iOS) or reads it (Android); every later call returns the same value. The call is cheap, but you can cache the result in memory if you need it often.

### Handling errors

`getId()` throws a `PlatformException` when the identifier cannot be obtained:

```dart
import 'package:flutter/services.dart';
import 'package:stable_device_id/stable_device_id.dart';

Future<String?> readDeviceId() async {
  try {
    return await StableDeviceId.getId();
  } on PlatformException catch (e) {
    debugPrint('Could not read device id: ${e.code} ${e.message}');
    return null;
  }
}
```

| Code | Platform | Meaning |
|---|---|---|
| `UNAVAILABLE` | Android / Dart | `ANDROID_ID` is not available, or the platform returned an empty value |
| `KEYCHAIN_ERROR` | iOS | Reading or writing the Keychain failed; `details` holds the `OSStatus` code |

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
- **Android** – always ignored; `ANDROID_ID` is returned. If your backend depends on the old identifier, plan the transition on the server side (for example, send both values for a while).

### Mocking in tests

The plugin uses a method channel named `stable_device_id`, so you can mock it in widget and unit tests:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('stable_device_id'),
          (_) async => 'test-device-id',
        );
  });

  // ...
}
```

You can also replace the implementation with your own `StableDeviceIdPlatform` subclass through `StableDeviceIdPlatform.instance`.

## How it works

### Android

- Returns `Settings.Secure.ANDROID_ID`.
- Since Android 8.0 (API 26), the value is unique per **app signing key, user and device**. Two apps signed with different keys get different values on the same device.
- With Play App Signing the signing key stays the same across releases, so the value does not change between versions.
- Debug builds signed with your local debug key get a **different** value than release builds.
- On Android 7.x and earlier, the value is shared by all apps on the device.

### iOS

- On the first call, the plugin stores an identifier in the Keychain and returns that value from then on. It uses your `initialValue` if you pass one, otherwise `identifierForVendor`, or a random UUID if that is unavailable.
- The item is saved with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: it can be read in the background after the first unlock, is **never synced to iCloud Keychain** and is **never restored onto another device** from a backup.
- The Keychain service is `<your bundle identifier>.stable_device_id`, so every app gets its own value.
- Keychain items persisting after an app is deleted is the current iOS behavior, but Apple does not formally guarantee it.
- The Keychain works on the iOS Simulator, but its identifier is different from any real device.

## FAQ

**Can I get the IMEI, serial number or MAC address?**
No. Android 10+ blocks these for regular apps, and iOS has never exposed them. This plugin returns the most stable identifier the platforms allow.

**Is the identifier the same on Android and iOS for the same user?**
No. It identifies a device installation, not a user. Use your own account id to identify users across devices.

**Will it change if the user restores a backup onto a new phone?**
Yes, on both platforms. A new device gets a new identifier, which is usually what you want for device binding.

**Can I use it for advertising or cross-app tracking?**
No. Use the platform advertising APIs (and App Tracking Transparency on iOS) for that.

## Privacy

The returned value is a device identifier. If you send it to a server:

- Declare **Device ID** in the App Store privacy details.
- Declare **Device or other IDs** in the Google Play Data safety form.

The plugin itself does not collect or send any data, and ships an empty iOS privacy manifest (`PrivacyInfo.xcprivacy`).

## Example

A complete example app is available in the [`example`](example) folder.

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
