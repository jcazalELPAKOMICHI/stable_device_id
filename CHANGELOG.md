## 0.2.0

* Add `AndroidIdSource.widevine`: the Widevine DRM device ID, hashed with the package name. On most physical devices it also survives a factory reset.
* The Android source is never switched silently: if Widevine is not available, `getId` throws `WIDEVINE_UNAVAILABLE`.
* Unknown Android sources throw `INVALID_ARGUMENT`.
* Widevine is read off the main thread.

## 0.1.0

* Initial release.
* `StableDeviceId.getId()` returns `ANDROID_ID` on Android and a Keychain-backed UUID on iOS.
* `initialValue` lets iOS apps keep an identifier they already use when migrating.
