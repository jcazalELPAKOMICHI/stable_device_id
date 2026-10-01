## 0.1.0

* Initial release.
* `StableDeviceId.getId()` returns `ANDROID_ID` on Android and a Keychain-backed UUID on iOS.
* `initialValue` lets iOS apps keep an identifier they already use when migrating.
